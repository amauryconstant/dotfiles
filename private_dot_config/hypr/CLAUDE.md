# Hyprland Configuration - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/hypr/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Hyprland compositor configuration
- **Main entry**: `hyprland.conf` (sources modular configs + theme + user extras)
- **Active format**: **`.conf`** files. Parallel `.lua` files exist (staged migration) but are **not** loaded — `hyprland.conf` sources `.conf`, and sourcing `.conf` blocks the `.lua` path. See `.claude/rules/hyprland-lua.md`.
- **Reload**: `Super+Shift+R` or `hyprctl reload`

## Modular Structure

`hyprland.conf` also pulls `conf.d/*.conf` (drop-ins), `monitors.conf` (HyprDynamicMonitors output), and `~/.config/themes/current/hyprland.conf` (theme borders).

**Base config files** (`conf/`, each `.conf` shadowed by an inactive `.lua`):

| File | Purpose | Template? |
|------|---------|-----------|
| `monitor.conf.tmpl` | Display settings (resolution, scaling, position) | ✅ Yes |
| `plugins.conf` | hyprsplit / plugin config | ❌ No |
| `environment.conf` | Env vars (NVIDIA, Qt/GTK, XDG) | ❌ No |
| `input.conf` | Keyboard, mouse, touchpad | ❌ No |
| `general.conf` | Layout, gaps, borders, colors | ❌ No |
| `decoration.conf` | Visual effects (blur, shadows, rounding) | ❌ No |
| `animations.conf` | Animation curves, timing | ❌ No |
| `windowrules.conf` | Per-app window behavior | ❌ No |
| `autostart.conf` | Startup apps (waybar, swaync, nextcloud) | ❌ No |

`helpers.lua`, `require_all.lua` are Lua-layer infrastructure (inactive).

**Keybinding files** (`conf/bindings/`, sourced by `hyprland.conf`):

| File | Purpose | Template? |
|------|---------|-----------|
| `applications.conf.tmpl` | App launchers (terminal, browser, editor) | ✅ Yes |
| `window-management.conf` | Window operations (close, float, fullscreen) | ❌ No |
| `focus-navigation.conf` | Focus + move (arrows, vim keys) | ❌ No |
| `workspace-management.conf` | Switch + move windows across workspaces | ❌ No |
| `window-resizing.conf` | Resize + mouse bindings | ❌ No |
| `media-keys.conf` | Volume, brightness, playback | ❌ No |
| `screenshots.conf` | Screenshot tools (Satty) | ❌ No |
| `voice.conf` | Voice dictation (Voxtype) | ❌ No |
| `desktop-utilities.conf` | Utilities (audio, gaps, waybar, nightlight) | ❌ No |
| `theme-session.conf` | Theme switching, dark mode | ❌ No |
| `system-control.conf` | Lock, power, help, menu | ❌ No |

Bindings use `bindd` (self-documenting descriptions). Modifier convention: SUPER (primary), SUPER+SHIFT (move/variant), SUPER+CTRL (system).

**User extras** (`~/.config/dotfiles/extra-bindings.conf`):

**User extra bindings**: `~/.config/dotfiles/extra-bindings.conf`
- Sourced last — personal bindings without modifying core config
- Chezmoi-managed (always present, prevents Hyprland parse error)
- Edit via: `dotfiles-bindings-edit` (auto-reloads on exit)
- See: `dotfiles/CLAUDE.md` for full documentation

## Template Decisions

Templated files: `hyprland.conf.tmpl`, `hyprlock.conf.tmpl`, `hypridle.conf.tmpl`, `conf/monitor.conf.tmpl` (laptop vs desktop displays), `conf/bindings/applications.conf.tmpl` (`{{ .globals.applications.terminal }}` etc.). Their `.lua.tmpl` twins exist but are inactive. Everything else is static — Hyprland syntax rarely needs dynamic values, so prefer editing the static `.conf` directly.

## Theme System Integration

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

## Reload

`Super+Shift+R` or `hyprctl reload`. `post_install` script `run_once_after_007_validate_hyprland_config` validates config after apply. Live-test a value without reloading via `hyprctl keyword general:gaps_in 5`.

## Integration Points

- **Theme borders**: `~/.config/themes/current/hyprland.conf` (sourced)
- **Desktop scripts**: `~/.local/lib/scripts/desktop/`
- **Menu system**: `~/.local/lib/scripts/user-interface/` (Super+Space)
- **Monitor automation**: `monitors.conf` from `hyprdynamicmonitors/` (see its CLAUDE.md)
