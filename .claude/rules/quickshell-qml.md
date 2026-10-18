---
paths:
  - "private_dot_config/quickshell/**"
---

# Quickshell QML Configuration Reference

**Location**: `private_dot_config/quickshell/dotfiles/`
**Runs as**: `quickshell -c dotfiles` (never a bare `~/.config/quickshell/shell.qml` — that
disables subdirectory discovery for every other config, including voxtype's)

**See**: Root `CLAUDE.md` for core standards
**See**: `private_dot_config/quickshell/CLAUDE.md` for what the shell is today, and
`_plans/QUICKSHELL_TOOL_RETIREMENT.md` — the removal work, and the only open Quickshell plan.
`_research/archive/QUICKSHELL_SURFACE_INVENTORY.md` (what each of the 30 surfaces is made of),
`_plans/archive/QUICKSHELL_SHELL.md` (the build record) and
`_plans/archive/QUICKSHELL_OPEN_WORK.md` (the contrast rulings, closed the day it was written)
are history, not roadmaps
**See**: `.claude/rules/quickshell-design.md` — geometry, the accent rule, contrast and theming
(loads for files that draw something); the measurements behind the rules here and there are in
`_research/archive/QUICKSHELL_RULE_EVIDENCE.md`
**See**: `.claude/rules/hyprland-lua.md` — this file is its counterpart

---

## File Categories

| Pattern | Purpose |
|---------|---------|
| `dotfiles/shell.qml` | Root `ShellRoot` — IPC handlers + `Variants` over screens + the OSD. Owns no widget |
| `dotfiles/qmldir` | Declares the singletons. **Load-bearing** — see below |
| `dotfiles/{Theme,Config,Backlight,Notifications,Meters,MenuServer}.qml*` | Singletons. `Config` is `.tmpl`, the other five are not |
| `dotfiles/bar/*.qml` | Bar shell and shared components (`BarWidget`, `BarTooltip`, `BarSeparator`, `WaybarJsonSource`) |
| `dotfiles/bar/{BarPopover,PopoverRow,PopoverSlider}.qml` | The popover chrome: header/body/footer + anchoring and grabs, the 34 row every list-shaped payload draws, and the only control taking both drag and wheel |
| `dotfiles/bar/ActionButton.qml` | The one push button — notification actions, the centre's Clear and DND, polkit's Cancel/Authenticate. `emphasis` primary / secondary / neutral; never hand-roll a button from a `Rectangle` |
| `dotfiles/bar/widgets/*.qml` | One file per bar widget |
| `dotfiles/bar/popovers/*.qml` | The eight payloads — one per bar widget that owns one |
| `dotfiles/osd/Osd.qml` | Volume + brightness overlay. One window, follows the focused monitor |
| `dotfiles/launcher/PickerSurface.qml` | The chrome the launcher, the menu and the clipboard share. Consumers supply **data**, never a delegate — see below |
| `dotfiles/launcher/Launcher.qml` | App launcher: ranking, `:` run, `=` calc |
| `dotfiles/menu/MenuPicker.qml` | The dmenu surface, fed by `MenuServer`'s socket |
| `dotfiles/clipboard/ClipboardPicker.qml` | cliphist history |
| `dotfiles/notifications/*.qml` | The card (shared), the popup stack (one window per screen) and the centre |
| `dotfiles/dock/Dock.qml` | Auto-hiding dock. One window **per screen**, hot-edge reveal |
| `dotfiles/power/PowerMenu.qml` | The power / session menu (design page 09) |
| `dotfiles/polkit/PolkitDialog.qml` | The polkit authentication dialog. Raised by the **system**: no toggle, no IPC target, visibility is the agent's `isActive` |
| `dotfiles/lock/LockScreen.qml` | The session lock: `WlSessionLock`, PAM, stranded-lock recovery. Non-visual, behind a `Loader` on `Config.lockOwned` |
| `dotfiles/lock/LockContent.qml` | What the lock draws, once per output. Clock, date, one field, one line — and deliberately nothing that reads a state |
| `dotfiles/keybindings/KeybindingsSheet.qml` | The keybindings reference (surface §9) — the one summoned surface that is a DOCUMENT, not a chooser. Fed by `desktop/keybindings --json` |
| `dotfiles/overview/*.qml` | Workspace carousel and its card. One window, follows the focused monitor |

Only files that genuinely need template data get `.tmpl`. Chassis gating is **one property**
(`Config.isLaptop`) consumed by `visible:`, never eight separate templates.

---

## Imports

**Use relative directory imports.** From `bar/widgets/`, `import "../../"` reaches the
singletons; `import "../"` reaches the shared bar components.

🚨 **Never `import "root:/"`.** Quickshell's `root:` URL scheme resolves at runtime but
qmllint has no interceptor for it, so the import silently fails to lint — the file passes
while every type in it goes unchecked. Verified: with relative imports, a typo'd
`Theme.inkPrimaryTYPO` two directories deep is caught.

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

🚨 **A `property Component` used as a delegate fails the build, at the WRONG file.** qmllint
cannot know the component is a delegate, so the `index`/`modelData` required properties that
`pragma ComponentBehavior: Bound` forces read as unsatisfiable — and the error surfaces at every
*use site* (`Component is missing required property index from Rectangle`, on `shell.qml`'s
`Launcher {}`), not in the file that declared the property. There is no suppression for it that
is not a lie. `PickerSurface` therefore takes **row data** and owns the delegate itself; that
was smaller code anyway, since all three list surfaces draw the same row.

⚠️ **The lint task renders from `git ls-files`, so an UNTRACKED new file is invisible to it** —
and worse, the files that import it fail with *"X was not found"* while the real cause is that
X was never copied into the render tree. `git add -N` the new file before running
`mise run lint:qml`.

---

## Upstream qmltypes gaps (quickshell 0.3.1)

Not our bugs, and not missing imports. Each needs an inline suppression:

| Symptom | Cause |
|---|---|
| `Type "BluetoothAdapter" ... not found` | `Quickshell/Bluetooth/qmldir` omits `depends Quickshell`, which Pipewire, SystemTray and Networking all declare |
| `Type "DeviceType::Enum" ... not found` | Networking's qmltypes records the enum unqualified; qmllint cannot match it to the module's own exported element |
| `Type "DBusMenuHandle" ... not found` | Not exposed declaratively; unavoidable when reading `SystemTrayItem.menu` |
| `Type "AuthFlow" of property "flow" not found` | Polkit's `AuthFlow` is a real type with a documented API, but it carries no `QML_ELEMENT`, so nothing declares it. Unavoidable when reading `PolkitAgent.flow`. See `polkit/PolkitDialog.qml` |
| `Type QProcess::ExitStatus of parameter exitStatus in signal called exited was not found` | `Process.exited(qint32, QProcess::ExitStatus)` (`io/process.hpp:221`) carries a second argument whose Qt type nothing declares to qmllint, so the handler cannot compile even when it only binds the first. Unavoidable when reading an exit code; suppress `signal-handler-parameters`. See `lock/LockScreen.qml` |
| `unknown grouped property scope margins` + `Type margins is used but it is not resolved` | `PanelWindow.margins` is a `Margins` gadget from the same `Quickshell._Window` indirection as the window itself. The block form `margins { left: ... }` is unresolvable; the dotted form still warns, so suppress `unqualified` and `unresolved-type` over those lines. See `bar/Bar.qml` |
| `Unused import` on `import "../../"` | A singleton reached **only** from inside a template literal (`` `${Config.scriptsDir}/…` ``) is not traced, so the import that makes it resolvable reads as unused. Suppress `unused-imports` over that one import. See `bar/widgets/KanataWidget.qml` |
| `Could not find property "left"` / `Member "values" not found on type "UntypedObjectModel"` / `Member "name" not found on type "QuickshellScreenInfo"`, as `missing-property` | Appeared with quickshell 0.3.2 (2026-10-11): its qmltypes no longer let qmllint resolve `PanelWindow.margins.*`, `PopupAnchor.item/edges/gravity/adjustment/updateAnchor()`, `ObjectModel.values` and `ShellScreen.name`. Suppress `missing-property` inline over those lines (and `redundant-optional-chaining` on `screen?.name`, a consequence). Bluetooth and Networking also declare an opaque `UntypedObjectModel` stub that may be involved. Re-test on the next quickshell bump and drop the suppressions if upstream fixes it |
| `No type found for property "edges"` | `PopupAnchor.edges`/`gravity` are `Edges::Flags`, unresolvable across the module split. Suppress inline with `missing-type` — the defaults are **not** usable, see below |

---

## Runtime behaviours that bite

🚨 **`Text` defaults to `Text.AutoText`, and `AutoText` SELF-PROMOTES to rich text.** Qt runs
`Qt.mightBeRichText()` on the string and switches format by itself — no `StyledText`, no opt-in.
Rich text then **fetches `<img src="http://…">`**, so any `Text` rendering a string this repo did
not author is an unauthenticated outbound GET waiting for a sender to notice. The reachable path
was the shared `BarWidget` label (window title, MPRIS track title). Do not strip tags — a substring
strip can be bypassed into a live tag; declare the format.

**The rule is foreign text, not every `Text`.** 18 of this tree's 83 unformatted `Text` elements
could carry a foreign string and now pin `textFormat: Text.PlainText`; the other 65 are glyph
literals, `qsTr` chrome, numbers, `Qt.formatDateTime` output, workspace ids and output names, and
are deliberately left alone. Foreign means: Hyprland window titles and app ids, MPRIS metadata,
notification summary/body/appName/action labels, clipboard entries, `.desktop` fields, tray titles
and tooltips, SSIDs, Bluetooth and PipeWire device names, polkit and PAM message text, and any
`Process` stdout.

The check is a grep, not a linter — every `Text.text` in this tree is bound in its own
declaration (no `Binding {}`, no alias, no `Component.onCompleted` assignment), so
`grep -n 'text:' <file>` against that list finds every site. Upstream ships a scanner
(`test/shell.d/qml-text-format-scan.py`); it is not vendored, because a guard nobody runs is worse
than the grep.

🚨 **A Nerd Font glyph literal can be authored as an empty string, silently.** It has
happened twice in this tree: `WorkspacesWidget`'s five state glyphs and `BacklightWidget`'s
nine-step brightness ramp were both committed as `""`, `""`, … — valid QML, valid strings,
nothing rendered, no error anywhere. qmllint cannot see it and the widget just looks blank.
Write glyphs through explicit codepoints (`chr(0xF00DA)` from a script, not a paste), and
grep for `""` inside glyph arrays before committing. The `nerdfonts-search` skill is the
source for the codepoints; its output is the thing to transcribe.

🚨 **`ExclusionMode.Auto` only reserves the margins of edges that are actually anchored.**
A floating bar is anchored `left`/`right`/`top` with a margin on all four sides, so Auto
reserves more than the bar occupies. Assigning `exclusiveZone` also switches the mode to
`ExclusionMode.Normal`, which is what you want.

🚨 **The compositor ADDS the margin, so the zone is not the bar's bottom edge.** Hyprland reserves
`margins.top + exclusiveZone`; `barHeight` alone reserves exactly the bottom edge. This tree
deliberately sets `exclusiveZone` to `barHeight + barInset`, so the gap under the bar is
`barInset + gaps_out` (8) against 4 at the sides — rendered and compared 2026-09-10, so a
symmetric-looking `barHeight` is a *change*, not a fix. See `bar/Bar.qml`.

Check against the compositor, never the QML: `hyprctl monitors -j` (`reserved`), `hyprctl layers`
(the bar's `xywh`), `hyprctl clients -j` (first tiled window's `at` = `gaps_out + border_size`).

🚨 **`barInset` and `gaps_out` are one number in two files** — `Config.qml.tmpl` and
`hypr/conf/general.lua` (plus its `.conf` twin). The inset is what aligns the bar's side
edges with every window's, and per the paragraph above the gap under the bar is
`barInset + gaps_out`, so neither the top gap nor the bottom one can be changed from the
QML side alone. Both are 4 today; `gaps_in` is half that, keeping the screen-edge gap equal
to the window-to-window gap.

🚨 **`PopupWindow.grabFocus` does not work on a layer-shell parent.** It requests an *xdg_popup*
grab (`popupwindow.cpp:63`); a popup parented to a layer surface is not one, so it silently sets
itself back to invisible. A bar popup therefore gets **no** click-outside dismissal from Qt.
`HyprlandFocusGrab` works (keys reach a focused `Item`, `cleared` fires on an outside click) but
takes the keyboard from the focused application while active and survives a workspace switch — only
correct for a surface the user deliberately summoned.

🚨 **`signal closed` on a `PopupWindow` is an override, not a new signal.** The engine reports
*"Duplicate signal name: invalid override of property change signal or superclass signal"* at
RUNTIME and qmllint says nothing. Same class of trap as the illegal `escape()` method name.

🚨 **A popup anchored to an item does not follow it.** `popupanchor.hpp:83-87`: the anchor rect
is computed when the popup is first shown, and `updateAnchor()` is the only thing that
recomputes it. Anything anchored to a bar widget must call it on every open — the window title
changes width and the workspace pills come and go, so the second opening lands where the widget
used to be.

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

🚨 **`Pipewire.defaultAudioSink` is resolved BY NAME, so a duplicate node wins silently.**
`defaults.cpp` reads `default.audio.sink` as a *name* and takes the first `findNodeByName()` match.
Every suspend/resume on the laptop leaks an orphaned `Audio/Sink` node with the same name; Quickshell
bound a frozen one, so the OSD and `AudioWidget` tracked a node nothing could change while `pamixer`
moved the real sink. Symptom: *"the volume keys do nothing"* with every layer below QML clean.
Diagnose with `wpctl status` (the live default carries `*`) or
`pw-dump | jq '.[] | select(.info.props["media.class"]=="Audio/Sink")'`; `systemctl --user restart
wireplumber` destroys the orphans. `after_sleep_cmd` in `.chezmoitemplates/hypridle_general` sweeps
them on resume (laptop only, where it was measured).

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

🚨 **An unresolvable icon renders a MAGENTA CHECKERBOARD that loads as `Image.Ready`.**
`iconimageprovider.cpp`'s `missingPixmap` paints a black/magenta 2x2 and returns it as a normal
pixmap, so a status gate cannot tell a missing icon from a loaded one — the fallback never fires
and the checkerboard is what the user sees. `Quickshell.iconPath(name, true)` is the reliable
test (it answers `""`), and `Quickshell.hasThemeIcon(name)` agrees; verified both false for
`gtk-dialog-info` and for any absolute path. Note also that an `image-path` hint or an `app_icon`
that is not a `file:` URL is wrapped as `image://icon/<it>` **whether it is a theme name or a
path**, so a real file reaches the icon provider and fails there: unwrap the prefix and hand a
path to `Image` as `file://` instead. See `notifications/NotificationCard.qml`.

🚨 **A notification's popup timeout must never call `expire()` or `dismiss()`.** Both destroy
the `Notification`, which removes it from `trackedNotifications` — the history a notification
centre exists to show. So a toast auto-hiding would silently empty the centre. Popup lifetime
is a separate list with its own timers in `Notifications.qml`; only a real dismissal destroys
anything.

🚨 **Constructing `PolkitAgent` is what REGISTERS the agent, and a session may have
exactly one.** Same shape as the notification server below, and the same consequence: the only
way not to own polkit is not to construct it, which is why the whole dialog sits behind a
`Loader { active: Config.polkitOwned }`.
`path` is deliberately unset — the binary's own
default (`/org/quickshell/Polkit`) is as good as any, and naming one only invites drift.

⚠️ **A failure does NOT end the flow.** Quickshell starts a fresh PAM session automatically and
emits `authenticationFailed` on the flow, so the dialog stays up and only the field is cleared.
Nothing in the QML may destroy the flow on a failure — cancelling is `cancelAuthenticationRequest()`
and nothing else.

🚨 **"Is the compositor locked" is NOT "is the lock stranded", and acting on the first
displaces a live lock screen.** `desktop/session-locked` is equally true while hyprlock runs, and
`misc:allow_session_lock_restore` means a second lock client is *accepted* (2026-09-12:
`LockScreen.qml` took a second lock on top of a live one). The probe is
`desktop/session-lock-stranded` (locked **and** the lock file free); the QML rules *itself* out first
with `locked || lockRequested`, since the in-process locker takes no lock file.

⚠️ **A restart while the shell holds the lock strands the session on purpose.** Use
`desktop/quickshell-restart`, which asks `ipc call lock status` and refuses on `secure` or
`requested`. A bare `systemctl --user restart quickshell.service` drops the `ext-session-lock`
client while the compositor still holds the lock, and the recovery above then has to clean up
after a self-inflicted wound.

🚨 **Constructing `NotificationServer` is what claims `org.freedesktop.Notifications`**, and a
bus name has exactly one owner. There is no "advertise nothing" configuration — the only way
not to own notifications is not to construct the server, which is why it sits behind a
`Loader { active: Config.notificationsOwned }`. A second daemon installed beside it would race
for the name at login.

🚨 **A notification is NOT tracked by default — the handler must set `tracked = true`.**
`isTracked()` reads `mCloseReason == 0`, which looks like "tracked unless closed", but the
member is initialised to `NotificationCloseReason::Dismissed`. `server.cpp` then DELETES the
notification the instant the `notification` signal returns if it is still untracked. Reading
the getter's body alone gives the opposite answer; the member's initialiser is the fact.

Missed, popups still appear and then turn into `null`s while the centre stays empty; the only log
symptom is `TypeError: Cannot read property 'hints' of null`. Implement `transient` by filtering it
out of history, never by `tracked = false`.

**`NotificationServer.extraHints` does not gate `hints`.** It only extends the advertised
`GetCapabilities` list; every hint a client sends arrives in `Notification.hints` regardless.
That is how `x-canonical-monitor` (sent by `ui_notify_focused` in `core/gum-ui.sh`) routes a
popup to a monitor without being declared.

**`keepOnReload` covers a RELOAD, not a restart.** Notifications survive a config reload and
come back flagged `lastGeneration`; a fresh process starts empty. That matches swaync, which
also loses history when its daemon restarts, so no disk persistence exists here.

🚨 **`chezmoi apply` does not reliably reload a running Quickshell.** Verified 2026-09-02: files on
disk correct, the log said *"Configuration Loaded"*, the live generation was still the old one
(`ipc show` had no `overview`, `hyprctl layers` no dock). The watcher compares CONTENT, not mtime
(`touch` is not a reload), and chezmoi's temp-and-rename replace does not survive a per-file watch —
so the watcher is **off in the deployed shell** (`QS_DISABLE_FILE_WATCHER=1` in
`quickshell.service`): a reload must never read a half-written tree.

So an apply that changes this tree ends with **`desktop/quickshell-restart`** (the lock-guarded
wrapper around `systemctl --user restart quickshell.service`), the only reload path. Verify with
`quickshell -c dotfiles ipc show` or `hyprctl layers`, never by looking at the files.

🚨 **Nothing else may launch the shell.** A bare `quickshell -c dotfiles` is unsupervised, and a
second one racing the unit is worse than none. `desktop/quickshell-toggle` starts the unit
(`reset-failed` first, since a shell that exhausted `StartLimitBurst` refuses `start` at exactly
the moment the user has no bar left to ask with). `quickshell -c dotfiles kill` is a *restart* now,
not a stop — `Restart=always` brings it back in 2s, because a clean exit still leaves the desktop
with no bar, no launcher and no notification daemon.

Quickshell re-execs itself from its signal handlers, so an ordinary segfault never reaches systemd;
the unit covers what that cannot: Qt `_exit()` on a lost Wayland connection, a crash within 10s of
launch, `SIGKILL`, and a QML tree that fails to load.

🚨 **`execDetached` detaches the PROCESS, not the CGROUP.** Everything the shell spawns stays in
`quickshell.service`'s cgroup, and a unit restart kills the whole control group — so every app
opened from the launcher died on each `desktop/quickshell-restart` (measured 2026-10-01: firefox
listed under `systemd-cgls --user-unit quickshell.service`). Every `Quickshell.execDetached`
therefore takes `Config.detach` as its prefix (a `systemd-run --user --scope` into
`app-graphical.slice`), and a `DesktopEntry` launches as
`execDetached({ command: Config.detach.concat(entry.command), workingDirectory })`, never
`.execute()`. Audit: `grep -rn 'execDetached\|\.execute()'` must show `Config.detach` on every
hit. `Process` children are the shell's own readers and are meant to die with it.

🚨 **`ScreencopyView` needs a RENDERED window, and `captureFrame()` needs a ready context.**
Both failures are quiet. Put the view anywhere that is not actually being painted — inside a
bare `Item` under `ShellRoot`, say — and no recording context is ever created, so `hasContent`
stays false forever with no error. Call `captureFrame()` from `Component.onCompleted` and it
logs *"Cannot capture frame, as no recording context is ready"* and captures nothing; even a
1.5s timer was too early here. `live: true` sidesteps the timing entirely, and scoping it to
the surface's own visibility means nothing is captured at rest.

**Hyprland DOES capture windows on inactive workspaces.** Verified 2026-09-02: all six
toplevels reported `hasContent` with `sourceSize` `1900x948` while only one workspace was
active. `captureSource` takes a `Quickshell.Wayland.Toplevel` — reach it as
`hyprlandToplevel.wayland` — over `hyprland-toplevel-export-v1`, and a `ShellScreen` for a whole
monitor.

🚨 **A window's `visible` does not reach its content item.** `live: root.visible` inside a
`PanelWindow` reads the *item's* visibility, so a capture bound to it runs for the life of the
session. Pass the window's visibility down as an explicit property instead.

🚨 **A hover-driven reveal needs a `HoverHandler`, never a `MouseArea`.** A hover-enabled
`MouseArea` reports hover only while nothing above it has it, so **every child `MouseArea`
steals it** — and `z: -1` does not help, because stacking decides who *wins* the event, not
who else gets to see it. The dock's tiles each own a `MouseArea` for their click, so the
pointer reaching a tile set `containsMouse` false and the dock retracted out from under the
click it was about to receive. Pointer handlers are passive and run in parallel with a child's
grab; quickshell's own `ui/ReloadPopup.qml:126` uses one for exactly this. Symptom to
recognise: the surface is *unclickable* and flickers worst wherever its controls are densest.

🚨 **The reveal mask is the UNION of the hot edge and the panel's LIVE rect.** `Region`'s default
property is `regions` and `Intersection` defaults to `Combine`, so a nested `Region` unions in:

```qml
mask: Region {
    item: hotEdge
    Region { item: panel }
}
```

A single rect fails three ways, each dropping the pointer out of the input region and oscillating:
the panel **alone** (it has not arrived while it slides), one **static centred** band (an off-centre
entry is outside it), or a **seam** between the panel's resting edge and the hot edge. Grow the hot
edge to meet the panel while revealed and keep it full-width. Add a hide grace anyway —
`Config.dockHideDelayMs` (220): `revealed: hoverHandler.hovered || hideDelay.running`. Drive the
pointer with `hyprctl dispatch 'hl.dsp.cursor.move({ x = …, y = … })'` (a **table** argument;
positional `move(x, y)` errors).

🚨 **`forceActiveFocus()` from a child's `Component.onCompleted` is SILENTLY DROPPED.** The
child completes before its window exists: `ProxyWindowBase::completeWindow()` reparents the content
item into the real `QQuickWindow` at `window/proxywindow.cpp:242`, and that runs when the *surface*
completes — after every child of it. An item with no window cannot take focus and nothing reports
the failure. The surface simply comes up with its field unfocused, so the first thing typed goes
nowhere; on the lock screen that is the password. Defer every focus claim through
`Qt.callLater(claimFocus)` — one function, called from each claim edge, never `forceActiveFocus()`
inline. Found 2026-09-13 on `lock/LockContent.qml`; omarchy defers the same call for the same
reason (`shell/plugins/lock/LockView.qml`).

🚨 **`escape` is an ILLEGAL METHOD NAME and qmllint does not catch it.** A
`function escape(): void {…}` on a `PanelWindow` renders, formats and lints clean —
`mise run lint:qml` passed on it — and then the engine refuses the whole file at LOAD time with
*"Illegal method name"*, taking the surface with it (`Type Launcher unavailable`). The only thing
that finds it is actually running the tree. Found 2026-09-08 on the launcher's Esc handler, now
`clearOrClose()`.

🚨 **`DesktopEntries.byId()` is a function call, not a dependency.** A binding written
`readonly property var entry: DesktopEntries.byId(id)` never re-evaluates when the manager
rescans after a `.desktop` file changes (`desktopentry.cpp` `handleFileChanges`). Resolve off
the model instead — `DesktopEntries.applications.values.find(e => e.id === id)` — which is
reactive for free. `heuristicLookup()` is also weaker than it sounds: it is `byId()` and then
an exact `StartupWMClass` match, nothing more, so `ghostty` does **not** find
`com.mitchellh.ghostty.desktop` and `org.xfce.thunar` does not find `thunar.desktop`.

🚨 **`HyprlandToplevel.lastIpcObject` is EMPTY for every window opened after the shell
started.** It is only filled by a `clients` fetch — `connection.cpp:92` at startup,
`refreshToplevels()`, and the `configreloaded` event. The `openwindow` handler parses the class
out of the event (`connection.cpp:459`) and then throws it away: `updateInitial()` takes address,
title and workspace only and never touches `bLastIpcObject`. So `lastIpcObject.class` reads `""`
for the rest of the session and a glyph keyed off it draws its fallback — which looked exactly
like "the bar is right after a reload and wrong after a boot". Read `toplevel.wayland.appId`
instead: same string (verified against `hyprctl clients` for firefox, ghostty and slack),
reactive, no IPC round trip, though it arrives a beat after the window. Measured 2026-09-11 with
a bare probe config — a window opened while it ran reported `class=""`, `appId=com.mitchellh.ghostty`.
Geometry (`at`/`size`) has no such substitute and is stale for the same reason.

🚨 **`HyprlandMonitor.width`/`height` are PHYSICAL pixels; window `at`/`size` are LOGICAL.**
`ipc/monitor.cpp:41` copies them verbatim out of the `hyprctl monitors` JSON, so the trap
`hyprland-lua.md` records for shell scripts applies identically in QML. Anything projecting a
window into a monitor-shaped space divides by `.scale` first, and subtracts the monitor's own
logical `x`/`y` origin before scaling. Verified against a live layout: at scale 1 the fractions
match `hyprctl clients` exactly — which is also why a scale-1 machine cannot catch this.

**A child sized off a positioner is a binding loop.** `height: someRow.height` inside a
`Repeater` in that `Row` deadlocks: the Row sizes itself from the very children reading it
back. Derive the size from the data instead — the overview's slots take their height from the
monitor's aspect.

**Hyprland's models populate lazily and asynchronously.** `Hyprland.workspaces` and
`.monitors` are both empty for the first ~1s. They fill on their own; `refreshWorkspaces()` is
not needed, but code must not assume data at startup.

**`FileView.watchChanges` only signals** — handle `onFileChanged` with `reload()`. And it
watches the *resolved* path, so a symlink swap (as `theme switch` does to `themes/current`)
never fires. That is why theming is driven by an explicit IPC call.

---

## IPC

Handlers live in `shell.qml`. Current targets: `theme.reload()`, `idle.refresh()`,
`bar.toggle()`, `launcher.toggle()`, `power.toggle()`, `keybindings.toggle()`, `notifications.toggle()`,
`notifications.dnd()`, `clipboard.toggle()`, `overview.toggle()`,
`popover.toggle(id)`, `lock.lock()`, `lock.isLocked()`, `lock.status()`. List them live with
`quickshell ipc --pid <pid> show`.

🚨 **The menu picker is deliberately NOT here.** A dmenu call must BLOCK until the user chooses,
and an IPC handler returns immediately — so `MenuServer.qml` runs a `SocketServer` at
`$XDG_RUNTIME_DIR/quickshell-menu.sock` instead, one connection per menu. See
`quickshell/CLAUDE.md` for the protocol and the four traps in the wrapper
(`nc -N`, the stripped trailing newline, `[ -S ]` against a stale socket, and queueing).

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

🚨 **An IPC function with no type annotations is never registered.** `ipchandler.hpp:130-131`:
*"Argument and return types must be explicitly specified or they will not be registered."* So
`function toggle() {…}` registers nothing while `function toggle(): void {…}` registers, and
with the exit-0 behaviour above the failure is silent from both ends — the handler is simply
absent from `ipc show`. Every handler in `shell.qml` is annotated today (`: void` or `: string`);
an unannotated one added later would look like a broken target rather than a syntax problem.

Callers today: `desktop/theme-switcher` (theme reload), `desktop/idle-toggle{,-nolock}` (idle
refresh), and the `SUPER+B` binding in `hypr/conf.d/quickshell.{lua,conf}`.

**The OSD is deliberately not on IPC.** Both its sources already notify (Pipewire on the sink,
`FileView.watchChanges` on the sysfs backlight), so a keybinding or a script hook would only
add a second, less reliable trigger for a change the shell can already see.

---

## Validation

```bash
mise run lint:qml             # render whole tree, qmllint -W 0, qmlformat diff check
mise run format:qml           # qmlformat --inplace, *.qml only (a template has nothing to write back to)
mise run lint:theme-contrast  # WCAG pairs across all 8 colorsets (part of lint)
```

Both are wired into `[tasks.lint]`/`[tasks.format]` and into pre-commit via
`.mise/tasks/lint/qml-staged.sh`.

`mise run lint:qml-rules` (part of `lint`) mechanizes the traps above that qmllint cannot see:
`import "root:/"`, `function escape(`, an `execDetached` without `Config.detach`, an `IpcHandler`
function with no return type, and an empty `""` in an array literal. It takes file arguments; a
PostToolUse hook runs it plus the `qmlformat` diff on every QML file Claude edits.

**The tree is linted as one rendered unit**, not per file: `shell.qml` references the `Config`
singleton, which exists in source only as `Config.qml.tmpl`. Formatting is checked against
**source** `*.qml` only.

No `.qmlformat.ini` exists, so QML formats to **4 spaces** — unlike the Lua tree's tabs.

**Limitation, shared with `lint:lua-tmpl`**: only this machine's chassis is rendered.
`Config.qml.tmpl`'s `isLaptop` is a value rather than a branch, which is deliberate — it keeps
chassis differences out of the template layer entirely (`.claude/rules/chezmoi-chassis.md`).

`mise run qml:smoke` does that for you: it renders the tree, patches the scratch copy so it contends
for nothing singular (notification bus name, polkit agent, session lock, menu socket), runs it under
`timeout` beside the live shell, and fails on `Illegal method name`, `Type … unavailable`, `ERROR`
or a missing `Configuration Loaded`. Manual — it needs a Wayland session and flashes a second bar
for ~8s. Verified to fail on an injected `function escape()` and pass on the real tree.

For other runtime checks, render the tree and run it directly rather than deploying:

```bash
quickshell -p /path/to/rendered/tree    # loads without touching ~/.config
```

A `console.log` in a `Timer` is the fastest way to check a live binding; QML binding errors and
D-Bus failures both surface in that output.
