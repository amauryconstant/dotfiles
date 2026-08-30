# Nix Modules Guide

## Overview

Nix modules provide a powerful alternative to YAML and Lua for creating package
configurations. While YAML modules are static and Lua modules use embedded Lua
scripts, Nix modules are evaluated by the real `nix` binary with access to
`nixpkgs`, enabling complex package expressions, attribute set manipulation,
and integration with existing Nix workflows.

**Use Nix modules when you need:**

- Access to `nixpkgs` for package filtering, version checks, or custom derivations
- Complex conditional logic based on system facts
- Integration with existing Nix flake or expression-based workflows
- Nix-based host configurations alongside module definitions

## Prerequisites

Nix modules require `nix` to be installed with the `nix-command` experimental
feature enabled:

```bash
# In ~/.config/nix/nix.conf or /etc/nix/nix.conf:
experimental-features = nix-command flakes
```

If `nix` is not installed or the feature is disabled, dcli falls back to
`module.lua` or `module.yaml` automatically.

## Quick Start

### Basic Nix Module

Create a file with `.nix` extension in your modules directory:

```nix
# ~/.config/arch-config/modules/gaming.nix
{ pkgs, system }: {
  description = "Gaming packages";
  packages = [
    "steam"
    "lutris"
    "wine"
    "gamemode"
  ];
}
```

Enable and sync like any other module:

```bash
dcli module enable gaming
dcli sync
```

### Directory Module with module.nix

Directory modules can use `module.nix` as the manifest instead of
`module.lua` or `module.yaml`:

```
modules/gaming/
├── module.nix          # Manifest (takes precedence over module.lua/module.yaml)
├── packages.nix        # Optional: Nix-based package files
├── packages.yaml       # Optional: YAML-based package files
├── scripts/
│   └── setup.sh
└── dotfiles/
    └── ...
```

```nix
# modules/gaming/module.nix
{ pkgs, system }: {
  description = "Gaming packages with conditional NVIDIA drivers";

  packages =
    # Base gaming packages
    [
      "steam"
      "lutris"
      "wine"
      "gamemode"
    ]
    # Conditionally add NVIDIA drivers
    ++ pkgs.lib.optionals (system == "x86_64-linux") [
      "nvidia"
      "nvidia-utils"
    ];

  package_files = [ "packages-extra.nix" ];
  post_install_hook = "scripts/setup.sh";
}
```

## Module Structure

A Nix module is a function `{ pkgs, system }: { ... }` that returns an
attribute set. The available fields are:

```nix
{ pkgs, system }: {
  description = "My module description";

  packages = [
    "pkg1"
    "pkg2"
    "flatpak:com.spotify.Client"    # Flatpak with prefix syntax
  ];

  flatpak_packages = [
    "com.spotify.Client"             # Alternative flatpak field
  ];

  nix_packages = [
    "helix"                          # Packages installed via nix profile
  ];

  deb_packages = [
    "package.deb"                    # Local .deb packages
  ];

  conflicts = [ "other-module" ];

  services = {
    enabled = [ "docker.service" ];
    disabled = [ "cups.service" ];
  };

  pre_install_hook = "scripts/pre-setup.sh";
  post_install_hook = "scripts/post-setup.sh";

  hook_behavior = "ask";
  pre_hook_behavior = "once";
  post_hook_behavior = "always";
  post_disable_hook = "scripts/cleanup.sh";
  post_disable_behavior = "ask";
  run_hooks_as_user = false;

  # Sharing metadata (for upload)
  author = "your-username";
  version = "1.0.0";
  category = "development";
  tags = [ "python" "tools" ];
  license = "MIT";
  upstream_url = "https://github.com/example/module";
}
```

## System Facts

Nix modules receive system facts via the `system` argument, which matches
`builtins.currentSystem` (e.g., `"x86_64-linux"`, `"aarch64-linux"`).

The `pkgs` argument is the default `nixpkgs` package set, giving you access
to all of nixpkgs for package filtering, version checks, and more.

## Package Entry Formats

```nix
{ pkgs, system }: {
  packages = [
    "firefox"                         # Simple native package
    "flatpak:com.spotify.Client"      # Flatpak with prefix
    "nix:helix"                       # Nix profile package

    # Structured package entries
    { name = "com.discordapp.Discord"; type = "flatpak"; }
    { name = "steam"; type = null; }  # Native (default)
  ];
}
```

## Differences from Lua Modules

| Feature | Lua Modules | Nix Modules |
|---------|-------------|-------------|
| **Runtime** | Embedded Lua interpreter | External `nix` binary |
| **Package access** | dcli API helpers (`dcli.hardware.*`, etc.) | Full `nixpkgs` via `pkgs` argument |
| **Conditional logic** | Lua `if`/`else`, loops | Nix expressions, `pkgs.lib.optionals`, etc. |
| **System facts** | dcli-provided API | `system` string + facts JSON internally |
| **Performance** | Fast (in-process) | Slower (subprocess eval) |
| **Dependency** | None (vendored Lua) | Requires `nix` with `nix-command` |

> **Note:** If `module.nix` exists alongside `module.lua` or `module.yaml` in a
> directory module, `module.nix` takes precedence (`module.nix` > `module.lua` > `module.yaml`).
