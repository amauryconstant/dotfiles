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

**6 semantic variables used** per theme (from `waybar.css` hex values):

| Variable | Role | CSS Target |
|----------|------|-----------|
| `bg-primary` | Notification background | `.notification-row` background |
| `fg-primary` | Text | All text |
| `bg-secondary` | Hover / button background | `.notification-row:hover`, `button` |
| `bg-overlay` | Control center panel | `.control-center` background |
| `accent-primary` | Border | `.notification-row` border |
| `accent-error` | Critical border | `.notification-row.critical` border |
| `fg-contrast` | Button hover text | `button:hover` text |

**Per-theme files**: `../themes/{variant}/swaync.css` (8 files, hardcoded hex)

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
