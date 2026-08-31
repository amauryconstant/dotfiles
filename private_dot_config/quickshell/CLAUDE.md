# Quickshell Desktop Shell

**Location**: `private_dot_config/quickshell/dotfiles/` → `~/.config/quickshell/dotfiles/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Syntax, tooling, traps**: `.claude/rules/quickshell-qml.md`
**Roadmap**: `_plans/QUICKSHELL_SHELL.md`

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Status**: Phases 2.5 and 3 complete — floating bar (40 tall, inset 8, reserving 56) plus
  volume/brightness OSDs. Phase 2 (Hyprland Lua cutover) still outstanding
- **Gate**: `features.quickshell_shell.enabled`. Flip it + `chezmoi apply` is the whole
  rollout; flipping back is the whole rollback
- 🚨 **The two bars are mutually exclusive, by config.** `.chezmoiignore` deploys exactly one
  of `hypr/conf.d/quickshell.{lua,conf}` and `hypr/conf.d/waybar.{lua,conf}`; each drop-in
  carries both its own autostart and `SUPER+B`. `conf/autostart.*` and
  `conf/bindings/desktop-utilities.*` start and bind **no** bar — that is deliberate, not an
  omission
- **Launch**: `quickshell -c dotfiles`, from `hypr/conf.d/quickshell.{lua,conf}`
- **Toggle**: `SUPER+B` (`desktop/quickshell-toggle`)
- **Lint**: `mise run lint:qml` · **Format**: `mise run format:qml`

## Layout

```
dotfiles/
├── shell.qml              # ShellRoot: IPC handlers + Variants over screens + the OSD
├── qmldir                 # declares the three singletons (required by qmllint)
├── Theme.qml              # colours from themes/current/colors.sh, at runtime
├── Config.qml.tmpl        # geometry scale, fonts, chassis, scriptsDir, shared glyph ramps
├── Backlight.qml          # sysfs backlight, shared by the bar widget and the OSD
├── osd/Osd.qml            # volume + brightness overlay, follows the focused monitor
└── bar/
    ├── Bar.qml            # PanelWindow, one per screen, three zones, grouped right side
    ├── BarWidget.qml      # the chip, the accent rule, tooltip, click/scroll plumbing
    ├── BarTooltip.qml     # PopupWindow hover tooltip
    ├── BarSeparator.qml   # 1x16 hairline, hides with the group it precedes
    ├── WaybarJsonSource.qml  # Process + SplitParser for Waybar-JSON scripts
    └── widgets/*.qml      # one per bar widget
```

`shell.qml` owns no widget. Widgets are added to a zone in `Bar.qml`, in
`waybar/config.tmpl`'s `modules-right` order, inside one of the six separator-delimited
groups (tray · network+bluetooth · backlight+battery · audio+media · kanata+idle+voxtype ·
notification).

A widget sets `icon`, `label` and — only for a real state — `iconColor` on `BarWidget`. It
does **not** declare its own `Text`, write a radius, or pick a rest colour: geometry and the
accent rule both live one level up. See `.claude/rules/quickshell-qml.md`.

## Widget → source

| Widget | Backed by |
|---|---|
| Launcher | none — a chip that runs `wofi --show drun`, new in Phase 2.5 |
| Workspaces, WindowTitle | `Quickshell.Hyprland` |
| Audio, Media, Tray | `Pipewire`, `Mpris`, `SystemTray` |
| Network, Bluetooth, Battery | `Networking`, `Bluetooth`, `UPower` — laptop only |
| Backlight | the `Backlight` singleton (sysfs via `FileView`), writes through `desktop/brightness-set` — laptop only |
| Kanata, Voxtype, Idle, Notification | existing scripts, via `WaybarJsonSource` |

## OSD (Phase 3)

`osd/Osd.qml`, one window, instantiated once in `shell.qml`. **Nothing triggers it** — no
keybinding, no IPC, no script change: it watches `Pipewire.defaultAudioSink` and the
`Backlight` singleton, so it fires whatever changed the value (media key, bar scroll, another
app). Three things in it are load-bearing:

- `mask: Region {}` — an empty input region. Without it the window eats every click in its
  320×56 patch while up, and it has nothing interactive to justify that
- an `armed` flag on a 1s timer — Pipewire's first binding and the first sysfs read both land
  after launch and would flash the OSD on every login
- `screen:` matched by **name** against `Hyprland.focusedMonitor` — `HyprlandMonitor` has no
  `screen` property; both sides expose `name`

Sits at `Config.osdMargin` (160) from the bottom, clearing voxtype's own OSD (a 72-tall card
at bottomMargin 72) so a dictation card and a volume key cannot overlap. On a desktop with a
DDC monitor there is no sysfs backlight, so the brightness half simply never fires.

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
- **A glyph literal can be authored as `""`** and render nothing, with no error — it has
  happened twice here. Take codepoints from the `nerdfonts-search` skill and write them via
  an explicit `chr(0x…)`, never a paste

All three fail silently and look plausible on screen.
