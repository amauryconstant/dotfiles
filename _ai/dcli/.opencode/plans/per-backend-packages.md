# Per-backend package fields

**Order: 2nd** (after `module-nix-support`, before `mixed-config-formats`)

Add `packages_pacman`, `packages_apt`, `packages_dnf` fields to config and module
data structures. The generic `packages:` list is always included; the per-backend
field is only merged when the active package manager matches.

## Conflicts with other plans

| Plan | Conflict | Resolution |
|---|---|---|
| `mixed-config-formats` | Both modify `Config::merge()` and `load_config()` | Implement `Config::merge()` here (first), then `mixed-config-formats` will extend it. `load_config()` changes are deferred to `mixed-config-formats`. |
| `dcli-install-per-backend` | This plan provides the fields `dcli-install` writes to | Prerequisite — implement this first |

## Structures to modify

All with `#[serde(default)]` so existing configs work unchanged.

| Struct | File:Line | Add |
|---|---|---|
| `Config` | `src/config/mod.rs:7` | `packages_pacman`, `packages_apt`, `packages_dnf: Vec<PackageEntry>` |
| `PackageList` | `src/config/mod.rs:850` | same 3 fields |
| `DynamicModule` | `src/config/mod.rs:923` | same 3 fields |
| `ModuleManifest` | `src/config/mod.rs:1255` | same 3 fields |
| `LuaModule` | `src/lua/mod.rs:101` | same 3 fields |
| `NixConfigRaw` | `src/nix_eval/types.rs:104` | same 3 fields |
| `NixModuleRaw` | `src/nix_eval/types.rs:344` | same 3 fields |

## Module filtering

Add to `ModuleStructure` (`src/config/mod.rs:1081`):
- `packages_for_backend(backend: &PackageManagerType) -> Vec<PackageEntry>`
  - returns `self.packages()` + per-backend field matching the given backend
  - for `Legacy` variant: reads from `content.packages_pacman` etc.
  - for `Directory`: reads from `dir.manifest.packages_pacman` etc.
  - for `Lua`: reads from `lua.packages_pacman` etc.
  - for `Nix`: reads from `dyn_mod.packages_pacman` etc.

## Package resolution

In `PackageManager::get_declared_packages()` (`src/package/mod.rs:34`):

1. Resolve active backend once with `resolve_package_manager(&config)?`
2. After step 4 (host packages), merge config-level per-backend packages:

```rust
let backend = resolve_package_manager(&config)?;
let per_backend = match backend {
    PackageManagerType::Pacman => &config.packages_pacman,
    PackageManagerType::Apt => &config.packages_apt,
    PackageManagerType::Dnf => &config.packages_dnf,
};
packages.extend(per_backend.iter().map(Package::from));
```

3. Step 5 (module loop): use `module.packages_for_backend(&backend)` instead of
   `module.packages()`

## Config merge

Update `Config::merge()` (`src/config/mod.rs:182`) to also merge the 3 new
fields (append lists, same as `packages` merge). This will be extended by
`mixed-config-formats`.

## Nix conversion

- `NixConfigRaw::to_config()` — convert `packages_pacman` etc. to `Vec<PackageEntry>`
- `NixModuleRaw::to_nix_module()` / `to_module_manifest()` — same

## Lua loading

- Read `packages_pacman`, `packages_apt`, `packages_dnf` from Lua tables in
  both config loader and module loader (`src/lua/mod.rs`)
