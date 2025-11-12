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
| `shell/` | Shell + Zsh config | ✅ Yes |
| `systemd/user/` | User services | ✅ Yes |
| `Nextcloud/` | Nextcloud client | ✅ Yes |
| `git/` | Git config | ✅ Yes |
| `themes/` | Theme files | ✅ Yes |
| `dunst/` | Notifications | ❌ No |
| `ghostty/` | Terminal config | ❌ No |
| `starship.toml` | Prompt config | ❌ No |
| `topgrade.toml.tmpl` | Update tool | ❌ No |

## Desktop Environment

### Hyprland Compositor (`hypr/`)
- Modular config (9 files in `conf/`)
- Templates: Only `bindings.conf.tmpl`, `monitor.conf.tmpl`
- Wallust integration (dynamic colors)

### Desktop Components (Consolidated)

**Waybar status bar**:
- 15 modules (workspaces, clock, CPU, memory, network, etc.)
- Oksolar theme + wallust colors
- Files: `config.tmpl` (JSON5), `style.css.tmpl` (CSS)
- Reload: `killall -SIGUSR2 waybar`

**Wofi launcher**:
- Wayland application launcher
- Integration: Hyprland (`Super+D`), menu system
- Files: `config` (static), `style.css.tmpl` (themed)
- Theme: Oksolar + wallust

**Wallust color generation**:
- Automatic wallpaper color extraction and theming
- Components: wallust (extraction) + swww (transitions) + systemd timer
- Config: `wallust.toml.tmpl`
- Algorithm: `full` backend, `labmixed` color space, `softdark16` palette
- Templates: 9 color templates → desktop components
- Template: `style.css.tmpl`

**Wallust colors** (`wallust/`):
- Automatic color extraction from wallpapers
- 9 output templates (Hyprland, Waybar, Wofi, etc.)
- Systemd timer (30 min rotation)

## Shell Configuration

**Zsh** (`zsh/`):
- Zephyr plugin framework (zstyle config)
- Antidote plugin manager
- Fish-like features (autosuggestions, syntax highlighting)

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

**Ghostty terminal** (`ghostty/`):
- Terminal config
- Wallust theme integration

**Starship prompt** (`starship.toml`):
- Cross-shell prompt
- Minimal, fast, informative

**Topgrade** (`topgrade.toml.tmpl`):
- System update automation
- Custom commands (system-health, maintenance)

## Systemd User Services

**User services** (`systemd/user/`):
- Wallpaper cycle timer (30 min)
- Other user services

## Themes

**Theme files** (`themes/`):
- Wallpapers (`themes/wallpapers/`)
- Icon themes
- Cursor themes

## Subdirectories with CLAUDE.md

**Detailed documentation**:
1. `hypr/` - Hyprland compositor config
2. `waybar/` - Status bar config
3. `wofi/` - Launcher config
4. `wallust/` - Color extraction
5. `systemd/user/` - User services
6. `zsh/` - Zsh config (Zephyr)
7. `shell/` - Common shell config
8. `Nextcloud/` - Nextcloud client (modify_manager)
9. `git/` - Git config
10. `themes/` - Theme organization

**See individual CLAUDE.md files for detailed references**

## Template Usage

**Common patterns**:
```go
# Color access
{{ .colors.oksolar.base0 }}

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
