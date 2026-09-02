# Quickshell Desktop Shell

**Location**: `private_dot_config/quickshell/dotfiles/` → `~/.config/quickshell/dotfiles/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Syntax, tooling, traps**: `.claude/rules/quickshell-qml.md`
**Roadmap**: `_plans/QUICKSHELL_SHELL.md`

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Status**: Phases 2, 2.5, 3, 4, 5 and 5.5 complete — floating bar (40 tall, inset 8,
  reserving 48), volume/brightness OSDs, launcher, power menu, notification server + centre,
  and Hyprland on the Lua entry point. Only the optional Phase 6 remains
- 🚨 **BOTH Phase 5.5 surfaces ship OFF**: `Config.dockEnabled` and `Config.overviewEnabled`
  are both `false`. Built, tried in daily use 2026-09-02, and declined — the bar's launcher
  chip and `SUPER+D` already covered launching, and the carousel was not wanted. The dock is
  hidden via `visible:`; the overview sits behind a `Loader` in `shell.qml`, so with the flag
  off there is no window, no screencopy and no carousel bindings at all. Re-enabling the
  overview needs the `SUPER+grave` binding restored to `hypr/conf.d/quickshell.{lua,conf}`
  too — those are plain files, so a single line in them cannot be template-gated. The
  `overview` IPC target stays registered either way and answers `"disabled"`, so a broken
  wiring still looks different from a switched-off feature
- **Gate**: `features.quickshell_shell.enabled`. Flip it + `chezmoi apply` is the whole
  rollout; flipping back is the whole rollback
- **Second gate**: `features.quickshell_notifications.enabled`, for notifications ONLY.
  Separate because it does something the bar flag does not — it takes
  `org.freedesktop.Notifications` from swaync by MASKING the unit
  (`run_onchange_after_configure_notifications`). A bus name has one owner, so this is the one
  phase with no coexistence. Flipping it back unmasks swaync, starts it, and points
  `SUPER+SHIFT+N` back at `swaync-client`
- 🚨 **The two bars are mutually exclusive, by config.** `.chezmoiignore` deploys exactly one
  of `hypr/conf.d/quickshell.{lua,conf}` and `hypr/conf.d/waybar.{lua,conf}`; each drop-in
  carries both its own autostart and `SUPER+B`. `conf/autostart.*` and
  `conf/bindings/desktop-utilities.*` start and bind **no** bar — that is deliberate, not an
  omission
- **Launch**: `quickshell -c dotfiles`, from `hypr/conf.d/quickshell.{lua,conf}`
- 🚨 **`PowerMenu.qml` holds the tree's only `hyprctl dispatch`** (log out). Under the Lua config
  provider it must be `hl.dsp.exit()`, never the legacy `exit` — it was the 30th call site the
  cutover audit had missed, because it postdates that inventory
- **Toggle**: `desktop/quickshell-toggle [bar|launcher|power|notifications|overview]` —
  `SUPER+B` (bar), `SUPER+D` (launcher), `SUPER+SHIFT+Q` (power menu), `SUPER+SHIFT+N`
  (notifications), `SUPER+grave` (overview). One script for all of them: IPC only reaches a
  *running* instance, so every binding needs the same launch-then-retry dance
- 🚨 **The primary keys were taken on 2026-09-01, by gating not shadowing.** Duplicate binds
  *stack* in Hyprland — both would fire — so the Wofi `SUPER+D`
  (`conf/bindings/applications.{conf,lua}.tmpl`) and the wlogout `SUPER+SHIFT+Q`
  (`conf/bindings/system-control.{conf,lua}.tmpl`, renamed to `.tmpl` for this) are wrapped in
  `{{ if not .features.quickshell_shell.enabled }}`. Flip the flag and the old pair comes back.
  **Wofi is still never removable** — it serves `cliphist` and every `--dmenu` caller
- 🚨 **`chezmoi apply` does not reliably reload the running shell.** The log will still say
  *"Configuration Loaded"* while the live generation is the pre-apply one — chezmoi replaces
  files by rename, which a per-file watch does not survive, and the watcher compares content
  rather than mtime so `touch` does nothing either. Finish an apply with
  `quickshell -c dotfiles kill && quickshell-toggle bar`, and verify with
  `quickshell -c dotfiles ipc show`, never by looking at the deployed files
- **Lint**: `mise run lint:qml` · **Format**: `mise run format:qml`

## Layout

```
dotfiles/
├── shell.qml              # ShellRoot: IPC handlers + Variants over screens + the OSD
├── qmldir                 # declares the four singletons (required by qmllint)
├── Theme.qml              # colours from themes/current/colors.sh, at runtime
├── Config.qml.tmpl        # geometry scale, fonts, chassis, scriptsDir, shared glyph ramps
├── Backlight.qml          # sysfs backlight, shared by the bar widget and the OSD
├── Notifications.qml      # NotificationServer + DND + popup list + history grouping
├── osd/Osd.qml            # volume + brightness overlay, follows the focused monitor
├── launcher/Launcher.qml  # app launcher (artboard 1d)
├── power/PowerMenu.qml    # power / session menu (artboard 1h)
├── dock/Dock.qml          # auto-hiding dock, one PER SCREEN (artboard comp-a)
├── overview/
│   ├── Overview.qml       # workspace carousel (artboard comp-b)
│   └── WorkspaceCard.qml  # one card, used at all three carousel scales
├── notifications/
│   ├── NotificationCard.qml     # THE card — shared by the centre and the popups
│   ├── NotificationPopups.qml   # toast stack, one window PER SCREEN
│   └── NotificationCentre.qml   # the 440-wide panel (artboard pan-a)
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
| Kanata, Voxtype, Idle | existing scripts, via `WaybarJsonSource` |
| Notification | the `Notifications` singleton — Phase 4 cut the last `swaync-client` call out of the tree |

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

**Two scripts are reused, not ported**: `kanata-layer` and `idle-indicator` already emit Waybar's
custom-module JSON. Voxtype reads `voxtype status --follow --format json` directly — the
`voxtype-waybar-status` wrapper it used went with voxtype 1.0's on-demand loading.
(`swaync-client -swb` was a third until Phase 4; the bell now reads an in-process singleton.)

## Launcher and power menu (Phase 5)

Two `PanelWindow`s in `shell.qml`, each a **single window that follows the focused monitor**
(same name-matching as the OSD) rather than one per screen: a modal you summoned belongs where
you are looking.

Both differ from every other window in this tree on two points:

- `WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive` — they must receive keys the
  instant they map, without a click first. The bar and the OSD are both `None`
- **no `mask`** — the opposite of the OSD's `mask: Region {}`. These *want* the whole surface,
  so a click anywhere outside the panel dismisses them

`toggle()` returns the state actually reached (`"shown"`/`"hidden"`), the same contract
`bar.toggle()` has, so `quickshell-toggle` can report what happened rather than what was asked.

**The bar's launcher chip does not shell out.** It raises `launcherRequested` on
`LauncherWidget`, relayed by `Bar.qml` to `shell.qml`, which owns the window. Going out through
`quickshell-toggle` would spawn a process for the shell to talk to itself.

### Launcher

`DesktopEntries.applications` + `TextInput` + a ranking function compressed from Omarchy's
`services/AppSearch.js` (prefix > substring > keyword/comment > acronym). `entry.execute()`
launches. Icons are `IconImage` on `Quickshell.iconPath(icon, true)`, falling back to
`Config.windowGlyphFallback` when the theme has none — same contract the workspace pills have.

**Apps is the only mode.** The artboard's `>` run, `=` calc, `:` emoji, `/` files and `?` help
prefixes are not built; the mode badge renders `apps` as structure, and nothing switches it.
The web-search fallback row (and with it the group separator) is likewise not built.

### Power menu

A front-end over the **exact** commands `wlogout/layout` ran, `session-save` included. Two
deliberate departures from artboard `1h`:

- **Six tiles, not five.** Hibernate exists here and does real work on the laptop. Same rule
  the bar's eleven widgets follow: do not delete a function to match the drawing
- **wlogout's mnemonics** (`l u e h r s`), not the canvas's `l s e r p` — muscle memory, and
  the canvas's set collides on `s`

🚨 **It keeps wlogout's activation model: one activation fires, no confirmation step**, because
the wrapper it replaces has none. Adding one would be a behaviour change smuggled in as a
redesign. What protects you is the *selection*: Lock is selected on open, so Return alone can
never power anything off.

## Dock and workspace overview (Phase 5.5)

Both optional, both genuinely new — nothing here did either job, and Omarchy has no dock to
read from. Four things the **artboards** (`Composites.dc.html`, `comp-a`/`comp-b`) settled that
the plan's prose transcription had wrong or missing; see Amendment E.

### Dock — `dock/Dock.qml`

One per screen, like the bar and unlike every modal here: a dock is furniture, not something
you summon. Geometry is measured off `comp-a` and sits **outside** the geometry scale
(`Config.dock*`), the same way `powerTileRadius` does — the dock is a peer of the bar, not
something nested in it. Amendment A's transcription had the padding (14, not `padTight`), the
tile radius (12, not `radiusTile`) and the gap (10, not `gap`) all wrong.

🚨 **Three input traps, all silent:**

- `exclusiveZone: 0` and a **`mask`**. An unmasked layer-shell window swallows every click over
  its whole surface — the dock would eat clicks along the bottom of every screen, permanently.
- Hover comes from a **`HoverHandler`**, not a `MouseArea`. A `MouseArea` only reports hover
  while nothing above it has it, so each tile's own `MouseArea` stole it and the dock retracted
  out from under the click. `z: -1` does not help — stacking picks the winner, not the
  observers.
- The revealed mask is the **union of the hot edge and the panel's live rect**, with the hot
  edge growing to meet the panel and staying full-width. A single rect fails three ways: bound
  to the panel alone it lags the slide, pinned static and centred it misses an off-centre
  entry, and left short of the panel it leaves a seam to cross.

Plus a `Config.dockHideDelayMs` grace period, so a momentary hover loss cannot retract it.

**The running-indicator dot is kept against the artboard**, which draws none. A static mockup
of one moment is weak evidence that a *state* indicator does not exist, Amendment A specifies
it, and without it the dock is a strictly worse `SUPER+D`. Running → `workspace.activate()`;
not running → `entry.execute()`.

`Config.dockApps` holds **desktop-entry ids**, deliberately not interpolated from
`globals.yaml` `applications`: that file holds binary and MIME names, so `ghostty` and
`org.xfce.thunar` would both resolve to null. `DesktopEntries.heuristicLookup()` does not close
the gap either — it falls back to `StartupWMClass`, which is `com.mitchellh.ghostty` for the
one and absent for the other.

### Overview — `overview/Overview.qml`

Structurally the launcher again: focused monitor, `WlrKeyboardFocus.Exclusive`, no mask,
click-out dismisses, `toggle()` returning the state reached.

**Windows are live `ScreencopyView` captures**, falling back to the app glyph and title when
there is no content. Phase 5.5 first shipped *without* them, on the reading that the artboard
draws chrome rather than screenshots — which read the mockup right and the requirement wrong.

🚨 Two silent conditions: the view must sit in a **rendered** window or no recording context is
created, and `captureFrame()` from `Component.onCompleted` is too early. `live: true` avoids
the timing, scoped to an explicit `active` property — a window's `visible` does **not** reach
its content item, so binding capture to `root.visible` would capture forever.

Hyprland does capture windows on **inactive** workspaces over `hyprland-toplevel-export-v1`,
verified — which is what makes a workspace overview possible at all.

🚨 **The projection divides by `monitor.scale` first.** `HyprlandMonitor.width`/`height` are
copied verbatim from the `hyprctl monitors` JSON (`ipc/monitor.cpp:41`), so they are
**physical** pixels while window `at`/`size` are **logical**. Missed, a scale-1.25 display
draws every window 25% oversized — and a scale-1 laptop hides it completely.

Cards take the **monitor's** aspect, not the artboard's: `comp-b` draws three different aspect
ratios (0.81 / 0.68 / 0.59), none of which is a screen, so its cards cannot host a truthful
layout. The note's falloff curve carries over unchanged (scale 1.0 / 0.69 / 0.46, opacity
1 / .6 / .35).

**Two drawn behaviours are out, both because they need a raw `Hyprland.dispatch()`** — exactly
what the Phase 2 cutover removed: dragging a window between workspaces (there is no
`toplevel` move invokable at all) and the dashed "+" card that creates a workspace.

A slot's height comes from the **monitor**, never from the carousel `Row`: sizing a child off
the positioner that sizes itself from its children is a binding loop.

🚨 **The scrim is `Theme.scrim`, a shade rather than a token**, because `BG_OVERLAY` is
0.71–0.96 luminance in every light theme and an 86% scrim over it renders near-white. Anything
drawn on it then needs `Theme.fgOnScrim`: the scrim is dark in all 8 themes, so a light theme's
own `fgPrimary` measures 1.81 there.

## Notifications (Phase 4)

`Notifications.qml` owns the server; `notifications/` draws it. The centre is the launcher and
power menu again structurally — focused monitor, exclusive keyboard focus, no mask, click-out
dismisses — but anchored top-right under the bar rather than centred, where the toasts it
archives were.

**The popups are the exception to "one window that follows the focus"**: one per screen. A
notification arrives on its own schedule, so "wherever you were looking when it fired" is the
wrong answer. Routing honours `x-canonical-monitor`, the hint `ui_notify_focused`
(`core/gum-ui.sh`) has always sent; anything unhinted lands on the focused monitor.

Four things are load-bearing, all documented in `.claude/rules/quickshell-qml.md`:

- a popup timing out must **not** `expire()`/`dismiss()` — that would empty the history
- constructing `NotificationServer` is what claims the bus name, hence the `Loader`
- `transient` cannot be implemented with `tracked = false` (the server deletes immediately)
- `keepOnReload` survives a reload, not a restart — same as swaync, so no disk persistence

**Card rules from artboard pan-a, both easy to "improve" wrongly**: no severity stripe (every
card keeps an identical silhouette; severity is the **title colour alone**), and every string
on a card is `fgPrimary` — the ground is elevated, so hierarchy comes from size, weight and
mono-vs-sans, never from dimming. `fgMuted` appears on a card in exactly one place: the
Dismiss button's outline, because borders are foreground-class.

Timeouts mirror the swaync config they replace: 10s normal, 5s low, **critical never
auto-hides**. Bell gestures are swaync's too — left opens, right toggles DND, middle clears.

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
