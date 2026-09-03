# SwayNotificationCenter - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/swaync/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- 🚨 **MASKED as of Phase 4 (2026-09-01)** when `features.quickshell_notifications.enabled` is
  true: Quickshell's `NotificationServer` owns `org.freedesktop.Notifications` instead.
  `org.freedesktop.Notifications` has exactly ONE owner and swaync is both a systemd user unit
  and D-Bus activatable, so stopping it is not enough — anything calling `notify-send` would
  activate it straight back. `systemctl --user mask --now swaync` is what actually prevents
  that, applied by `.chezmoiscripts/run_onchange_after_configure_notifications.sh.tmpl`.
- **Revert**: set `features.quickshell_notifications.enabled: false` and `chezmoi apply` — the
  same script unmasks swaync, starts it, and the `SUPER+SHIFT+N` binding in
  `hypr/conf/bindings/system-control.{lua,conf}.tmpl` swings back to `swaync-client`. Do not
  unmask by hand; the flag and the binding would then disagree.
- **Kept, not removed**: this config, the 8 per-theme `swaync.css.tmpl` files and the package
  all stay. Retirement is Phase 6 of `_plans/QUICKSHELL_SHELL.md`, gated on the replacement
  having lived a month — masked is the reversible state, deleted is not.
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
| `bg-elevated` | Highest elevation | Special elevated elements — ⚠️ **CSS-only** |
| `bg-overlay` | Modal overlays | `.notification-background` |

⚠️ `bg-elevated` is declared only in each theme's `waybar.css`, **not** in `colors.sh`, so it is
invisible to shell scripts and to Quickshell's `Theme.qml`. Same category as the `*-hover`
variants — see `themes/CLAUDE.md`. The colorset is exactly 24 variables and this is not one.

### Foreground Hierarchy

| Variable | Role | CSS Target |
|----------|------|-----------|
| `fg-primary` | Primary text | All body text, `.summary` |
| `fg-secondary` | Secondary text | `.time`, `.body` — ⚠️ **on `.notification-background`, which is `bg-overlay`: this is the banned elevated pairing** (`themes/CLAUDE.md`). Quickshell's `NotificationCard.qml` does not repeat it — everything on a card is `fg-primary`, hierarchy by size/weight/mono (Amendment C) |
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

🚨 **swaync is masked whenever Quickshell owns notifications.** `features.quickshell_notifications`
decides which daemon holds `org.freedesktop.Notifications` — the bus name has exactly one owner, so
there is no coexistence. `.chezmoiscripts/run_onchange_after_configure_notifications.sh.tmpl` masks
or unmasks `swaync.service` on that flag. It is currently **masked**; everything below applies only
after flipping the flag back.

- **Start**: systemd user unit (`/usr/lib/systemd/user/swaync.service`) + D-Bus activation.
  **Not** a Hyprland `exec-once` — `hypr/conf/autostart.lua:58` explicitly warns against adding one,
  because it conflicts with `SystemdService=`.
- **Keybinding**: `Super+Shift+N` — restored to swaync only when the flag is off; Quickshell's
  notification centre holds it otherwise.
- **Theme switcher**: `executable_theme-switcher.tmpl` (reload on theme change)
- **Session denylist**: `dotfiles/session-denylist.conf` (not saved/restored)
- **Theme CSS**: `themes/*/swaync.css.tmpl`
