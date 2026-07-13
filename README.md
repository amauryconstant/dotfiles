<!--# dcli-->

**A declarative package management tool for Linux** that brings NixOS-style configuration management to Arch Linux and Debian/Ubuntu-based distributions. Define your entire system in YAML files, organize packages into reusable modules, and sync your setup across multiple machines with confidence. No more manually tracking what you installed - your configuration is the source of truth.

**Supported Package Managers:**
- **Pacman** (Arch Linux, Manjaro, EndeavourOS, etc.)
- **APT** (Debian, Ubuntu, Linux Mint, Pop!_OS, etc.)

**Why use dcli?**
- 🎯 **Declarative**: Define what you want, not how to get there
- 🔄 **Reproducible**: Same config = same system, every time
- 📦 **Organized**: Modules keep related packages together (gaming, dev, media)
- 🖥️ **Multi-machine**: Share configs, customize per host
- 🔒 **Safe**: Automatic backups, conflict detection, validation
- ⚡ **Fast**: Rust-powered, zero runtime dependencies

Built with Rust for performance and reliability.

> **⚠️ BETA SOFTWARE** - Use at your own risk. Always maintain backups before major operations. I am not a full stack developer so I have utilized opensource AI models for help with areas I lack. If you would like to contribute or help expand the software, PRs are welcome or you can message me on discord! 

---

**💖 Support the Project**

If dcli saves you time or makes your Arch life easier, consider supporting development:

**[🥤 Buy me an orange soda on Ko-fi](https://ko-fi.com/theblackdon)**

## Quick Links

- [Installation](#installation)
  - [Arch Linux (AUR)](#arch-linux-aur)
  - [Fedora (COPR)](#fedora-copr)
  - [Debian/Ubuntu (Manual Install)](#debianubuntu-manual-install)
- [Quick Start](#quick-start)
- [Core Commands](#core-commands)
- [Configuration](#configuration)
- [Services Management](#services-management)
- [AUR Package](#aur-package)
- [Manual Install](#manual-install)

---

## Features

### Package Management
- **Declarative Configuration** - Define packages in YAML, Lua, or Nix, sync your system to match
- **Lua Scripting** - Dynamic configs with hardware detection, conditional logic, and system queries
- **Module System** - Organize packages into reusable modules (gaming, development, etc.)
- **Host-Specific Configs** - Different package sets per machine with shared modules
- **Flatpak Support** - Seamlessly manage flatpak apps alongside pacman packages
- **Safe Merge** - Capture manually installed packages without dependencies
- **Dependency Tracking** - Optional `--include-deps` flag to capture all dependencies in a separate module
- **Conflict Detection** - Prevents enabling conflicting modules

### Interactive TUI (powered by fzf)
- **`dcli search`** - Multi-select package search with live preview
- **`dcli module enable/disable`** - Interactive module selection
- **`dcli restore`** - Browse and restore snapshots
- **`dcli hooks run`** - Select and run post-install hooks
- **`dcli edit`** - Interactive config file editor

### System Management
- **Dotfiles Management** - GNU Stow-like dotfiles with conflict detection and flexible path mapping
- **Services** - Declaratively manage systemd services alongside packages
- **Default Applications** - Set default apps for browsers, editors, terminals, and custom MIME types
- **Sequential Module Processing** - Process modules in order with pre/post hooks (perfect for repo setup)
- **Backups** - Config backups + system snapshots (Timeshift/Snapper)
- **Post-Install Hooks** - Run scripts after package installation with fine-grained control
- **Git Integration** - Built-in commands to sync configs across machines
- **Self-Updating** - Update dcli with a single command

### Developer Features
- **Zero Runtime Dependencies** - Self-contained Rust binary
- **JSON Output** - All commands support `--json` for scripting
- **Validation** - `dcli validate` checks config integrity
- **Migration Tool** - Safely migrate from old config structure

---

## Installation

### Arch Linux (AUR)

**Recommended for Arch-based distributions:**

```bash
# Using an AUR helper
yay -S dcli-arch-git
# or
paru -S dcli-arch-git
```

The installer will:
1. Install Rust toolchain if needed
2. Build the release binary
3. Install to `/usr/local/bin/dcli`
4. Check for optional dependencies (AUR helper, backup tools)

**Prerequisites:**
- Arch Linux or Arch-based distro
- Rust toolchain (installer handles this)

**Optional:**
- `fzf` - For interactive TUI features
- `paru` or `yay` - AUR package support
- `timeshift` or `snapper` - System backups

### Fedora (COPR)

**Recommended for Fedora and RHEL-based distributions:**

```bash
# Enable the COPR repository
sudo dnf copr enable theblackdon/dcli

# Install dcli
sudo dnf install dcli
```

The COPR package provides:
- Pre-built binary installed to `/usr/bin/dcli`
- Zsh completion at `/usr/share/zsh/site-functions/_dcli`
- Automatic updates via `dnf update`

**Prerequisites:**
- Fedora 40+ or RHEL/CentOS 9+

**Optional:**
- `fzf` - For interactive TUI features

> 💡 **Tip:** COPR is the easiest way to install and keep dcli up to date on Fedora. The package is built against the latest Fedora releases.

### Debian/Ubuntu (Manual Install)

**For Debian, Ubuntu, and derivatives, use the manual install script:**
thebla
> ⚠️ **Note:** The AUR package is Arch-specific. Debian/Ubuntu users **must** use the manual install method below.

```bash
# Install prerequisites
sudo apt update
sudo apt install -y git curl build-essential

# Clone and install
git clone https://gitlab.com/theblackdon/dcli.git
cd dcli
./install.sh
```

**Prerequisites:**
- Debian 11+ or Ubuntu 20.04+
- `git`, `curl`, `build-essential` (for Rust compilation)
- Rust toolchain (installer handles this)

**Optional:**
- `fzf` - For interactive TUI features
- `timeshift` - System backups

**Note:** The install script will:
1. Detect your package manager (pacman or apt)
2. Install Rust toolchain if needed
3. Build the release binary
4. Install to `/usr/local/bin/dcli`

## Manual Install (All Distros)

If the install script fails, you can manually build from source:

```bash
git clone https://gitlab.com/theblackdon/dcli.git
cd dcli
cargo build --release --locked --all-features
```

Then copy the binary to your PATH:
```bash
sudo cp target/release/dcli /usr/local/bin/
```

**Requirements:**
- Rust toolchain (1.70+)
- For Arch: `base-devel` group
- For Debian/Ubuntu: `build-essential` package

### Manual cargo build (alternative)

```bash
cargo build --release --locked --all-features
```

This produces `target/release/dcli` with Lua and Nix scripting compiled in (vendored Lua 5.4).

---

## Quick Start

### 1. Initialize Configuration

**Option A: Start from scratch**
```bash
dcli init
```

**Option B: Bootstrap from example config**
```bash
dcli init -b
```

This creates `~/.config/arch-config/` with:
```
arch-config/
├── config.yaml           # Pointer to active host
├── hosts/
│   └── {hostname}.yaml   # Your full configuration
├── modules/
│   ├── base.yaml         # Base packages
│   └── example.yaml      # Example module
└── scripts/              # Post-install hooks
```

### 2. Define Packages

Edit your host file: `~/.config/arch-config/hosts/{hostname}.yaml`

```yaml
host: desktop
description: My desktop computer

# Enable modules
enabled_modules:
  - gaming
  - development

# Host-specific packages
packages:
  - firefox
  - discord
  - flatpak:com.spotify.Client

# Exclude packages from modules
exclude:
  - steam  # Don't want from gaming module

# Settings
flatpak_scope: user           # "user" or "system"
auto_prune: false             # Auto-remove unmanaged packages during sync
module_processing: parallel   # "parallel" (default) or "sequential"
aur_helper: paru              # AUR helper for Arch (paru, yay, etc.) - auto-detected if not set
package_manager: apt          # Optional: force package manager (pacman or apt)
editor: nano                  # Editor for config files (falls back to $EDITOR)

# Config backups
config_backups:
  enabled: true         # Auto-backup configs before sync
  max_backups: 5        # Keep last N backups (0 = unlimited)

# System backups (Timeshift/Snapper)
system_backups:
  enabled: true         # Global toggle for system backups
  backup_on_sync: true  # Create backup during dcli sync
  backup_on_update: true # Create backup during dcli update
  tool: timeshift       # Backup tool: timeshift or snapper
  snapper_config: root  # Snapper config name (if using snapper)
  max_backups: 5        # Keep last N backups (0 = unlimited)
```

### 3. Create Modules

Create `~/.config/arch-config/modules/gaming.yaml`:

```yaml
description: Gaming packages

packages:
  - steam
  - lutris
  - wine
  - gamemode

post_install_hook: scripts/setup-gaming.sh
hook_behavior: ask
```

### 4. Sync Your System

```bash
dcli sync              # Install missing packages
dcli sync --dry-run    # Preview changes first
dcli sync --prune      # Also remove unmanaged packages
```

---

## Core Commands

### Package Management

```bash
dcli search                    # Interactive package search (TUI)
dcli install <package>         # Install and add to config
dcli remove <package>          # Remove package
dcli forget <package>          # Remove from dcli tracking (keep installed)
dcli update                    # Update system
dcli find <package>            # Find where package is defined
dcli merge                     # Add unmanaged packages to config
dcli merge --include-deps      # Also capture dependencies in separate module
dcli merge --services          # Add enabled services to config
dcli merge --defaults          # Add current default apps to config
```

### Modules

```bash
dcli module list               # Show all modules
dcli module enable             # Interactive selection (TUI)
dcli module enable gaming      # Enable specific module
dcli module disable            # Interactive selection (TUI)
```

### Configuration

```bash
dcli status                    # Show config and sync status
dcli validate                  # Check config integrity
dcli edit                      # Interactive file editor (TUI)
dcli migrate                   # Migrate to new structure
```

### Backups

**Configuration Backups:**
```bash
dcli save-config               # Backup current config
dcli restore-config            # Interactive restore (TUI)
```

**System Snapshots:**
```bash
dcli backup                    # Create system snapshot
dcli backup list               # List snapshots
dcli restore                   # Interactive restore (TUI)
```

### Hooks

```bash
dcli hooks list                # Show all hooks and status
dcli hooks run                 # Interactive selection (TUI)
dcli hooks skip <module>       # Mark hook as skipped
dcli hooks reset <module>      # Reset hook to run again
```

### Git Repository

```bash
dcli repo init                 # Set up git for arch-config
dcli repo clone                # Clone existing arch-config
dcli repo push                 # Commit and push changes
dcli repo pull                 # Pull updates from remote
dcli repo status               # Show git status
```

### Maintenance

```bash
dcli self-update               # Update dcli itself
dcli help                      # Show help
dcli <command> --json          # JSON output for scripting
```

---

## Configuration

### Host File Format

Full host configuration in `hosts/{hostname}.yaml`:

```yaml
host: desktop
description: Gaming Desktop

# Import shared configs (optional)
import:
  - hosts/shared/common.yaml

# Enable modules
enabled_modules:
  - gaming
  - development

# Host-specific packages
packages:
  - firefox
  - discord
  - flatpak:com.spotify.Client  # Flatpak using prefix
  - name: org.videolan.VLC       # Flatpak using object format
    type: flatpak

# Exclude from base/modules
exclude:
  - vim  # Use neovim instead

# Services
services:
  enabled:
    - bluetooth
    - sshd
  disabled:
    - cups

# Default applications
default_apps:
  scope: user           # "user" or "system"
  browser: firefox
  text_editor: code
  file_manager: thunar
  terminal: kitty
  email: thunderbird
  video: vlc
  music: spotify
  image: gwenview
  mime_types:
    application/pdf: okular

# Settings
flatpak_scope: user           # "user" or "system"
auto_prune: false
module_processing: parallel   # "parallel" or "sequential"
aur_helper: paru              # AUR helper (Arch only) - auto-detected
package_manager: apt          # Optional: force package manager (pacman/apt)

# Config backups
config_backups:
  enabled: true
  max_backups: 5

# System backups (Timeshift/Snapper)
system_backups:
  enabled: true         # Global toggle
  backup_on_sync: true  # Backup during sync
  backup_on_update: true # Backup during update
  tool: timeshift       # timeshift or snapper
  snapper_config: root  # Snapper config name
  max_backups: 5        # Keep last N backups (0 = unlimited)

# Update hooks (optional)
update_hooks:
  pre_update: "scripts/pre-update.sh"   # Run before system update
  post_update: "scripts/post-update.sh" # Run after system update
  behavior: ask                          # ask | always | once | skip
  devel: false                           # Update VCS packages (-git, -svn, etc.)
```

### Lua Configuration (Advanced)

**Dynamic, programmable configuration with Lua scripting.**

Initialize with Lua support:
```bash
dcli init --adv    # Creates host.lua instead of host.yaml
```

**Why use Lua?**
- 🎯 **Hardware detection** - Auto-detect GPU, laptop/desktop, CPU features
- 🔧 **Conditional logic** - Install packages based on system properties
- 📦 **Dynamic packages** - Compute package lists at runtime
- 🖥️ **System queries** - Check installed packages, services, environment
- 🔄 **Reusable functions** - DRY configuration with helper functions

**Quick Example:**
```lua
-- host.lua - Dynamic GPU driver selection
local packages = {}

if dcli.hardware.has_nvidia() then
    table.insert(packages, "nvidia")
    table.insert(packages, "nvidia-utils")
elseif dcli.hardware.has_amd_gpu() then
    table.insert(packages, "mesa")
    table.insert(packages, "vulkan-radeon")
end

return {
    host = dcli.system.hostname(),
    description = "Auto-configured system",
    packages = packages,
    enabled_modules = { "base", "desktop" }
}
```

**Available APIs:**
- `dcli.hardware.*` - CPU, GPU, laptop detection
- `dcli.system.*` - Hostname, distro, kernel, memory
- `dcli.package.*` - Check installed packages, versions
- `dcli.file.*` - File operations, read configs
- `dcli.env.*` - Environment variables, paths
- `dcli.util.*` - Helper functions, version comparison

**Learn More:**
- 📖 [Lua Host Configuration Guide](docs/LUA-HOSTS.md) - Full host.lua examples
- 📖 [Lua Module Guide](docs/LUA-MODULES.md) - Dynamic module creation
- 📖 [Complete Lua API Reference](docs/DCLI-LUA-API.md) - All available functions

**Current limitations (Lua/Nix configs):**
- `dcli module enable/disable` (including interactive) cannot edit `.lua` or `.nix` host/config files; update `enabled_modules` manually or use YAML if you want automatic edits.
- `dcli service enable/disable` cannot write to `.lua` or `.nix` configs; update `enabled_service_profiles` manually or switch to YAML.
- `dcli edit` does not list `.lua` or `.nix` configs; open and edit your advanced config files directly.
- Coming soon: safe write support for Lua/Nix configs so these commands can update them automatically.

**YAML, Lua, and Nix work together:**
- Modules can be YAML, Lua, or Nix (mix and match)
- Host files can import all formats
- Use YAML for simple configs, Lua for complex logic, Nix for Nix ecosystem integration

---

### Module Format

Modules in `modules/{name}.yaml`:

```yaml
description: Gaming packages

packages:
  - steam
  - lutris
  - wine

conflicts:
  - office-suite  # Can't coexist with this module

post_install_hook: scripts/setup-gaming.sh
hook_behavior: ask  # ask | always | once | skip
```

### Directory-Based Modules

For complex modules, use a directory:

```
modules/
└── hyprland/
    ├── module.yaml          # Main module definition
    ├── packages.yaml        # Package list
    ├── wayland-tools.yaml   # Additional package lists
    └── dotfiles/            # Optional: dotfiles to sync
        ├── hypr/
        └── waybar/
```

`module.yaml`:
```yaml
description: Hyprland window manager
post_install_hook: scripts/install-hypr-dotfiles.sh

# Dotfiles configuration (optional)
dotfiles_sync: true          # Auto-sync dotfiles/ directories to ~/.config/
dotfiles:                    # Explicit dotfiles for custom paths
  - source: hyprland.conf
    target: ~/.hyprland.conf
```

`packages.yaml`:
```yaml
packages:
  - hyprland
  - waybar
  - wofi
```

#### Dotfiles Management

dcli includes powerful dotfiles management with automatic conflict detection and flexible path mapping.

**Automatic Sync Mode:**
Enable `dotfiles_sync: true` to automatically sync all directories from `dotfiles/` to `~/.config/`:

```yaml
# module.yaml
dotfiles_sync: true
```

With this structure:
```
modules/hyprland/
├── module.yaml
└── dotfiles/
    ├── hypr/      → symlinked to ~/.config/hypr
    └── waybar/    → symlinked to ~/.config/waybar
```

**Explicit Sync Mode:**
Define custom source/target pairs for files outside `~/.config/`:

```yaml
# module.yaml
dotfiles:
  - source: .zshrc
    target: ~/.zshrc
  - source: .bashrc
    target: ~/.bashrc
  - source: config/starship.toml
    target: ~/.config/starship.toml
```

**Hybrid Mode:**
Use both together - explicit entries override automatic sync for the same target:

```yaml
# module.yaml
dotfiles_sync: true          # Auto-sync directories to ~/.config/
dotfiles:
  - source: kitty            # Override automatic ~/.config/kitty
    target: ~/.config/kitty-hypr
  - source: .zshrc           # Additional file outside .config
    target: ~/.zshrc
```

**Features:**
- ✅ **Conflict Detection** - Errors if multiple modules target the same path
- ✅ **Automatic Backups** - Backs up existing files before creating symlinks
- ✅ **Flexible Paths** - Not limited to `~/.config/`, sync anywhere
- ✅ **Hybrid Mode** - Mix automatic and explicit with precedence rules

**Commands:**
```bash
dcli sync                    # Sync dotfiles during normal sync
dcli sync --force-dotfiles   # Force re-sync even if already synced
dcli sync --prune            # Remove dotfiles from disabled modules
```

**Dotfiles-Only Module:**
Create modules that only manage dotfiles with no packages:

```yaml
# modules/dotfiles/module.yaml
description: Personal dotfiles
dotfiles_sync: true
```

```
modules/dotfiles/
├── module.yaml
└── dotfiles/
    ├── nvim/
    ├── tmux/
    └── zsh/
```

### Lua and Nix Modules

For dynamic, conditional configurations, use Lua or Nix instead of YAML:

**Lua example:**

```lua
-- modules/gpu-drivers.lua
local packages = {}

-- Auto-detect CPU and add microcode
if dcli.hardware.cpu_vendor() == "intel" then
    table.insert(packages, "intel-ucode")
elseif dcli.hardware.cpu_vendor() == "amd" then
    table.insert(packages, "amd-ucode")
end

-- Auto-detect GPU and add drivers
if dcli.hardware.has_nvidia() then
    table.insert(packages, "nvidia")
    table.insert(packages, "nvidia-utils")
elseif dcli.hardware.has_amd_gpu() then
    table.insert(packages, "mesa")
    table.insert(packages, "vulkan-radeon")
end

return {
    description = "GPU drivers (auto-detected)",
    packages = packages,
}
```

**Available APIs:**

| Namespace | Functions |
|-----------|-----------|
| `dcli.hardware` | `cpu_vendor()`, `gpu_vendors()`, `has_nvidia()`, `has_amd_gpu()`, `has_intel_gpu()`, `is_laptop()`, `has_battery()`, `chassis_type()` |
| `dcli.system` | `hostname()`, `kernel_version()`, `arch()`, `os()`, `distro()`, `distro_name()`, `distro_version()`, `memory_total_mb()`, `cpu_cores()` |
| `dcli.file` | `exists(path)`, `is_file(path)`, `is_dir(path)`, `read(path)`, `read_lines(path)` |
| `dcli.env` | `get(name)`, `home()`, `user()`, `config_dir()`, `data_dir()`, `cache_dir()`, `shell()` |
| `dcli.package` | `is_installed(name)`, `version(name)`, `is_available(name)`, `repo(name)`, `flatpak_installed(id)`, `aur_available(name)` |
| `dcli.util` | `contains(t, v)`, `merge(t1, t2)`, `extend(t, s)`, `version_compare(v1, v2)`, `split(s, d)`, `trim(s)` |
| `dcli.log` | `info(msg)`, `warn(msg)`, `error(msg)`, `debug(msg)` |

**Nix example:**

```nix
# modules/gpu-drivers.nix
{ system, pkgs }:

{
  description = "GPU drivers (auto-detected)";

  packages = if system.hardware.has_nvidia then
    [ "nvidia" "nvidia-utils" ]
  else if system.hardware.has_amd_gpu then
    [ "mesa" "vulkan-radeon" ]
  else
    [];
}
```

Nix modules have access to the same `system` facts API as Lua (`system.hardware.*`, `system.system.*`, etc.). Nix files are evaluated via `nix-instantiate` and support the same package types as YAML.

See [LUA-MODULES.md](LUA-MODULES.md) for complete Lua documentation and examples.

### Hook Behaviors

Control when hooks run with independent behaviors for pre/post install:

```yaml
# Module hooks with separate behaviors
pre_install_hook: "scripts/pre-setup.sh"
pre_hook_behavior: "always"    # Runs every sync without asking

post_install_hook: "scripts/post-setup.sh"
post_hook_behavior: "ask"      # Prompts user each time

# Legacy format (still supported)
hook_behavior: "once"          # Applied to both if new fields not set

# Run hooks as user (without sudo) - useful for user-level tools
# Can be: false (default, uses sudo), true (current user), or "username"
run_hooks_as_user: "myuser"     # Default: false (runs with sudo as root)
```

| Behavior | Description |
|----------|-------------|
| `ask` | Prompt before running (default) |
| `always` | Run every sync, no questions |
| `once` | Run once without prompting |
| `skip` | Never run this hook |

**User-Level Hooks:**
Some tools (like Go programs, user-level package managers) should not run as root. Set `run_hooks_as_user` to run hooks without sudo:

```yaml
# Module that installs user-level tools
post_install_hook: "scripts/setup-go-tools.sh"
run_hooks_as_user: true  # Run as current user without sudo

# Or specify a particular user:
post_install_hook: "scripts/setup-go-tools.sh"
run_hooks_as_user: "myusername"  # Run as specific user using sudo -u
```

**Note:** Backward compatible with the old boolean format (`true`/`false`).

**Update Hooks** - Run scripts before/after system updates:

```yaml
# In host configuration
update_hooks:
  pre_update: "scripts/pre-update.sh"   # Before yay -Syu
  post_update: "scripts/post-update.sh" # After flatpak update
  behavior: ask                          # ask | always | once | skip
  devel: true                            # Update VCS packages (e.g., yay -Syu --devel)
  run_as_user: true                      # Run hooks without sudo (default: false)
```

```bash
dcli update               # Runs hooks (if configured)
dcli update --no-hooks    # Skip hooks
dcli update --devel       # Update -git packages (overrides config)
dcli hooks list           # Shows update hooks too
dcli hooks reset update_pre    # Reset pre-update hook
dcli hooks skip update_post    # Skip post-update hook
```

---

## Flatpak Support

### Setup

```bash
sudo pacman -S flatpak
flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
```

### Usage

Two ways to declare flatpak packages:

```yaml
packages:
  - firefox                          # Regular pacman package
  - flatpak:com.spotify.Client      # Flatpak (prefix format)
  - name: org.videolan.VLC           # Flatpak (object format)
    type: flatpak
```

### Configuration

Set installation scope in your host file:

```yaml
flatpak_scope: user  # "user" (default) or "system"
```

---

## Services Management

Declaratively manage systemd services:

```yaml
services:
  enabled:
    - bluetooth    # Enable and start
    - sshd
    - docker
  disabled:
    - cups         # Stop and disable
```

**User Services:**
For systemd user services (run with `--user` flag), set the scope:

```yaml
services:
  scope: user      # "system" (default) or "user"
  enabled:
    - syncthing    # User service - runs as current user
    - pipewire
  disabled:
    - pulseaudio
```

Bootstrap from current system:

```bash
dcli merge --services           # Add enabled services to config
dcli merge --services --dry-run # Preview first
```

Services sync automatically during `dcli sync`.

---

## Default Applications

Declaratively manage default applications using XDG MIME types:

```yaml
# Default applications configuration
default_apps:
  scope: system              # "user" or "system"
  browser: firefox
  text_editor: code
  file_manager: thunar
  terminal: kitty
  email: thunderbird
  video: vlc
  music: spotify
  image: gwenview
  
  # Custom MIME types
  mime_types:
    application/pdf: okular
    text/html: firefox
    image/svg+xml: inkscape
```

### Supported Application Types

| Type | Description | MIME Types |
|------|-------------|------------|
| `browser` | Web browser | text/html, x-scheme-handler/http(s) |
| `text_editor` | Text/code editor | text/plain, text/x-* |
| `file_manager` | File browser | inode/directory |
| `terminal` | Terminal emulator | x-scheme-handler/terminal |
| `email` | Email client | x-scheme-handler/mailto |
| `video` | Video player | video/* |
| `music` | Music player | audio/* |
| `image` | Image viewer | image/* |

### Bootstrap from Current System

```bash
dcli merge --defaults           # Add current defaults to config
dcli merge --defaults --dry-run # Preview first
```

### Features

- ✅ **Pre-flight Validation** - Checks all .desktop files exist before applying
- ✅ **NixOS-style Fail-fast** - Refuses to apply if any app is invalid
- ✅ **State Tracking** - Only updates changed defaults
- ✅ **Flexible Format** - Accepts `firefox` or `firefox.desktop`
- ✅ **Custom MIME Types** - Full control over any MIME type association

**Requirements:**
- `xdg-utils` package for `xdg-mime` command

Default apps sync automatically during `dcli sync`.

---

## Sequential Module Processing

Control module installation order for complex setups like custom repositories:

```yaml
# Enable sequential processing (default: parallel)
module_processing: sequential

enabled_modules:
  - cachyos-repo    # 1. Adds CachyOS repository
  - gaming          # 2. Can now install packages from CachyOS
  - development     # 3. Processes in order
```

### How It Works

**Parallel Mode (Default - Fast):**
- Collects all packages from all modules
- Installs everything at once
- Runs hooks after installation
- Best for most use cases

**Sequential Mode (Ordered - Controlled):**
```
For each module in order:
  1. Run pre-install hook
  2. Refresh package database (if hook ran)
  3. Install module packages
  4. Run post-install hook
  
After all modules:
  5. Sync dotfiles
  6. Sync services & defaults
```

### Strict Package Order

When using sequential module processing, you can enable strict package ordering to install packages one-at-a-time in the exact order they appear in the module:

```yaml
module_processing: sequential
strict_package_order: true  # Install packages one at a time (default: false)
```

**With `strict_package_order: true`:**
- Packages install one-at-a-time instead of in batches
- Installation order matches the package order in module files
- All pacman/AUR packages install first, then all flatpaks
- Installation continues even if individual packages fail
- A summary shows which packages succeeded or failed
- Uses `--noconfirm` flag for non-interactive installation

**Example output:**
```
→ Processing module 2/3: gaming
  → Installing packages sequentially (strict order)...
  → Installing package 1/5: steam
  → Installing package 2/5: lutris
  → Installing package 3/5: wine
  → Installing package 4/5: proton-ge
  → Installing package 5/5: gamemode
  ✓ All 5 packages installed successfully
```

**When to use:**
- Package installation order matters (e.g., dependencies between packages)
- You want visibility into which specific package is installing
- You need to debug package installation issues
- Certain packages must install before others in the same module

### Use Cases

**Custom Repository Module:**
```yaml
# modules/cachyos-repo/module.yaml
description: CachyOS repository setup

pre_install_hook: scripts/add-cachyos-repo.sh
pre_hook_behavior: once

packages:
  - cachyos-keyring
  - cachyos-mirrorlist
```

```bash
#!/bin/bash
# scripts/add-cachyos-repo.sh
echo "Adding CachyOS repository..."
sudo tee -a /etc/pacman.conf > /dev/null <<EOF
[cachyos]
Include = /etc/pacman.d/cachyos-mirrorlist
EOF
```

**Then install packages from that repo:**
```yaml
# modules/gaming.yaml
packages:
  - cachyos-gaming-meta  # From CachyOS repo
  - steam
```

### Benefits

- **Repository Setup** - Add repos before installing packages from them
- **Dependency Control** - Ensure modules install in correct order
- **Progress Tracking** - See "Module 2/9" during sync
- **Fail-Fast** - Stops on first error (NixOS-style)
- **Hook Respect** - Honors behavior settings (once/always/skip)

Set `module_processing: sequential` in your host configuration to enable.

---

## Multi-Machine Setup

### First Machine

```bash
# Initialize config
dcli init

# Set up git repo
dcli repo init
```

### Additional Machines

```bash
# Clone your config
dcli repo clone

# Sync packages
dcli sync
```

### Workflow

**On desktop:**
```bash
dcli module enable gaming
dcli sync
dcli repo push
```

**On laptop:**
```bash
dcli repo pull
dcli module enable gaming  # Shared module, different packages per host
dcli sync
```

---

## Advanced Features

### Config Import

Share configurations across hosts:

```yaml
# hosts/laptop.yaml
import:
  - hosts/shared/common.yaml
  - hosts/shared/laptop-base.yaml
```

### Package Finding

Find where a package is defined:

```bash
dcli find steam
# → Module: gaming
#   File: /home/user/.config/arch-config/modules/gaming.yaml
```

### Forgetting Packages

Remove a package from dcli tracking without uninstalling it:

```bash
dcli forget fakeroot
```

**Use case:** You have packages that were originally installed manually and added via `dcli merge`, but are now transitive dependencies of another package (e.g., `fakeroot` is a dependency of `base-devel`). Use `forget` to stop tracking them:

```bash
# Before: fakeroot tracked in system-packages, but now it's a dependency of base-devel
dcli forget fakeroot
dcli forget make

# Now dcli won't try to:
# - Re-add them during `dcli merge`
# - Remove them during `dcli sync --prune`
```

The command removes the package from:
- `declared-packages.yaml/.lua` (packages from `dcli install`/`dcli search`)
- `system-packages-{host}/packages.yaml` (packages from `dcli merge`)

If found in other locations (base.yaml, host config, modules), it will warn you to remove manually.

### Capturing Installed Packages (Merge)

The `dcli merge` command captures packages already installed on your system and adds them to your dcli configuration:

```bash
# Capture explicitly installed packages (excludes dependencies)
dcli merge

# Preview what would be captured
dcli merge --dry-run

# Capture all packages including dependencies
dcli merge --include-deps
```

**What it creates:**
- `system-packages-{hostname}` module - Contains explicitly installed packages
- `dependencies-{hostname}` module (with `--include-deps`) - Contains all dependency packages

**Note about dependencies:**
The `--include-deps` flag creates a separate module containing all packages installed as dependencies. This is useful for:
- **Complete system documentation** - Track every package on your system
- **Visibility** - See what dependencies are pulled in
- **Special cases** - When you need to ensure specific dependency versions

However, in most cases you don't need to enable the dependencies module because:
- Dependencies are automatically resolved when installing packages
- It can add significant overhead (thousands of packages)
- It may cause conflicts on fresh installs

```bash
# Typical workflow
dcli merge                    # Capture your explicitly installed packages
dcli module enable system-packages-myhost
dcli sync

# Optional: Also track dependencies (usually not needed)
dcli merge --include-deps
dcli module enable dependencies-myhost  # Only if you really need this
```

### Config Backups

Automatic validation and backup before syncing:

```yaml
config_backups:
  enabled: true      # Auto-backup on sync
  max_backups: 5     # Keep last 5 backups
```

```bash
dcli save-config       # Manual backup
dcli restore-config    # Interactive restore
```

Backups include:
- Active host configuration
- All modules and scripts
- Dotfiles and state

### AUR Helper

### Package Manager Configuration

dcli automatically detects your package manager (pacman for Arch, apt for Debian/Ubuntu). You can optionally override this:

```yaml
# Force specific package manager
package_manager: apt  # or "pacman"
```

**Arch Linux only** - Configure your preferred AUR helper:

```yaml
aur_helper: paru  # or "yay"
```

Auto-detects if not specified (prefers paru → yay).

### JSON Output

All commands support JSON for scripting:

```bash
dcli status --json
dcli module list --json
dcli find vim --json
```

---

## Migration

Migrate from old structure (`packages/` directory) to new clean structure:

```bash
dcli migrate --dry-run  # Preview changes
dcli migrate            # Perform migration (creates backup)
```

Changes:
- `packages/modules/` → `modules/`
- `packages/hosts/` → `hosts/`
- `packages/base.yaml` → `modules/base.yaml`
- Converts `config.yaml` to pointer format
- Creates full host configuration

**Note:** Old structure still works! Migration is optional.

---

## Troubleshooting

### dcli not found after installation

```bash
hash -r  # Refresh shell cache
# or restart terminal
```

### Build fails

```bash
source $HOME/.cargo/env  # Load Rust environment
./install.sh
```

### Sync fails with conflicts

```bash
sudo pacman -S <conflicting-package>
dcli sync
```

### TUI commands don't work

```bash
sudo pacman -S fzf  # Install fzf for TUI features
```

### Backup commands fail

```bash
sudo pacman -S timeshift  # or snapper
```

---

## AUR Package

dcli is available on the AUR as `dcli-arch-git`:

```bash
yay -S dcli-arch-git
# or
paru -S dcli-arch-git
```

**Package Details:**
- **Name:** dcli-arch-git
- **Type:** VCS package (builds from latest git)
- **Maintainer:** Don <theblackdonatello@gmail.com>
- **URL:** https://aur.archlinux.org/packages/dcli-arch-git

---

## Manual Install

If AUR installs fail (e.g., Lua dependency resolution), clone the repo and run the installer directly:

```bash
git clone https://gitlab.com/theblackdon/dcli.git
cd dcli
./install.sh
```

This builds from source with the same script used in the AUR package. Requires a Rust toolchain and Lua 5.4 libs.

---

## Examples

### Gaming Setup

```yaml
# modules/gaming.yaml
description: Gaming packages and tools

packages:
  - steam
  - lutris
  - wine
  - gamemode
  - mangohud

services:
  enabled:
    - gamemode

post_install_hook: scripts/setup-gaming.sh
hook_behavior: ask
```

### Development Environment

```yaml
# modules/development.yaml
description: Development tools

packages:
  - git
  - neovim
  - rust
  - nodejs
  - docker
  - code

services:
  enabled:
    - docker

post_install_hook: scripts/setup-dev-env.sh
hook_behavior: once
```

### Media Production

```yaml
# modules/media.yaml
description: Media production tools

packages:
  - ffmpeg
  - audacity
  - gimp
  - flatpak:com.obsproject.Studio
  - flatpak:org.kde.kdenlive
  - name: org.blender.Blender
    type: flatpak

post_install_hook: scripts/setup-media.sh
```

### Window Manager with Dotfiles

```yaml
# modules/bdots-niri/module.yaml
description: "Niri scrollable-tiling Wayland compositor with dotfiles"

# Conflicts with other desktop environments
conflicts:
  - bdots-kde

# Auto-sync dotfiles from dotfiles/ to ~/.config/
dotfiles_sync: true

# Post-install hook for additional setup
post_install_hook: "scripts/install-niri-dotfiles.sh"
hook_behavior: ask

# Load multiple package files
package_files:
  - niri-packages.yaml
  - niri-themes.yaml
  - dependencies.yaml
  - default-apps.yaml
```

```yaml
# modules/bdots-niri/niri-packages.yaml
description: Niri scrollable-tiling Wayland compositor core packages

packages:
  - niri                           # Niri Wayland compositor
  - xdg-desktop-portal-gnome       # Desktop portal
  - wl-clipboard                   # Clipboard utilities
  - cliphist                       # Clipboard history
  - grim                           # Screenshot tool
  - slurp                          # Region selector
  - satty                          # Screenshot annotation
  - swaybg                         # Background manager
  - brightnessctl                  # Brightness control
  - fuzzel                         # Application launcher
  - mako                           # Notification daemon
  - waybar                         # Status bar
```

**Directory Structure:**
```
modules/bdots-niri/
├── module.yaml                    # Main module config
├── niri-packages.yaml             # Core packages
├── niri-themes.yaml               # Theme packages
├── dependencies.yaml              # Dependencies
├── default-apps.yaml              # Default applications
├── scripts/
│   └── install-niri-dotfiles.sh  # Post-install setup
└── dotfiles/                      # Auto-synced to ~/.config/
    ├── niri/
    ├── waybar/
    ├── mako/
    ├── kitty/
    ├── fish/
    └── gtk-3.0/
```

**Usage:**
```bash
dcli module enable bdots-niri
dcli sync                          # Installs packages & syncs dotfiles
```

---

## What's New

### Latest Features

**Debian/Ubuntu Support** 🐧
- Full APT package manager support (in addition to Pacman)
- Works on Debian, Ubuntu, Linux Mint, Pop!_OS, and other Debian-based distros
- Use `./install.sh` for manual installation on Debian/Ubuntu

**Dependency Tracking** 📦
- New `dcli merge --include-deps` flag captures all dependencies
- Creates a separate `dependencies-{hostname}` module
- Perfect for complete system documentation
- Optional - dependencies are auto-resolved during normal installs

**Default Applications Management** 🎨
- Declaratively set default apps for browsers, editors, terminals, and more
- Pre-flight validation ensures .desktop files exist
- Bootstrap from current system with `dcli merge --defaults`
- Custom MIME type support for full control

**Sequential Module Processing** 🔄
- Process modules in order for complex setups
- Perfect for custom repository workflows (e.g., CachyOS repo)
- Automatic package database refresh after repo hooks
- Progress tracking shows "Module 2/9" during sync
- Fail-fast error handling (NixOS-style)

**Nix Configuration Support** ❄️
- Full Nix language support for configs and modules alongside YAML and Lua
- Nix modules access the same `system` facts API for hardware detection
- Evaluated via `nix-instantiate` for zero runtime dependencies
- Mix and match Nix, Lua, and YAML modules in the same setup

**Enhanced Commands** 📊
- `dcli status` now shows services, default apps, and module processing mode
- `dcli validate` checks services and default apps configuration
- Improved hook behavior tracking (won't re-run completed hooks)

---

## Documentation

- **Configuration Guide:** See examples above
- **Hook System:** Run `dcli hooks list` for overview
- **Service Management:** [SERVICES.md](SERVICES.md)
- **Directory Modules:** [DIRECTORY-MODULES.md](DIRECTORY-MODULES.md)
- **Lua Modules:** [LUA-MODULES.md](LUA-MODULES.md)
- **Nix Modules:** [NIX-MODULES.md](NIX-MODULES.md)
- **Dotfiles:** [DOTFILES-SYMLINK-GUIDE.md](DOTFILES-SYMLINK-GUIDE.md)

---

## Contributing

Contributions welcome! Open an issue or submit a pull request.

**Repository:** https://gitlab.com/theblackdon/dcli

---

## License

0BSD License - See [LICENSE](LICENSE)

---

## Credits

Special thanks to:
- **Alice Alysia** - https://gitlab.com/alicealysia
- **Ddubs** - https://gitlab.com/dwilliam62
- **Tyler Kelly** - https://gitlab.com/Zaney

Built with ❤️ for the Linux community.
