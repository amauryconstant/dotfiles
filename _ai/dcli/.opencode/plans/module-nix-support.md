# Fix directory-based Nix module discovery

**Order: 1st** (independent, no dependencies)

## Bug

`list_modules()` in `src/module/mod.rs:127-132` only checks for `module.lua`
and `module.yaml`, skipping directories that have only `module.nix`:

```rust
let has_lua_manifest = path.join("module.lua").exists();
let has_yaml_manifest = path.join("module.yaml").exists();
if !has_lua_manifest && !has_yaml_manifest {
    continue;  // BUG: module.nix directories are skipped
}
```

## Conflicts with other plans

None — touches entirely different files than the other plans (`module/mod.rs`,
`commands/find.rs`, `tui/screens/upload.rs`).

## Fixes

### 1. `src/module/mod.rs:127-132` — missing `module.nix` check

```rust
let has_nix_manifest = path.join("module.nix").exists();
if !has_lua_manifest && !has_yaml_manifest && !has_nix_manifest {
    continue;
}
```

### 2. `ModuleInfo` struct (`src/module/mod.rs:384-392`) — missing `is_nix`

Add field:
```rust
pub struct ModuleInfo {
    pub name: String,
    pub description: String,
    pub package_count: usize,
    pub conflicts: Vec<String>,
    pub post_install_hook: Option<String>,
    pub is_directory: bool,
    pub is_lua: bool,
    pub is_nix: bool,  // NEW
}
```

Set `is_nix` in the directory module push (line ~163) based on whether
`module.nix` is the manifest.

### 3. `src/commands/find.rs:111-113` — missing `module.nix` display

Add branch for display path:
```rust
if module_path.join("module.lua").exists() {
    module_path.join("module.lua")
} else if module_path.join("module.nix").exists() {
    module_path.join("module.nix")
} else if module_path.join("module.yaml").exists() {
    module_path.join("module.yaml")
} else {
    module_path.clone()
}
```

### 4. `src/tui/screens/upload.rs:158-162` — skips `.nix` standalone files

Add `is_nix` handling:
```rust
let module_path = if module_info.is_directory {
    modules_dir.join(&module_info.name)
} else if module_info.is_lua {
    modules_dir.join(format!("{}.lua", &module_info.name))
} else if module_info.is_nix {
    modules_dir.join(format!("{}.nix", &module_info.name))
} else {
    continue; // skip legacy YAML single-file modules
};
```

## Verification

No other locations need changes — `grep` shows all 65+ other `module.nix`
checks across the codebase already include it.
