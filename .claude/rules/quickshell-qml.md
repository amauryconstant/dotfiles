# Quickshell QML Configuration Reference

**Location**: `private_dot_config/quickshell/dotfiles/`
**Runs as**: `quickshell -c dotfiles` (never a bare `~/.config/quickshell/shell.qml` — that
disables subdirectory discovery for every other config, including voxtype's)
**Gated by**: `features.quickshell_shell` via `.chezmoiignore`

**See**: Root `CLAUDE.md` for core standards
**See**: `_research/QUICKSHELL_SURFACE_INVENTORY.md` for what exists, what does not, and the
reading order for every Quickshell document. `_plans/archive/QUICKSHELL_SHELL.md` is the frozen
build record — history, not a roadmap
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
| `dotfiles/bar/widgets/*.qml` | One file per bar widget |
| `dotfiles/bar/popovers/*.qml` | The seven payloads — one per bar widget that owns one |
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
| `No type found for property "edges"` | `PopupAnchor.edges`/`gravity` are `Edges::Flags`, unresolvable across the module split. Suppress inline with `missing-type` — the defaults are **not** usable, see below |

---

## Runtime behaviours that bite

🚨 **`Text` defaults to `Text.AutoText`, and `AutoText` SELF-PROMOTES to rich text.** Qt runs
`Qt.mightBeRichText()` on the string and switches format by itself — no `StyledText`, no opt-in.
Rich text then **fetches `<img src="http://…">`**, so any `Text` rendering a string this repo did
not author is an unauthenticated outbound GET waiting for a sender to notice. The reachable path
here was the shared `BarWidget` label, which carries the **window title** and the **MPRIS track
title**: a web page setting `document.title = '<img src="http://…">'` makes the bar beacon.
Omarchy shipped the same class and patched it in v4.0.2 (`shell/plugins/notifications/`), after
its own `/<img[^>]*>/gi` strip turned out to be bypassable — `<im<img src="decoy">g src="beacon">`
is *rewritten into* a live tag by a substring strip. Do not strip; declare the format.

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

🚨 **The compositor ADDS the margin, so the zone is not the bar's bottom edge.** An
exclusive zone is measured from the surface's own edge, so Hyprland reserves
`margins.top + exclusiveZone`. Verified live 2026-09-10: `margins.top` 4 with a zone of 44
gave `hyprctl monitors` `reserved=[0,48,0,0]` — four PAST the bar's own bottom edge, not at
it. `barHeight` alone is what reserves exactly the bottom edge and leaves `gaps_out` as the
only gap below the bar.

This tree deliberately does **not** do that: `exclusiveZone` is `barHeight + barInset`, so
the inset is counted twice and the gap under the bar is `barInset + gaps_out` (8) against
the 4 its side edges get. Both were rendered and compared on 2026-09-10 and the asymmetric
one was chosen — the bar reads as separated from the windows rather than as one more tile.
So a symmetric-looking `barHeight` here is a *change*, not a fix. See `bar/Bar.qml`.

Check it against the compositor, never against the QML: `hyprctl monitors -j` for `reserved`,
`hyprctl layers` for the bar's own `xywh`, and `hyprctl clients -j` for the first tiled
window's `at` — which is inside the 2px border, so it reads `gaps_out + border_size`.

🚨 **`barInset` and `gaps_out` are one number in two files** — `Config.qml.tmpl` and
`hypr/conf/general.lua` (plus its `.conf` twin). The inset is what aligns the bar's side
edges with every window's, and per the paragraph above the gap under the bar is
`barInset + gaps_out`, so neither the top gap nor the bottom one can be changed from the
QML side alone. Both are 4 today; `gaps_in` is half that, keeping the screen-edge gap equal
to the window-to-window gap.

🚨 **`PopupWindow.grabFocus` does not work on a layer-shell parent.** It sets `Qt::Popup`
(`popupwindow.cpp:63`), which makes Qt request an *xdg_popup* grab — and a popup parented to a
layer surface is not an xdg_popup. Measured 2026-09-10 with `quickshell -p`: *"Failed to create
grabbing popup. Ensure popup has a transientParent set and that parent window has received
input"*, then *"Cannot attach popup … as the popup is not an xdg_popup"*, and the popup silently
sets itself back to invisible. So a bar popup gets **no** click-outside dismissal from Qt.
`HyprlandFocusGrab` (`Quickshell.Hyprland`, re-exported from `_FocusGrab`) is what works: keys
reach a focused `Item` inside the popup and `cleared` fires on an outside click — but it takes
the keyboard away from the focused application for as long as it is active, and it survives a
workspace switch, so it is only correct for a surface the user deliberately summoned.

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
`defaults.cpp` `onMetadataProperty` reads `default.audio.sink` out of the metadata as a *name*
string and hands it to `registry->findNodeByName()` — first match, no id, no tiebreak. Every
suspend/resume on this laptop leaks one orphaned `Audio/Sink` node whose `device.id` points at a
device that no longer exists, all sharing the name `alsa_output.pci-…-analog-stereo`; after 17
resumes there were 18. Quickshell bound a frozen one, so `onVolumeChanged` never fired and the OSD
and `AudioWidget` tracked a node nothing could change — while `pamixer` was correctly moving the
real sink all along. The symptom reads as *"the volume keys do nothing"*, and every layer below QML
tests clean. Diagnose with `wpctl status` (the live default carries `*`) or
`pw-dump | jq '.[] | select(.info.props["media.class"]=="Audio/Sink")'`; `systemctl --user restart
wireplumber` destroys the orphans. The leak is swept on every resume by `after_sleep_cmd` in
`.chezmoitemplates/hypridle_general`.

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
`Loader { active: Config.polkitOwned }`. With the flag off, `hypr/conf.d/polkit-gnome.{lua,conf}`
deploys and polkit-gnome keeps the session. `path` is deliberately unset — the binary's own
default (`/org/quickshell/Polkit`) is as good as any, and naming one only invites drift.

⚠️ **A failure does NOT end the flow.** Quickshell starts a fresh PAM session automatically and
emits `authenticationFailed` on the flow, so the dialog stays up and only the field is cleared.
Nothing in the QML may destroy the flow on a failure — cancelling is `cancelAuthenticationRequest()`
and nothing else.

🚨 **"Is the compositor locked" is NOT "is the lock stranded", and acting on the first
displaces a live lock screen.** `desktop/session-locked` is equally true while hyprlock is
running, and `misc:allow_session_lock_restore` means a second client is now *accepted* rather
than refused — which is the whole reason `immediate-lock`'s guard had to become a `flock`.
Measured 2026-09-12: `lock/LockScreen.qml` ran `session-locked` at startup, got 0 while
hypridle's hyprlock was up, concluded orphan, and took a second lock on top of a live one. The
probe is `desktop/session-lock-stranded` (locked **and** the lock file free); the QML rules
*itself* out first with `locked || lockRequested`, because the in-process locker takes no lock
file and so cannot be seen by one.

⚠️ **A restart while the shell holds the lock strands the session on purpose.** Use
`desktop/quickshell-restart`, which asks `ipc call lock status` and refuses on `secure` or
`requested`. A bare `systemctl --user restart quickshell.service` drops the `ext-session-lock`
client while the compositor still holds the lock, and the recovery above then has to clean up
after a self-inflicted wound.

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

🚨 **`chezmoi apply` does not reliably reload a running Quickshell.** Verified 2026-09-02
after Phase 5.5: the files on disk were correct, the shell's own log said
*"Reloading configuration… Configuration Loaded"* — and the live generation was still the
pre-apply one. `ipc show` listed no `overview` target and `hyprctl layers` showed no dock
surface, while the same tree run with `quickshell -p` mapped it immediately at `1920x74 @0,1006`
with no errors.

Two facts behind it, both measured:

- **The watcher compares CONTENT, not mtime.** `touch shell.qml` produces no reload at all;
  appending a byte produces one. So `touch` is not a reload command.
- `EngineGeneration::setWatchingFiles` (`generation.cpp:170`) adds a `QFileSystemWatcher` path
  for every scanned file *and* its directory. chezmoi replaces files by writing a temp and
  renaming over the target, which is exactly the pattern a per-file watch does not survive —
  and the one directory-triggered reload can land mid-apply, re-reading files that have not
  been replaced yet. (The mid-apply ordering is inference; the stale generation is not.)

The watcher is therefore **off in the deployed shell**: `quickshell.service` sets
`Environment=QS_DISABLE_FILE_WATCHER=1` (`qmlglobal.cpp:67`), the same call Omarchy makes in
`bin/omarchy-launch-shell` for the same reason — an upgrade rewriting the tree must not reload
against a half-written one. The facts above are why it is off, not a behaviour to work around.

So an apply that changes this tree ends with **`desktop/quickshell-restart`** (which wraps
`systemctl --user restart quickshell.service` in the lock guard below), the only reload path. Never verify by looking at the files — verify with
`quickshell -c dotfiles ipc show` (is the new target there?) or `hyprctl layers`.

🚨 **Nothing else may launch the shell.** A bare `quickshell -c dotfiles` is unsupervised, and a
second one racing the unit is worse than none. `desktop/quickshell-toggle` starts the unit
(`reset-failed` first, since a shell that exhausted `StartLimitBurst` refuses `start` at exactly
the moment the user has no bar left to ask with). `quickshell -c dotfiles kill` is a *restart* now,
not a stop — `Restart=always` brings it back in 2s, because a clean exit still leaves the desktop
with no bar, no launcher and no notification daemon.

Quickshell also re-execs **itself** from its signal handlers (`src/crash/handler.cpp:148-156`), so
an ordinary segfault never reaches systemd. The unit exists for what that cannot cover: Qt leaving
through `_exit()` on a lost Wayland connection, a crash within 10s of launch (its own crash-loop
guard calls `exit(-1)` instead of relaunching, `src/launch/main.cpp:68`), `SIGKILL`, and a QML tree
that fails to load at all.

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

🚨 **A modal scrim cannot be built from a background token.** `GROUND_FLOAT` measures 0.71–0.96
luminance in all four light themes, so an 86% scrim over it renders near-white — and
`INK_CONTRAST_CANDIDATE` inverts per theme (0.006 in mocha, 0.88 in gruvbox-dark). A scrim is a *shade*,
not a theme colour: `Theme.scrim` is a deliberate literal, under the same exemption as
`Theme.qml`'s fallbacks.

🚨 **Then everything drawn on it needs `Theme.fgOnScrim`.** The scrim is dark in every theme,
so a light theme's own foregrounds land on it at **1.81** (gruvbox-light) and 2.63 (latte) and
are simply not there. Same computed pick as `inkOnSignal`, better of `INK_PRIMARY` / `GROUND_BASE`;
worst case across all 8 becomes 6.64. `mise run lint:theme-contrast` checks both, in their own
section — the scrim is not a colorset token, so the `PAIRS` table cannot express it.

🚨 **A hover-driven reveal needs a `HoverHandler`, never a `MouseArea`.** A hover-enabled
`MouseArea` reports hover only while nothing above it has it, so **every child `MouseArea`
steals it** — and `z: -1` does not help, because stacking decides who *wins* the event, not
who else gets to see it. The dock's tiles each own a `MouseArea` for their click, so the
pointer reaching a tile set `containsMouse` false and the dock retracted out from under the
click it was about to receive. Pointer handlers are passive and run in parallel with a child's
grab; quickshell's own `ui/ReloadPopup.qml:126` uses one for exactly this. Symptom to
recognise: the surface is *unclickable* and flickers worst wherever its controls are densest.

🚨 **The reveal mask is the UNION of the hot edge and the panel's LIVE rect.** `regions` is
`Region`'s default property (`region.hpp:109`) and `Intersection` defaults to `Combine`
(`region.hpp:144`), so a nested `Region` unions in:

```qml
mask: Region {
    item: hotEdge
    Region { item: panel }
}
```

Three ways a single rect gets this wrong, all of which drop the pointer out of the input region
and oscillate: binding it to the panel **alone** (the panel has not arrived yet while it slides),
pinning it to one **static centred** band (an off-centre entry is outside it), and leaving a
**seam** between the panel's resting edge and the hot edge (crossing it loses hover). Grow the
hot edge to meet the panel while revealed, and keep it full-width so the edge can be entered
anywhere. caelestia's `modules/drawers/Regions.qml` sizes its regions off the live animation
(`panel.height * (1 - offsetScale) + borderThickness`) for the same reason — with slack.

**Add a hide grace period anyway.** caelestia gets away with none because its hit-testing is
exhaustive coordinate math in one `MouseArea`; anything built from real child `MouseArea`s
wants the slack. `Config.dockHideDelayMs` (220) holds `revealed` true through a momentary loss:
`revealed: hoverHandler.hovered || hideDelay.running`.

Verified by driving the pointer with `hyprctl dispatch 'hl.dsp.cursor.move({ x = …, y = … })'`
(note the **table** argument — a positional `move(x, y)` errors) and logging the state: hover
held continuously from a bottom-centre entry, onto a tile, and across a far-left entry at
x=120 against a panel spanning only x≈815–1104.

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

## Geometry and the accent rule

Both originate in Amendment A of the frozen `_plans/archive/QUICKSHELL_SHELL.md` (which cites a
design set that no longer exists), and both live in exactly one place here.

**Geometry** is the scale in `Config.qml.tmpl`, and a widget never writes a radius, a
spacing, a font size or an animation duration of its own.

🚨 **There are exactly THREE radii, and radii are NOT on the density ramp**: `radiusChip` 8
for chips and rows, `radiusPanel` 12 for surfaces, `radiusPill` 999. The four-step ramp this
tree used to carry (plus a fifth at 14 on the power tiles and a sixth at 6 on tooltips) was
inventing distinctions no surface needs — a tooltip and a chip are the same kind of thing.
Spacing is `gap` 8 and `padTight`/`pad`/`padLoose` 12/16/24; `rowH` 34 is a list row and
`launcherRowHeight` 48 is a two-line one. `barHeight` 40, `barInset` 4, `chipSize` 26,
`pillHeight` 24.

🚨 **`hitMin` 32 does not scale with anything.** It is a pointer fact, not a density
preference: a widget whose paint is 26 still claims 32 of pointer space. `BarWidget`'s
`MouseArea` floors at it, which costs no layout because chips sit `gap` apart and two 32px
areas on adjacent 26px chips are 34 apart.

**Type is six steps and four glyph sizes, and nothing outside them is drawn**: `fontMeta` 11,
`fontBody` 12, `fontTitle` 14, `fontDisplay` 20 (the OSD readout, its only use), with glyphs
at `glyphRow` 13, `glyphBar` 16, `glyphOsd` 28, `glyphTile` 32. QML's `font.pixelSize` is an
**integer**, so the design's half-pixel steps round here — meta 10.5 → 11, title 13.5 → 14.
That is a QML constraint, not a reading of the design.

**Motion is three durations**: `motionFast` 120 (hover and press tints, meter fills),
`motionSlow` 180 (reflow, pill travel, OSD fade-out), `motionEnter` 220 (arrival). Never
animated: text replacing text, the focus ring, and anything whose only change is a colour role
— which is why a live theme switch repaints with no transition at all.

🚨 **Truncation is by PIXELS, never by character count.** `titleMaxLength` and
`mediaMaxLength` are gone: `WWWW…` is about three times the width of `iiii…`, so a character
cap does not bound the bar. Set `labelMaxWidth` on `BarWidget` and let `Text.elide` do it —
`labelElideMode: Text.ElideMiddle` for a path, whose identifying half is its tail.

**The design publishes three density columns** (compact 12 / default 13 / roomy 14). Only the
default is implemented: the one thing that could select a column is the system menu, which is
not built, and two unreachable columns are dead configuration.

**The accent rule** — *one accent marks the focused thing, everything else neutral, semantic
colours only for state* — is enforced by `BarWidget.iconColor`. A widget overrides it only
for a genuine state (muted, disconnected, inhibited, low battery); at rest every widget is
the same colour. Set `icon`/`label` on `BarWidget` rather than declaring your own `Text`, and
the rule applies for free.

🚨 **`iconColor`/`labelColor` are not one fixed rest colour — they default to `restColor`,
which follows `grounded`.** A widget colouring for a state ends its ternary on `root.restColor`;
ending it on a flat `Theme.inkSecondary` pins the ungrounded colour onto a lit ground. That was
six widgets' worth of defect, found by the reviewer below and fixed 2026-09-01.
`themes/CLAUDE.md` bans the second ink on an elevated ground outright, and a hovered chip, a
pill and the launcher tint are all elevated surfaces. So the default is `inkSecondary` at rest
and `inkPrimary` the moment a ground appears. Anything that hardcodes one of the two
reintroduces the banned pair on half the widget's states.

🚨 **`signalError` is the ONLY semantic colour a bar widget may take.** Measured across all
eight colorsets, `SIGNAL_WARN` lands at **2.05** in rose-pine-dawn and 2.19 in
gruvbox-light, and `SIGNAL_INFO` at **2.80–3.31** in the light sets — under the 3:1 a graphic
owes, so a state drawn in either was *less* visible than the same state drawn neutral. Only
`SIGNAL_ERROR` clears 3:1 everywhere (worst 3.25, on `GROUND_BASE`). The battery's low band,
the idle inhibitor's second state, the unread bell and three dictation states all moved onto
their own **glyph**, which is what they should always have carried. `signalWarn`, `signalInfo`
and `signalOk` are bound in `Theme.qml` and drawn nowhere.

`labelColor` is split from `iconColor` so the glyph can carry a state while the number it
annotates stays readable — the battery pill is the case that needs it. `monoLabel: true`
puts a number in `terminalFont`: digits only line up fixed-pitch, and a proportional face
reflows the bar every time the value changes width.

`pill: true` gives a widget its own permanent ground. **Exactly two widgets have it** — the
battery and the meter — because charge and load are the two numbers that have to be readable
without a hover. The design draws both grounded; what it forbids is a *second meter* beside
the first, not a second ground.
`tinted: true` is the same idea without the pill radius, and **only the launcher chip has
it**: an accent ground at rest is the single fixed anchor the bar is allowed.
Everything else is icon-only, with its number in the tooltip.

`BarSeparator` binds to the group that **follows** it (`group: gPower`), so a group that
collapses to zero width on a desktop takes its leading hairline with it instead of leaving a
stray rule in the bar. **The hairline is `Theme.edge`** — bar border, separators, the gap dot
and every panel border alike. `edge` resolves to `groundRaised`; use the role name, because a
`border.color` and a ground are different jobs even where the value coincides.

🚨 **This was the fill-inert tier until 2026-09-01, on a mis-mapping.** Amendment A read the canvas's
`#313244` as "`surface0`, which is what `FILL_INERT` maps to". It does not: in
`themes/catppuccin-mocha/colors.sh`, `GROUND_RAISED` is `#313244` and `FILL_INERT` is
`#45475a`. The correction moved the hairline one tier the wrong way in all 8 themes. See the
hex table below — and never map a canvas colour by its LABEL.

### Contrast is measured, not eyeballed — `mise run lint:theme-contrast`

`themes/CLAUDE.md` states the rules and says outright that QML gets no automatic
enforcement. `.mise/tasks/lint/theme-contrast.py` is that enforcement: it reads all **8**
colorsets (not just the one symlinked at `themes/current`) and measures the pairs this tree
actually renders. **Manual-only**, like `lint:hypr-lua` — its pair table is harvested by hand,
so it goes stale silently when a widget changes a colour. Run it after touching any colour here.

🚨 **There is no `INHERENT` escape hatch any more.** It used to excuse five accent-as-text pairs
on the grounds that Waybar renders the same ratios — parity with an older tool is not a reason to
ship failing text, as design page 13 says outright. The rules changed instead, so those pairs are
no longer drawn rather than being excused. The script also carries a `BANNED` list, measured and
reported but asserted absent from the tree: a rule keeps its evidence, or the next reader
reintroduces what it forbids.

🚨 **Harvest by parenting, never by grepping colour lines.** Most `Theme.groundRaised` uses in
this tree are 1px hairlines and borders, not grounds. Reading `color: Theme.groundRaised` two
lines above an ink token and calling it a violation invents failures that are not on
screen — the 2026-09-01 pass started with five such suspects in `NotificationCentre`,
`PowerMenu` and `Launcher` and **all five were hairlines**.

Two thresholds, per WCAG 2.1: **4.5:1 for text, 3:1 for UI components and graphics** — an
outline, a progress fill. Getting this wrong in the strict direction is how a legitimate
outline gets "fixed" into a `fgPrimary` that competes with the button beside it.

What the first run found, all four fixed 2026-09-01 and all four invisible to the eye on the
one theme that happened to be applied:

| Site | Was | Ratio | Now |
|---|---|---|---|
| OSD progress fill on its track | `accentPrimary` on `bgTertiary` | **1.38** in solarized-light | track is `bgSecondary` |
| OSD dimmed fill | `fgMuted` on `bgTertiary` | **1.00** in both solarized themes — `INK_MUTED` *equals* `FILL_INERT` there | `fgSecondary` on `bgSecondary` |
| PowerMenu avatar initial | `accentPrimary` on `bgTertiary` | **1.46** solarized-dark | `fgPrimary` on `bgSecondary` |
| NotificationCard action outlines | `fgMuted` on `bgOverlay` | **2.18** solarized-light | `fgSecondary` |

The pattern in three of the four: **`fillInert` (`FILL_INERT`) is the trap tier**, which is
exactly why the role system makes it a *material* rather than a ground and forbids text on it
outright. Prefer `groundRaised` for any ground that has to carry something on top of it. The
2026-09-08 pass found a fourth instance the first one missed: the occupied workspace pill, at
**1.67** in solarized-light.

### `Theme.inkOnSignal` — text on an accent fill

🚨 **No fixed token works across the 8 themes.** `INK_CONTRAST_CANDIDATE` is the one named for the job and
lands at **1.49:1** on gruvbox-dark's own accent — the focused workspace number, the most-read
thing in the bar, unreadable in that theme. `GROUND_BASE` is better there (8.69) and worse in
gruvbox-light (2.19). So `Theme.qml` computes the pick per theme from WCAG relative luminance,
and the worst case across all 8 goes 1.49 → **3.47** (rose-pine-dawn).

🚨 **Design page 01 says this is a fixed binding to `GROUND_BASE`; pages 04 and 07 say it is
computed. Keep it computed** — the computation picks whichever of `INK_CONTRAST_CANDIDATE` /
`GROUND_BASE` contrasts more, and `GROUND_BASE` is one of its two candidates, so its result is ≥
the fixed binding in every theme and can never be worse. Page 13 quotes 4.34 (latte) as the worst case for the bound
value; that is not the worst case, rose-pine-dawn is.

Use `Theme.inkOnSignal` for anything drawn **on** a `signalFocus` fill — the focused workspace
pill, the notification count badge, an active DND chip, the launcher's text selection. A bare
`Theme.inkContrastCandidate` at such a site is the defect; that property exists only to be one
of the two candidates and is never assigned to a `color:`.

### Reading the design source, not the transcription

The canvas lives in a Claude Design project (`1d494341-deaa-47cb-ac39-32ccb9c23862`) and is
readable through the `DesignSync` MCP tool: `list_files`, then `get_file`.

🚨 **The project was REWRITTEN on 2026-09-08 and every earlier artboard id is dead.** It is
now **fourteen pages** — `Shell-00-Index`, `Shell-01-Colour`, `Shell-02-Geometry`,
`Shell-03-Behaviour`, then one page per surface (`04-Bar`, `05-Launcher`, `06-Popovers`,
`07-Notifications`, `08-OSD`, `09-Session`, `10-Menu`, `11-Clipboard`, `12-Deferred`) and
`Shell-13-Accessibility`. The nine-file set (`Foundations`, `Bar - Dock`, `Composites`,
`Launcher - Menu`, `Panels`, `Session`, `Popovers`, `States`, `Proof`) and every id inside it
— `f-a`, `bar-a`, `pop-g`, `st-b`, `pf-a`, `comp-a`, `comp-b`, `pan-a`, `1a`–`1i` — no longer
resolves. `support.js` beside them is the generated dc-runtime and carries no design content.

Three pages state rules and nothing else does: **01** colour, type and motion; **02**
geometry; **03** behaviour. A surface page states only its own departures from those, so a
number found on a surface page that contradicts a foundation page is a **defect in the
design**, not a local override. There have been four such, all catalogued.

🚨 **Read `_research/QUICKSHELL_DESIGN_AUDIT.md` Part 5 before implementing anything from a
page.** It records where the fourteen-page set contradicts itself, where its numbers are
wrong, and which of this tree's departures are deliberate. Parts 1–4 audit the dead nine-file
set and are kept for their measurements only.

⚠️ **`DesignSync` needs its own authorization.** A session without it fails with *"DesignSync
needs design-system authorization"*; `/design-login` grants it. Nothing in the repo can
substitute — plan on reading the source, not a transcription of it.

**Two surfaces this tree ships have no page in the current set**: the dock and the workspace
overview. Both are dormant (`Config.dockEnabled` / `Config.overviewEnabled` are `false`) and
both were declined in daily use, so their absence is consistent rather than an omission to
correct. They are not deleted, and they are not updated.

### 🚨 Map canvas colours by HEX, never by name

The canvas names three background tiers with Catppuccin-tier names; our colorset has four,
ordered differently. Matching on the name is how the hairline defect above happened. Verified
against `themes/catppuccin-mocha/colors.sh`:

| Canvas hex | Canvas label | **Our token** |
|---|---|---|
| `#1e1e2e` | bg-primary | `GROUND_BASE` |
| `#313244` | bg-secondary | **`GROUND_RAISED`** — hairlines, chip grounds |
| `#45475a` | (unused by the canvas) | `FILL_INERT` |
| `#181825` | bg-tertiary | **`GROUND_FLOAT`** — notification cards, tooltips |
| `#6c7086` | fg-muted | `INK_MUTED` (`#9399b2` here — a different value, same role) |

The same trap bit `Theme.qml`: **nine of its 24 fallbacks were the canvas's Mocha palette
rather than our colorset's** — including `accentPrimary`, mauve on the canvas and blue
(`#89b4fa`) in `colors.sh`. Fixed 2026-09-01. Copy a fallback from `colors.sh`, never from a
mockup.

⚠️ **The canvas's fourth background tier has no single equivalent here.** Amendment A said
`FILL_INERT` and `GROUND_FLOAT` (then `FILL_INERT` and `GROUND_FLOAT`) "are the same value in the
shipped themes (verified in `rose-pine-moon`)" — that generalised from **one** theme. Checked across all eight, they are
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
refresh, beside their existing `pkill -RTMIN+9 waybar`), and the `SUPER+B` binding in
`hypr/conf.d/quickshell.{lua,conf}`.

**The OSD is deliberately not on IPC.** Both its sources already notify (Pipewire on the sink,
`FileView.watchChanges` on the sysfs backlight), so a keybinding or a script hook would only
add a second, less reliable trigger for a change the shell can already see.

---

## Theming

`Theme.qml` parses `~/.config/themes/current/colors.sh` at runtime — the same format-neutral
colorset every other app reads, so there is no ninth per-theme file. A missing key falls back to
hardcoded Catppuccin, which renders wrong colours **with no error**, so the property set must
stay complete, and every fallback is a verbatim copy from `themes/catppuccin-mocha/colors.sh` —
never from a mockup.

🚨 **The names are SEMANTIC ROLES, in the colorset too.** A token names a meaning or it names the
module that happens to spend it, and only the first kind can be reasoned about — a module-named
scheme cannot even *express* the requirement that a CPU readout and a failed service must stay
tellable apart. Until 2026-09-09 `Theme.qml` was a translation layer over module-named keys;
the colorsets were renamed on that date, so a property here now reads **the key of the same
name** and six keys with no consumer were deleted. `waybar.css`, `wofi.css`, `swaync.css.tmpl`,
`btop.theme` and `ghostty.conf` carry their own variables and were never involved.

| Tier | Roles | Colorset keys |
|---|---|---|
| Ground | `groundBase` `groundRaised` `groundFloat` | `GROUND_BASE` `GROUND_RAISED` `GROUND_FLOAT` |
| Material | `fillInert` | `FILL_INERT` — **never accepts text**, 1.67 at worst |
| Ink | `inkPrimary` `inkSecondary` | `INK_PRIMARY` `INK_SECONDARY` |
| Signal | `signalFocus` `signalError` `signalWarn` `signalOk` `signalInfo` | `SIGNAL_FOCUS` `SIGNAL_ERROR` `SIGNAL_WARN` `SIGNAL_OK` `SIGNAL_INFO` |
| Identity | `identity1`…`identity5` | `IDENTITY_1`…`IDENTITY_5` |

🚨 **The colorset parser's character class is `[A-Z0-9_]+`, not `[A-Z_]+`.** `IDENTITY_1`…`_5`
carry a digit, and a class without one drops all five silently into the hardcoded fallback —
wrong colours, no error. The same bug was live in `theme-contrast.py`'s own parser and was
fixed with it.

🚨 **`inkSecondary` is OFFERED, not guaranteed.** Design page 01: the quiet ink is "offered per
ground, per theme, and withdrawn where it fails". `Theme.qml` measures `inkSecondaryOffered`
against `groundBase` and falls back to `inkPrimary` below 4.5:1 — rose-pine-dawn (4.02) and both
Solarized sets, where the palette assigns body text to base0/base00. Withdrawing by measurement
fixes every colorset including any added later; hand-editing two palettes fixes two. Never
assign `inkSecondaryOffered` to a `color:` — like `inkContrastCandidate`, it exists only to be
measured.

**Six values are derived, not read**: `edge` (every hairline), `hover` (one opaque step up the
ground stack), `press` (`inkPrimary` at 8%), `select` (`signalFocus` at 13%, **always** paired
with a glyph or a weight change — the tint alone reaches 1.10–1.98), `focusRing` and
`disabledOpacity`. Plus `inkOnSignal`, `scrim` and `fgOnScrim`, each because no token in the set
works across all 8 themes. `disabledOpacity` is measured against the **live** theme rather than
fixed — the lowest 5% step of `inkSecondary` over `groundBase` still clearing 3:1, which lands
between 0.60 and 0.85 depending on the colorset.

🚨 **`INK_MUTED` is not bound here at all.** It is banned as text (2.48 worst) and fails 3:1 as
an outline, so every former site is `inkSecondary` or the `disabled` derivation. It survives in
the colorset only because `core/gum-ui.sh` and `media/organize-wallpapers-by-color` spend it,
and a terminal is not a lit surface. `INK_CONTRAST_CANDIDATE` (was `INK_CONTRAST_CANDIDATE`) survives as a
property that is read by the `inkOnSignal` computation and never assigned to a `color:`.

**Six keys were deleted outright** in the rename, all with zero consumers: `ACCENT_BORDER`,
`ACCENT_PERFORMANCE`, `ACCENT_MEDIA`, `ACCENT_SECONDARY`, `ACCENT_ALTERNATIVE` and
`ACCENT_URGENT_SECONDARY`. The first four sat too near `signalFocus` or `signalError` to be
identity slots; the last was the battery's 20–30% band, which is `signalWarn`'s job — expressed
by the glyph, since no warn colour clears 3:1. 24 keys became 18.

Contrast rules from `themes/CLAUDE.md` are measured by `mise run lint:theme-contrast` (see
above) across all 8 colorsets; everything that task's hand-harvested pair table does not cover
is still by-hand discipline here. The
module → semantic-colour mapping this bar follows is `waybar/CLAUDE.md`'s table.

The closest thing to enforcement is the `theme-consistency-reviewer` subagent, which takes this
tree as a second review target: literal hex (only `Theme.qml`'s fallbacks are allowed), literal
font name (only `Config.qml.tmpl`, and only through `globals.yaml`), and `Theme.inkSecondary` on
a lit ground. It judges the third against `BarWidget`'s `grounded` ternary, so an override that
pins one fixed rest colour is the finding.

---

## Validation

```bash
mise run lint:qml             # render whole tree, qmllint -W 0, qmlformat diff check
mise run format:qml           # qmlformat --inplace, *.qml only (a template has nothing to write back to)
mise run lint:theme-contrast  # WCAG pairs across all 8 colorsets — MANUAL, see above
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
