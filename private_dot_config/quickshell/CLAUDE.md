# Quickshell Desktop Shell

**Location**: `private_dot_config/quickshell/dotfiles/` → `~/.config/quickshell/dotfiles/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Syntax, tooling, traps**: `.claude/rules/quickshell-qml.md`
**Roadmap**: `_plans/QUICKSHELL_SHELL.md`

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Status**: Phase 1 complete — bar at Waybar module parity. **Waybar still runs.**
- **Gate**: `features.quickshell_shell.enabled` (default `false`). Flip it + `chezmoi apply`
  is the whole rollout; flipping back is the whole rollback
- **Launch**: `quickshell -c dotfiles`, from `hypr/conf.d/quickshell.{lua,conf}`
- **Toggle**: `SUPER+SHIFT+B`. `SUPER+B` still toggles Waybar
- **Lint**: `mise run lint:qml` · **Format**: `mise run format:qml`

## Layout

```
dotfiles/
├── shell.qml              # ShellRoot: IPC handlers + Variants over screens
├── qmldir                 # declares Theme + Config as singletons (required by qmllint)
├── Theme.qml              # colours from themes/current/colors.sh, at runtime
├── Config.qml.tmpl        # sizes, fonts, chassis, scriptsDir
└── bar/
    ├── Bar.qml            # PanelWindow, one per screen, three zones
    ├── BarWidget.qml      # padding, hover, tooltip, click/scroll plumbing
    ├── BarTooltip.qml     # PopupWindow hover tooltip
    ├── WaybarJsonSource.qml  # Process + SplitParser for Waybar-JSON scripts
    └── widgets/*.qml      # one per bar widget
```

`shell.qml` owns no widget. Widgets are added to a zone in `Bar.qml`, in
`waybar/config.tmpl`'s `modules-right` order.

## Widget → source

| Widget | Backed by |
|---|---|
| Workspaces, WindowTitle | `Quickshell.Hyprland` |
| Audio, Media, Tray | `Pipewire`, `Mpris`, `SystemTray` |
| Network, Bluetooth, Battery | `Networking`, `Bluetooth`, `UPower` — laptop only |
| Backlight | sysfs via `FileView`, writes through `desktop/brightness-set` — laptop only |
| Kanata, Voxtype, Idle, Notification | existing scripts, via `WaybarJsonSource` |

**Four scripts are reused, not ported**: `kanata-layer`, `voxtype-waybar-status`,
`idle-indicator`, and `swaync-client -swb` all already emit Waybar's custom-module JSON. Their
names still say "waybar" — renaming waits for Phase 6, when Waybar actually goes.

## Deviations from Waybar, and why

Not oversights — each replaces something that was broken or useless:

| Module | Change |
|---|---|
| Clock | `format-alt` dropped. It turned the bar text into a calendar block; the calendar is in the tooltip instead, where Waybar's own default also puts it |
| Battery | No power profile. `power-profiles-daemon` is neither installed nor in `packages.yaml`, so Waybar's `on-click: powerprofilesctl` launched a binary that does not exist. Click runs `battery-status` instead |
| Backlight | **New, not ported.** Waybar's was gated on `exec-if: which light`, and `light` is not installed, so it never rendered |
| Network | No bandwidth counters — the native module does not expose them. Event-driven rather than Waybar's 5s poll |
| Media | `playerctld` is filtered out alongside the browsers: Quickshell lists every player, so the proxy would double-count the player it proxies |

## Gotchas

Full list in `.claude/rules/quickshell-qml.md`. The two that cost the most time:

- **`UPowerDevice.percentage` is 0..1**, not 0..100. Waybar/`upower` say 72%, the property says 0.72
- **Pipewire volume needs a `PwObjectTracker`** or it binds to nothing and shows 0% with no error

Both fail silently and look plausible on screen.
