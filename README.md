# Sophisticated Chezmoi Dotfiles

A comprehensive chezmoi dotfiles repository that manages personal configuration files across systems with advanced AI assistant integration. This repository implements sophisticated templating, encryption, and automated maintenance systems designed for Arch Linux development workstations.

## Features

### Desktop Environment
Modern Wayland-based desktop with tiling window management:
- **Hyprland**: Wayland compositor with dynamic tiling and animations
- **Waybar**: Customizable status bar (15 modules: workspaces, system info, tray)
- **Wofi**: Application launcher for desktop apps
- **Ghostty**: Primary terminal emulator with GPU acceleration
- **Dunst**: Notification daemon for desktop notifications
- **NVIDIA Support**: Hardware acceleration configured for NVIDIA GPUs
- **oksolar Theming**: Consistent color scheme across desktop and applications

### Development Environment
Everything you need for modern software development on Arch Linux:
- **Languages**: Go, Python, Rust with mise for version management
- **Containers**: Docker with automated setup and service configuration
- **Editor**: VSCode with curated extension suite
- **Version Control**: Git with delta (beautiful diffs), mergiraf (smart merging), template protection
- **CLI Tools**: ripgrep, fd, fzf, bat, delta - modern replacements for grep, find, ls, cat
- **Consistent Theming**: Solarized (oksolar) across terminal, editor, and development tools

### System Management
Automated, reliable system maintenance with clear separation of concerns:
- **Package Installation**: Multi-strategy installation (pacman → AUR binary → AUR source)
- **Automated Updates**: Topgrade integration with systemd timer for hands-off maintenance
- **Health Monitoring**: System health dashboards and package health checks
- **Backup Automation**: Scheduled backups via systemd user timers
- **Security Auditing**: Automated security scans and vulnerability checks
- **Clear Boundaries**: Chezmoi handles setup, external tools handle ongoing maintenance

### Shell Experience
Consistent, powerful shell environment across sh, bash, and zsh:
- **Universal Initialization**: Same environment in all shells and execution contexts
- **Layered Architecture**: Common POSIX base with shell-specific enhancements
- **Dual Function System**: Simple functions for automation, rich interactive functions for terminal
- **Modern Prompt**: Starship with informative, fast git-aware prompt
- **Plugin Management**: Antidote for Zsh with carefully selected plugins
- **Interactive Tools**: Gum-based UI for maintenance commands (system-health, check-packages)

### AI Integration
Structured AI assistant configuration for enhanced development workflow:
- **Behavioral Rules**: Cline AI rules for consistent coding agent behavior
- **Editor Integration**: Continue AI extension pre-configured for VSCode
- **Local Models**: Ollama with automatic model download and management
- **Development Focus**: AI tools optimized for software development workflows

### Configuration Management
Sophisticated dotfiles management with security and flexibility:
- **Dynamic Templating**: Go text/template + Sprig for conditional configuration
- **Smart Config Handling**: chezmoi_modify_manager separates user settings from runtime state
- **Security First**: Age encryption for keys, credentials, and secrets
- **Template Protection**: Custom git merge driver preserves template variables during merges
- **Single Source of Truth**: All configuration managed through chezmoi with git versioning

## Installation

### Prerequisites

This repository assumes you have completed a fresh Arch Linux installation using **archinstall** with the **Hyprland desktop profile**. The baseline system should include:
- Core system packages (base, base-devel, linux, systemd-boot)
- Hyprland desktop environment (hyprland, dunst, kitty, wofi, dolphin)
- Audio system (pipewire, wireplumber)
- Graphics drivers (NVIDIA drivers for NVIDIA GPUs)
- Network management (NetworkManager, iwd)
- Display manager (SDDM)

See `.chezmoidata/packages.yaml` → `archinstall_baseline` section for the complete list.

### Quick Start
```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin
chezmoi init --apply https://gitlab.com/amoconst/dotfiles.git
reboot
```

### What Gets Installed

After the archinstall baseline, this dotfiles repository will:
1. Install yay AUR helper and configure chaotic-aur repository
2. Create necessary directories and write global environment variables
3. Install distribution-specific packages and tools
4. Set up age encryption keys
5. Install chezmoi_modify_manager for intelligent config management
6. Install all package categories (fonts, terminal tools, languages, development tools, AI tools, applications)
7. Create maintenance user for automated tasks
8. Generate and configure CLI tools (delta, bat, ripgrep)
9. Enable system services (Docker, Snap, Bluetooth)
10. Set up network printer (if applicable)
11. Configure topgrade automation with systemd timer
12. Configure git merge driver for template protection
13. Configure Ollama and install AI models
14. Switch to SSH remote for repository updates
15. Install VSCode extensions
16. Set up git hooks

### With AI Features

During initialization, you'll be prompted to enable AI tools and configurations. Answer `y` to include:
- AI assistant behavioral rules for Cline and other AI coding agents
- Continue AI extension configuration for VS Code
- Ollama local LLM setup with automatic service enablement
- AI model management with automated downloads
- Development-focused AI tooling and integrations

## Architecture

### Repository Structure

This is a comprehensive chezmoi dotfiles repository with:
- **Advanced templating**: Go text/template with custom functions and Sprig library
- **Age encryption**: Secure handling of sensitive files with manual operation workflows
- **chezmoi_modify_manager integration**: Smart handling of configuration files with mixed settings and state

```
.chezmoidata/           # Template data sources (YAML)
├── packages.yaml      # Arch native + Flatpak package management
├── ai.yaml           # AI models configuration
├── extensions.yaml   # VSCode extensions list
└── colors.yaml       # Color scheme definitions (oksolar)

.chezmoiscripts/        # Setup and configuration scripts
├── run_once_before_*  # Initial setup scripts (package managers, directories)
├── run_once_after_*   # Post-setup configuration (services, tools)
└── run_onchange_*     # Content-driven updates (extensions, models)

.chezmoitemplates/      # Reusable template includes
├── log_start          # Standardized logging templates
├── log_step
├── log_success
├── log_error
└── log_complete

private_dot_config/     # XDG config directory contents (~/.config)
├── shell/             # Common shell configuration
├── bash/              # Bash-specific configuration
├── zsh/               # Zsh-specific configuration
├── sh/                # POSIX sh configuration
└── scripts/           # Standalone utility scripts

private_dot_keys/       # Encrypted keys and secrets (age-encrypted)
private_dot_ssh/        # SSH configuration and encrypted keys
```

### Key Concepts Explained

#### chezmoi_modify_manager

**The Problem:** Many applications (like Nextcloud Desktop, VSCode) store both user preferences and runtime state in the same config file. Traditional dotfiles management causes constant conflicts because runtime data (window positions, cache, session IDs) changes on every run.

**The Solution:** `chezmoi_modify_manager` intelligently separates concerns:
- You maintain a `.src.ini` file with only the settings you want to manage
- Runtime state data is ignored using `ignore` directives
- User-specific values are dynamically set using chezmoi templates
- The manager merges your settings with the application's current state

**Real Example:** Nextcloud Desktop Configuration
```bash
# File: modify_nextcloud.conf.tmpl
#!/usr/bin/env chezmoi_modify_manager
source auto

# Ignore runtime state
ignore section "DirSelect Dialog"    # Window positions
ignore section "Cache"               # Temporary data

# Set user-specific values
set "User" "Name" "{{ .fullname }}"
set "User" "Email" "{{ .personalEmail }}"

# Hide sensitive data
add:hide "Accounts" "0\\password"
```

This keeps your dotfiles clean while respecting application state. See working implementation: `private_dot_config/Nextcloud/modify_nextcloud.cfg.tmpl`

#### Template Merge Protection

**The Problem:** When merging git branches with chezmoi template files, git might render template variables (turning `{{ .firstname }}` into actual values), breaking the templates.

**The Solution:** Custom git merge driver that:
1. Detects `.tmpl` files during merge operations
2. Prioritizes versions containing template syntax
3. Preserves `{{ .variable }}` syntax instead of rendering
4. Only falls back to standard merge when both versions lack templates

**How It Works:**
- `.gitattributes` configures `*.tmpl merge=chezmoi-template`
- Custom merge driver in `.scripts/template-merge-driver.sh` handles the logic
- Automatic setup via `run_once_after_005_configure_template_merge_driver.sh.tmpl`

This means you can safely merge branches without breaking your templates. The protection is automatic and requires no manual intervention.


### Shell Initialization System

This repository implements a sophisticated multi-shell initialization system that provides consistent environment setup across sh, bash, and zsh in all execution modes (interactive, non-interactive, login).

#### Core Architecture Pattern

**Layer 1: Common Shell Configuration (`~/.config/shell/`)**
- **`shell/env`** - Core environment setup, sets ENV/BASH_ENV variables, sources `env_functions`
- **`shell/env_functions`** - POSIX shell functions available to all shells (e.g., `system_health_simple()`)
- **`shell/interactive`** - Common interactive shell configuration
- **`shell/login`** - Login shell environment variables (EDITOR, VISUAL, BROWSER, etc.)
- **`shell/logout`** - Logout cleanup (clears console for privacy)

**Layer 2: Shell-Specific Adapters**

Each shell follows the same delegation pattern where shell-specific files source common `shell/` files:

**Bash:**
- `~/.bash_profile` - Complex bash login setup with BASH_ENV management
- `~/.bashrc` - Sources `bash/env` + `bash/interactive`
- `~/.config/bash/env` → sources `shell/env`
- `~/.config/bash/interactive` → sources `shell/interactive`
- `~/.config/bash/login` → sources `shell/login`
- `~/.config/bash/logout` → sources `shell/logout`

**Zsh:**
- `~/.zshenv` - Sources `zsh/env`, sets ZDOTDIR
- `~/.config/zsh/env` → sources `shell/env`
- `~/.config/zsh/.zlogin` → sources `shell/login`
- `~/.config/zsh/.zlogout` → sources `shell/logout`
- `~/.config/zsh/.zshrc` - Sources `shell/interactive`, then Zsh-specific setup with antidote plugins
- `~/.config/zsh/.zfunctions/` - Zsh-specific interactive functions

**POSIX Shell:**
- `~/.profile` - Sources `sh/env` + `sh/login` (for sh-compatible login shells)
- `~/.config/sh/env` → sources `shell/env`
- `~/.config/sh/interactive` → sources `shell/interactive`
- `~/.config/sh/login` → sources `shell/login`

#### Function Architecture

**POSIX Functions (`~/.config/shell/env_functions`):**
- **Purpose**: Automation, scripts, systemd services, topgrade integration
- **Examples**: `system_health_simple()`, `system_maintenance_simple()`
- **Features**: Simple ANSI output, no dependencies, fast execution
- **Loaded by**: All shells via `shell/env`
- **Usage**: `system_health_simple --brief`, `system_maintenance_simple --cleanup`

**Interactive Functions (`~/.config/zsh/.zfunctions/`):**
- **Purpose**: Rich terminal interaction with enhanced UI
- **Examples**: `system-health`, `system-maintenance`, `check-packages`
- **Features**: Gum-based UI, interactive menus, progress spinners, formatted tables
- **Loaded by**: Zsh autoload mechanism
- **Usage**: Direct terminal commands with full interactive experience

#### Key Benefits

- **Universal Consistency**: Same functions available across all shells and execution contexts
- **Separation of Concerns**: POSIX functions for automation, rich functions for interaction
- **Architecture Symmetry**: Each shell follows identical delegation patterns
- **Reliable Automation**: Non-interactive shells get consistent environment (systemd, topgrade, scripts)
- **Rich UX**: Interactive shells get enhanced functionality with modern UI elements

### System Maintenance Architecture

System maintenance is handled by separate tools outside of chezmoi scripts:

#### CLI Functions (`~/.config/zsh/.zfunctions/`)
- **system-health** - Comprehensive system status dashboard with health metrics
- **system-troubleshoot** - System troubleshooting and diagnostics
- **package-manager** - Manage system packages and applications
  - `package-manager install <category>` - Install package category
  - `package-manager remove <category>` - Remove package category
  - `package-manager sync` - Sync system with configuration
  - `package-manager health` - Check package system health
  - All commands support `--dry-run` to preview changes
- **git-prune-branch** - Git branch cleanup and maintenance

#### Standalone Scripts (`~/.config/scripts/`)
```
scripts/
├── system/
│   ├── health.sh              # System health monitoring
│   └── troubleshoot.sh        # System troubleshooting tools
├── git/
│   └── prune-branch.sh        # Git branch cleanup
├── package-manager.sh         # Package management wrapper
└── reorder-json.sh            # JSON formatting utility
```

#### Systemd Timers
**System timers** (configured by chezmoi):
- `topgrade.timer` - Automated system updates with topgrade

#### Topgrade Integration (`~/.config/topgrade.toml`)

Custom commands integrated into topgrade workflow:
- **System Health Check** - Pre-update health assessment
- **Package Health** - Package database integrity verification
- **Security Status** - Quick security status check
- **Pre-backup** - Automated backup before major updates

#### Separation of Concerns

- **chezmoi** (`.chezmoiscripts/`): Deploys and configures maintenance tools during initial setup
- **topgrade**: Handles system updates and upgrades with custom pre/post commands
- **systemd**: Schedules automated maintenance tasks independent of chezmoi
- **CLI tools**: Provide manual maintenance capabilities with rich interactive UX
- **Standalone scripts**: Execute complex maintenance workflows for automation

### Package Management

Sophisticated package installation with fallback chains to ensure reliable deployment:

#### Installation Strategies

```yaml
strategies:
  _install_binary: [pacman, yay_bin]
  _install_from_source: [pacman, yay_bin, yay_source]
```

**Strategy Execution:**
1. Try `pacman` (official Arch repositories)
2. Try `yay_bin` (AUR precompiled packages)
3. Try `yay_source` (AUR packages built from source)

#### System Configuration

The system is configured as a comprehensive development environment with:
- **All package categories**: Complete development stack with tools and applications
- **System-level services**: Docker, Flatpak, Bluetooth, and topgrade automation enabled
- **Extensions**: VSCode extensions automatically installed
- **AI Models**: Ollama models automatically pulled
- **Automatic package management**: Packages sync automatically with configuration changes

#### Package Categories

- **fonts**: Programming fonts (FiraCode Nerd Font, OpenDyslexic, Geist Mono)
- **terminal_essentials**: Core CLI tools (ghostty, neovim, ripgrep, fd, bat, fzf, eza, zoxide)
- **terminal_utils**: System monitoring (btop, nvitop, fastfetch, topgrade)
- **languages**: Programming languages (Go, Python, Rust)
- **development_tools**: Development software (Docker, mise)
- **development_clis**: Developer CLIs (AWS CLI, git-delta, lazygit, posting)
- **wayland_desktop**: Wayland desktop components (waybar status bar)
- **ai_tools**: AI/ML tools (Ollama for local LLMs)
- **general_software**: Native applications (Firefox, Nextcloud Desktop)
- **work_software**: Work applications (Chromium, VSCode)
- **flatpak_apps**: Sandboxed applications via Flatpak:
  - Spotify - Music streaming
  - Slack - Team communication
  - Xournalpp - Note-taking and PDF annotation
  - qBittorrent - Torrent client

#### Package Installation Flow

The system automatically installs and manages packages in these phases:

1. **Initial Setup**:
   - Package managers installed (yay for AUR, Flatpak for sandboxed apps)
   - System directories and encryption keys configured
   - Maintenance user created for automated updates

2. **Package Installation**:
   - All Arch Linux packages installed from configuration
   - Flatpak applications installed for cross-platform software
   - Packages automatically sync when you change configuration

3. **System Configuration**:
   - Services enabled (Docker, Bluetooth, topgrade automation)
   - Network printer configured (if available)
   - Git hooks and merge drivers configured
   - AI system (Ollama) configured

4. **Automatic Updates**:
   - VSCode extensions stay in sync
   - AI models automatically updated
   - Applications added/removed based on configuration
   - No manual intervention needed - just edit config and apply

**Key Benefit**: Change `packages.yaml` and run `chezmoi apply` - everything updates automatically. Add a package to the config and it installs. Remove a package from the config and it uninstalls.

## Usage

### Common Workflows

#### Making Configuration Changes

```bash
# 1. Edit source files
chezmoi edit ~/.config/zsh/.zshrc

# 2. Preview changes
chezmoi diff

# 3. Apply changes
chezmoi apply
```

#### Adding New Packages

```bash
# 1. Edit package list
chezmoi edit ~/.local/share/chezmoi/.chezmoidata/packages.yaml

# 2. Add package to appropriate category
# Example: add 'htop' to terminal_utils.list

# 3. Apply changes (will install package)
chezmoi apply
```

#### Handling Encrypted Files

```bash
# View encrypted file
chezmoi decrypt ~/.keys/api-key.txt.age

# Edit encrypted file (opens in $EDITOR)
chezmoi edit ~/.keys/api-key.txt.age

# Add new file with encryption
chezmoi add --encrypt ~/sensitive-file.txt
```

#### Recovering from Mistakes

```bash
# See what changed
chezmoi diff

# Revert specific file
git -C ~/.local/share/chezmoi checkout HEAD -- path/to/file

# Reapply from source
chezmoi apply

# Nuclear option: reset all changes
git -C ~/.local/share/chezmoi reset --hard HEAD
chezmoi apply
```

### Daily Operations

```bash
# Apply configuration changes
chezmoi apply -v               # Apply all changes with verbose output
chezmoi status                 # Check what files have changed
chezmoi diff                   # Preview changes before applying

# Edit managed files
chezmoi edit <file>            # Edit file in source state
chezmoi add <file>             # Add new file to dotfiles management

# Merge conflict resolution
chezmoi merge <file>           # Resolve conflicts in specific file
chezmoi merge-all             # Resolve all conflicts at once
```

### System Maintenance

```bash
# Automated updates
topgrade                       # Comprehensive system updates (packages, tools, firmware)
sudo systemctl enable --now topgrade.timer  # Enable automated updates

# Package management
yay -Syu                      # Update Arch packages + AUR packages
mise install                  # Install/update development tool versions

# Manual maintenance (interactive functions)
system-health                 # System health dashboard with detailed metrics
system-troubleshoot          # System troubleshooting and diagnostics
```

### AI Integration

```bash
# AI models are managed through .chezmoidata/ai.yaml
# Ollama automatically pulls configured models on chezmoi apply

# View configured models
cat ~/.local/share/chezmoi/.chezmoidata/ai.yaml

# Models are automatically installed during chezmoi apply
```

### Development Workflow

```bash
# Start development environment
mise install                  # Install project tool versions
docker compose up -d          # Start development containers

# Use enhanced tools
bat <file>                   # Syntax-highlighted file viewing
rg <pattern>                 # Fast recursive grep
fd <pattern>                 # Fast file finding
delta <file>                 # Beautiful git diffs

# Version management
mise install                  # Install project tool versions
```

## Development Environment

This dotfiles repository sets up a comprehensive development environment with:

### Languages and Version Management
- **Go**: Latest stable Go compiler
- **Python**: Python 3 with pip and virtualenv support
- **Rust**: Rust toolchain with cargo
- **mise**: Universal version manager for language runtimes and tools

### Development Tools
- **Docker**: Container platform with docker-compose
- **VSCode**: Visual Studio Code with extensive extension suite
- **Git enhancements**:
  - delta: Syntax-highlighting pager for git diffs
  - difftastic: Structural diff tool
  - mergiraf: Intelligent merge tool
  - Custom merge driver for template protection

### Terminal Tools
- **Terminal**: Ghostty (primary, GPU-accelerated), Kitty (archinstall baseline)
- **Shell**: Zsh with antidote plugin manager and Starship prompt
- **File operations**: ripgrep (rg), fd, eza (ls replacement), zoxide (cd replacement)
- **File viewing**: bat (cat replacement), hexyl (hex viewer)
- **System monitoring**: btop, nvitop, fastfetch, dust, duf
- **Utilities**: fzf, jq, yq, httpie, hyperfine

### AI Tools
- **Ollama**: Local LLM inference with automatic model management
- **ai-shell**: AI-powered shell command suggestions
- **aichat**: Terminal-based AI chat interface
- **Continue**: AI-powered code assistance in VS Code

### Theming
- **Consistent Solarized (oksolar)** color scheme across:
  - Desktop environment (Waybar, Wofi)
  - Terminal emulators (Ghostty, Kitty)
  - Shell prompts (Starship)
  - Syntax highlighting (bat, delta)
  - Development tools

## Updating Your Dotfiles

Follow this safe update workflow when pulling changes from the repository:

```bash
# 1. Pull latest changes
cd ~/.local/share/chezmoi
git pull origin main

# 2. Review what will change
chezmoi diff

# 3. Dry-run to validate
chezmoi apply --dry-run

# 4. Apply if safe
chezmoi apply
```

**Handling Breaking Changes:**
- Check commit messages for breaking changes before pulling
- Review `CHANGELOG.md` if available
- Test in dry-run mode first
- Keep backups of critical configs before major updates

**Automated Updates:**

The system uses smart update scripts that automatically trigger when you change configuration files. For example:

- Edit `packages.yaml` → Packages automatically install/remove
- Edit `extensions.yaml` → VSCode extensions automatically install
- Edit `ai.yaml` → AI models automatically download

The system only updates what changed, making it fast and efficient. You don't need to manually reinstall or track what needs updating - just change the config and run `chezmoi apply`.

## Troubleshooting

### Installation Issues

**Age key setup failures:**
```bash
# Verify age is installed
which age

# Check key file permissions
ls -la ~/.config/chezmoi/key.txt

# Regenerate key if needed
age-keygen -o ~/.config/chezmoi/key.txt
```

**Package installation failures:**
```bash
# AUR timeout - try with more build time
yay -S package-name --timeout 3600

# Check chaotic-aur repo is configured
cat /etc/pacman.conf | grep chaotic

# Fallback to binary package
# Edit .chezmoidata/packages.yaml and change strategy to _install_binary
```

**Network/proxy issues:**
```bash
# Check internet connectivity
ping archlinux.org

# Verify proxy settings if behind corporate firewall
echo $http_proxy $https_proxy

# Configure git proxy
git config --global http.proxy http://proxy:port
```

### Daily Usage Issues

**Merge conflicts:**
```bash
# Check conflict status
chezmoi status

# Resolve specific file
chezmoi merge path/to/file

# Resolve all conflicts
chezmoi merge-all

# If merge-all fails, resolve manually
chezmoi edit path/to/file  # Fix conflicts
chezmoi apply
```

**Template errors:**
```bash
# Validate template syntax
chezmoi execute-template < template.tmpl

# Check available data
chezmoi data

# View rendered output without applying
chezmoi cat path/to/file
```

**Failed scripts:**
```bash
# Check which script failed
chezmoi apply -v

# Run script manually to see error
bash -x ~/.local/share/chezmoi/.chezmoiscripts/script_name.sh.tmpl

# Skip problematic script temporarily
# (Remove or rename to disable)
```

### Recovery Scenarios

**Rollback recent changes:**
```bash
# View recent commits
cd ~/.local/share/chezmoi
git log --oneline -5

# Rollback to specific commit
git checkout <commit-hash>
chezmoi apply

# Rollback to previous commit
git checkout HEAD~1
chezmoi apply
```

**Complete system restore:**
```bash
# Reset to clean state
cd ~/.local/share/chezmoi
git reset --hard origin/main
chezmoi apply

# If that fails, re-initialize
mv ~/.local/share/chezmoi ~/.local/share/chezmoi.backup
chezmoi init --apply https://gitlab.com/amoconst/dotfiles.git
```

**Backup/restore specific configs:**
```bash
# Backup before changes
cp ~/.zshrc ~/.zshrc.backup

# Restore from backup
cp ~/.zshrc.backup ~/.zshrc

# Or use chezmoi to restore from source
chezmoi apply --force ~/.zshrc
```

## Uninstall/Rollback

### Safe Removal

To remove these dotfiles and restore system to pre-installation state:

```bash
# 1. Backup current configs (optional but recommended)
tar czf ~/dotfiles-backup-$(date +%Y%m%d).tar.gz \
  ~/.config ~/.zshrc ~/.bashrc ~/.profile

# 2. Remove chezmoi-managed files
chezmoi purge

# 3. Remove chezmoi itself
rm -rf ~/.local/share/chezmoi
rm -rf ~/.config/chezmoi
rm ~/.local/bin/chezmoi

# 4. Remove installed packages (optional)
# The system manages both Arch and Flatpak packages

# View all managed packages:
cat ~/.local/share/chezmoi/.chezmoidata/packages.yaml

# Remove Arch packages:
yay -Rns package-name

# Remove Flatpak applications:
flatpak list --app                    # List installed apps
flatpak uninstall com.spotify.Client  # Remove specific app

# Or let package-manager do it:
package-manager remove <category>     # Remove entire category
```

### Partial Rollback

To keep chezmoi but revert specific changes:

```bash
# Revert specific file
chezmoi forget ~/.config/zsh/.zshrc
rm ~/.config/zsh/.zshrc
# Manually restore previous version

# Keep chezmoi but reset to clean slate
cd ~/.local/share/chezmoi
git reset --hard origin/main
chezmoi apply
```

### Restore Previous System Config

If you backed up configs before installation:

```bash
# Extract backup
tar xzf ~/dotfiles-backup-YYYYMMDD.tar.gz -C ~

# Verify restoration
ls -la ~/.config ~/.zshrc ~/.bashrc
```

## Documentation

- **CLAUDE.md** - Technical reference for AI coding agents (development patterns, syntax, standards)
- **README.md** - This file, comprehensive user guide for humans

## Contributing

This is a personal dotfiles repository, but feel free to:
- Fork for your own use
- Open issues for bugs or suggestions
- Submit pull requests for improvements

## License

Personal configuration files. Use at your own discretion.

---

**Note**: This repository is designed for Arch Linux systems. While some configurations may work on other distributions, full functionality is only guaranteed on Arch Linux.
