# Modern Arch Linux + Hyprland Dotfiles

A complete, automated desktop environment for Arch Linux with dynamic theming, intelligent configuration management, and smart package handling.

**Target System**: Vanilla Arch Linux (archinstall with Hyprland profile)

**Quick Links**: [Features](#features) | [Installation](#installation) | [Daily Usage](#daily-usage) | [Common Workflows](#common-workflows) | [Documentation](#documentation)

---

## Features

### Desktop Experience

- **Dynamic Theming**: Automatic color palette generation from wallpapers
- **Hyprland Compositor**: Wayland-native tiling with modular configuration
- **Smart Wallpapers**: 30-minute automatic rotation, theme-organized collections
- **Unified Interface**: Hierarchical menu system (`Super+Space`) for all system functions
- **Adaptive UI**: 13+ applications auto-theme (desktop: Hyprland, Waybar, Wofi, Dunst, Ghostty; CLI: bat, btop, starship, yazi; plus Firefox, VSCode)

### System Management

- **Intelligent Packages**: Dual-layer (Arch + Flatpak) auto-sync from YAML
- **Automated Updates**: Topgrade integration with systemd timers
- **Health Monitoring**: Dashboard with detailed system metrics
- **Smart Config**: Separates settings from state using chezmoi_modify_manager

### Configuration Intelligence

- **Template-Driven**: Go templates with hash-based change detection
- **Secure Secrets**: Age encryption with manual-only operations
- **Merge Protection**: Preserves template syntax during git merges
- **Data-Driven**: YAML changes trigger automatic updates

### Shell Environment

- **Zephyr Framework**: 8-plugin suite (XDG management, PATH deduplication, editor enhancements)
- **CLI Discovery**: `commands` lists all available tools
- **Lazy Loading**: Fast shell startup with on-demand script loading
- **Universal Functions**: POSIX automation + rich Gum-based interactive tools

[Technical details → CLAUDE.md]

---

## Installation

### Prerequisites

Fresh Arch Linux installation via **archinstall** with **Hyprland desktop profile**.

### Quick Start

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin

# Initialize and apply (15-45 minutes)
.local/bin/chezmoi init --apply https://gitlab.com/amoconst/dotfiles.git

# Reboot to complete setup
reboot
```

**What happens**: Automated setup installs packages, configures services, applies dotfiles.

### First Run

After reboot:

1. `Super+Space` - Explore hierarchical menu system
2. `commands` - See all available custom commands
3. `random-wallpaper` - Test dynamic theme switching
4. `Super+/` - View all keybindings

---

## Daily Usage

### Essential Commands

**Configuration Management**:
```bash
chezmoi diff          # Preview changes
chezmoi apply         # Apply changes
chezmoi edit <file>   # Edit managed file
chezmoi status        # Check file status
```

**System Maintenance**:
```bash
topgrade             # Update everything
system-health        # Health dashboard
package-manager      # Package management
```

**Desktop Control**:
```bash
Super+Space          # Hierarchical menu system
Super+Return         # Terminal
Super+D              # App launcher (Wofi)
Print                # Screenshot + annotation (Satty)
random-wallpaper     # Change wallpaper + theme
```

**CLI Discovery**:
```bash
commands                    # List all custom commands
commands | grep <term>      # Search commands
<command> --help            # Get help for any command
```

**Note**: `commands` is a Zsh function, available in interactive shells only.

### Desktop Toggles

| Key | Function | Description |
|-----|----------|-------------|
| `Super+N` | Nightlight | Blue light filter (6000K ↔ 4000K) |
| `Super+I` | Idle inhibit | Presentation mode (disable lock) |
| `Super+B` | Waybar | Show/hide status bar |
| `Super+G` | Gaps | Toggle gaps/borders (immersive mode) |
| `Super+A` | Audio output | Cycle available outputs |

### Screenshot System

| Mode | Keybinding | Description |
|------|------------|-------------|
| **Smart** | `Print` | Auto-snaps to window, opens Satty editor |
| **Region** | `Shift+Print` | Direct to clipboard (no editor) |
| **Fullscreen** | `Super+Shift+Print` | Entire screen capture |
| **Color Picker** | `Super+Print` | Pick color from screen |

---

## Common Workflows

### Adding Packages

```bash
# Edit packages.yaml
chezmoi edit ~/.local/share/chezmoi/.chezmoidata/packages.yaml

# Add to appropriate category:
# For Arch packages:
#   packages.install.arch.packages.<category>:
#     strategy: *_install_binary       # or *_install_from_source
#     list: [package-name]
#
# For Flatpak apps:
#   packages.flatpak.packages.<category>:
#     - com.example.App

# Apply (auto-installs/removes)
chezmoi apply
```

**Strategy selection**:
- `*_install_binary`: Faster, precompiled packages (recommended)
- `*_install_from_source`: AUR packages without binaries, customization needs

### Customizing Configuration

**Hyprland settings**:
```bash
# Edit configuration
chezmoi edit ~/.local/share/chezmoi/private_dot_config/hypr/conf/monitor.conf.tmpl

# Example: monitor=DP-1,2560x1440@144,0x0,1

# Apply and reload
chezmoi apply
hyprctl reload  # or Super+Shift+R
```

### Managing Updates

```bash
# Pull latest changes
cd ~/.local/share/chezmoi
git pull origin main

# Review changes
chezmoi diff && chezmoi apply --dry-run

# Apply if safe
chezmoi apply
```

### Working with Encrypted Files

```bash
# View encrypted content
chezmoi decrypt <file>

# Edit encrypted file (opens in $EDITOR)
chezmoi edit <file>

# Add new file with encryption
chezmoi add --encrypt ~/sensitive-file.txt
```

⚠️ **Security model**: Age encryption uses manual operations to prevent accidental exposure. Files ending in `.age`, files in `private_dot_keys/`, and SSH private keys are automatically encrypted.

---

## Troubleshooting

### Quick Fixes

**Template errors**:
```bash
chezmoi execute-template < file.tmpl  # Test syntax
chezmoi data | grep variable          # Check data available
chezmoi cat ~/.config/app/config      # Preview rendered output
```

**Package installation failures**:
- AUR timeout: Use `*_install_binary` strategy or increase timeout
- Fallback: Edit `packages.yaml` and change strategy

**Systemd timer issues** (wallpaper rotation stopped):
```bash
systemctl --user status wallpaper-cycle.timer   # Check status
journalctl --user -u wallpaper-cycle.service    # View logs
systemctl --user restart wallpaper-cycle.timer  # Restart if stuck
```

**Merge conflicts**:
```bash
chezmoi status        # Identify conflicts
chezmoi merge-all     # Resolve all (template protection active)
```

### Recovery

**Rollback recent changes**:
```bash
cd ~/.local/share/chezmoi
git log --oneline -10           # View recent commits
git checkout HEAD~1             # Rollback one commit
chezmoi apply
```

**Complete reset**:
```bash
cd ~/.local/share/chezmoi
git reset --hard origin/main
chezmoi apply
```

**Nuclear option** (re-initialize):
```bash
mv ~/.local/share/chezmoi ~/.local/share/chezmoi.backup
chezmoi init --apply https://gitlab.com/amoconst/dotfiles.git
```

[Complete troubleshooting → CLAUDE.md]

---

## Documentation

### User Documentation

- **README.md** (this file): Installation and daily usage guide

### Technical Documentation

- **[CLAUDE.md](CLAUDE.md)**: Core architecture, development standards, script patterns
- **[private_dot_config/CLAUDE.md](private_dot_config/CLAUDE.md)**: Desktop environment configuration
- **[private_dot_local/CLAUDE.md](private_dot_local/CLAUDE.md)**: CLI tools and script library
- **Location-specific**: CLAUDE.md files throughout repository for detailed implementation docs

### Quick References

- **Keybindings**: `Super+/` or `Super+Space` → Learn
- **Commands**: Run `commands` in terminal
- **Template system**: [CLAUDE.md → Template System Reference](CLAUDE.md#template-system-reference)
- **Package management**: [CLAUDE.md → Package Management](CLAUDE.md#package-management-for-development)

---

## Project Information

**Repository**: Personal dotfiles configuration
**License**: Personal configuration, use at your own discretion

**Contributing**: Feel free to:
- Fork for your own use and customization
- Open issues for bugs or suggestions
- Submit pull requests for improvements

⚠️ **Target OS**: Arch Linux only (archinstall + Hyprland profile). Other systems not supported.
