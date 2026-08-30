# Mixed config format support (YAML + Lua + Nix)

**Order: 3rd** (after `per-backend-packages`, before `dcli-install-per-backend`)

## Current behavior

`resolve_config_path()` picks **exactly one** config format in priority order:
`config.lua` > `config.nix` (if nix installed) > `config.yaml`. Having both
`config.lua` and `config.nix` is an error.

## New behavior

Load **all** existing top-level config files and merge them into one `Config`.
Last loaded wins for scalar values; lists are appended.

## Conflicts with other plans

| Plan | Conflict | Resolution |
|---|---|---|
| `per-backend-packages` | Both modify `Config::merge()` and `load_config()` | The `Config::merge()` update from `per-backend-packages` is a prerequisite. This plan extends `load_config()` to load multiple files. |
| `dcli-install-per-backend` | `resolve_config_path()` behavior may change | Keep `resolve_config_path()` returning a single primary path for host file editing; the mixed loading only applies to `load_config()` |

## Implementation

### `load_config()` (`src/config/mod.rs:1728`)

Replace the single-path resolution with multi-path loading:

```rust
pub fn load_config(paths: &ConfigPaths) -> Result<Config> {
    let mut config = Config::default();
    let mut pointer_pkg_manager = None;

    // Load YAML first (base)
    let yaml_path = paths.config_dir.join("config.yaml");
    if yaml_path.exists() {
        let content = std::fs::read_to_string(&yaml_path)?;
        if is_pointer_config_raw(&content) {
            let pointer: Config = serde_yaml::from_str(&content)?;
            let host_file = paths.host_packages_file(&pointer.host);
            if host_file.exists() {
                config = load_config_from_file(paths, &host_file)?;
            }
            if let Some(pm) = pointer.package_manager {
                pointer_pkg_manager = Some(pm);
            }
        } else {
            let file_config: Config = serde_yaml::from_str(&content)?;
            config.merge(file_config);
        }
    }

    // Load Lua second (overrides YAML)
    let lua_path = paths.config_dir.join("config.lua");
    if lua_path.exists() {
        let lua_config = load_config_from_file(paths, &lua_path)?;
        config.merge(lua_config);
    }

    // Load Nix last (highest priority)
    let nix_path = paths.config_dir.join("config.nix");
    if nix_path.exists() && crate::nix_eval::is_nix_installed() {
        let nix_config = load_config_from_file(paths, &nix_path)?;
        config.merge(nix_config);
    }

    // Apply pointer package_manager if set
    if let Some(pm) = pointer_pkg_manager {
        config.package_manager = Some(pm);
    }

    // Host-specific companion packages (existing logic)
    // ...

    // Handle imports from the primary config file
    // ...

    Ok(config)
}
```

### `resolve_config_path()` (`src/config/mod.rs:1605`)

Keep unchanged for backward compat. It returns the **primary** config path
(for single-file editing in `dcli install`/`dcli edit`). The mixed loading is
internal to `load_config()`.

### `Config::merge()` (`src/config/mod.rs:182`)

Already updated by `per-backend-packages` to merge the 3 new per-backend
fields. No additional changes needed here.

### Validation

Remove the error in `resolve_config_path()` about having both `config.lua`
and `config.nix`.

## Host-file resolution in mixed mode

If config files exist in multiple formats at the host level too:

- `hosts/myhost.yaml` — loaded
- `hosts/myhost.lua` — loaded and merged (overrides YAML)
- `hosts/myhost.nix` — loaded and merged (overrides both)

The `host` field is determined by whichever pointer config exists (or is
explicitly set) and must be consistent across formats.

## Limitations

- No cross-format imports (`import:` only works within files matching the
  host format)
- Pointer configs in Lua/Nix that don't match the YAML host is undefined
  behavior (user shouldn't mix pointers)
