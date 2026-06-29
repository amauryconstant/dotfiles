# SwayNotificationCenter - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/swaync/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Notification daemon with persistent control center panel (the repo's only notification daemon — no dunst)
- **Toggle**: `Super+Shift+N` → `swaync-client --toggle-panel`
- **Reload CSS**: `swaync-client --reload-css` (hot-reload stylesheet without restart)
- **Reload Config**: `swaync-client --reload-config` (reload JSON config only)
- **DND toggle**: `swaync-client --toggle-dnd`

## File Structure

| File | Purpose |
|------|---------|
| `config.json` | Static daemon config (position, timeouts, widgets) |
| `style.css` | `@import url("theme.css");` |
| `symlink_theme.css` | Chezmoi symlink → `~/.config/themes/current/swaync.css` |

**Theme source is templated**: per-theme file is `../themes/{variant}/swaync.css.tmpl` — the **only templated theme file**. It renders to `swaync.css` in the deployed theme dir, and the symlink above resolves to that. It must be a template because it injects the configured fonts (`{{ .globals.terminalFont }}` / `guiFont`); the other theme files are static CSS/conf. Edit the `.tmpl`, not the rendered output.

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

### Background Hierarchy

| Variable | Role | CSS Target |
|----------|------|-----------|
| `bg-primary` | Main background | `.control-center` background |
| `bg-secondary` | Elevated surfaces | `.notification-action`, `.widget-mpris-player` |
| `bg-tertiary` | Popovers | Action hover, DND checked |
| `bg-elevated` | Highest elevation | Special elevated elements |
| `bg-overlay` | Modal overlays | `.notification-background` |

### Foreground Hierarchy

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

**Theme switching**: `theme-switcher.tmpl` calls `swaync-client --reload-css` after updating the symlink (hot-reload, no restart).

## Integration Points

- **Hyprland autostart**: `autostart.conf` (exec-once = swaync)
- **Keybinding**: `bindings/system-control.conf` (Super+Shift+N)
- **Theme switcher**: `executable_theme-switcher.tmpl` (reload on theme change)
- **Session denylist**: `dotfiles/session-denylist.conf` (not saved/restored)
- **Theme CSS**: `themes/*/swaync.css.tmpl`
