# Quickshell QML Configuration Reference

**Location**: `private_dot_config/quickshell/dotfiles/`
**Runs as**: `quickshell -c dotfiles` (never a bare `~/.config/quickshell/shell.qml` — that
disables subdirectory discovery for every other config, including voxtype's)
**Gated by**: `features.quickshell_shell` via `.chezmoiignore`

**See**: Root `CLAUDE.md` for core standards
**See**: `_plans/QUICKSHELL_SHELL.md` for the phase roadmap
**See**: `.claude/rules/hyprland-lua.md` — this file is its counterpart

---

## File Categories

| Pattern | Purpose |
|---------|---------|
| `dotfiles/shell.qml` | Root `ShellRoot` — IPC handlers + `Variants` over screens + the OSD. Owns no widget |
| `dotfiles/qmldir` | Declares the singletons. **Load-bearing** — see below |
| `dotfiles/{Theme,Config,Backlight,Notifications}.qml*` | Singletons. `Config` is `.tmpl`, the other three are not |
| `dotfiles/bar/*.qml` | Bar shell and shared components (`BarWidget`, `BarTooltip`, `BarSeparator`, `WaybarJsonSource`) |
| `dotfiles/bar/widgets/*.qml` | One file per bar widget |
| `dotfiles/osd/Osd.qml` | Volume + brightness overlay. One window, follows the focused monitor |
| `dotfiles/notifications/*.qml` | The card (shared), the popup stack (one window per screen) and the centre |

Only files that genuinely need template data get `.tmpl`. Chassis gating is **one property**
(`Config.isLaptop`) consumed by `visible:`, never eight separate templates.

---

## Imports

**Use relative directory imports.** From `bar/widgets/`, `import "../../"` reaches the
singletons; `import "../"` reaches the shared bar components.

🚨 **Never `import "root:/"`.** Quickshell's `root:` URL scheme resolves at runtime but
qmllint has no interceptor for it, so the import silently fails to lint — the file passes
while every type in it goes unchecked. Verified: with relative imports, a typo'd
`Theme.fgPrimaryTYPO` two directories deep is caught.

**`pragma Singleton` needs a `qmldir` entry.** It works at runtime without one, but qmllint
reports *"not declared as singleton in qmldir"* and fails. The lint task copies `qmldir` into
its render tree for exactly this reason.

---

## 🚨 Tooling: always the absolute Qt6 path

`/usr/bin/qmllint` and `/usr/bin/qmlformat` are **Qt5** (`qt5-declarative`). The Qt5 linter is
a syntax-only verifier that exits 0 on unknown types *and* unknown properties. The usable Qt6
tools are `/usr/lib/qt6/bin/{qmllint,qmlformat}` and are **not on `$PATH`**.

`.mise/tasks/lint/qml.sh` pins both. Never use the bare names anywhere.

Three independent ways this task silently becomes a no-op, all of which it now defends against:

| Cause | Defence |
|---|---|
| Qt5 tool on `$PATH` | absolute paths, pinned once at the top of the task |
| qmllint exits 0 on warnings (`--max-warnings` defaults to `-1`) | `-W 0` makes any warning fatal |
| `qmlformat` 6.11 has no `--check`/`--verify` | `qmlformat "$f" \| diff -q - "$f"` |

**Prove it fails.** A passing lint on good code proves nothing. After any change to the task or
its exemptions, break something deliberately and confirm non-zero.

### Exemption discipline

The tree-wide exemption list is **exactly one entry**: `--uncreatable-type disable`. That one is
structural — `PanelWindow` and `PopupWindow` are exported through the `Quickshell._Window`
indirection with `isCreatable: false`, and the real window is substituted at runtime from a qrc
file qmllint cannot see.

**Everything else is suppressed inline**, over the affected lines only:

```qml
// qmllint disable unresolved-type
readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
// qmllint enable unresolved-type
```

Widening the CLI list is how this task turns back into a no-op — `unresolved-type` in
particular is also how a genuinely missing import surfaces. Verified: the same error class
placed *outside* a disable/enable region still fails the build.

⚠️ **A comment whose first word is `qmllint` is parsed as a directive**, so prose explaining a
suppression must never start a line with it. Doing so produces one `invalid-lint-directive`
warning per word.

---

## Upstream qmltypes gaps (quickshell 0.3.1)

Not our bugs, and not missing imports. Each needs an inline suppression:

| Symptom | Cause |
|---|---|
| `Type "BluetoothAdapter" ... not found` | `Quickshell/Bluetooth/qmldir` omits `depends Quickshell`, which Pipewire, SystemTray and Networking all declare |
| `Type "DeviceType::Enum" ... not found` | Networking's qmltypes records the enum unqualified; qmllint cannot match it to the module's own exported element |
| `Type "DBusMenuHandle" ... not found` | Not exposed declaratively; unavoidable when reading `SystemTrayItem.menu` |
| `unknown grouped property scope margins` + `Type margins is used but it is not resolved` | `PanelWindow.margins` is a `Margins` gadget from the same `Quickshell._Window` indirection as the window itself. The block form `margins { left: ... }` is unresolvable; the dotted form still warns, so suppress `unqualified` and `unresolved-type` over those lines. See `bar/Bar.qml` |
| `Unused import` on `import "../../"` | A singleton reached **only** from inside a template literal (`` `${Config.scriptsDir}/…` ``) is not traced, so the import that makes it resolvable reads as unused. Suppress `unused-imports` over that one import. See `bar/widgets/KanataWidget.qml` |
| `No type found for property "edges"` | `PopupAnchor.edges`/`gravity` are `Edges::Flags`, unresolvable across the module split. Suppress inline with `missing-type` — the defaults are **not** usable, see below |

---

## Runtime behaviours that bite

🚨 **A Nerd Font glyph literal can be authored as an empty string, silently.** It has
happened twice in this tree: `WorkspacesWidget`'s five state glyphs and `BacklightWidget`'s
nine-step brightness ramp were both committed as `""`, `""`, … — valid QML, valid strings,
nothing rendered, no error anywhere. qmllint cannot see it and the widget just looks blank.
Write glyphs through explicit codepoints (`chr(0xF00DA)` from a script, not a paste), and
grep for `""` inside glyph arrays before committing. The `nerdfonts-search` skill is the
source for the codepoints; its output is the thing to transcribe.

🚨 **`ExclusionMode.Auto` only reserves the margins of edges that are actually anchored.**
A floating bar is anchored `left`/`right`/`top` with a margin on all four sides, so Auto
reserves `height + topMargin` and windows tile *under* the bottom inset. Set `exclusiveZone`
explicitly to `barHeight + inset * 2`; assigning it also switches the mode to
`ExclusionMode.Normal`, which is what you want. See `bar/Bar.qml`.

🚨 **A `PopupWindow` anchored to an item covers that item at the default `edges`.**
`PopupAnchorState` defaults to `edges = Top | Left`, `gravity = Bottom | Right`
(`_ai/quickshell/src/core/popupanchor.hpp`), and setting `anchor.item` without `anchor.rect`
makes the anchor rect the item's **full** `boundingRect()` (`popupanchor.cpp` `updateAnchor`).
So `anchorY` is the item's *top* edge and the popup lands on top of the widget it describes.
The popup then steals the pointer, `containsMouse` drops, a `visible:`-bound popup hides, the
pointer returns, and it flickers forever — while swallowing every click meant for the widget.
Set `edges: Edges.Bottom` and `gravity: Edges.Bottom` (which also centres it horizontally) and
suppress `missing-type` over those two lines. See `bar/BarTooltip.qml`.

🚨 **A shared `MouseArea` declared after the content container consumes every child's events.**
Later siblings stack above earlier ones, so `BarWidget`'s catch-all `MouseArea` sat over the
per-workspace and per-tray-item `MouseArea`s and killed their clicks *and* their `containsMouse`.
`z: -1` puts it under the content: a child `MouseArea` wins where one exists, and elsewhere the
event still reaches it because `Text` and `Rectangle` do not accept mouse events.

🚨 **A layer-shell window with no `mask` swallows every click over its whole surface**, even
with nothing in it that accepts mouse events — the input region defaults to the full surface,
and the compositor routes the pointer there. A purely informational overlay must declare
`mask: Region {}` (empty region = nothing clickable, everything passes through). The `Xor`
form in the upstream docs is for punching a hole in an otherwise-clickable window. See
`osd/Osd.qml`.

**A window that follows the focused monitor is matched by name.** `HyprlandMonitor` exposes
`id`/`name`/`description`/geometry but **no `screen`**; `Quickshell.screens` entries expose
`name`. So `screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)`,
not a direct handoff. `Hyprland.monitorFor(screen)` is the inverse and does exist.

**Pipewire node properties are unbound without a tracker.** `Pipewire.defaultAudioSink.audio.volume`
reads a permanent 0 with no error unless a `PwObjectTracker { objects: [sink] }` holds the node.
See `bar/widgets/AudioWidget.qml`.

**`WifiNetwork.signalStrength` is a 0..1 fraction too.** Same trap, different module: `nmcli`
reports 61, the property reads 0.61. A `/ 25` banding written for a percentage pins the index at
0, so a full-strength link draws the empty-signal glyph forever, with no error. See
`bar/widgets/NetworkWidget.qml`.

**`Networking.devices` is empty for the first ~1-2s**, like Hyprland's models below. It fills on
its own and `ObjectModel.values` does notify (`valuesChanged`), so a binding recovers — but a
one-shot read at startup sees nothing. A wifi device's `networks` already contains the connected
network without `scannerEnabled`; leave the scanner off unless a picker needs the full list.

**`UPowerDevice.percentage` is a 0..1 fraction**, not the 0..100 that the UPower D-Bus API and
`upower -i` both report. Verified: `upower` said 72%, the property said 0.72. Every threshold
goes 100x out if this is missed.

**`Quickshell.Io/Socket` is a UNIX socket** — its only address property is `path`. There is no
TCP support, so anything speaking to a TCP service (kanata's port 5829) goes through a `Process`.

🚨 **A notification's popup timeout must never call `expire()` or `dismiss()`.** Both destroy
the `Notification`, which removes it from `trackedNotifications` — the history a notification
centre exists to show. So a toast auto-hiding would silently empty the centre. Popup lifetime
is a separate list with its own timers in `Notifications.qml`; only a real dismissal destroys
anything.

🚨 **Constructing `NotificationServer` is what claims `org.freedesktop.Notifications`**, and a
bus name has exactly one owner. There is no "advertise nothing" configuration — the only way
not to own notifications is not to construct the server, which is why it sits behind a
`Loader { active: Config.notificationsOwned }`. With swaync unmasked and a server constructed
anyway, the two race for the name at login.

🚨 **A notification is NOT tracked by default — the handler must set `tracked = true`.**
`isTracked()` reads `mCloseReason == 0`, which looks like "tracked unless closed", but the
member is initialised to `NotificationCloseReason::Dismissed`. `server.cpp` then DELETES the
notification the instant the `notification` signal returns if it is still untracked. Reading
the getter's body alone gives the opposite answer; the member's initialiser is the fact.

Missed, the failure is quiet and misleading: popups still appear (the handler already captured
the pointer), then turn into a list of `null`s, while the centre stays permanently empty. The
only symptom in the log is `TypeError: Cannot read property 'hints' of null`. Verified live
2026-09-01. The corollary: implement `transient` by filtering it out of history, never by
setting `tracked = false`.

**`NotificationServer.extraHints` does not gate `hints`.** It only extends the advertised
`GetCapabilities` list; every hint a client sends arrives in `Notification.hints` regardless.
That is how `x-canonical-monitor` (sent by `ui_notify_focused` in `core/gum-ui.sh`) routes a
popup to a monitor without being declared.

**`keepOnReload` covers a RELOAD, not a restart.** Notifications survive a config reload and
come back flagged `lastGeneration`; a fresh process starts empty. That matches swaync, which
also loses history when its daemon restarts, so no disk persistence exists here.

**Hyprland's models populate lazily and asynchronously.** `Hyprland.workspaces` and
`.monitors` are both empty for the first ~1s. They fill on their own; `refreshWorkspaces()` is
not needed, but code must not assume data at startup.

**`FileView.watchChanges` only signals** — handle `onFileChanged` with `reload()`. And it
watches the *resolved* path, so a symlink swap (as `theme switch` does to `themes/current`)
never fires. That is why theming is driven by an explicit IPC call.

---

## Geometry and the accent rule

Both are Amendment A of `_plans/QUICKSHELL_SHELL.md`, and both live in exactly one place.

**Geometry** is the scale in `Config.qml.tmpl`: `radiusPanel` 12 / `radiusTile` 10 /
`radiusChip` 8 / `radiusPill` 999, `gap` 8, `padTight`/`pad`/`padLoose` 12/16/24, plus
`barHeight` 40, `barInset` 8, `chipSize` 26, `pillHeight` 24. A widget never writes a radius
or a spacing of its own — the four-step radius ramp is what makes a chip inside a panel read
as nested rather than as a coincidence.

**The accent rule** — *one accent marks the focused thing, everything else neutral, semantic
colours only for state* — is enforced by `BarWidget.iconColor`. A widget overrides it only
for a genuine state (muted, disconnected, inhibited, low battery); at rest every widget is
the same colour. Set `icon`/`label` on `BarWidget` rather than declaring your own `Text`, and
the rule applies for free.

🚨 **`iconColor`/`labelColor` are not one fixed rest colour — they default to `restColor`,
which follows `grounded`.** A widget colouring for a state ends its ternary on `root.restColor`;
ending it on a flat `Theme.fgSecondary` pins the ungrounded colour onto a lit ground. That was
six widgets' worth of defect, found by the reviewer below and fixed 2026-09-01.
`themes/CLAUDE.md` bans `@fg-secondary` on `@bg-secondary`/`@bg-tertiary` outright (both
"secondary" reads at 4.0-4.5:1 and fails WCAG AA), and a hovered chip, a pill and the
launcher tint are all elevated surfaces. So the default is `fgSecondary` at rest and
`fgPrimary` the moment a ground appears. Anything that hardcodes one of the two reintroduces
the banned pair on half the widget's states.

`labelColor` is split from `iconColor` so the glyph can carry a state while the number it
annotates stays readable — the battery pill is the case that needs it. `monoLabel: true`
puts a number in `terminalFont`: digits only line up fixed-pitch, and a proportional face
reflows the bar every time the value changes width.

`pill: true` gives a widget its own permanent ground. **Exactly one widget has it** — the
battery — because charge is the only number that has to be readable without a hover.
`tinted: true` is the same idea without the pill radius, and **only the launcher chip has
it**: an accent ground at rest is the single fixed anchor the bar is allowed.
Everything else is icon-only, with its number in the tooltip.

`BarSeparator` binds to the group that **follows** it (`group: gPower`), so a group that
collapses to zero width on a desktop takes its leading hairline with it instead of leaving a
stray rule in the bar. **The hairline is `bgSecondary`** — bar border, separators, the gap dot
and every panel border alike.

🚨 **This was `bgTertiary` until 2026-09-01, on a mis-mapping.** Amendment A read the canvas's
`#313244` as "`surface0`, which is what `BG_TERTIARY` maps to". It does not: in
`themes/catppuccin-mocha/colors.sh`, `BG_SECONDARY` is `#313244` and `BG_TERTIARY` is
`#45475a`. The correction moved the hairline one tier the wrong way in all 8 themes. See the
hex table below — and never map a canvas colour by its LABEL.

### Reading the design source, not the transcription

The canvas lives in a Claude Design project (`1d494341-deaa-47cb-ac39-32ccb9c23862`) and is
readable through the `DesignSync` MCP tool: `list_files`, then `get_file`. It is now **six
files** — `Foundations`, `Bar - Dock`, `Composites`, `Launcher - Menu`, `Panels`, `Session`
(`.dc.html`) — replacing the single-file `1a`–`1i` set. `support.js` beside them is the
generated dc-runtime and carries no design content — do not bother fetching it. Reading the
artboards directly has now settled seven things the prose transcriptions had lost or got
wrong: the launcher chip, the hairline tier (twice, in opposite directions), the mono
numerals, urgent being a text colour rather than a red fill, the card contrast law, and that
notification cards carry no severity stripe.

⚠️ **`DesignSync` needs its own authorization.** A session without it fails with *"DesignSync
needs design-system authorization"*; `/design-login` grants it. Nothing in the repo can
substitute — plan on reading the source, not a transcription of it.

### 🚨 Map canvas colours by HEX, never by name

The canvas names three background tiers with Catppuccin-tier names; our colorset has four,
ordered differently. Matching on the name is how the hairline defect above happened. Verified
against `themes/catppuccin-mocha/colors.sh`:

| Canvas hex | Canvas label | **Our token** |
|---|---|---|
| `#1e1e2e` | bg-primary | `BG_PRIMARY` |
| `#313244` | bg-secondary | **`BG_SECONDARY`** — hairlines, chip grounds |
| `#45475a` | (unused by the canvas) | `BG_TERTIARY` |
| `#181825` | bg-tertiary | **`BG_OVERLAY`** — notification cards, tooltips |
| `#6c7086` | fg-muted | `FG_MUTED` (`#9399b2` here — a different value, same role) |

The same trap bit `Theme.qml`: **nine of its 24 fallbacks were the canvas's Mocha palette
rather than our colorset's** — including `accentPrimary`, mauve on the canvas and blue
(`#89b4fa`) in `colors.sh`. Fixed 2026-09-01. Copy a fallback from `colors.sh`, never from a
mockup.

⚠️ **The canvas's fourth background tier has no single equivalent here.** Amendment A said
`BG_TERTIARY` and `BG_OVERLAY` "are the same value in the shipped themes (verified in
`rose-pine-moon`)" — that generalised from **one** theme. Checked across all eight, they are
equal only in `rose-pine-moon`; mocha has `#45475a` vs `#181825`, latte `#bcc0cc` vs
`#e6e9ef`. The canvas's separate "visible on another monitor" and "occupied" grounds still
collapse to one, but because collapsing a tier beats inventing a colour — **not** because the
two tokens coincide. They mostly do not.

⚠️ **The "empty" workspace pill departs from the mockup on purpose.** The canvas gives it a
faint ground; ours stays transparent, because a ground makes it an elevated surface and the
contrast rule would then force `fg-primary` on the one state that has to recede. On the bar
ground, `fg-muted` is allowed.

---

## IPC

Handlers live in `shell.qml`. Current targets: `theme.reload()`, `idle.refresh()`,
`bar.toggle()`, `launcher.toggle()`, `power.toggle()`, `notifications.toggle()`,
`notifications.dnd()`. List them live with `quickshell ipc --pid <pid> show`.

**Flag placement differs by flag**, which is not obvious:

```sh
quickshell -c dotfiles ipc call theme reload   # config selection: BEFORE `ipc`
quickshell ipc --pid 1234 call theme reload    # instance selection: AFTER `ipc`
```

`-c dotfiles` is load-bearing: without it the call targets config name `default`, and voxtype
runs a second instance so "just pick one" is wrong too.

🚨 **`quickshell ipc call` exits 0 even when it fails.** A nonexistent target prints
*"Target not found."* and still returns 0. A broken IPC wiring can therefore never be detected
from an exit code — the `|| true` in the calling scripts is harmless but buys nothing. Verify
by hand with `ipc show`.

Callers today: `desktop/theme-switcher` (theme reload), `desktop/idle-toggle{,-nolock}` (idle
refresh, beside their existing `pkill -RTMIN+9 waybar`), and the `SUPER+B` binding in
`hypr/conf.d/quickshell.{lua,conf}`.

**The OSD is deliberately not on IPC.** Both its sources already notify (Pipewire on the sink,
`FileView.watchChanges` on the sysfs backlight), so a keybinding or a script hook would only
add a second, less reliable trigger for a change the shell can already see.

---

## Theming

`Theme.qml` parses `~/.config/themes/current/colors.sh` at runtime — the same format-neutral
colorset every other app reads, so there is no ninth per-theme file. All **24** semantic
variables are exposed; a missing key falls back to hardcoded Catppuccin, which renders wrong
colours with no error, so the property set must stay complete.

Contrast rules from `themes/CLAUDE.md` get **no automatic enforcement in QML** — `@fg-primary`
on `@bg-secondary`/`@bg-tertiary`/`@bg-overlay` is a by-hand discipline here. The
module → semantic-colour mapping this bar follows is `waybar/CLAUDE.md`'s table.

The closest thing to enforcement is the `theme-consistency-reviewer` subagent, which takes this
tree as a second review target: literal hex (only `Theme.qml`'s fallbacks are allowed), literal
font name (only `Config.qml.tmpl`, and only through `globals.yaml`), and `Theme.fgSecondary` on
a lit ground. It judges the third against `BarWidget`'s `grounded` ternary, so an override that
pins one fixed rest colour is the finding.

---

## Validation

```bash
mise run lint:qml      # render whole tree, qmllint -W 0, qmlformat diff check
mise run format:qml    # qmlformat --inplace, *.qml only (a template has nothing to write back to)
```

Both are wired into `[tasks.lint]`/`[tasks.format]` and into pre-commit via
`.mise/tasks/lint/qml-staged.sh`.

**The tree is linted as one rendered unit**, not per file: `shell.qml` references the `Config`
singleton, which exists in source only as `Config.qml.tmpl`. Formatting is checked against
**source** `*.qml` only.

No `.qmlformat.ini` exists, so QML formats to **4 spaces** — unlike the Lua tree's tabs.

**Limitation, shared with `lint:lua-tmpl`**: only the branch of a `.tmpl` that renders for the
current machine is checked. `Config.qml.tmpl`'s `isLaptop` is a value rather than a branch,
which is deliberate — it keeps chassis differences out of the template layer entirely.

For runtime checks, render the tree and run it directly rather than deploying:

```bash
quickshell -p /path/to/rendered/tree    # loads without touching ~/.config
```

A `console.log` in a `Timer` is the fastest way to check a live binding; QML binding errors and
D-Bus failures both surface in that output.
