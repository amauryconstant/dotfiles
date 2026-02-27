# SwayNotificationCenter - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/swaync/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Notification daemon with persistent control center panel
- **Replaces**: dunst (retained in `../dunst/` as historical reference)
- **Toggle**: `Super+Shift+N` → `swaync-client --toggle-panel`
- **Reload CSS**: `swaync-client --reload-css` (hot-reload stylesheet without restart)
- **Reload Config**: `swaync-client --reload-config` (reload JSON config only)
- **DND toggle**: `swaync-client --toggle-dnd`

## File Structure

| File | Purpose |
|------|---------|
| `config.json` | Static daemon config (position, timeouts, widgets) |
| `style.css` | `@import url("theme.css");` |
| `symlink_theme.css` | Chezmoi symlink → `../themes/current/swaync.css` |

**Symlink resolution**: `~/.config/swaync/theme.css` → `~/.config/themes/current/swaync.css`

## Config Overview

- **Position**: top-right
- **Timeouts**: 10s normal, 5s low, 0 critical (persistent)
- **Widgets**: title (clear-all), dnd, mpris, notifications
- **Panel size**: 500×600px

## Theme Integration

**Implementation**: Direct translation of official catppuccin/swaync theme
- Uses `border: 1px solid` instead of `box-shadow: inset` for borders
- Follows official padding/margin values (rem-based accessibility)
- See: https://github.com/catppuccin/swaync

**Semantic variables used** per theme (from `waybar.css`):

### Background Hierarchy (5 variables)

| Variable | Role | CSS Target |
|----------|------|-----------|
| `bg-primary` | Main background | `.control-center` background |
| `bg-secondary` | Elevated surfaces | `.notification-action`, `.widget-mpris-player` |
| `bg-tertiary` | Popovers | Action hover, DND checked |
| `bg-elevated` | Highest elevation | Special elevated elements |
| `bg-overlay` | Modal overlays | `.notification-background` |

### Foreground Hierarchy (4 variables)

| Variable | Role | CSS Target |
|----------|------|-----------|
| `fg-primary` | Primary text | All body text, `.summary` |
| `fg-secondary` | Secondary text | `.time`, `.body` |
| `fg-muted` | Disabled/inactive | Unfocused elements |
| `fg-contrast` | High contrast | Text on colored backgrounds (close button, active actions) |

### Accent Colors (8+ core, extended)

| Variable | Role | CSS Target |
|----------|------|-----------|
| `accent-primary` | Active states | DND checked, slider background, active actions |
| `accent-error` | Critical/urgent | Critical border, close button, Clear All |
| `accent-modification` | File changes | Close button hover |
| `accent-info` | Information | Volume slider highlight |
| `accent-warning` | Warnings | Backlight slider highlight |
| `accent-media` | Media controls | MPRIS player |

**Per-theme files**: `../themes/{variant}/swaync.css` (8 files, semantic CSS variables)

**Theme switching**: `theme-switcher.tmpl` calls `swaync-client --reload-css` after updating the symlink.

## Management

```bash
# Toggle control center
swaync-client --toggle-panel

# Toggle DND
swaync-client --toggle-dnd

# Hot-reload CSS (after theme switch)
swaync-client --reload-css

# Reload JSON config (position, timeouts)
swaync-client --reload-config

# View logs
journalctl --user -u swaync

# Restart daemon
pkill swaync; swaync &
```

## Integration Points

- **Hyprland autostart**: `autostart.conf` (exec-once = swaync)
- **Keybinding**: `bindings/system-control.conf` (Super+Shift+N)
- **Theme switcher**: `executable_theme-switcher.tmpl` (reload on theme change)
- **Session denylist**: `dotfiles/session-denylist.conf` (not saved/restored)
- **Theme CSS**: `themes/*/swaync.css` (8 per-theme files)
