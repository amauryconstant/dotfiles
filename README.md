# Modern Arch Linux + Hyprland Dotfiles

A comprehensive chezmoi-based dotfiles repository for Arch Linux with Hyprland compositor, featuring dynamic theming, intelligent configuration management, and automated system maintenance.

**Target System**: Vanilla Arch Linux (installed via archinstall with Hyprland profile)

## Overview

This repository implements a complete desktop environment configuration with focus on:
- **Automation**: Minimal manual intervention, intelligent updates
- **Security**: Age-encrypted secrets with manual operation workflows
- **Modularity**: XDG-compliant architecture with clear separation of concerns
- **Maintainability**: Template-driven configuration with single source of truth

## Key Features

### Dynamic Desktop Environment
- **Hyprland Compositor**: Wayland-native tiling with modular configuration (9 conf files)
- **Dynamic Theming**: Automatic color palette generation from wallpapers via `wallust`
- **Wallpaper Rotation**: Systemd timer with 30-minute intervals, smooth `swww` transitions
- **Adaptive UI**: 8 applications auto-theme (Hyprland, Waybar, Wofi, Dunst, Ghostty, Thunar, etc.)
- **Status Bar**: Waybar with 15 modules (workspaces, system info, network, audio)
- **Native Integration**: Hyprland polkit agent, GTK-based file manager (Thunar)

### Intelligent System Management
- **Hierarchical Menu System**: `Super+Space` launches 10-category system control interface
- **Desktop Utilities**: Screenshot annotation (Satty), GPU recording, nightlight, idle/gaps toggles
- **CLI Discovery**: `commands` function lists all available custom tools
- **Package Management**: Dual-layer (Arch native + Flatpak) with automatic sync
- **Automated Updates**: Topgrade integration with systemd timers

### Modern Shell Environment
- **Zephyr Plugin Framework**: 8-plugin suite providing XDG management, PATH deduplication, editor enhancements
- **CLI Wrapper System**: Lazy-loading executables in `~/.local/bin/` reduce shell startup overhead
- **XDG Compliance**: Proper Base Directory adherence throughout
- **Universal Consistency**: POSIX functions for automation, rich Gum-based functions for interaction

### Smart Configuration
- **chezmoi_modify_manager**: Separates user settings from application state (filters runtime data)
- **Template Protection**: Custom git merge driver preserves `{{ .variable }}` syntax during merges
- **Age Encryption**: Secure handling of keys and credentials with manual operation workflows
- **Data-Driven**: YAML configuration files trigger automatic hash-based updates

## Repository Structure

### Chezmoi Source Directory Layout

```
~/.local/share/chezmoi/           # Chezmoi source repository

├── .chezmoidata/                 # Template data sources (YAML)
│   ├── packages.yaml             # Package management (Arch + Flatpak)
│   ├── ai.yaml                   # AI model configuration
│   ├── extensions.yaml           # VSCode extensions list
│   ├── colors.yaml               # Color scheme definitions
│   └── globals.yaml              # Global variables (XDG, apps, printer)
│
├── .chezmoiscripts/              # Lifecycle automation scripts
│   ├── run_once_before_*.sh.tmpl # Pre-setup (6 scripts: yay, dirs, packages)
│   ├── run_once_after_*.sh.tmpl  # Post-setup (8 scripts: services, git, boot)
│   └── run_onchange_*.sh.tmpl    # Hash-triggered (5 scripts: packages, extensions)
│
├── .chezmoitemplates/            # Reusable template includes
│   ├── log_start, log_step       # Logging templates (10 files)
│   ├── log_success, log_error    # Used via {{ includeTemplate "name" . }}
│   └── log_complete
│
├── private_dot_config/           # ~/.config/ directory contents
│   │
│   ├── hypr/                     # Hyprland compositor
│   │   ├── hyprland.conf         # Main config (sources conf/*)
│   │   ├── conf/                 # Modular configuration (9 files)
│   │   │   ├── monitor.conf.tmpl      # Display settings
│   │   │   ├── bindings.conf.tmpl     # Keybindings (templated)
│   │   │   ├── environment.conf       # Environment variables
│   │   │   ├── general.conf           # Layout, gaps, borders
│   │   │   ├── decoration.conf        # Visual effects
│   │   │   ├── animations.conf        # Animation curves
│   │   │   ├── input.conf             # Keyboard/mouse/touchpad
│   │   │   ├── windowrules.conf       # Per-app window behavior
│   │   │   └── autostart.conf         # Startup applications
│   │   ├── hypridle.conf.tmpl    # Idle management
│   │   └── hyprlock.conf         # Lock screen
│   │
│   ├── waybar/                   # Status bar
│   │   ├── config.tmpl           # Module config (JSON5, templated)
│   │   └── style.css.tmpl        # Styling with color templates
│   │
│   ├── wofi/                     # Application launcher
│   │   ├── config                # Static settings
│   │   └── style.css.tmpl        # Themed styling
│   │
│   ├── wallust/                  # Color palette generator
│   │   └── wallust.toml.tmpl     # K-means clustering config
│   │
│   ├── shell/                    # Common POSIX shell base
│   │   ├── env                   # Core environment setup
│   │   ├── env_functions         # POSIX functions (automation)
│   │   ├── login.tmpl            # Login environment vars
│   │   ├── interactive           # Interactive shell config
│   │   └── logout                # Logout cleanup
│   │
│   ├── zsh/                      # Zsh-specific configuration
│   │   ├── .zshrc                # Main Zsh config
│   │   ├── .zsh_plugins.txt      # Antidote plugin list
│   │   ├── .zstyles              # Zephyr plugin configuration
│   │   └── .zshrc.d/             # Additional config snippets
│   │
│   ├── systemd/user/             # User systemd units
│   │   ├── wallpaper-cycle.timer    # 30-minute rotation schedule
│   │   └── wallpaper-cycle.service  # Wallpaper rotation service
│   │
│   └── [40+ other apps]          # ghostty, dunst, wlogout, etc.
│
├── private_dot_local/            # ~/.local/ directory contents
│   │
│   ├── bin/                      # CLI wrapper executables (10 files)
│   │   ├── executable_system-health         # Health dashboard
│   │   ├── executable_package-manager       # Package management
│   │   ├── executable_random-wallpaper      # Wallpaper rotation
│   │   ├── executable_set-wallpaper         # Set specific wallpaper
│   │   ├── executable_screenshot            # Screenshot utilities
│   │   ├── executable_launch-or-focus       # Single-instance launcher
│   │   └── [4 more wrappers]
│   │
│   └── lib/scripts/              # Script library (11 categories, 44 scripts)
│       ├── core/                 # colors.sh, gum-ui.sh
│       ├── desktop/              # Window mgmt, audio, toggles (18 scripts)
│       ├── media/                # Screenshots, wallpapers, recording
│       ├── system/               # Health, maintenance, packages
│       ├── user-interface/       # Menu system (12 scripts)
│       ├── terminal/             # Terminal utilities
│       ├── network/              # Network management
│       ├── git/                  # Git utilities
│       ├── development/          # Dev workflows
│       └── utils/                # General utilities
│
├── private_dot_keys/             # Encrypted secrets (.age files)
├── private_dot_ssh/              # SSH configuration and keys
│
├── Root dotfiles/                # Shell startup files
│   ├── .bash_profile, .bashrc    # Bash configuration
│   ├── .zshenv                   # Zsh environment bootstrap
│   ├── .profile                  # POSIX sh profile
│   └── .bash_logout              # Logout cleanup
│
├── Documentation/
│   ├── README.md                 # User guide (this file)
│   └── CLAUDE.md                 # AI agent development reference
│
└── Configuration/
    ├── .chezmoi.yaml.tmpl        # Chezmoi configuration
    ├── .chezmoiignore            # Files to ignore
    ├── .gitattributes            # Git merge driver config
    └── .gitignore                # Git ignore patterns
```

### Chezmoi Naming Conventions

| Prefix | Target Location | Example |
|--------|----------------|---------|
| `private_dot_` | `~/.{name}` | `private_dot_config/` → `~/.config/` |
| `executable_` | Executable file | `executable_system-health` → `system-health` (755) |
| `encrypted_` | Age-encrypted | `encrypted_key.txt.age` → `key.txt` (decrypted) |
| `modify_` | chezmoi_modify_manager | `modify_app.conf.tmpl` → managed config |
| `*.tmpl` | Template file | `config.tmpl` → `config` (processed) |
| `run_once_*` | Run once on setup | Lifecycle scripts (installation) |
| `run_onchange_*` | Run when hash changes | Content-driven updates |

**Quick Navigation:**
- **Hyprland config**: `private_dot_config/hypr/conf/`
- **Shell config**: `private_dot_config/shell/` (common), `private_dot_config/zsh/` (Zsh-specific)
- **Scripts**: `private_dot_local/lib/scripts/`
- **CLI wrappers**: `private_dot_local/bin/`
- **Package definitions**: `.chezmoidata/packages.yaml`
- **Lifecycle scripts**: `.chezmoiscripts/`

## Architecture

### Design Philosophy

**Separation of Concerns**:
- **chezmoi** (`.chezmoiscripts/`): Initial setup and configuration deployment only
- **systemd**: Scheduled maintenance tasks (timers, services)
- **topgrade**: System updates with custom pre/post hooks
- **CLI tools**: User-initiated maintenance and utilities

This clear boundary prevents chezmoi from becoming a "do everything" tool. Setup happens once, maintenance happens through appropriate channels.

**XDG Base Directory Compliance**:
```
~/.config/              # User configuration (managed by chezmoi)
~/.local/
  ├── bin/              # CLI wrappers (lazy-loading executables)
  ├── lib/scripts/      # Script library (11 categories)
  ├── share/            # Application data
  └── state/            # State tracking (package lists, hashes)
```

### Key Technologies

#### Template System (Go text/template + Sprig)

**Built-in Variables**:
- `.chezmoi.os`, `.chezmoi.hostname`, `.chezmoi.arch` - System information
- `.chezmoi.username`, `.chezmoi.homeDir` - User information

**User-Defined Variables** (`.chezmoi.yaml.tmpl`):
- `.fullname`, `.firstname`, `.personalEmail`, `.workEmail`
- `.chassisType` - Laptop vs desktop detection

**Data Files** (`.chezmoidata/*.yaml`):
- `.packages.install.arch`, `.packages.flatpak` - Package lists
- `.colors.oksolar.*` - Color scheme values
- `.globals.applications.terminal`, `.globals.xdg.*` - Global settings

**Testing Templates**:
```bash
chezmoi data                                # View all available variables
chezmoi execute-template < file.tmpl        # Test template syntax
chezmoi cat ~/.config/app/config            # Preview rendered output
```

**Common Patterns**:
```go
{{ if eq .chezmoi.os "linux" }}             # OS detection
{{ .globals.applications.terminal }}        # Access nested data
{{ .firstname | lower }}                    # String transformations
{{ includeTemplate "log_start" "message" }} # Reusable logging templates
```

#### chezmoi_modify_manager (Smart Config Handling)

**Problem**: Many applications store user preferences (settings) and runtime data (state) in the same file. Traditional dotfiles cause constant conflicts.

**Solution**: `chezmoi_modify_manager` separates concerns by:
1. Maintaining clean `.src.ini` with only managed settings
2. Filtering runtime state (window positions, cache, session IDs)
3. Injecting template variables for user-specific values
4. Merging with application's current state on apply

**When to Use**:
- ✅ App stores both settings and state in one file (Nextcloud, VSCode)
- ✅ Need dynamic template values in config
- ✅ Want to hide sensitive data in source
- ❌ App separates settings/state cleanly (use standard templates)
- ❌ Simple static configuration (no modify_manager needed)

**Example** (Nextcloud Desktop):
```bash
#!/usr/bin/env chezmoi_modify_manager
source auto  # Automatically finds corresponding .src.ini

# Filter runtime state
ignore section "DirSelect Dialog"    # Window positions
ignore section "Cache"               # Temporary data

# Set user-specific values
set "User" "Name" "{{ .fullname }}"
set "User" "Email" "{{ .personalEmail }}"

# Hide sensitive data when re-adding
add:hide "Accounts" "0\\password"
```

**Key Directives**:
- `ignore section "Name"` - Filter entire section
- `ignore "Section" "Key"` - Filter specific key
- `set "Section" "Key" "Value"` - Force specific value
- `add:hide "Section" "Key"` - Hide sensitive values in source
- `add:remove "Section" "Key"` - Remove from source when re-adding

See: `private_dot_config/Nextcloud/modify_nextcloud.conf.tmpl` for working example.
Full directive reference: `CLAUDE.md` → "chezmoi_modify_manager Reference"

#### Template Merge Protection

**Problem**: Git merges can accidentally render template variables (turning `{{ .firstname }}` into actual values), breaking templates.

**Solution**: Custom git merge driver that:
1. Detects `.tmpl` files during merge operations
2. Prioritizes versions containing template syntax
3. Preserves `{{ .variable }}` syntax instead of rendering
4. Falls back to standard merge when both versions lack templates

**How It Works**:
- `.gitattributes` configures `*.tmpl merge=chezmoi-template`
- Merge driver script: `.scripts/template-merge-driver.sh`
- Auto-configured by: `run_once_after_005_configure_git_tools.sh.tmpl`

**Result**: You can safely use `chezmoi merge-all` without fear of breaking template syntax.

#### CLI Wrapper Architecture

**Problem**: Loading heavy script libraries at shell startup slows down terminal launch.

**Solution**: Lightweight executables in `~/.local/bin/` that lazy-load scripts from `~/.local/lib/scripts/` on demand.

**Pattern**:
```bash
# ~/.local/bin/system-health (lightweight wrapper)
#!/usr/bin/env bash
exec "$HOME/.local/lib/scripts/system/system-health.sh" "$@"
```

**Benefits**:
- Fast shell startup (no library sourcing overhead)
- Reduced memory footprint
- Clean command interface (`system-health` vs `~/.local/lib/scripts/system/system-health.sh`)
- Easy discovery via `commands` function

**Discovery**:
```bash
commands                   # List all available custom commands
commands | grep wallpaper  # Search for specific commands
```

### Package Management

**Multi-Strategy Installation**:
```yaml
strategies:
  _install_binary: [pacman, yay_bin]           # Faster, precompiled
  _install_from_source: [pacman, yay_bin, yay_source]  # Flexible, builds locally
```

Strategy execution: Try official repos → Try AUR binary → Try AUR source (if strategy allows)

**Dual Package System**:

| Use Arch Native (pacman/yay) | Use Flatpak |
|------------------------------|-------------|
| ✅ CLI tools and utilities | ✅ Proprietary apps (Spotify, Slack) |
| ✅ System services and daemons | ✅ Cross-platform GUI apps |
| ✅ Development tools and languages | ✅ Apps needing sandboxing |
| ✅ Linux-first applications | ✅ Frequent GUI updates (Firefox ESR vs stable) |
| ✅ Deep system integration needed | ❌ CLI tools (use Arch instead) |

**Automatic Sync**:
- Edit `packages.yaml` → Run `chezmoi apply` → Packages install/remove automatically
- Hash-based change detection: Only affected package systems update
- State tracking: Prevents redundant operations (`~/.local/state/chezmoi/installed_packages.txt`)

**archinstall_baseline Note**: This section in `packages.yaml` documents packages from initial archinstall setup. It's for **reference only** (overlap detection), not managed by chezmoi.

### Shell Initialization

**Layered Architecture**:

1. **Common POSIX Base** (`~/.config/shell/`): Universal environment for all shells
   - `shell/env`: Core environment, sets `ENV`/`BASH_ENV` for non-interactive shells
   - `shell/env_functions`: POSIX functions for automation (systemd, scripts, topgrade)
   - `shell/login`: Login environment variables (EDITOR, VISUAL, BROWSER, paths)
   - `shell/interactive`: Common interactive configuration
   - `shell/logout`: Cleanup on logout

2. **Shell-Specific Adapters**: Each shell sources common base + adds enhancements
   - **Bash**: `~/.bash_profile`, `~/.bashrc` → delegates to `~/.config/bash/`
   - **Zsh**: `~/.zshenv`, `~/.config/zsh/.zshrc` → delegates + Zephyr plugins
   - **POSIX sh**: `~/.profile` → delegates to `~/.config/sh/`

**Zephyr Plugin Framework** (8 plugins):

Zephyr provides modern Zsh environment management via zstyle configuration:

- **environment**: XDG Base Directory management, PATH deduplication, custom variables
- **editor**: Prepend-sudo (Ctrl+S), magic-enter for navigation, dot-expansion
- **completion**: Modern completion system with caching
- **compstyle**: Zephyr completion style
- **history**: Intelligent history management
- **utility**: General shell utilities
- **directory**: Directory navigation enhancements
- **confd**: Config directory support

**Configuration** (`~/.config/zsh/.zstyles`):
```zsh
zstyle ':zephyr:plugin:environment' prepath "$HOME/.local/bin"
zstyle ':zephyr:plugin:environment' enable 'yes'
zstyle ':zephyr:plugin:editor' prepend-sudo 'yes'
zstyle ':zephyr:plugin:completion' enable-cache 'yes'
```

**Function Architecture**:
- **POSIX Functions** (`shell/env_functions`): Simple, fast, dependency-free for automation and scripts
- **Interactive Functions** (`~/.local/bin/` wrappers): Rich UI with Gum framework for terminal use

## Installation

### Prerequisites

Fresh Arch Linux installation via **archinstall** with **Hyprland desktop profile**.

**Expected Baseline**: base, base-devel, linux, systemd-boot, Hyprland desktop, pipewire, NVIDIA drivers (if applicable), NetworkManager, SDDM.

See `.chezmoidata/packages.yaml` → `archinstall_baseline` for complete list.

### Quick Start

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin

# Initialize and apply dotfiles
chezmoi init --apply https://gitlab.com/amoconst/dotfiles.git

# Reboot to complete setup
reboot
```

### What Happens (Automated)

All lifecycle scripts run automatically via chezmoi. No manual intervention required.

| Phase | Scripts | Purpose | Trigger |
|-------|---------|---------|---------|
| **1. Pre-Setup** | `run_once_before_*` (6 scripts) | Install yay AUR helper, configure repos, create directories, install essential packages, set up Age encryption, create maintenance user | First `chezmoi apply` |
| **2. Package Install** | `run_onchange_before_*` (1 script) | Install all Arch packages with multi-strategy fallback | Hash change in `packages.yaml` |
| **3. Configuration** | `run_once_after_*` (8 scripts) | Generate CLI configs, configure services (Docker, Bluetooth, Ollama, Tailscale), set up printer, configure git tools, wallpaper timer, boot system (GPU, locale, Plymouth, SDDM) | First `chezmoi apply` |
| **4. Content Updates** | `run_onchange_after_*` (3 scripts) | Install VSCode extensions, pull AI models, install Flatpak apps | Hash change in respective YAML files |
| **5. Finalization** | `run_once_after_999_*` (1 script) | Switch git remote to SSH (requires key) | First `chezmoi apply` |

**Estimated Time**: 15-45 minutes depending on internet speed and AUR build requirements.

### With AI Features

During initialization, answer `y` when prompted for AI tools to enable:
- **Ollama**: Local LLM with automatic model downloads (requires NVIDIA GPU for acceleration)
- **Continue**: AI-powered code assistance in VSCode
- **Cline Rules**: AI assistant behavioral rules for coding agents

## Usage

### Essential Commands

**Configuration Management**:
```bash
chezmoi diff                    # Preview changes before applying
chezmoi apply                   # Apply configuration changes
chezmoi edit <file>             # Edit managed file in source state
chezmoi status                  # Check what files have changed
```

**System Maintenance**:
```bash
topgrade                        # Comprehensive system updates (packages, tools, firmware)
system-health                   # System health dashboard with detailed metrics
package-manager                 # Interactive package management interface
```

**Desktop Utilities**:
```bash
Super+Space                     # Hierarchical menu system (10 categories)
Super+Return                    # Terminal (preserves current directory)
Super+D                         # Application launcher (Wofi)
Print                           # Screenshot with annotation (Satty editor)
Super+R                         # Toggle screen recording (GPU-accelerated)
```

**Wallpaper Management**:
```bash
random-wallpaper                # Random wallpaper + automatic color theming
set-wallpaper <path>            # Set specific wallpaper and regenerate palette
```

**CLI Discovery**:
```bash
commands                        # List all available custom commands
commands | grep <term>          # Search for specific commands
<command> --help                # Get help for any custom command
```

### Common Workflows

#### Adding Packages

```bash
# 1. Edit package configuration
chezmoi edit ~/.local/share/chezmoi/.chezmoidata/packages.yaml

# 2. Add to appropriate category and strategy
#
# For Arch packages:
#   packages.install.arch.packages.<category>:
#     strategy: *_install_binary       # or *_install_from_source
#     list: [package-name]
#
# For Flatpak apps:
#   packages.flatpak.packages.<category>:
#     - com.example.App                # Use Flatpak ID format

# 3. Apply (automatically installs/removes)
chezmoi apply
```

**Strategy Selection**:
- Use `*_install_binary` for: Faster installation, precompiled packages
- Use `*_install_from_source` for: AUR packages without binary versions, customization needs

#### Configuration Customization

**Monitor Settings** (`private_dot_config/hypr/conf/monitor.conf.tmpl`):
```bash
# 1. Edit monitor configuration
chezmoi edit ~/.local/share/chezmoi/private_dot_config/hypr/conf/monitor.conf.tmpl

# 2. Modify monitor settings (resolution, position, scale)
# Example: monitor=DP-1,2560x1440@144,0x0,1

# 3. Apply and reload
chezmoi apply
hyprctl reload  # or Super+Shift+R
```

**Keybindings** (`private_dot_config/hypr/conf/bindings.conf.tmpl`):
```bash
# 1. Edit keybinding configuration
chezmoi edit ~/.local/share/chezmoi/private_dot_config/hypr/conf/bindings.conf.tmpl

# 2. Add or modify keybindings
# Example: bind = SUPER, T, exec, kitty

# 3. Apply and reload
chezmoi apply
hyprctl reload
```

**View Current Keybindings**: Press `Super+?` or run `Super+Space` → Learn → Keybindings

#### Encrypted Files

```bash
# View encrypted content
chezmoi decrypt <file>

# Edit encrypted file (opens in $EDITOR)
chezmoi edit <file>

# Add new file with encryption
chezmoi add --encrypt ~/sensitive-file.txt
```

**Security Model**: Age encryption uses manual operations to prevent accidental exposure. Files ending in `.age`, files in `private_dot_keys/`, and SSH private keys are automatically encrypted.

#### Handling Updates

```bash
# 1. Pull latest changes
cd ~/.local/share/chezmoi
git pull origin main

# 2. Review what will change
chezmoi diff

# 3. Validate with dry-run
chezmoi apply --dry-run

# 4. Apply if safe
chezmoi apply
```

#### Merge Conflicts

```bash
# Check for conflicts
chezmoi status

# Resolve all conflicts (template protection active)
chezmoi merge-all

# Or resolve specific file
chezmoi merge <file>
```

**Note**: Template merge protection automatically preserves `{{ .variable }}` syntax during merges.

#### Recovery

**Rollback Specific File**:
```bash
git -C ~/.local/share/chezmoi checkout HEAD -- path/to/file
chezmoi apply
```

**Complete Reset**:
```bash
cd ~/.local/share/chezmoi
git reset --hard origin/main
chezmoi apply
```

**Rollback to Specific Commit**:
```bash
cd ~/.local/share/chezmoi
git log --oneline -10           # View recent commits
git checkout <commit-hash>      # Rollback to specific commit
chezmoi apply
```

### Desktop Features

#### Hierarchical Menu System (`Super+Space`)

10-category system control interface:

- **Apps**: Application launcher (Wofi)
- **Learn**: Help and documentation (keybindings, man pages)
- **Trigger**: Quick actions
  - **Capture**: Screenshots, screen recording, color picker
  - **Share**: File/clipboard sharing (planned)
  - **Toggle**: Nightlight, idle, waybar, gaps
- **Style**: Theme and appearance settings
- **Setup**: System configuration utilities
- **Install**: Package installation by category
- **Remove**: Package removal interface
- **Update**: System updates (topgrade, package managers)
- **About**: System information (fastfetch)
- **System**: Power management (lock, logout, suspend, reboot, shutdown)

#### Desktop Toggles

| Keybinding | Function | Description |
|------------|----------|-------------|
| `Super+N` | Nightlight | Toggle blue light filter (6000K ↔ 4000K) |
| `Super+I` | Idle inhibit | Presentation mode (disable screen lock) |
| `Super+B` | Waybar | Show/hide status bar (distraction-free mode) |
| `Super+G` | Workspace gaps | Toggle gaps and borders (immersive mode) |
| `Super+A` | Audio output | Cycle through available audio outputs |

#### Screenshot System

Advanced screenshot workflow with annotation:

| Mode | Keybinding | Description |
|------|------------|-------------|
| **Smart** | `Print` | Auto-snaps to window if tiny selection, opens Satty editor |
| **Region** | `Shift+Print` | Direct to clipboard (no editor) |
| **Windows** | `Ctrl+Print` | Window selection mode |
| **Fullscreen** | `Alt+Print` | Entire screen capture |
| **Color Picker** | `Super+Print` | Pick color from screen (hyprpicker) |

**Workflow**:
1. Press Print → Make selection (or tiny selection auto-snaps to window)
2. Satty annotation editor opens
3. Add text, arrows, highlights, or crops
4. Save to `~/Pictures/Screenshots/` or copy to clipboard

**Integration**: Uses wayfreeze for clean captures (freezes screen to hide selection UI).

#### Wallpaper System

**Automatic Rotation**:
- Systemd timer triggers every 30 minutes
- Smooth transitions via `swww` daemon
- Color palette extraction via `wallust` (K-means in Lab color space)
- 8 applications adapt colors automatically: Hyprland, Hyprlock, Waybar, Wofi, Dunst, Wlogout, Ghostty, Shell

**Manual Control**:
```bash
random-wallpaper                # Select random wallpaper from ~/Pictures/wallpapers/
set-wallpaper ~/path/to/image   # Set specific wallpaper
```

**Systemd Management**:
```bash
systemctl --user status wallpaper-cycle.timer   # Check timer status
systemctl --user restart wallpaper-cycle.timer  # Restart if stuck
journalctl --user -u wallpaper-cycle.service    # View logs
```

## Development Environment

### Languages & Version Management
- **Go**: Latest stable compiler for system tools and utilities
- **Python**: Python 3 with pip, virtualenv for scripting and data work
- **Rust**: Rust toolchain with cargo for performance-critical tools
- **mise**: Universal version manager for project-specific tool versions

### Development Tools
- **Containers**: Docker with docker-compose for development environments
- **Editor**: VSCode with curated extension suite (automatically synced)
- **Git Enhancements**:
  - **delta**: Syntax-highlighting pager for beautiful diffs
  - **difftastic**: Structural diff tool that understands syntax
  - **mergiraf**: Intelligent merge tool
  - **Custom merge driver**: Template protection for `.tmpl` files
- **Terminal**: Ghostty (primary, GPU-accelerated), Kitty (archinstall baseline)

### CLI Tools
- **File Operations**: ripgrep (rg), fd, eza, zoxide, bat, hexyl
- **System Monitoring**: btop, nvitop, fastfetch, dust, duf
- **Shell**: Zsh with antidote plugin manager + Starship prompt
- **Utilities**: fzf, jq, yq, httpie, hyperfine

### Theming
Consistent Solarized (oksolar) base with dynamic wallpaper-derived accents:
- **Desktop**: Waybar, Wofi, Hyprland, Dunst
- **Terminal**: Ghostty, Kitty
- **Development**: bat, delta, Starship
- **Shell**: Prompt and syntax highlighting

## Troubleshooting

### Installation Issues

**Age key setup failures**:
```bash
# Verify Age is installed
which age

# Check key file permissions
ls -la ~/.config/chezmoi/key.txt

# Regenerate key if needed
age-keygen -o ~/.config/chezmoi/key.txt
```

**Package installation failures**:
```bash
# AUR timeout - increase build time
yay -S <package> --timeout 3600

# Fallback to binary strategy
# Edit .chezmoidata/packages.yaml
# Change strategy from *_install_from_source to *_install_binary
chezmoi apply
```

**Network/proxy issues**:
```bash
# Check internet connectivity
ping archlinux.org

# Configure git proxy if behind corporate firewall
git config --global http.proxy http://proxy:port
```

### Runtime Issues

**Template errors**:
```bash
# Validate template syntax
chezmoi execute-template < template.tmpl

# Check available template data
chezmoi data | grep <variable>

# View rendered output without applying
chezmoi cat ~/.config/app/config
```

**Systemd timer issues** (e.g., wallpaper rotation stopped):
```bash
# Check timer status (should show "Next trigger" time)
systemctl --user status wallpaper-cycle.timer

# Check service logs for errors
journalctl --user -u wallpaper-cycle.service -n 50

# Restart timer if stuck
systemctl --user restart wallpaper-cycle.timer

# Manually trigger for testing
systemctl --user start wallpaper-cycle.service
```

**Merge conflicts**:
```bash
# Identify conflicts
chezmoi status

# Resolve specific file
chezmoi merge <file>

# Resolve all conflicts (template protection active)
chezmoi merge-all

# If merge-all fails, manually edit and reapply
chezmoi edit <file>  # Fix conflicts in source
chezmoi apply
```

**chezmoi_modify_manager issues**:
```bash
# Preview what modify_manager will produce
chezmoi cat ~/.config/AppName/config

# Test modify script directly
chezmoi execute-template < private_dot_config/AppName/modify_app.conf.tmpl

# Check modify_manager syntax
chezmoi_modify_manager --help-syntax
```

### Recovery Scenarios

**Rollback recent changes**:
```bash
# View recent commits
cd ~/.local/share/chezmoi
git log --oneline -10

# Rollback to specific commit
git checkout <commit-hash>
chezmoi apply

# Rollback one commit
git checkout HEAD~1
chezmoi apply

# Return to latest
git checkout main
chezmoi apply
```

**Complete system restore**:
```bash
# Reset chezmoi source to remote state
cd ~/.local/share/chezmoi
git reset --hard origin/main
chezmoi apply

# If that fails, re-initialize (nuclear option)
mv ~/.local/share/chezmoi ~/.local/share/chezmoi.backup
chezmoi init --apply https://gitlab.com/amoconst/dotfiles.git
```

**Backup/restore specific configs**:
```bash
# Backup before major changes
cp ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.backup
tar czf ~/config-backup-$(date +%Y%m%d).tar.gz ~/.config

# Restore from backup
cp ~/.config/hypr/hyprland.conf.backup ~/.config/hypr/hyprland.conf

# Or force restore from chezmoi source
chezmoi apply --force ~/.config/hypr/hyprland.conf
```

## Uninstalling

### Safe Removal

```bash
# 1. Backup current configuration (optional but recommended)
tar czf ~/dotfiles-backup-$(date +%Y%m%d).tar.gz \
  ~/.config ~/.zshrc ~/.bashrc ~/.profile ~/.local

# 2. Remove chezmoi-managed files
chezmoi purge

# 3. Remove chezmoi itself
rm -rf ~/.local/share/chezmoi
rm -rf ~/.config/chezmoi
rm ~/.local/bin/chezmoi

# 4. Remove installed packages (optional)
# View managed packages
cat ~/.local/share/chezmoi/.chezmoidata/packages.yaml

# Remove Arch packages by category
yay -Rns $(yay -Qqs <package-prefix>)

# Remove Flatpak applications
flatpak list --app                    # List installed
flatpak uninstall com.spotify.Client  # Remove specific app

# Or use package-manager command
package-manager remove <category>
```

### Partial Rollback

To keep chezmoi but revert specific changes:

```bash
# Remove specific file from management
chezmoi forget ~/.config/app/config
rm ~/.config/app/config
# Manually restore previous version

# Reset to clean state
cd ~/.local/share/chezmoi
git reset --hard origin/main
chezmoi apply
```

### Restore Previous Configuration

If you backed up configs before installation:

```bash
# Extract backup
tar xzf ~/dotfiles-backup-YYYYMMDD.tar.gz -C ~

# Verify restoration
ls -la ~/.config ~/.zshrc ~/.bashrc
```

## Documentation

- **README.md** (this file): Comprehensive user guide for installation, usage, and architecture
- **CLAUDE.md**: Technical reference for AI coding agents (development patterns, mandatory protocols, syntax standards)

## Project Information

**Repository**: Personal dotfiles configuration
**Target OS**: Arch Linux only (full functionality not guaranteed on other distributions)
**License**: Personal configuration files, use at your own discretion

**Contributing**: This is a personal repository, but feel free to:
- Fork for your own use and customization
- Open issues for bugs or suggestions
- Submit pull requests for improvements

---

**Note**: This configuration is specifically designed for Arch Linux installed via archinstall with Hyprland profile. While some configurations may work on other distributions or desktop environments, the system is designed, tested, and maintained exclusively for this target environment.
