# XDG Configuration - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/`
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: XDG Base Directory config (`~/.config/`)
- **Target**: Desktop environment, applications, shell configs
- **Structure**: Category-based subdirectories
- **Templates**: Many `.tmpl` files use Go templates

## XDG Structure

**Config categories**:

| Directory | Purpose | Has CLAUDE.md? |
|-----------|---------|----------------|
| `hypr/` | Hyprland compositor | ✅ Yes |
| `shell/` | POSIX shell layer + Zephyr patterns | ✅ Yes |
| `zsh/` | Zsh-specific config (antidote, plugins, functions) | ✅ Yes |
| `systemd/user/` | User services | ✅ Yes |
| `Nextcloud/` | Nextcloud client | ✅ Yes |
| `git/` | Git config | ✅ Yes |
| `themes/` | Theme system | ✅ Yes |
| `bat/` | Syntax highlighting (themed) | ❌ No |
| `broot/` | File tree (themed) | ❌ No |
| `btop/` | System monitor (themed) | ❌ No |
| `lazygit/` | Git TUI (themed) | ❌ No |
| `yazi/` | File manager (themed) | ❌ No |
| `dunst/` | Notifications | ❌ No |
| `ghostty/` | Terminal config | ❌ No |
| `starship.toml` | Prompt (themed via symlink) | ❌ No |
| `topgrade.toml.tmpl` | Update tool | ❌ No |

## Desktop Environment

### Hyprland Compositor (`hypr/`)
- Modular config (9 files in `conf/`)
- Templates: Only `bindings.conf.tmpl`, `monitor.conf.tmpl`
- Theme integration via `source ~/.config/themes/current/hyprland.conf`

### Desktop Components (Consolidated)

**Theme system** (`themes/`):
- 8 variants: Catppuccin (latte/mocha), Rose Pine (dawn/moon), Gruvbox (light/dark), Solarized (light/dark)
- 24 semantic variables (backgrounds, foregrounds, accents)
- Desktop apps: Waybar, Dunst, Wofi, Wlogout, Hyprland, Ghostty, Hyprlock
- CLI tools: bat, broot, btop, lazygit, starship, yazi
- Switching: `theme switch <name>`, darkman (solar auto), keybindings
- See: `themes/CLAUDE.md`

**Waybar status bar**:
- 15 modules (workspaces, clock, CPU, memory, network, etc.)
- Theme integration via `@import "themes/current/waybar.css"`
- Files: `config.tmpl` (JSON5), `style.css.tmpl` (CSS)
- Reload: `killall -SIGUSR2 waybar`

**Wofi launcher**:
- Wayland application launcher
- Integration: Hyprland (`Super+D`), menu system
- Files: `config` (static), `style.css.tmpl` (themed)
- Theme: CSS import from `themes/current/wofi.css`

## Shell Configuration

**Zsh** (`zsh/`):
- Antidote plugin manager + Zephyr framework
- Fish-like features (autosuggestions, syntax highlighting)
- See: `zsh/CLAUDE.md`

**Common shell** (`shell/`):
- POSIX-compliant layered config
- Files: env, env_functions, login.tmpl, interactive, logout
- Shared between Zsh and Bash

## Application Configs

**Nextcloud** (`Nextcloud/`):
- chezmoi_modify_manager (separates settings from state)
- Template: `modify_nextcloud.cfg.tmpl`

**Git** (`git/`):
- Config template: `config.tmpl`
- Attributes: `.gitattributes` (template merge driver)
- Hooks: Pre-commit, etc.

**Jujutsu** (`jj/`):
- Version control system config
- Files: `config.toml.tmpl`
- Delta integration via git config inheritance
- See: `jj/CLAUDE.md`

**CLI tools** (themed):
- **bat**: Syntax highlighting via `~/.config/bat/config` symlink
- **broot**: File tree skin via `~/.config/broot/skin.hjson` symlink
- **btop**: System monitor via `~/.config/btop/color_theme` symlink
- **lazygit**: Git TUI via `~/.config/lazygit/config.yml` symlink
- **starship**: Shell prompt via `~/.config/starship.toml` symlink
- **yazi**: File manager via `~/.config/yazi/theme.toml` symlink

**Ghostty terminal** (`ghostty/`):
- Terminal config
- Theme integration via `source ~/.config/themes/current/ghostty.conf`

**Topgrade** (`topgrade.toml.tmpl`):
- Unified update workflow (firmware, git, cleanup)
- Calls `package-manager update` as pre-command (packages handled by package-manager)
- Disabled: system (Arch/AUR), flatpak (handled by package-manager)
- Custom commands: system-health, unmanaged package check, orphan removal

## Systemd User Services

**User services** (`systemd/user/`):
- Wallpaper cycle timer (30 min)
- Other user services

## Themes

**Theme system** (`themes/`):
- 8 variants: Catppuccin (latte/mocha), Rose Pine (dawn/moon), Gruvbox (light/dark), Solarized (light/dark)
- 13 themed apps: 7 desktop + 6 CLI tools
- Wallpapers: Theme-integrated collections (`themes/{variant}/wallpapers/`)
- See: `themes/CLAUDE.md` for architecture and integration details

## Subdirectories with CLAUDE.md

**Detailed documentation**:
1. `hypr/` - Hyprland compositor config
2. `systemd/user/` - User services
3. `shell/` - POSIX shell layer (env, interactive, login)
4. `zsh/` - Zsh config (antidote plugins, zfunctions, zshrc.d)
5. `Nextcloud/` - Nextcloud client (modify_manager)
6. `git/` - Git config
7. `themes/` - Theme system (semantic variables, CLI integration)

**See individual CLAUDE.md files for detailed references**

## Template Usage

**Common patterns**:
```go
# Application defaults
{{ .globals.applications.terminal }}

# User-specific
{{ .firstname | lower }}

# Conditional
{{ if eq .chassisType "laptop" }}
```

**Validation**:
```bash
chezmoi execute-template < file.tmpl
chezmoi cat path/to/file
```

## Integration Points

- **Chezmoi data**: `.chezmoidata/` (colors, globals, packages)
- **Scripts**: `~/.local/lib/scripts/` (desktop utilities)
- **CLI**: `~/.local/bin/` (command wrappers)
- **Zephyr**: Zstyle-based Zsh config
