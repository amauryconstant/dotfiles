# `dcli install` writes to per-backend field in host config

**Order: 4th** (after `per-backend-packages` and `mixed-config-formats`)

## Prerequisites

1. `per-backend-packages` — `Config` must have `packages_pacman`, `packages_apt`, `packages_dnf` fields
2. `mixed-config-formats` — `resolve_config_path()` may return multiple paths; host config resolution must be stable

## Conflicts with other plans

| Plan | Conflict | Resolution |
|---|---|---|
| `per-backend-packages` | This plan writes to the fields that plan defines | Implement after it |
| `mixed-config-formats` | `resolve_config_path()` behavior changes | Use the final version of `resolve_config_path()` (single path, for the primary host config) |

## Current behavior

`dcli install firefox` installs via backend, then adds `firefox` to a separate
`declared-packages.yaml` file.

## New behavior

`dcli install firefox` installs via backend, then adds `firefox` directly under
`packages_pacman:` (or `packages_apt:` / `packages_dnf:`) in the **host config
file** — the one resolved by `resolve_config_path()`.

Flatpak (`flatpak:...`) and nix (`nix:...`) prefixes still go to the generic
`packages:` list.

## Implementation

### `add_package_to_host_config` (`src/commands/simple.rs:40`)

```rust
fn add_package_to_host_config(package: &str, paths: &ConfigPaths) -> Result<()> {
    // 1. Load config to check duplicates + resolve backend
    let config = load_config(paths)?;
    let backend = resolve_package_manager(&config)?;

    // 2. Determine target field name
    let (target_field, is_backend_specific) = if package.starts_with("flatpak:")
        || package.starts_with("nix:")
    {
        ("packages", false)
    } else {
        match backend {
            PackageManagerType::Pacman => ("packages_pacman", true),
            PackageManagerType::Apt => ("packages_apt", true),
            PackageManagerType::Dnf => ("packages_dnf", true),
        }
    };

    // 3. Read the host config file
    let config_path = resolve_config_path(paths)?;

    // 4. Check if already declared (existing logic)

    // 5. Add to the right field in the host config file
    match config_path.extension().and_then(|e| e.to_str()) {
        Some("yaml" | "yml") => add_to_yaml_field(&config_path, target_field, package)?,
        Some("lua") => add_to_lua_field(&config_path, target_field, package)?,
        Some("nix") => add_to_nix_field(&config_path, target_field, package)?,
        _ => bail!("unsupported config format"),
    }

    Ok(())
}
```

### Write-back strategies

**YAML**: Parse as `serde_yaml::Value`, locate/create the sequence at the
target key, append the package name, serialize back. This preserves existing
keys, but may reorder fields.

**Lua**: Parse the Lua file to find the target table field (or add it at the
end), append the package string. Simple string manipulation for the common
case (`packages_pacman = { "firefox" }`).

**Nix**: Same approach — find the target attr or add it, append to the list.

### `remove_package_from_host_config` (`src/commands/simple.rs:147`)

Mirror the add logic: resolve backend, determine target field, read host
config, remove the package name from the matching list, write back.

## Edge cases

| Case | Handling |
|---|---|
| Field doesn't exist yet | Create the field with `[package]` |
| Package already in field | Skip (existing dup check) |
| Package in generic `packages` | Leave it; per-backend is additive |
| Package in wrong per-backend field (e.g. in `packages_apt` on Arch) | `dcli sync` ignores it |
| Host config file doesn't exist | Create host config with the per-backend list |
