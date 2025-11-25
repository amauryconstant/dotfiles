# Modern Arch Linux + Hyprland Dotfiles

A comprehensive dotfiles repository for Arch Linux with Hyprland compositor, featuring dynamic theming, intelligent configuration management, and automated system maintenance.

**Target System**: Vanilla Arch Linux (archinstall with Hyprland profile)

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

All setup scripts run automatically via chezmoi. No manual intervention required.

| Phase | Purpose | Trigger |
|-------|---------|---------|
| **1. Pre-Setup** | Configure repos (Chaotic-AUR, multilib), install paru + dependencies, create directories, set up Age encryption | First `chezmoi apply` |
| **2. Package Install** | Sync all packages (Arch + Flatpak) from packages.yaml | First install AND when packages change |
| **3. File Application** | Apply dotfiles and configuration templates | Every `chezmoi apply` |
| **4. Configuration** | Set up services (Docker, Bluetooth, Ollama, Tailscale), printer, git tools, wallpaper timer, boot system | First `chezmoi apply` |
| **5. Content Updates** | Install VSCode extensions, pull AI models, update themes | When data files change |

**Estimated Time**: 15-45 minutes depending on internet speed and AUR build requirements.

### With AI Features

During initialization, answer `y` when prompted for AI tools to enable:
- **Ollama**: Local LLM with automatic model downloads (requires NVIDIA GPU for acceleration)
- **Continue**: AI-powered code assistance in VSCode
- **Cline Rules**: AI assistant behavioral rules for coding agents

## What You Get

### Desktop Environment
- **Hyprland**: Wayland-native tiling compositor with modular configuration
- **Dynamic Theming**: Automatic color palette generation from wallpapers via `wallust`
- **Wallpaper Rotation**: Systemd timer with 30-minute intervals, smooth transitions
- **Adaptive UI**: 8 applications auto-theme (Hyprland, Waybar, Wofi, Dunst, Ghostty, etc.)
- **Status Bar**: Waybar with system info, workspaces, network, audio
- **Native Integration**: Polkit agent, GTK file manager (Thunar)

### System Management
- **Hierarchical Menu System**: `Super+Space` launches 10-category system control interface
- **Desktop Utilities**: Screenshot annotation (Satty), GPU recording, nightlight, idle/gaps toggles
- **Package Management**: Dual-layer (Arch native + Flatpak) with automatic sync
- **Automated Updates**: Topgrade integration with systemd timers
- **Health Monitoring**: System health dashboard with detailed metrics

### Modern Shell
- **Zsh**: With Starship prompt and intelligent completion
- **Zephyr Framework**: 8-plugin suite for XDG management, PATH handling, editor enhancements
- **CLI Tools**: Over 40 custom commands and utilities
- **CLI Discovery**: `commands` function lists all available custom tools

### Smart Configuration
- **chezmoi**: Template-driven dotfiles with automatic deployment
- **chezmoi_modify_manager**: Separates user settings from application state
- **Age Encryption**: Secure handling of keys and credentials
- **Template Protection**: Custom git merge driver preserves template syntax

## Daily Usage

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

### Desktop Toggles

| Keybinding | Function | Description |
|------------|----------|-------------|
| `Super+N` | Nightlight | Toggle blue light filter (6000K ↔ 4000K) |
| `Super+I` | Idle inhibit | Presentation mode (disable screen lock) |
| `Super+B` | Waybar | Show/hide status bar (distraction-free mode) |
| `Super+G` | Workspace gaps | Toggle gaps and borders (immersive mode) |
| `Super+A` | Audio output | Cycle through available audio outputs |

### Screenshot System

| Mode | Keybinding | Description |
|------|------------|-------------|
| **Smart** | `Print` | Auto-snaps to window if tiny selection, opens Satty editor |
| **Region** | `Shift+Print` | Direct to clipboard (no editor) |
| **Windows** | `Ctrl+Print` | Window selection mode |
| **Fullscreen** | `Alt+Print` | Entire screen capture |
| **Color Picker** | `Super+Print` | Pick color from screen (hyprpicker) |

## Common Workflows

### Adding Packages

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

### Configuration Customization

**Monitor Settings**:
```bash
# 1. Edit monitor configuration
chezmoi edit ~/.local/share/chezmoi/private_dot_config/hypr/conf/monitor.conf.tmpl

# 2. Modify monitor settings (resolution, position, scale)
# Example: monitor=DP-1,2560x1440@144,0x0,1

# 3. Apply and reload
chezmoi apply
hyprctl reload  # or Super+Shift+R
```

**Keybindings**:
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

### Encrypted Files

```bash
# View encrypted content
chezmoi decrypt <file>

# Edit encrypted file (opens in $EDITOR)
chezmoi edit <file>

# Add new file with encryption
chezmoi add --encrypt ~/sensitive-file.txt
```

**Security Model**: Age encryption uses manual operations to prevent accidental exposure. Files ending in `.age`, files in `private_dot_keys/`, and SSH private keys are automatically encrypted.

### Handling Updates

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

### Merge Conflicts

```bash
# Check for conflicts
chezmoi status

# Resolve all conflicts (template protection active)
chezmoi merge-all

# Or resolve specific file
chezmoi merge <file>
```

**Note**: Template merge protection automatically preserves `{{ .variable }}` syntax during merges.

### Recovery

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

## Desktop Features

### Hierarchical Menu System (`Super+Space`)

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

### Wallpaper System

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
paru -S <package> --timeout 3600

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
paru -Rns $(paru -Qqs <package-prefix>)

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

### User Documentation
- **README.md** (this file): Installation, usage, and common workflows

### Technical Documentation (for AI/Development)
- **CLAUDE.md**: Complete technical reference for AI coding agents
  - Architecture and design patterns
  - Template system internals
  - Script standards and development protocols
  - chezmoi_modify_manager syntax reference
  - Package management architecture
  - Quality standards and validation

Location-specific CLAUDE.md files exist throughout the repository for detailed implementation documentation.

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
