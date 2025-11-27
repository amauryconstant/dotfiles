# Hyprland Configuration - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/hypr/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Hyprland compositor configuration
- **Main entry**: `hyprland.conf` (sources all modular configs)
- **Modular structure**: 9 conf/ files
- **Templates**: Only `bindings.conf.tmpl`, `monitor.conf.tmpl`
- **Reload**: `Super+Shift+R` or `hyprctl reload`

## Modular Structure

**9 configuration files** (`conf/`):

| File | Purpose | Template? |
|------|---------|-----------|
| `monitor.conf.tmpl` | Display settings (resolution, scaling, position) | ✅ Yes |
| `environment.conf` | Env vars (NVIDIA, Qt/GTK, XDG) | ❌ No |
| `input.conf` | Keyboard, mouse, touchpad | ❌ No |
| `general.conf` | Layout, gaps, borders, colors | ❌ No |
| `decoration.conf` | Visual effects (blur, shadows, rounding) | ❌ No |
| `animations.conf` | Animation curves, timing | ❌ No |
| `bindings.conf.tmpl` | Keybindings (terminal: ghostty) | ✅ Yes |
| `windowrules.conf` | Per-app window behavior | ❌ No |
| `autostart.conf` | Startup apps (waybar, dunst, nextcloud) | ❌ No |

**Main entry** (`hyprland.conf`):
```
source = ~/.config/hypr/conf/monitor.conf
source = ~/.config/hypr/conf/environment.conf
# ... all 9 files ...
```

## Template Decisions

**Only 2 templates**:
1. **`monitor.conf.tmpl`**: Display-specific settings (laptop vs desktop)
2. **`bindings.conf.tmpl`**: Terminal preference (ghostty vs kitty)

**Why most are static**:
- Hyprland config syntax rarely needs dynamic values
- Reduces template processing overhead
- Easier to read and maintain
- Manual editing preferred for compositor settings

## Current Applications

**File Manager**: Thunar (GTK-based, lightweight)
**Polkit Agent**: hyprpolkitagent (native Hyprland integration)
**Terminal**: Ghostty (configured via bindings.conf.tmpl)

**Template examples**:
```go
# bindings.conf.tmpl
bind = $mod, Return, exec, {{ .globals.applications.terminal }}

# monitor.conf.tmpl
{{ if eq .chassisType "laptop" }}
monitor=eDP-1,1920x1080@60,0x0,1
{{ else }}
monitor=DP-1,2560x1440@144,0x0,1
{{ end }}
```

## Wallust Integration

**Dynamic color generation**:
- Hyprland sources `~/.config/hypr/wallust/wallust-hyprland.conf` (generated)
- Wallust extracts colors from wallpaper
- Updates borders, active window colors

**Configuration** (`hyprland.conf`):
```
source = ~/.config/hypr/wallust/wallust-hyprland.conf
```

**Template** (`wallust/templates/colors-hyprland.conf`):
```
col.active_border = {{color6}} {{color4}} 45deg
col.inactive_border = {{color0}}
```

**NOT managed by chezmoi**: Generated files in `wallust/` subdirectory (ephemeral state)

## Theme System Integration (Phase 2+3)

**Static theme files**: Unlike GTK apps (Waybar, Wofi, Wlogout), Hyprland uses static theme files per theme variant.

**Border colors** (`~/.config/themes/{theme}/hyprland.conf`):
```conf
# Example: Rose Pine Moon
$activeBorder = rgba(c4a7e7ee)    # iris (accent-border semantic)
$inactiveBorder = rgba(6e6a86aa)  # muted (fg-muted semantic)
```

**Semantic mapping** (Phase 2):
- Active borders use `accent-border` semantic (violet/iris/yellow per theme)
- Inactive borders use `fg-muted` semantic
- **Note**: Hyprland syntax doesn't support CSS `@variable` imports - uses shell-style `$variables` with hardcoded hex values

**Color format**: `rgba(hexee)` where `hex` = 6-digit color, `ee` = alpha channel (no # prefix)

**Border migration** (Phase 2): Borders migrated from `accent-primary` to dedicated `accent-border` for semantic clarity

## Testing & Reload

**Preview config**:
```bash
chezmoi cat ~/.config/hypr/hyprland.conf
chezmoi cat ~/.config/hypr/conf/bindings.conf
```

**Validate template**:
```bash
chezmoi execute-template < private_dot_config/hypr/conf/bindings.conf.tmpl
```

**Reload Hyprland**:
- `Super+Shift+R` (keybinding)
- `hyprctl reload` (CLI)

**Test specific config**:
```bash
hyprctl keyword general:gaps_in 5
hyprctl keyword general:border_size 2
```

## Configuration Sections

### Monitor Settings (`monitor.conf.tmpl`)

**Syntax**: `monitor=NAME,RES@RATE,POS,SCALE`

**Example**:
```
monitor=DP-1,2560x1440@144,0x0,1
monitor=eDP-1,1920x1080@60,0x0,1
```

### Environment Variables (`environment.conf`)

**NVIDIA**:
```
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
```

**XDG**:
```
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
```

### Input Settings (`input.conf`)

- Keyboard layout, repeat rate
- Mouse acceleration, sensitivity
- Touchpad gestures, natural scroll

### General Layout (`general.conf`)

- Gaps (inner/outer)
- Border size, colors
- Layout (dwindle/master)

### Decorations (`decoration.conf`)

- Rounding radius
- Blur (enabled/disabled, passes, size)
- Shadows (enabled/disabled, range, offset)

### Animations (`animations.conf`)

- Curve types (bezier)
- Animation timing
- Enable/disable per animation

### Keybindings (`bindings.conf.tmpl`)

**Modifier**: `$mod = SUPER`

**Categories**:
- Window management (move, resize, focus)
- Workspace switching
- Application launching
- Screenshot, recording
- Media controls
- System menu

### Window Rules (`windowrules.conf`)

**Syntax**: `windowrulev2 = RULE, MATCH`

**Examples**:
```
windowrulev2 = float, class:(Rofi)
windowrulev2 = opacity 0.9, class:(kitty)
windowrulev2 = workspace 2, class:(firefox)
```

### Autostart (`autostart.conf`)

**Executed on Hyprland start**:
```
exec-once = waybar
exec-once = dunst
exec-once = nextcloud --background
exec-once = swww init
```

## Integration Points

- **Waybar**: Status bar styling from wallust
- **Wofi**: Launcher styling from wallust
- **Terminal**: Ghostty theme from wallust
- **Desktop scripts**: `~/.local/lib/scripts/desktop/` (16 utilities)
- **Wallust**: `~/.config/wallust/` (color generation)
- **Menu system**: `~/.local/lib/scripts/user-interface/` (Super+Space)
