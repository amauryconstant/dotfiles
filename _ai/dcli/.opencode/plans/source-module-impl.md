# dcli Source Module Implementation Plan

## Overview
Add a `dcli source` command to build packages from git repositories, with declarative configuration similar to regular modules.

## Key Decisions
- Source repos: `~/.config/arch-config/sources/repos/` (default, overridable)
- Tracking: Use `checkinstall` to create trackable packages
- Build: Direct system builds (simpler, no chroot)
- Multi-distro: Same YAML/Lua configs, distro-specific build logic

## Configuration Structure

### Source Module Manifest (source.yaml)
```yaml
name: hyprland-git
description: Hyprland window manager from git
version: "1.0.0"

source:
  url: https://github.com/hyprwm/Hyprland.git
  branch: main
  depth: 1
  # clone_path: /custom/path/to/repo  # optional override

build:
  dependencies:
    - cmake
    - meson
    - ninja
    - wayland-protocols
  
  commands:
    - meson setup build --prefix=/usr/local
    - ninja -C build
    - sudo ninja -C build install
  
  # Alternative: script: build.sh

update:
  check: git
  auto_rebuild: true

package:
  use_checkinstall: true
  pkgname: hyprland-git
  pkgver: auto
  pkgdesc: "Hyprland window manager built from source"
```

### In Host Config
```yaml
host: myhost

enabled_sources:
  - hyprland-git
  - waybar-git
```

## CLI Commands
- `dcli source list` - List all source modules
- `dcli source add <git-url> [name]` - Create new source
- `dcli source build [name]` - Build specific/all sources
- `dcli source remove <name>` - Uninstall source
- `dcli source update` - Check and rebuild updates
- `dcli sync` - Also builds sources (with --skip-sources flag)

## Implementation Files
```
src/
├── commands/source.rs         # dcli source subcommand
├── source/
│   ├── mod.rs                # SourceManager, SourceModule
│   ├── config.rs             # SourceConfig structs
│   ├── builder.rs            # Build execution
│   ├── installer.rs          # checkinstall integration
│   ├── updater.rs            # Update checking
│   └── tracker.rs            # State management
└── config/mod.rs             # Add enabled_sources field
```

## State Tracking
File: `~/.config/arch-config/state/sources.yaml`
```yaml
sources:
  hyprland-git:
    repo_path: /home/user/.config/arch-config/sources/repos/hyprland-git
    installed_commit: abc123
    package_name: hyprland-git
    is_installed: true
```

## Build Flow
1. Parse source.yaml
2. Install build dependencies via pacman
3. Clone repo to sources/repos/<name>/
4. Run build commands
5. Use checkinstall to create .pkg.tar.zst
6. Install via pacman
7. Update state file

## Phases
1. Core infrastructure (config, state, list command)
2. Add and build (clone, build, checkinstall)
3. Update and sync integration
4. Advanced (remove, scripts, PKGBUILD)
5. Polish (TUI, logging, docs)
