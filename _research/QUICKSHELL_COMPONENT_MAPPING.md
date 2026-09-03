# Quickshell Component Mapping

**Purpose**: Document what each existing desktop component does and how it maps to Quickshell QML capabilities
**Created**: June 2026
**Verified against quickshell 0.3.1 source, 2026-09-03**

> **Scope of the 2026-09-03 pass.** The "What X does" halves were spot-checked against the
> legacy configs still in `private_dot_config/{waybar,wofi,swaync,wlogout}/` — every line count
> in this document was wrong, and several behaviours had drifted. The "Quickshell QML mapping"
> and "Feasibility" halves were rewritten against the vendored upstream source
> (`_ai/quickshell/src/`, CMake version 0.3.1, matching the installed `quickshell 0.3.1-1`) and
> the registered types in `/usr/lib/qt6/qml/Quickshell/**/*.qmltypes`.
>
> **Eleven type or property names in the original mapping do not exist.** `PipeWire`,
> `StatusNotifier`, `NetworkManager`, `Clock`, `Mpris.currentPlayer`,
> `PipeWire.defaultAudioPlayback`, `notifServer.notifications`, `Notification.close()`,
> and three uses of `Qt.openUrl()` as a process launcher were all invented or misremembered.
> Every replacement below is cited to source, to a qmltypes file, or to the shipped QML that
> implements it. Four "❌ Hard" verdicts and two "⚠️ Medium" ones are closed out against
> shipped code; **one genuine gap remains** (backlight), and it is the one the original
> document rated as medium rather than hard.

---

## Overview: Current Components & Their Scope

| Component | Type | Lines of Config | Purpose | Status |
|-----------|------|-----------------|---------|--------|
| **Waybar** | Bar | 515 (`config.tmpl`) + 638 (`style.css.tmpl`) | Status bar with modules (workspaces, clock, audio, battery, tray, media, etc.) | ✅ Feature-rich |
| **Wofi** | Launcher | 221 (`config`) + 328 (`style.css.tmpl`) | Application launcher with fuzzy search, icons | ✅ Lightweight |
| **swaync** | Notifications | 60 (`config.json`); `style.css` is a one-line theme import | Notification daemon + persistent history/control panel | ✅ Full-featured |
| **wlogout** | Power menu | 36 (`layout`, 6 buttons) + 101 (`style.css.tmpl`) | Shutdown/reboot/suspend/hibernate/logout/lock buttons with icons | ✅ Simple |

---

## Component-by-Component Mapping

### 1. WAYBAR → Bar in Quickshell

#### What Waybar does (515 config lines)

**Layout**:

- Single horizontal bar, top edge, 30px height (`waybar/config.tmpl:34`)
- Left: workspaces + active window title
- Center: clock
- Right: system tray + network + Bluetooth + backlight (laptop) + battery (laptop) + audio + media + custom indicators + notification bell

**Modules** (14 total, not 19 — the three module arrays list exactly these):

| Module | Displays | Behavior |
|--------|----------|----------|
| `hyprland/workspaces` | Workspace buttons (icons per state) | Click to activate, shows urgent indicator |
| `hyprland/window` | Active window title, max 50 chars truncated | Reactive, updates on focus change |
| `clock` | Date + time, click toggles calendar (`format-alt` via `actions.on-click: mode`) | `interval: 60` |
| `pulseaudio` | Volume icon + percentage | Scroll ±5% via `pamixer`, click opens pavucontrol, right-click mute, middle-click next sink |
| `mpris` | Media player: status icon + title/artist, `dynamic-len: 35` | Click play/pause, scroll volume, right-click next, middle prev; `playerctld`, ignores firefox/chromium |
| `tray` | System tray icons | `icon-size: 16`, dynamic |
| `network` | Network status icon (5-step signal ramp) | `interval: 5`; click opens nmtui in Ghostty, shows SSID/bandwidth tooltip |
| `bluetooth` | Bluetooth icon + device count | Click opens blueman-manager, device list in tooltip |
| `backlight` | Brightness icon + % | Scroll ±1 via `light`, click presets 25/75/50% (left/right/middle), `interval: 2` |
| `battery` | Battery icon + % or time remaining | `interval: 3`; color-coded states, click `powerprofilesctl`, right-click info notification |
| `custom/kanata-layer` | Active keyboard layer name | `exec-persistent` JSON, `exec-if` gates on the systemd unit; click toggles layer |
| `custom/idle-indicator` | Idle lock state | **Polled `interval: 30` plus `signal: 9`, not exec-persistent**; click toggles, right-click toggles nolock |
| `custom/voxtype` | Mic state (idle/recording/transcribing/stopped) | `exec-persistent` JSON, click restarts the unit |
| `custom/swaync` | Notification bell + unread count | `exec-persistent` `swaync-client -swb`; four state keys (`notification`/`none`/`dnd-notification`/`dnd-none`); click toggles panel, right-click DND, middle clears |

**Interaction**: scroll, left/right/middle click, hover tooltips.

**Styling**: 638 lines of CSS importing `themes/current/waybar.css`; semantic colours; flexbox.

#### Quickshell QML mapping

Shipped in `private_dot_config/quickshell/dotfiles/bar/`. One `Bar.qml` plus one file per widget
in `bar/widgets/`, all built on a shared `BarWidget.qml`.

**Canvas**: `PanelWindow` anchored top/left/right. The shipped bar is a **floating** 40px bar
with an 8px inset (`Config.qml.tmpl:34-35`), not a 30px edge-to-edge one, so it must set
`exclusiveZone` explicitly — `ExclusionMode.Auto` only reserves anchored edges and windows
would tile under the bottom inset. See `bar/Bar.qml`.

**Layout**: three `RowLayout` sections inside `Bar.qml`, with `BarSeparator.qml` hairlines bound
to the group that follows them.

**Workspace module** — `bar/widgets/WorkspacesWidget.qml`:

```qml
import Quickshell.Hyprland

Repeater {
    model: Hyprland.workspaces
    delegate: Item {
        required property HyprlandWorkspace modelData
        MouseArea { onClicked: parent.modelData.activate() }
    }
}
```

🚨 **`HyprlandWorkspace.activate()`, never `Hyprland.dispatch("workspace N")`.** `activate()`
is the one call quickshell translates for Hyprland's Lua config provider — it emits
`hl.dsp.focus({ workspace = "…" })` when `usingLua` is set and the plain `workspace N` string
otherwise (`_ai/quickshell/src/wayland/hyprland/ipc/workspace.cpp:153-167`). This tree runs the
Lua config, so a hand-written dispatch string would simply not work.

**Window title**: `Hyprland.activeToplevel?.title`, truncated by character count to match
Waybar's `max-length`. See `bar/widgets/WindowTitleWidget.qml`.

**Clock** — there is no `Clock` type. The registered type is `SystemClock`, and it takes a
`precision` enum, not an interval (`_ai/quickshell/src/core/clock.hpp:37,53`):

```qml
SystemClock { precision: SystemClock.Minutes }
```

See `bar/widgets/ClockWidget.qml:65-68`.

**Audio** — the singleton is `Pipewire` (not `PipeWire`) and the property is `defaultAudioSink`
(not `defaultAudioPlayback`); volume lives on the node's `audio` sub-object
(`/usr/lib/qt6/qml/Quickshell/Services/Pipewire/quickshell-service-pipewire.qmltypes`,
`Pipewire` → `defaultAudioSink`, `PwNodeAudio` → `volume`/`muted`):

```qml
import Quickshell.Services.Pipewire

readonly property PwNode sink: Pipewire.defaultAudioSink
// sink.audio.volume is a 0..1 float; sink.audio.muted is a bool
PwObjectTracker { objects: [sink] }   // without this, volume reads a permanent 0
```

Sink switching is `Pipewire.preferredDefaultAudioSink`, not a shelled-out `pamixer --next-sink`.
Launching pavucontrol is `Quickshell.execDetached(["pavucontrol"])` — `Qt.openUrl()` is a URL
opener and cannot run a command. See `bar/widgets/AudioWidget.qml`.

**Media** — `Mpris.currentPlayer` does not exist. The `Mpris` singleton exposes **exactly one**
property, `players` (an `ObjectModel`); selecting a player is the consumer's job
(`Services/Mpris/quickshell-service-mpris.qmltypes:514-527`). Track fields are
`trackTitle`/`trackArtist`/`trackAlbum`/`trackArtUrl`, and control is
`togglePlaying()`/`next()`/`previous()`:

```qml
readonly property MprisPlayer player: Mpris.players.values.filter(p => !ignored(p))[0] ?? null
```

Waybar's `ignored-players` maps onto that filter. See `bar/widgets/MediaWidget.qml`.

**Battery** — `UPower.displayDevice` is right, and so is the type name `UPowerDevice`. The trap
is the unit: `percentage` is a **0..1 fraction**, not the 0..100 that `upower -i` and the UPower
D-Bus API both report. State comes from the `UPowerDeviceState` enum. See
`bar/widgets/BatteryWidget.qml:23-32`.

**System tray** — there is no `StatusNotifier` singleton. It is `SystemTray` in
`Quickshell.Services.SystemTray`, with an `items` model of `SystemTrayItem`
(`Services/SystemTray/quickshell-service-statusnotifier.qmltypes`). Icons render through
`Quickshell.Widgets/IconImage`. `SystemTrayItem.menu` is a `DBusMenuHandle` that qmllint cannot
resolve, so that line carries an inline suppression. See `bar/widgets/TrayWidget.qml`.

**Network** — there is no `NetworkManager` singleton. It is `Networking` in
`Quickshell.Networking`, with a `devices` model of `NetworkDevice`/`WifiDevice`/`WiredDevice`
(`Networking/quickshell-network.qmltypes`). `WifiNetwork.signalStrength` is another 0..1
fraction. `Networking.devices` is empty for the first 1-2s and fills reactively. See
`bar/widgets/NetworkWidget.qml`.

**Bluetooth** — `Bluetooth` in `Quickshell.Bluetooth` is correct: `defaultAdapter`
(`BluetoothAdapter`), `adapters`, `devices`. Upstream's `Bluetooth/qmldir` omits
`depends Quickshell`, so `BluetoothAdapter` needs an inline `unresolved-type` suppression. See
`bar/widgets/BluetoothWidget.qml`.

**Backlight** — still no native module in 0.3.1, and this is the **only** capability in the
whole document with no first-class API. Shipped as one singleton, `Backlight.qml`: a `Process`
call to this repo's DDC/CI-aware `brightness-set`, plus two `FileView`s on
`/sys/class/backlight/*/brightness` and `max_brightness` so the value is observed rather than
polled. `Slider` from QtQuick.Controls is not used; the bar widget is scroll-driven
(`bar/widgets/BacklightWidget.qml`).

**Custom indicators** (kanata, voxtype, idle, swaync) — the "no custom script module" problem
was never real. `Quickshell.Io` ships `Process` with a `stdout: SplitParser` sink
(`_ai/quickshell/src/io/datastream.hpp:67-86`), which is a line-for-line analog of Waybar's
`exec-persistent` + `return-type: json`. The tree factors it into one reusable
`bar/WaybarJsonSource.qml` consumed by `KanataWidget`, `VoxtypeWidget` and `IdleWidget`.

The one nuance: `Quickshell.Io/Socket` is a **UNIX** socket — its only address property is
`path` (`_ai/quickshell/src/io/socket.hpp:31`), with no host/port. So kanata's TCP port 5829 is
unreachable from `Socket` and goes through `Process` like everything else
(`bar/widgets/KanataWidget.qml:12-13`).

The swaync indicator is not a script at all any more: `Notifications.qml` owns the state and
`bar/widgets/NotificationWidget.qml` reads it, reproducing the same four glyph keys
(`Notifications.qml:112-116`).

**Styling**: pure QML. `Theme.qml` parses `~/.config/themes/current/colors.sh` at runtime and
exposes all 24 semantic variables, so there is no ninth per-theme file and no generated QML.

#### Feasibility

✅ **Shipped**: workspaces, window title, clock, audio, media, battery, network, Bluetooth,
tray (all native bindings) — plus all four custom indicators, via `Process` + `SplitParser`.
⚠️ **Real gap, shipped as a wrapper**: backlight — no native module; `Process` + `FileView`
(`Backlight.qml`).
❌ ~~Hard: real-time polling without executor abstraction~~ — **void.** `Process`/`SplitParser`
is the `exec-persistent` analog, in QML, with no C++.

---

### 2. WOFI → Launcher in Quickshell

#### What Wofi does (221 config lines)

**Features**:

- Floating window, `location=center`, 600×400px
- `show=drun` — desktop app search (`.desktop` files, icons, exec)
- `matching=fuzzy`, `insensitive=true`, `filter_rate=100`
- `allow_images=true`, `image_size=32`, `allow_markup=true`
- `no_actions=true` — no per-entry action list
- `term=ghostty` for terminal entries
- Click to launch; keyboard navigation (arrows, Tab, Enter, Escape)
- Frecency ordering out of `~/.cache/wofi-drun`

**Styling**: 328-line `style.css.tmpl` importing the theme — window bg, input field, item hover,
selected item.

#### Quickshell QML mapping

Shipped as `private_dot_config/quickshell/dotfiles/launcher/Launcher.qml` (435 lines).

**Canvas**: **not** `FloatingWindow`. A launcher needs exclusive keyboard focus, which is a
layer-shell property, so it is a `PanelWindow` with
`WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive` (`launcher/Launcher.qml:143`), sized
760px wide (`Config.launcherWidth`) and following the focused monitor by name via
`Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)`.

**Model** — the "no native bulk-load" claim is void. `DesktopEntries` is a **built-in
singleton** with an `applications` model of parsed `DesktopEntry` objects, plus `byId()` and
`heuristicLookup()` (`_ai/quickshell/src/core/desktopentry.hpp:298-315`). Each entry exposes
`name`, `genericName`, `comment`, `keywords`, `icon`, `execString`, `command`,
`runInTerminal`, `noDisplay` and `actions`:

```qml
DesktopEntries.applications.values.filter(e => e && !e.noDisplay && e.name)
```

**Launching** — `DesktopEntry.execute()` is a first-class invokable
(`_ai/quickshell/src/core/desktopentry.cpp:260-262`). Neither `Qt.openUrl()` nor a
`Hyprland.dispatch("exec …")` string is needed, and neither would handle the `Exec=` field
codes that `parseExecString()` strips.

🚨 **`DesktopEntries.byId()` is a function call, not a reactive dependency** — a binding written
against it never re-evaluates when the manager rescans. Resolve off `applications.values`
instead. This is why the dock resolves its pinned ids that way (`dock/Dock.qml:149-152`).

**Icons** — the `❌ Hard` verdict is void twice over. `Quickshell.iconPath(name, check)` and
`Quickshell.hasThemeIcon()` resolve theme icons
(`_ai/quickshell/src/core/qmlglobal.hpp:219-227`), and `Quickshell.Widgets/IconImage` renders
them at the right density. See `launcher/Launcher.qml:302,332`.

**Fuzzy match**: a hand-written `score()` — prefix on name, prefix on id, substring in name,
substring across the whole haystack, then initials ("vsc" → Visual Studio Code)
(`launcher/Launcher.qml:79-96`). Wofi's frecency ordering is preserved by reading
`~/.cache/wofi-drun` through a `FileView` (`launcher/Launcher.qml:148-151`), so switching
launchers does not reset the ranking.

**Keyboard nav**: `Keys.onUpPressed`/`onDownPressed`/`onReturnPressed`/`onEscapePressed` on the
query field (`launcher/Launcher.qml:228-232`).

#### Feasibility

✅ **Shipped**: window, search field, list, launch, keyboard nav, frecency.
✅ ~~Medium: `.desktop` file parsing~~ — **void.** `DesktopEntries` is a parsed, reactive index;
`DesktopEntry.execute()` launches.
✅ ~~Hard: icon loading without explicit path resolution~~ — **void.**
`Quickshell.iconPath()` + `IconImage`.
⚠️ **Not built, by choice**: the canvas's `>` `=` `:` `/` `?` prefix modes. Only drun exists;
the mode badge is in place (`launcher/Launcher.qml:236-252`).

---

### 3. SWAYNC → Notifications in Quickshell

#### What swaync does (60-line `config.json`)

**Components**:

1. **Notification daemon** — Freedesktop notifications over D-Bus
2. **Notification popup** — top-right, `notification-window-width: 500`, `timeout: 10`,
   `timeout-low: 5`, `timeout-critical: 0` (never expires)
3. **Control center panel** — `control-center-width: 500`, `control-center-height: 600`, four
   widgets in order: `title` (with a Clear All button), `dnd`, `mpris`, `notifications`

**Features**:

- `notification-grouping: true`
- Action buttons; `notification-2fa-action: true`; `notification-inline-replies: false`
- DND mode
- `image-visibility: when-available`, body images capped 200×100
- `relative-timestamps: true`, `hide-on-action: true`, `transition-time: 200`

*(The original document attributed swaync's history persistence to a `keepOnReload` flag. That
is a quickshell property, not a swaync one, and it covers a config **reload**, not a daemon
restart — swaync loses history on restart too.)*

**Styling**: `style.css` here is a single `@import` line; the real sheet is
`themes/current/swaync.css` via the `symlink_theme.css` entry.

#### Quickshell QML mapping

Shipped as the `Notifications.qml` singleton plus three surfaces in `notifications/`.

**Daemon** — `NotificationServer` is **not a singleton**. It is an instantiable type in
`Quickshell.Services.Notifications`
(`Services/Notifications/quickshell-service-notifications.qmltypes`), and **constructing it is
what claims `org.freedesktop.Notifications`**. A bus name has exactly one owner and there is no
"advertise nothing" setting, so it sits behind a `Loader` gated on
`Config.notificationsOwned` — otherwise it would race an unmasked swaync at login
(`Notifications.qml:134-145`).

```qml
Loader {
    active: Config.notificationsOwned
    sourceComponent: NotificationServer {
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false     // cards render PlainText
        imageSupported: true
        inlineReplySupported: false
        persistenceSupported: true
        onNotification: notification => { notification.tracked = true; /* … */ }
    }
}
```

🚨 **The property is `trackedNotifications`, not `notifications`** (`qml.hpp:72`), and 🚨 **a
notification is not tracked by default.** `isTracked()` reads `mCloseReason == 0`
(`notification.cpp:234`), which looks like "tracked unless closed" — but the member is
initialised to `NotificationCloseReason::Dismissed` (`notification.hpp:209`), and `server.cpp`
deletes the notification the instant the signal handler returns if it is still untracked
(`server.cpp:82,91`). Missed, popups still appear and then decay into a list of `null`s while
the centre stays permanently empty.

**Popup** — `notifications/NotificationPopups.qml`, one `PanelWindow` per screen over
`Quickshell.screens`, up to `Config.notifPopupMaxVisible` (4) cards.

🚨 **A popup timing out must never call `expire()` or `dismiss()`.** Both destroy the
`Notification`, which removes it from `trackedNotifications` — the history the centre exists to
show. Popup lifetime is a separate list with its own deadlines, ticked by one shared `Timer`
rather than a per-delegate one (`Notifications.qml:35-41,186-200`).

🚨 **`Notification.expireTimeout` is in MILLISECONDS**, despite the property's own doc comment
saying seconds: `server.cpp:185,195` takes the D-Bus `expire_timeout` and
`notification.cpp:111-115` assigns it verbatim. Multiplying by 1000 turned every
`notify-send -t 2000` in this repo into a 33-minute toast. `-1` means "server decides", `0`
means never — and Critical is forced to 0, matching swaync's `timeout-critical`
(`Notifications.qml:125-133`).

**Control center** — `notifications/NotificationCentre.qml`: one window on the focused monitor,
exclusive keyboard focus, header with a DND chip and Clear, a `Flickable` list of grouped
cards. Grouping is `Notifications.groups` (`Notifications.qml:62`), reproducing swaync's
`notification-grouping`.

**Actions** — the original "challenge" (spec action IDs vs. text) does not exist.
`Notification.actions` is a list of `NotificationAction` objects, each with `identifier`, a
display `text`, and an `invoke()` method. So:

```qml
Repeater {
    model: notification.actions
    delegate: MouseArea { onClicked: parent.modelData.invoke() }
}
```

See `notifications/NotificationCard.qml:170-209`. Inline reply is also first-class
(`Notification.hasInlineReply`, `inlineReplyPlaceholder`, `sendInlineReply()`) — deliberately
left off here, matching swaync's `notification-inline-replies: false`, because the popup stack
takes no keyboard focus (`Notifications.qml`).

**Rich rendering** — not hard, and mostly a policy decision. `imageSupported` is on and
`Notification.image` carries the app-supplied image; `bodyMarkupSupported` is **off on purpose**
because `Text` renders markup by default, so advertising it would invite senders to ship tags
that PlainText cards would then show raw. Every card string is `textFormat: Text.PlainText`
(`notifications/NotificationCard.qml:136-151`).

**Close/dismiss** — there is no `Notification.close()`. The methods are `dismiss()` and
`expire()`, both from `Retainable`.

**DND mode**: still no native DND in 0.3.1 — a `property bool dnd` on the `Notifications.qml`
singleton plus a filter in the handler, exposed on IPC as `notifications.dnd()`.

**MPRIS widget**: **not built.** swaync's control centre carries an mpris widget with album
art; the Quickshell centre does not, and media lives in the bar instead
(`bar/widgets/MediaWidget.qml`). `MprisPlayer.trackArtUrl` is the property if it is ever added.

#### Feasibility

✅ **Shipped**: daemon, popups, history, grouping, DND toggle, actions, per-urgency timeouts.
✅ ~~Medium: action button routing~~ — **void.** `NotificationAction.invoke()`; no subclassing.
✅ ~~Hard: rich notification rendering~~ — images are first-class; markup is off by choice.
⚠️ **Not built**: the control centre's MPRIS/album-art widget; inline reply (API exists).

---

### 4. WLOGOUT → Power Menu in Quickshell

#### What wlogout does (36-line `layout`)

Six buttons, each with icon text and a keybind. The actions are **not** bare system commands —
five of the six go through this repo's `session-save` wrapper first
(`wlogout/layout`):

| Keybind | Label | Action |
|---|---|---|
| `l` | Lock | `~/.local/lib/scripts/desktop/immediate-lock` |
| `e` | Logout | `session-save && hyprctl dispatch 'hl.dsp.exit()'` |
| `u` | Suspend | `systemctl suspend` |
| `h` | Hibernate | `session-save hibernate && systemctl hibernate` |
| `r` | Reboot | `session-save reboot && systemctl reboot` |
| `s` | Shutdown | `session-save shutdown && systemctl poweroff` |

- Trigger: `Super+Shift+E`
- No confirmation step

**Styling**: 101-line `style.css.tmpl` — per-button semantic accent, size, spacing, rounding.

#### Quickshell QML mapping

Shipped as `private_dot_config/quickshell/dotfiles/power/PowerMenu.qml` (292 lines).

**Canvas**: **not** `FloatingWindow` and not `PopupWindow`. Same reason as the launcher — the
menu is keyboard-driven, so it is a `PanelWindow` with layer-shell exclusive keyboard focus,
following the focused monitor (`power/PowerMenu.qml:112`).

**Actions**: one `list<var>` of `{ key, label, glyph, command }`, carrying the *same* shell
lines wlogout ran, `session-save` included (`power/PowerMenu.qml:27-68`). Running one is:

```qml
Quickshell.execDetached(["sh", "-c", action.command]);
```

🚨 **`Qt.openUrl("systemctl suspend")` does not work.** `Qt.openUrl` opens a URL through the
desktop handler; it is not a process launcher. The invokable is
`Quickshell.execDetached()`, which takes an argv list or a `ProcessContext`
(`_ai/quickshell/src/core/qmlglobal.hpp:187-209`). Every command here has `&&` in it, hence the
explicit `sh -c` (`power/PowerMenu.qml:94-98`).

**Keyboard**: `Keys.onLeftPressed`/`onRightPressed` move the selection,
`onReturnPressed`/`onEnterPressed` fire it, `onEscapePressed` cancels, and a
`Keys.onPressed` handler matches the six single-letter keybinds
(`power/PowerMenu.qml:144-149`). A `Process` fills the header with
`$USER@$(hostname)`, uptime and session count (`power/PowerMenu.qml:276-281`).

**Keybinding trigger**: `SUPER+SHIFT+E` → `quickshell -c dotfiles ipc call power toggle`. The
`-c dotfiles` is load-bearing; without it the call targets config name `default`, and voxtype
runs a second instance.

#### Feasibility

✅ **Shipped**: window, buttons, glyphs, keybinds, per-action semantic colour, system commands.
⚠️ ~~Medium: confirm dialogs~~ — **deliberately not built.** The wrapper being replaced has no
confirmation step either, so adding one would change behaviour rather than port it
(`power/PowerMenu.qml:11-16`).

---

## Summary: Quickshell Feature Coverage

| Component | Coverage | Remaining gaps | Quickshell modules actually used |
|-----------|----------|----------------|----------------------------------|
| **Waybar bar** | Shipped, all 14 modules | Backlight has no native module (wrapped) | `Quickshell.Hyprland`, `Quickshell.Services.Pipewire`, `.UPower`, `.Mpris`, `.SystemTray`, `Quickshell.Networking`, `Quickshell.Bluetooth`, `Quickshell.Io`, `Quickshell.Widgets` |
| **Wofi launcher** | Shipped | Non-drun modes (`>`/`=`/`:`/`/`/`?`) | `Quickshell` (`DesktopEntries`, `iconPath`), `Quickshell.Wayland`, `Quickshell.Widgets`, `Quickshell.Io` |
| **swaync notifications** | Shipped | Control-centre MPRIS widget; inline reply | `Quickshell.Services.Notifications`, `Quickshell.Wayland`, `Quickshell.Widgets` |
| **wlogout power menu** | Shipped | None (no confirm step, by design) | `Quickshell` (`execDetached`), `Quickshell.Wayland`, `Quickshell.Io` |

Note the module-name corrections against the original table: **`PipeWire` → `Pipewire`**,
**`StatusNotifier` → `SystemTray`**, **`NetworkManager` → `Networking`**, and `QProcess` is not
reachable from QML at all — the QML-side equivalents are `Quickshell.Io/Process` and
`Quickshell.execDetached()`.

---

## Integration Challenges

🚨 **Resolved 2026-09-01. Three of these four were never real** — they were written from an
incomplete API picture. Kept as a record of what the wrong picture cost, not as open work.
`_plans/QUICKSHELL_SHELL.md` "Verified facts" carries how each was checked.

| # | Challenge as written | Verdict |
|---|---|---|
| 1 | *No `exec-persistent` analog; needs C++ or D-Bus rewrite* | **Void.** `Process { stdout: SplitParser { onRead: … } }` from `Quickshell.Io` is an exact analog, in QML, no C++ (`_ai/quickshell/src/io/datastream.hpp:67-86`). kanata's TCP port needs a `Process` — `Socket` is UNIX-only, its only address property is `path` (`_ai/quickshell/src/io/socket.hpp:31`); voxtype is `Process` + `SplitParser`. Shipped as `bar/widgets/{KanataWidget,VoxtypeWidget}.qml` over the shared `bar/WaybarJsonSource.qml` |
| 2 | *No `.desktop` parser; wrap `gio` or pre-parse to JSON* | **Void.** `DesktopEntries` is a built-in singleton — a parsed, reactive index with icons and an `execute()` method (`_ai/quickshell/src/core/desktopentry.hpp:298-315`) |
| 3 | *Theming bridge undecided* | **Decided and shipped.** `Theme.qml` parses `~/.config/themes/current/colors.sh` at runtime with a regex; no new per-theme file, no generated QML. Reload is an explicit `IpcHandler` call from `theme-switcher`, because the switch swaps a symlink and an inotify watch on the resolved path never fires |
| 4 | *No native backlight module* | **Real, and the only one.** Shipped as a `Process` call to our own DDC/CI-aware `brightness-set`, plus a `FileView` watch on `/sys/class/backlight/*/brightness`. One file: `Backlight.qml` |

The one wrinkle from the 2026-08-24 note survives, and is now a Phase 6 ordering constraint
rather than a design problem: our `colors.sh` is generated *from* `waybar.css`, so removing
Waybar's config would orphan the source of truth that `Theme.qml` reads. See
`_plans/QUICKSHELL_SHELL.md` → "The `waybar.css` trap".

---

## Status

Superseded as a planning document. **Phases 0–5.5 are shipped** (bar, OSDs, notifications,
launcher, power menu, dock and overview — the last two ship disabled behind
`Config.dockEnabled` / `Config.overviewEnabled`) — see `_plans/QUICKSHELL_SHELL.md` for the
phase list and `private_dot_config/quickshell/CLAUDE.md` for how the tree is actually laid out.
The component-by-component mapping above is still accurate as a description of what each
replaced tool does.

**Still the completeness checklist.** As of 2026-09-03 the shell's scope is a *full* desktop-shell
replacement, not a bar port, so the coverage table above is the reference for what remains to be
owned — including the pieces previously declined on scope grounds (clipboard, system menu, lock
screen). See `_research/QUICKSHELL_DESIGN_BRIEF_R5.md` §1.1.

For those three, 0.3.1 already ships the primitives, so none of them is a research question:

| Piece | First-class API in 0.3.1 | Caveat |
|---|---|---|
| Lock screen | `Quickshell.Wayland/WlSessionLock` + `WlSessionLockSurface`, authenticated with `Quickshell.Services.Pam/PamContext` | A lock surface that crashes locks the user out; `PamContext` is the only supported auth path |
| Clipboard | `Quickshell.clipboardText` (read/write, with `clipboardTextChanged`) (`_ai/quickshell/src/core/qmlglobal.hpp:141`) | Current selection only — there is **no** history API, so a clipboard manager still needs its own store |
| System / tray menus | `Quickshell.DBusMenu` + `QsMenuOpener`/`QsMenuAnchor`/`QsMenuEntry` from `Quickshell` | `SystemTrayItem.menu` returns a `DBusMenuHandle` that qmllint cannot resolve; needs an inline suppression |

Also registered and unused so far: `Quickshell.Services.Polkit/PolkitAgent` (authentication
dialogs), `Quickshell.Services.Greetd/Greetd` (a display-manager greeter),
`Quickshell.Wayland/IdleMonitor` and `IdleInhibitor` (which could replace the `idle-indicator`
script entirely), and `Quickshell.WindowManager/WindowManager`.
