# Quickshell QML API Reference
**Source**: Vendored upstream at `_ai/quickshell/` (git.outfoxxed.me/quickshell/quickshell, LGPL-3)
**Created**: June 2026
**Purpose**: API reference for building custom Quickshell desktop shell components (bar, launcher, notifications, etc.)

🚨 **Corrected 2026-09-01.** This doc was written from an incomplete API picture and several of
its names were wrong: no singleton is auto-available, and `StatusNotifier`/`NetworkManager`/
`PipeWire` do not exist under those names. The corrections below are verified against the
installed `quickshell 0.3.1` **and** against the shipped bar in
`private_dot_config/quickshell/dotfiles/`, which is running code. `_plans/QUICKSHELL_SHELL.md`
"Verified facts" #1-#4 and #7 record how each was checked.

🚨 **Corrected again 2026-09-03.** The 2026-09-01 pass fixed the prose and left the **code
examples** wrong. Six further errors, each verified against `_ai/quickshell/src/` and
`/usr/lib/qt6/qml/Quickshell/`:

| Was | Is | Consequence if believed |
|---|---|---|
| `UPower` device `percentage` "0–100" | **0.0–1.0 fraction** | every threshold 100× out; the example below printed "1%" for a full battery |
| `import Quickshell.WindowManager` for `Hyprland` (two examples) | `import Quickshell.Hyprland` | the singleton is undefined; this is the error the 2026-09-01 header says it fixed, fixed only in prose |
| `HyprlandMonitor.width/height` "dimensions in pixels" | **PHYSICAL** pixels, while window geometry is **LOGICAL** | anything projecting a window into a monitor-shaped space is wrong by `scale`; already broke the overview once |
| `NotificationServer` example calls `close()` and reads `.notifications` | the handler **must set `tracked = true`** or the notification is destroyed the instant it returns; history is `trackedNotifications` | popups appear, then become a list of `null`s and the centre stays empty |
| `Clock { interval: … }` | the type is **`SystemClock`** | no such type |
| `DesktopEntry { appId: … }` declarative form | resolve off `DesktopEntries.applications.values`; the id property is `id`, and `byId()` is a call, not a reactive dependency | a binding that never re-evaluates on rescan |

**And one omission that changed a decision**: `Quickshell.Services.Polkit` and
`Quickshell.Services.Pam` are **real, shipped modules** with first-class APIs — see the Polkit
and PAM section below. A 2026-09-03 planning note claimed a polkit agent would have to be
hand-written over raw D-Bus; that was wrong.

🚨 **Third pass, 2026-09-03 (later the same day).** A full member-by-member audit of every type
named here against the 0.3.1 headers and the installed `.qmltypes`. The previous pass fixed the
examples it knew about; this one found that several *property tables* still listed members that
do not exist in 0.3.1 at all. Everything below is fixed in the body text as well as listed here.

| Was | Is | Evidence |
|---|---|---|
| `NotificationServer` is a singleton (three places) | it is `QML_NAMED_ELEMENT` with **no** `QML_SINGLETON` — you instantiate it, and constructing it is what claims the bus name | `services/notifications/qml.hpp:76` |
| `NotificationServer.notifications` | **does not exist.** `trackedNotifications` is the only model | `services/notifications/qml.hpp:72` |
| `Notification.close()` | `expire()` / `dismiss()` | `services/notifications/notification.hpp:128,131` |
| `Notification.replaceWithWidget(qml)` | **does not exist anywhere in the source** | grep of `_ai/quickshell/src/` |
| `Notification.urgency` is an int | `NotificationUrgency::Enum` — compare against `NotificationUrgency.Critical`, not `2` | `services/notifications/notification.hpp:23-32` |
| `HyprlandMonitor.refreshRate` | **does not exist.** Only `lastIpcObject.refreshRate`, which is stale until `refreshMonitors()` | `wayland/hyprland/ipc/monitor.hpp:20-37` |
| `HyprlandWorkspace.windows` | `toplevels` (an `ObjectModel`, so `.values.length`, not `.length`) | `wayland/hyprland/ipc/workspace.hpp:42` |
| `HyprlandToplevel.focused` | `activated` | `wayland/hyprland/ipc/hyprland_toplevel.hpp:37` |
| `HyprlandToplevel.initialClass` | **does not exist.** Use `lastIpcObject.class`, or `wayland.appId` | `hyprland_toplevel.hpp:28-49`; shipped `bar/widgets/WorkspacesWidget.qml:108` |
| `UPower.batteries` | **does not exist.** `displayDevice`, `devices`, `onBattery` | `services/upower/core.hpp:75-80` |
| `UPowerDevice.state` is a string | an enum — `UPowerDeviceState.Charging` etc.; `UPowerDeviceState.toString(state)` for the string | `services/upower/device.hpp:17-37` |
| `Pipewire.outputDevices` / `inputDevices` | **do not exist.** `nodes`, filtered by `PwNode.isSink` | `services/pipewire/qml.hpp:67,97-128` |
| `Scope` is "the root container, one Scope = one shell config" | `Scope` is a `ReloadPropagator` — a non-visual grouping that propagates reload identity. `ShellRoot` is the (optional) root element | `core/reload.hpp:106`, `core/shell.hpp:11-15` |
| `SystemClock { onTriggered: … }` | there is no `triggered` signal. Bind to `date` (or `hours`/`minutes`/`seconds`) | `core/clock.hpp:35-53` |
| `DesktopEntry { appId: … }` instantiated, `.exec` read | `DesktopEntry` is `QML_UNCREATABLE`; the properties are `id` (basename **without** `.desktop`), `execString`, `command`, and `execute()` | `core/desktopentry.hpp:88-89,52-108`; `desktopentry.cpp:396-397` |
| `PopupWindow` "transient, closes on focus loss" | it does neither by default. It is not shown at all until `anchor` resolves to a window **and** `visible` is true; dismissal on an outside click is opt-in via `grabFocus` | `window/popupwindow.hpp:61-80` |
| session lock example used `lock.pam` and a `PanelWindow` | `WlSessionLock`'s default property is `surface`, which must create a **`WlSessionLockSurface`**; PAM is a separate `PamContext` | `wayland/session_lock.hpp:24-70,145` |
| `Notification.expireTimeout` "seconds" (upstream's own comment says so) | **milliseconds** — the D-Bus argument is assigned verbatim and the fd.o spec defines `expire_timeout` in ms | `notification.cpp:115` vs `notification.hpp:83` |
| — (not previously recorded) | `UPowerDevice.healthPercentage` is **0–100**, unlike `percentage`. Only `percentage` gets the `* 0.01` wire transform | `services/upower/device.cpp:115` vs `device.hpp:250` |
| — (not previously recorded) | `UPower.displayDevice` **cannot be null**; it is an aggregate device and is *not* in `devices`. Null-checking it is dead code — check `ready`/`isPresent` | `services/upower/core.hpp:70-75` |

🚨 **Fourth pass, 2026-09-03.** An independent re-run of the same audit against the 0.3.1
headers and the installed qmltypes reproduced every correction above and found no further
*errors* — but it did find three **omissions**, each of which the shipped tree already depends
on and none of which this doc mentioned at all:

| Missing | Why it matters | Evidence |
|---|---|---|
| The `Quickshell` singleton itself | `Quickshell.execDetached()` is the process launcher and is called by eight shipped widgets; `Quickshell.screens` appears in two examples here having never been introduced; `Quickshell.iconPath()` is how a tray or notification icon *name* becomes a URL | `core/qmlglobal.hpp`; `bar/widgets/*.qml` |
| `SystemTrayItem.activate()`, `.secondaryActivate()`, `.scroll(delta, horizontal)` | the Services table listed only `display()`, yet a tray widget is unusable without the other three — the shipped `bar/widgets/TrayWidget.qml:69,61,71` calls all of them | `services/status_notifier/item.hpp:130-136` |
| The whole `Quickshell.Io` module | listed in the module table and then never documented, though `IpcHandler` is what the theme bridge and every toggle script talk to, and `FileView` is what `Theme.qml` parses `colors.sh` with | `io/ipchandler.hpp:123-232`, `io/process.hpp`, `io/fileview.hpp` |

The `Quickshell` and `Quickshell.Io` sections below were added to close those. One fact found
while writing them is worth promoting here, because it explains a symptom
`.claude/rules/quickshell-qml.md` already records without a cause: **an `IpcHandler` function
is only registered if its argument *and* return types are explicitly annotated**
(`io/ipchandler.hpp:131-132`). `function toggle() { … }` registers nothing;
`function toggle(): void { … }` registers. Since `quickshell ipc call` exits 0 even when the
target is missing, an unannotated handler fails completely silently — which is exactly why the
rule is to verify with `ipc show` rather than an exit code.

---

## Module Structure

| Module URI | Purpose | Key types / singleton |
|--------|---------|-----------|
| `Quickshell` | Core shell, window types, screen info, menus, utilities | `ShellRoot`, `PanelWindow`, `PopupWindow`, `FloatingWindow`, `Scope`, `Singleton`, `Variants`, `LazyLoader`, `Region`, `SystemClock`, `Quickshell`, `DesktopEntries` |
| `Quickshell.Io` | Process and file I/O, IPC | `Process`, `SplitParser`, `StdioCollector`, `Socket`, `SocketServer`, `FileView`, `JsonAdapter`, `IpcHandler` |
| `Quickshell.Wayland` | Wayland surfaces and protocols | `WlrLayershell`, `WlSessionLock`, `WlSessionLockSurface`, `ScreencopyView`, `IdleMonitor`, `IdleInhibitor`, `ToplevelManager` |
| `Quickshell.Hyprland` | Hyprland IPC | `Hyprland`, `HyprlandWorkspace`, `HyprlandMonitor`, `HyprlandToplevel`, `HyprlandFocusGrab`, `GlobalShortcut` |
| `Quickshell.WindowManager` | Compositor-agnostic window layer | `WindowManager`, `Windowset` |
| `Quickshell.Widgets` | Utility widgets (QML, not C++) | `IconImage`, `ClippingRectangle`, `WrapperItem`, `WrapperRectangle`, `WrapperMouseArea` |
| `Quickshell.DBusMenu` | Tray menus | `DBusMenuHandle`, `DBusMenuItem` — what `SystemTrayItem.menu` returns |
| `Quickshell.Networking` | Network state | `Networking`, `NetworkDevice`, `WifiDevice`, `WifiNetwork` |
| `Quickshell.Bluetooth` | Bluetooth devices | `Bluetooth`, `BluetoothAdapter`, `BluetoothDevice` |
| `Quickshell.Services.{Notifications,Mpris,Pipewire,UPower,SystemTray,Polkit,Pam,Greetd}` | Services | mostly one singleton each — but see below |

`Quickshell.I3` and `Quickshell.X11` also ship; neither is relevant here.

🚨 **Singletons are not auto-available.** Each is `QML_SINGLETON` inside its own module and is
unusable without that module's import — `import Quickshell.Services.SystemTray` before
`SystemTray.items`. Hyprland types live in `Quickshell.Hyprland`, **not**
`Quickshell.WindowManager` (which is the newer compositor-agnostic layer).

🚨 **"One singleton per service module" is not universally true.** Three of the service modules
export an **instantiable element** rather than a singleton, because each one *claims* something
and so must be created deliberately: `NotificationServer`
(`services/notifications/qml.hpp:76` — `QML_NAMED_ELEMENT`, no `QML_SINGLETON`), `PolkitAgent`
(`services/polkit/qml.hpp:29`) and `PamContext` (`services/pam/qml.hpp:24`). That is exactly why
the shipped tree puts the notification server behind
`Loader { active: Config.notificationsOwned }` — a singleton could not be conditionally absent.

Real singleton names, and the three this doc had wrong:

| Singleton | Import | Note |
|---|---|---|
| `Quickshell` | `Quickshell` | the shell's own handle — `screens`, `execDetached()`, `iconPath()`. See below |
| `Hyprland` | `Quickshell.Hyprland` | workspaces, monitors, toplevels, dispatch |
| `Mpris` | `Quickshell.Services.Mpris` | |
| `Pipewire` | `Quickshell.Services.Pipewire` | ❌ not `PipeWire` |
| `UPower`, `PowerProfiles` | `Quickshell.Services.UPower` | |
| `SystemTray` | `Quickshell.Services.SystemTray` | ❌ not `StatusNotifier` |
| `Networking` | `Quickshell.Networking` | ❌ not `NetworkManager` |
| `Bluetooth` | `Quickshell.Bluetooth` | |
| `DesktopEntries` | `Quickshell` | parsed `.desktop` index with icons |
| `Greetd` | `Quickshell.Services.Greetd` | |

❌ **`NotificationServer`, `PolkitAgent` and `PamContext` are not on that list** — they are types
you instantiate. Enum holders (`NotificationUrgency`, `UPowerDeviceState`, `WifiSecurityType`, …)
*are* registered as singletons, which is how `NotificationUrgency.Critical` resolves.

There is no `Idle` singleton; idle monitoring is the instantiable `IdleMonitor` in
`Quickshell.Wayland` (`enabled`, `timeout` in seconds, `respectInhibitors`, read-only `isIdle`).

**Every `ObjectModel` property is a model, not an array.** `Hyprland.workspaces`,
`SystemTray.items`, `Networking.devices`, `NotificationServer.trackedNotifications` and friends
feed a `Repeater` directly, but JavaScript on them goes through `.values`
(`core/model.hpp`) — which does notify, so `[...model.values].filter(…)` is a live binding.

---

## Window Types (the canvas for shells)

All three inherit `QsWindow`, which is where `visible`, `width`/`height`,
`implicitWidth`/`implicitHeight`, `screen`, `color`, `mask` and `contentItem` come from.

### PanelWindow (bar / notification / launcher surfaces)
Layer-shell surface, desktop-aware positioning. Best for persistent bars, panels, docks.

```qml
import Quickshell

PanelWindow {
    id: bar

    // Anchoring two opposite edges FORCES that dimension to the screen's, so a
    // full-width bar sets no width of its own — only its height, as an implicit
    // one (panelinterface.hpp:102).
    anchors {
        left: true
        right: true
        top: true
    }

    implicitHeight: 40
    color: "transparent"

    // Offsets from the screen edge. Only applies to edges that are anchored.
    // The grouped-block form `margins { … }` is unresolvable to qmllint; use the
    // dotted form with a suppression. See bar/Bar.qml.
    // qmllint disable unqualified unresolved-type
    margins.left: 8
    margins.right: 8
    margins.top: 8
    // qmllint enable unqualified unresolved-type

    // Space reserved from other windows. Setting it switches exclusionMode from
    // Auto to Normal (panelinterface.hpp:110). Auto only reserves the margins of
    // edges that ARE anchored, so a floating bar must set this by hand.
    exclusiveZone: 40 + 8

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"

        Text {
            text: "My Bar"
            color: "#cdd6f4"
        }
    }
}
```

`aboveWindows` (default true) and `focusable` (default false) are the portable spellings of
the layer-shell layer and keyboard-focus mode. For the full control, `WlrLayershell` is an
**attached object** on `PanelWindow`, not a type you wrap it in
(`wayland/wlr_layershell/wlr_layershell.hpp:96-116`):

```qml
import Quickshell
import Quickshell.Wayland

PanelWindow {
    WlrLayershell.layer: WlrLayer.Bottom          // WlrLayer: Background=0, Bottom=1, Top=2, Overlay=3
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None   // None=0, Exclusive=1, OnDemand=2
    WlrLayershell.namespace: "my-bar"             // how external tools (hyprctl layers) identify it
}
```

`layer` defaults to `WlrLayer.Top`, `keyboardFocus` to `WlrKeyboardFocus.None`. To stay
platform-independent, set them from `Component.onCompleted` behind a
`if (this.WlrLayershell != null)` guard.

### FloatingWindow (standalone windows, test UIs)
Standard window, not anchored to edges. Adds `title`, `minimumSize`, `maximumSize`,
`minimized`, `maximized`, `fullscreen`.

```qml
FloatingWindow {
    width: 400
    height: 300
    visible: true

    Rectangle {
        anchors.fill: parent
        color: "#fff"
    }
}
```

### PopupWindow (menus, dropdowns)

🚨 **It is neither transient nor focus-dismissed by default.** A `PopupWindow` is not shown at
all until its `anchor` resolves against a window *and* `visible` is true
(`window/popupwindow.hpp:61-73`), and it stays up until something hides it. Dismissal on an
outside click is opt-in through `grabFocus`, and changing `grabFocus` while the window is open
does nothing until it is hidden and shown again (`popupwindow.hpp:79-87`).

```qml
PopupWindow {
    anchor.window: parentWindow   // or anchor.item — see PopupAnchor below
    implicitWidth: 200
    implicitHeight: 150
    grabFocus: true               // dismiss on click-outside; defaults to false
    visible: true

    Rectangle {
        anchors.fill: parent
        color: "#fff"
    }
}
```

`parentWindow`, `relativeX` and `relativeY` still exist but are **deprecated** in favour of
`anchor.window` and `anchor.rect.x`/`.y` (`popupwindow.hpp:46-60`). Under Hyprland,
`HyprlandFocusGrab` detects an outside click *without* closing the popup, which `grabFocus`
cannot.

---

## Hyprland Integration (singleton `Hyprland`)

The `Hyprland` singleton provides real-time workspace, monitor, and window introspection + dispatchers.

### Properties

```qml
import Quickshell
import Quickshell.Hyprland   // NOT Quickshell.WindowManager

Text {
    text: {
        let ws = Hyprland.focusedWorkspace;
        let mon = Hyprland.focusedMonitor;
        let active = Hyprland.activeToplevel;
        return `Workspace ${ws?.id}, Monitor ${mon?.name}, Window ${active ? active.title : 'none'}`;
    }
}
```

| Property | Type | Notes |
|----------|------|-------|
| `Hyprland.usingLua` | bool | True if Hyprland is in Lua mode (dispatcher syntax differs). **False until the module initialises**, so it is not a safe one-shot read at startup |
| `Hyprland.focusedWorkspace` | `HyprlandWorkspace` | Current active workspace (may be null) |
| `Hyprland.focusedMonitor` | `HyprlandMonitor` | Current active monitor (may be null) |
| `Hyprland.activeToplevel` | `HyprlandToplevel` | Currently focused window (may be null) |
| `Hyprland.workspaces` | `ObjectModel<HyprlandWorkspace>` | All workspaces, sorted by ID |
| `Hyprland.monitors` | `ObjectModel<HyprlandMonitor>` | All monitors |
| `Hyprland.toplevels` | `ObjectModel<HyprlandToplevel>` | All windows |
| `Hyprland.requestSocketPath`, `.eventSocketPath` | string | `.socket.sock` / `.socket2.sock` |

All three models are empty for the first ~1s after startup and fill on their own.

### Methods

All are `Q_INVOKABLE static` on the singleton (`wayland/hyprland/ipc/qml.hpp:52-72`):

```qml
// Execute a Hyprland dispatcher (same as `hyprctl dispatch`)
Hyprland.dispatch("movefocus l");
Hyprland.dispatch("workspace 2");

// Refresh state (many actions that invalidate state send no event)
Hyprland.refreshMonitors();
Hyprland.refreshWorkspaces();
Hyprland.refreshToplevels();

// Get the HyprlandMonitor for a given screen (the inverse of matching by name)
var mon = Hyprland.monitorFor(screen);
```

The singleton also emits `rawEvent(HyprlandEvent)` for every line on socket2;
`HyprlandEvent` carries `name`, `data` and `parse(argumentCount)`.

### HyprlandWorkspace (workspace objects in model)

```qml
Repeater {
    model: Hyprland.workspaces

    delegate: Rectangle {
        required property HyprlandWorkspace modelData

        color: modelData.focused ? "#80ff00" : "#333"

        Text {
            // `toplevels` is an ObjectModel, so count through .values
            text: `WS ${modelData.id} (${modelData.toplevels.values.length} windows)`
        }
    }
}
```

| Property | Type | Notes |
|----------|------|-------|
| `id` | int | Workspace ID (negative for named workspaces, which sort first) |
| `name` | string | Workspace name (if named) |
| `active` | bool | Active on its own monitor |
| `focused` | bool | Active on the *focused* monitor — this is the one a bar highlights |
| `urgent` | bool | |
| `hasFullscreen` | bool | |
| `monitor` | `HyprlandMonitor` | Which monitor it's on |
| `toplevels` | `ObjectModel<HyprlandToplevel>` | ❌ not `windows` |
| `lastIpcObject` | object | Raw `hyprctl workspaces` entry; **stale until `refreshWorkspaces()`** |

`activate()` is invokable and is the direct alternative to `dispatch("workspace N")`.

### HyprlandMonitor (monitor objects in model)

```qml
Text {
    text: {
        let mon = Hyprland.focusedMonitor;
        // There is no refreshRate property — it only exists on the raw IPC object.
        return `${mon?.name}: ${mon?.width}x${mon?.height} @ scale ${mon?.scale}`;
    }
}
```

| Property | Type | Notes |
|----------|------|-------|
| `id` | int | Hyprland's monitor id |
| `name` | string | Monitor name (e.g., "DP-1", "HDMI-A-1") |
| `description` | string | EDID description — what HyprDynamicMonitors matches profiles on |
| `width`, `height` | int | 🚨 **PHYSICAL** pixels, copied verbatim out of `hyprctl monitors` (`monitor.cpp:41-42`). Window `at`/`size` are **LOGICAL** — divide by `scale`, and subtract the monitor's logical `x`/`y` origin, before comparing |
| `x`, `y` | int | Logical origin of this monitor in the layout |
| `scale` | double | Scaling factor |
| `focused` | bool | Is actively focused |
| `activeWorkspace` | `HyprlandWorkspace` | May be null |
| `lastIpcObject` | object | Raw `hyprctl monitors` entry — the **only** place `refreshRate`, `transform`, `dpmsStatus` etc. live, and stale until `refreshMonitors()` |

❌ There is no `refreshRate` property (`monitor.hpp:20-37`).

### HyprlandToplevel (window objects in model)

```qml
Repeater {
    model: Hyprland.toplevels

    delegate: Rectangle {
        required property HyprlandToplevel modelData

        color: modelData.activated ? "#0ff" : "#333"

        Text {
            text: modelData.title
        }
    }
}
```

| Property | Type | Notes |
|----------|------|-------|
| `title` | string | Window title |
| `activated` | bool | Has focus — ❌ not `focused` |
| `urgent` | bool | |
| `address` | string | Hyprland window address |
| `workspace` | `HyprlandWorkspace` | Which workspace |
| `monitor` | `HyprlandMonitor` | Which monitor |
| `wayland` | `Quickshell.Wayland.Toplevel` | The wlr-foreign-toplevel handle — has `appId`, `close()`, `activate()`, and is what `ScreencopyView.captureSource` takes |
| `lastIpcObject` | object | Raw `hyprctl clients` entry — where `class`, `at`, `size`, `floating` live |

❌ There is no `initialClass`. The app class is `lastIpcObject.class` (what the shipped
`bar/widgets/WorkspacesWidget.qml:108` and `dock/Dock.qml:158` use) or `wayland.appId`.

---

## Notification Server (element `NotificationServer` — **not** a singleton)

Run a Freedesktop notification daemon in QML. 🚨 Constructing this object is what claims
`org.freedesktop.Notifications`, and a bus name has exactly one owner — there is no
"advertise nothing" mode, which is why the shipped tree wraps it in a `Loader`.

```qml
import Quickshell
import Quickshell.Services.Notifications

NotificationServer {
    id: notifServer

    // Advertise capabilities. These gate what GetCapabilities reports; they do NOT
    // gate `hints`, which always arrives in full.
    bodySupported: true
    bodyMarkupSupported: true
    imageSupported: true
    actionsSupported: true
    persistenceSupported: true
    keepOnReload: true   // survive a config RELOAD (not a process restart)

    // 🚨 MANDATORY. A notification is NOT tracked by default: server.cpp:202,212
    // DELETES it the instant this handler returns unless tracked is set. Miss it and
    // popups still appear (the handler already captured the pointer) but history
    // becomes a list of nulls.
    onNotification: notification => {
        notification.tracked = true;
    }
}
```

```qml
Column {
    Repeater {
        // history is trackedNotifications; there is no `notifications` property
        model: notifServer.trackedNotifications

        delegate: Rectangle {
            required property Notification modelData

            width: 300
            height: 80
            color: "#333"

            Column {
                Text { text: modelData.summary }
                Text { text: modelData.body }
            }

            MouseArea {
                anchors.fill: parent
                // dismiss() DESTROYS the notification, so it leaves history too.
                // Never call it (or expire()) from a popup auto-hide timer.
                onClicked: modelData.dismiss()
            }
        }
    }
}
```

| Property (NotificationServer) | Type | Notes |
|------|------|-------|
| `trackedNotifications` | `ObjectModel<Notification>` | The only model. ❌ There is no `notifications` |
| `keepOnReload` | bool | Carries notifications across a config **reload**, flagged `lastGeneration`. A process restart still starts empty |
| `bodySupported`, `bodyMarkupSupported`, `bodyHyperlinksSupported`, `bodyImagesSupported` | bool | Advertised body capabilities |
| `actionsSupported`, `actionIconsSupported`, `imageSupported`, `inlineReplySupported`, `persistenceSupported` | bool | Advertised capabilities |
| `extraHints` | list<string> | Extends the advertised capability list only — every hint a client sends arrives in `Notification.hints` regardless |

| Property (Notification object) | Type | Notes |
|------|------|-------|
| `id` | uint | fd.o notification id |
| `summary`, `body` | string | Title / body (markup if enabled) |
| `appName`, `appIcon`, `desktopEntry` | string | Sender identity; `desktopEntry` is the hint that maps to a `DesktopEntries` id |
| `image` | string | Image URL from the `image-data`/`image-path` hint |
| `urgency` | `NotificationUrgency::Enum` | `NotificationUrgency.Low` / `.Normal` / `.Critical` — ❌ not a bare int |
| `expireTimeout` | double | 🚨 **MILLISECONDS**, despite the upstream doc comment saying seconds: `notification.cpp:115` assigns the D-Bus `expire_timeout` verbatim, and the fd.o spec defines that in ms. `-1` means "server decides", `0` means never |
| `actions` | list<`NotificationAction`> | Each has `identifier`, `text` and `invoke()` |
| `transient`, `resident`, `hasActionIcons`, `hasInlineReply` | bool | fd.o hints |
| `hints` | object | Every hint the client sent, undeclared ones included |
| `tracked` | bool (R/W) | 🚨 Must be set true in the handler. Setting it back to false is equivalent to `dismiss()` |
| `lastGeneration` | bool | Carried over from before a reload |

| Method (Notification object) | Effect |
|------|--------|
| `expire()` | **Destroys** the notification, hinting it timed out |
| `dismiss()` | **Destroys** the notification, hinting the user closed it |
| `sendInlineReply(text)` | Only when `hasInlineReply` and the server advertises `inlineReplySupported` |

`Notification` also inherits `Retainable`, so a `RetainableLock` can hold an object alive past
its destruction (useful for a close animation) without keeping it in history.

---

## Audio / Volume (singleton `Pipewire`)

```qml
import Quickshell.Services.Pipewire

readonly property PwNode sink: Pipewire.defaultAudioSink
PwObjectTracker { objects: [sink] }        // without this, volume reads a permanent 0
Text { text: `Volume: ${Math.round((sink?.audio.volume ?? 0) * 100)}%` }
```

Volume lives on `node.audio.volume`/`.muted`, not on the node itself. See
`bar/widgets/AudioWidget.qml`.

🚨 **Objects are unbound by default** (`services/pipewire/qml.hpp:426-436`): an unbound node
exposes only a subset of its data, so anything reading `audio` needs a `PwObjectTracker`
holding it. There is no error — the value simply reads 0.

| Property (`Pipewire`) | Type | Notes |
|----------|------|-------|
| `defaultAudioSink` | `PwNode` | Main speaker/headphone — ❌ not `defaultAudioPlayback` |
| `defaultAudioSource` | `PwNode` | Main microphone — ❌ not `defaultAudioCapture` |
| `preferredDefaultAudioSink` / `Source` | `PwNode` (R/W) | Writing these changes the system default |
| `nodes` | `ObjectModel<PwNode>` | All nodes. ❌ There are no `outputDevices` / `inputDevices` — filter `nodes.values` on `isSink` / `isStream` |
| `links`, `linkGroups` | `ObjectModel` | Routing graph |
| `ready` | bool | Pipewire connection established |

| Property (`PwNode`) | Type | Notes |
|------|------|-------|
| `name`, `description`, `nickname` | string | `description` is the human label |
| `isSink`, `isStream` | bool | Sink vs source; stream vs device |
| `audio` | `PwNodeAudio` | Null on a non-audio node; **requires binding** |
| `properties` | object | Raw pipewire props |
| `ready` | bool | |

| Property (`PwNodeAudio`) | Type | Notes |
|------|------|-------|
| `volume` | float, R/W | Average over channels; `1.0` = 100%. Not clamped — values above 1.0 are over-amplification |
| `muted` | bool, R/W | |
| `volumes`, `channels` | lists | Per-channel; index-aligned |

---

## Battery / Power (singleton `UPower`)

```qml
import Quickshell.Services.UPower

Text {
    text: {
        let bat = UPower.displayDevice;   // cannot be null; check `ready` instead
        if (!bat.ready || !bat.isPresent) return "No battery";
        // percentage is 0.0-1.0
        return `${Math.round(bat.percentage * 100)}% (${UPowerDeviceState.toString(bat.state)})`;
    }
}
```

| Property | Type | Notes |
|----------|------|-------|
| `displayDevice` | `UPowerDevice` | 🚨 **Cannot be null**, and is an *aggregate* device that does **not** appear in `devices` (`core.hpp:70-75`). Check `ready` |
| `devices` | `ObjectModel<UPowerDevice>` | All physical power devices |
| `onBattery` | bool | System is running on battery / discharging |

❌ There is no `batteries` property; filter `devices.values` on `isLaptopBattery` or
`type === UPowerDeviceType.Battery`.

| Device Property | Type | Notes |
|------|------|-------|
| `percentage` | **0.0–1.0** | 🚨 A **fraction**, not the 0–100 that the UPower D-Bus API and `upower -i` both report — `device.cpp:115` applies `wire * 0.01`. Verified: `upower` said 72%, the property read 0.72. Every threshold is 100× out if this is missed |
| `healthPercentage` | **0–100** | 🚨 The opposite convention, in the same object: `device.hpp:250` binds `Capacity` with **no** wire transform. Do not assume the two match |
| `state` | `UPowerDeviceState::Enum` | ❌ Not a string. `Unknown`/`Charging`/`Discharging`/`Empty`/`FullyCharged`/`PendingCharge`/`PendingDischarge`; `UPowerDeviceState.toString(state)` for a label |
| `type` | `UPowerDeviceType::Enum` | Battery, Mouse, Keyboard, … |
| `timeToEmpty` | seconds | `0` unless discharging |
| `timeToFull` | seconds | `0` unless charging |
| `isPresent`, `isLaptopBattery`, `powerSupply`, `ready` | bool | |
| `energy`, `energyCapacity`, `changeRate` | double (Wh / W) | |
| `iconName`, `model`, `nativePath` | string | |

`PowerProfiles` (same module) is a separate singleton: R/W `profile`
(`PowerProfile.PowerSaver`/`.Balanced`/`.Performance`), `hasPerformanceProfile`,
`degradationReason`, `holds`.

---

## Services (Singletons)

| Singleton | Purpose | Example |
|-----------|---------|---------|
| `Mpris` | Media control | `Mpris.players.values` → `MprisPlayer` (playbackState, metadata, transport calls) |
| `SystemTray` | System tray | `SystemTray.items` → `SystemTrayItem` (`id`, `title`, `icon`, `status`, `category`, `tooltipTitle`, `tooltipDescription`, `hasMenu`, `menu`, `onlyMenu`). Invokables: `activate()`, `secondaryActivate()`, `scroll(delta, horizontal)`, `display(window, x, y)` — `item.hpp:130-136` |
| `Networking` | Network state | `Networking.devices.values`; also `wifiEnabled` (R/W), `connectivity`, `backend`. `WifiNetwork.signalStrength` is a **0..1 fraction** (`network/nm/network.cpp:260` divides by 100) |
| `Bluetooth` | BT devices | `Bluetooth.defaultAdapter`, `.adapters`, `.devices` |

`SystemTrayItem.menu` is a `DBusMenuHandle` from `Quickshell.DBusMenu`; it is not exposed
declaratively, so reading it needs an inline `unresolved-type` suppression.

Instantiated rather than singletons: `NotificationServer` (above), `PolkitAgent` and
`PamContext` (below).

---

## Polkit and PAM (`Quickshell.Services.Polkit`, `Quickshell.Services.Pam`)

🚨 **Both are shipped, first-class modules.** Verified 2026-09-03 in
`_ai/quickshell/src/services/{polkit,pam}/` and installed at
`/usr/lib/qt6/qml/Quickshell/Services/{Polkit,Pam}/`. An authentication dialog does **not**
require hand-writing an `org.freedesktop.PolicyKit1.AuthenticationAgent` over raw D-Bus.

### `PolkitAgent` (`polkit/qml.hpp`)

A `QML_ELEMENT` you instantiate; it registers as the session's polkit agent.

| Member | Kind | Notes |
|---|---|---|
| `path` | R/W string | session path to register for (`qml.hpp:36`) |
| `isRegistered` | bindable bool | whether registration succeeded (`qml.hpp:39`) |
| `isActive` | bindable bool | a request is in flight |
| `flow` | bindable `AuthFlow*` | the current request, or null |

### `AuthFlow` (`polkit/flow.hpp`) — one authentication request

| Member | Kind | Maps to the `pf-d` artboard |
|---|---|---|
| `message` | string | polkit's own reason string, unedited |
| `actionId` | string | the mono action-id line (`org.freedesktop.systemd1.manage-units`) |
| `iconName` | string | |
| `cookie` | string | |
| `identities`, `selectedIdentity` | list / R-W | which user to authenticate as — **the artboard does not draw this** |
| `isResponseRequired` | bindable bool | whether to show the field |
| `inputPrompt` | bindable string | the field's label ("Password") |
| `responseVisible` | bindable bool | echo on/off |
| `supplementaryMessage` | bindable string | the "Wrong password — 2 attempts left" line |
| `supplementaryIsError` | bindable bool | whether that line is an error |
| `isCompleted` / `isSuccessful` / `isCancelled` / `failed` | bindable bool | terminal states, incl. the exhausted case |
| `submit(value)` | invokable | `flow.hpp:95` |
| `cancelAuthenticationRequest()` | invokable | `flow.hpp:97` |

The design's `pf-d` maps onto this almost exactly — including the supplementary error line and
the action id. The one artboard gap is `identities`: polkit may offer a **choice of user**, and
`pf-d` assumes a single implicit one.

**The real risk is not the API, it is exclusivity**: a polkit session has one agent. Adopting
this means unregistering `polkit-gnome` (`hypr/conf/autostart.lua:32`), and a crash in the
Quickshell agent then leaves no agent at all — every privileged action fails until the shell is
restarted. That, not the D-Bus work, is what the deferral has to weigh.

### `PamContext` (`pam/qml.hpp`)

| Member | Kind | Notes |
|---|---|---|
| `active` | R/W bool | writing true starts the conversation |
| `config`, `configDirectory` | R/W string | PAM service name (e.g. `login`) |
| `user` | R/W string | |
| `message`, `messageIsError` | read-only | prompt / failure text |
| `responseRequired`, `responseVisible` | read-only bool | |
| `start()`, `respond(value)`, `abort()` | invokable | `qml.hpp:72,80,75` |
| `completed(result)`, `error(err)`, `pamMessage()` | signals | terminal + per-prompt |

Plus `PamResult` and `PamError` singletons with `toString()`. This is what a `WlSessionLock`
screen authenticates against — note it is a **separate object**, not a property of the lock.

---

## Other Core Types

### The `Quickshell` singleton

Same name as the module, and it is where the shell's own handle lives. Every shipped widget
uses it, so it is worth knowing before anything else.

```qml
import Quickshell

MouseArea {
    // Launch a program WITHOUT keeping it as a child of the shell. Takes an argv
    // LIST, not a shell string — nothing is word-split and nothing is globbed.
    onClicked: Quickshell.execDetached(["pavucontrol"])
}
```

| Member | Notes |
|---|---|
| `screens` | `list<ShellScreen>` — `name`, `model`, `serialNumber`, `x`/`y`/`width`/`height`, `devicePixelRatio`. The model a `Variants` iterates for one window per monitor |
| `execDetached(argv)` | Fire-and-forget launch, argv list. The overload also accepts a `ProcessContext` for env/cwd. Use this, not `Qt.openUrl` — and use `Process` instead when you need the output |
| `iconPath(name)`, `iconPath(name, fallback)`, `hasThemeIcon(name)` | Resolve an XDG icon *name* (what `SystemTrayItem.icon` and `Notification.appIcon` give you) to something `Image.source` can load |
| `reload(hard)` | Reload the config from QML |
| `shellDir`, `configDir`, `dataDir`, `stateDir`, `cacheDir` | Plus `shellPath()`/`configPath()`/`dataPath()`/`statePath()`/`cachePath()` to join onto them |
| `clipboardText` | R/W |
| `processId`, `instanceId`, `shellId`, `launchTime` | Instance identity |
| `hasVersion(major, minor)`, `hasQtVersion(…)` | Feature-gate against the running quickshell |

### `Quickshell.Io` — IPC, processes and files

**`IpcHandler`** is how the outside world drives the shell: `theme switch` tells it to reload
colours, a keybinding toggles the bar. Each handler is a uniquely-`target`ed bag of functions
reachable from `quickshell ipc call <target> <function>`.

🚨 **Argument and return types must be explicitly annotated or the function is not registered
at all** (`io/ipchandler.hpp:131-132`), and `ipc call` exits 0 even when the target does not
exist — so an unannotated handler fails with no signal whatsoever. Verify with `ipc show`,
never with an exit code.

```qml
import Quickshell.Io

IpcHandler {
    target: "theme"                                  // required, unique

    function reload(): void { Theme.reload(); }      // `: void` is load-bearing
    function current(): string { return Theme.name; }
}
```

Supported parameter and return types are `string`, `int`, `bool`, `real` and `color`, up to ten
arguments. `enabled` (default true) gates the handler.

**`Process`** runs something you need output from. `command` is an argv list; `running` starts
and stops it; `stdout`/`stderr` take a `DataStreamParser` — `SplitParser` for line-at-a-time,
`StdioCollector` for the whole output at exit.

```qml
Process {
    command: ["waybar-kanata-layer"]
    running: true
    stdout: SplitParser { onRead: line => root.layer = line }
}
```

`signal(sig)`, `write(data)` (needs `stdinEnabled`) and `startDetached()` are the other
invokables; `workingDirectory`, `environment` and `clearEnvironment` shape the environment.

**`FileView`** reads and writes a file — this is what `Theme.qml` parses `colors.sh` with.
`path`, `text()`/`data()`, `setText()`, `reload()`, `loaded`, plus `watchChanges` with an
`onFileChanged` handler, and `atomicWrites`/`blockWrites` for writing. A `JsonAdapter` on
`adapter` maps a JSON file onto QML properties in both directions.

🚨 **`watchChanges` only signals — it does not reload.** Handle `onFileChanged` and call
`reload()` yourself. And it watches the *resolved* path, so a symlink swap (which is exactly
what `theme switch` does to `themes/current`) never fires it. That is why theming here is
driven by the `IpcHandler` above rather than by the watch.

**`Socket`** is a **UNIX** socket and its only address property is `path`. There is no TCP
support anywhere in the module, so anything speaking to a TCP service goes through a `Process`.
`SocketServer` is the listening side.

### ShellRoot and Scope

`ShellRoot` is the optional root element of a config file — optional because any `QtObject`
works as a root, but it is what exposes `settings` inline (`core/shell.hpp:11-15`).

`Scope` is **not** "one shell config". It is a `ReloadPropagator`
(`core/reload.hpp:88-106`): a non-visual container whose children behave, for reload-identity
purposes, as if they were declared in its parent. It exists to group non-`Item` objects; it
does not scope or isolate anything at runtime.

```qml
import Quickshell

ShellRoot {
    Scope {
        // grouping only — reload behaves as if these were one level up
        PanelWindow { /* ... */ }
    }
}
```

### Variants (one window per screen)

`Variants` is `Repeater` for non-`Item` objects, and is how a shell gets one bar per monitor
(`core/variants.hpp:48-55`). `delegate` is its default property and each instance receives
`modelData`.

```qml
Variants {
    model: Quickshell.screens        // list<ShellScreen>: name, model, x/y/width/height, devicePixelRatio

    PanelWindow {
        required property var modelData
        screen: modelData
    }
}
```

There is no `screen` property on `HyprlandMonitor`, so going the other way is a name match:
`Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)`.
`Hyprland.monitorFor(screen)` is the supported inverse.

### SystemClock (a clock, not a timer)

❌ **There is no `triggered` signal and no `interval`.** `SystemClock` is a *view* of the
system clock that updates at hour/minute/second granularity; you bind to its properties
(`core/clock.hpp:35-53`). For an arbitrary interval, use QtQuick's `Timer`.

```qml
import Quickshell
import QtQuick

SystemClock {
    id: clock
    precision: SystemClock.Seconds   // Hours | Minutes | Seconds; defaults to Seconds
    enabled: true                    // false pauses it
}

Text {
    text: Qt.formatDateTime(clock.date, "hh:mm:ss - yyyy-MM-dd")
}
```

`hours`/`minutes`/`seconds` are also exposed; `minutes` reads 0 at `Hours` precision, and
`seconds` reads 0 at anything coarser than `Seconds`. Ticks land within ±50ms of the real
change, which is why you use `clock.date` rather than constructing a `new Date()`.

### DesktopEntry (app info)

🚨 `DesktopEntry` is `QML_UNCREATABLE` (`core/desktopentry.hpp:88-89`) — there is no
`DesktopEntry { appId: … }` form. Entries come from the `DesktopEntries` singleton, and `id` is
the file's basename **without** the `.desktop` suffix (`desktopentry.cpp:396-397`), so
`com.mitchellh.ghostty.desktop` has id `com.mitchellh.ghostty`.

```qml
import Quickshell

Text {
    // Resolve off the MODEL, not byId(): DesktopEntries.byId() is a plain function
    // call, so a binding written around it never re-evaluates when the manager
    // rescans after a .desktop file changes.
    readonly property var entry: DesktopEntries.applications.values.find(e => e.id === "firefox")

    text: entry ? `${entry.name} (${entry.execString})` : ""
}
```

| Member | Notes |
|---|---|
| `id` | Basename without `.desktop`; subdirectories become an `-` prefix |
| `name`, `genericName`, `comment`, `icon` | |
| `startupClass` | `StartupWMClass` — what window-to-app matching uses |
| `execString` | The raw `Exec=` line. ❌ There is no `exec` |
| `command` | `Exec` already split into argv, field codes expanded |
| `workingDirectory`, `runInTerminal`, `noDisplay`, `categories`, `keywords` | |
| `actions` | list<`DesktopAction`>, each with `id`, `name`, `icon`, `execute()` |
| `execute()` | Launches it |

`DesktopEntries.byId(id)` and `heuristicLookup(name)` are `Q_INVOKABLE` functions.
`heuristicLookup` is weaker than the name suggests: it is `byId()`, then an exact
`startupClass` match, then a case-insensitive one, and nothing more
(`desktopentry.cpp:447-464`). `byId` itself already falls back to a lowercase match
(`desktopentry.cpp:437-445`).

### PopupAnchor (position popups relative to items)

`PopupWindow` has an `anchor` group — there is no `PopupAnchor.rect()` factory.

```qml
PopupWindow {
    id: popup
    anchor {
        item: owner          // the widget this popup describes
        edges: Edges.Bottom  // NOT the default
        gravity: Edges.Bottom
    }
}
```

🚨 **The defaults cover the owner and oscillate.** `PopupAnchorState` defaults to
`edges = Top | Left`, `gravity = Bottom | Right` (`core/popupanchor.hpp:68-69`), and setting
`anchor.item` without `anchor.rect` makes the anchor rect the item's **full**
`boundingRect()` (`core/popupanchor.cpp:190`). So `anchorY` is the item's *top* edge and the
popup lands on top of the widget it describes — it then steals the pointer, `containsMouse`
drops, a `visible:`-bound popup hides, the pointer returns, and it flickers forever while
swallowing every click meant for the widget. `edges: Edges.Bottom` plus
`gravity: Edges.Bottom` (which also centres it horizontally) is the fix; both lines need a
`missing-type` qmllint suppression, since `Edges::Flags` is unresolvable across the module split.

`anchor` also carries `window`, `rect`, `margins` and `adjustment` (the flip/slide/resize
strategy when the popup would leave the screen).

See `bar/BarTooltip.qml` and `.claude/rules/quickshell-qml.md`.

---

## Session Lock (for custom lock screens)

Secure lock surface using Wayland `ext-session-lock-v1`, authenticated against a separate
`PamContext`.

`WlSessionLock`'s **default property is `surface`**, a `Component` that must create a
`WlSessionLockSurface` — one is instantiated per screen when `locked` becomes true
(`wayland/session_lock.hpp:24-70`). A `PanelWindow` inside a lock is wrong and will not
display. `WlSessionLock` has **no `pam` sub-object and no `onPasswordAccepted` signal**.

```qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Controls

ShellRoot {
    PamContext {
        id: pam
        config: "login"
        onCompleted: result => {
            if (result === PamResult.Success) lock.locked = false;
        }
    }

    WlSessionLock {
        id: lock
        locked: true

        // Default property: instantiated once per screen.
        WlSessionLockSurface {
            color: "#1e1e2e"

            Column {
                anchors.centerIn: parent

                Text { text: pam.message || "Locked" }

                TextField {
                    id: pwInput
                    echoMode: pam.responseVisible ? TextInput.Normal : TextInput.Password
                    onAccepted: {
                        if (pam.responseRequired) pam.respond(pwInput.text);
                        else pam.start();
                        pwInput.clear();
                    }
                }
            }
        }
    }
}
```

⚠️ **If the lock is destroyed without `locked` being set back to false, a conformant compositor
leaves the session locked and painted a solid colour** (`session_lock.hpp:47-53`). That is what
makes it secure, and also what makes it the last thing to build. `secure` (read-only) reports
whether the compositor has confirmed every screen is covered.

---

## Concrete Example: Minimal Bar + Workspace Indicator

This bar shows focused workspace and current window title, one bar per screen.

```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland   // NOT Quickshell.WindowManager

ShellRoot {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData

            screen: bar.modelData
            color: "#1e1e2e"
            implicitHeight: 30   // width comes from anchoring left AND right

            anchors {
                left: true
                right: true
                top: true
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 5

                // Workspace buttons — this monitor's only, matching Waybar's
                // all-outputs:false.
                Row {
                    spacing: 5

                    Repeater {
                        model: Hyprland.workspaces

                        delegate: Rectangle {
                            required property HyprlandWorkspace modelData

                            visible: modelData.monitor?.name === bar.modelData.name
                            width: 30
                            height: 20
                            radius: 4
                            color: modelData.focused ? "#80ff00" : "#333"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.name || modelData.id
                                color: "#000"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: modelData.activate()
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Active window title
                Text {
                    text: Hyprland.activeToplevel?.title ?? "—"
                    color: "#cdd6f4"
                    font.pixelSize: 12
                }

                Item { Layout.fillWidth: true }

                // Time. `new Date()` in a binding would never re-evaluate —
                // clock.date is the reactive source.
                Text {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: "#cdd6f4"
                    font.pixelSize: 12
                }
            }
        }
    }
}
```

---

## Key Observations for Desktop Shell Design

1. **Singletons need their module imported** — `Hyprland`, `Pipewire`, `UPower`, `SystemTray`
   each live in their own module and are undefined without its import. They are singletons, so
   no instantiation; bind directly once imported. `NotificationServer`, `PolkitAgent` and
   `PamContext` are the exceptions: they are elements you create, because creating them is what
   claims a bus name or a session role.

2. **Models are reactive** — changes to workspace focus, windows, battery state, etc. automatically trigger QML property updates. No polling. But they are `ObjectModel`s: feed them to a `Repeater` directly, and reach for `.values` only in JavaScript.

3. **PanelWindow is the core** — layer-shell surfaces are how bars/panels stick to edges. The
   `WlrLayershell` *attached object* gives full control (layer, keyboard focus, namespace).

4. **Hyprland IPC is rich** — access to workspace list, monitor list, window list, plus ability to execute dispatchers. Enough for a full bar + workspace switcher. Anything not exposed as a property is in `lastIpcObject`, which is stale until the matching `refresh*()` call.

5. **Services are batteries-included** — notification daemon, audio control, battery/power, system tray, media, network, Bluetooth, polkit and PAM all available.

6. **No CSS** — styling is pure QML (Rectangle, palette, gradients, etc.). This is where the semantic-color bridge (JSON or QML singleton) fits in.

7. **Lock screens are possible but secondary** — `WlSessionLock` exists, but a lock that dies without unlocking leaves the session inoperable; leave as last phase.

8. **Units are the recurring trap in this API.** Three different conventions coexist and none of
   them errors when misread: `UPowerDevice.percentage` and `WifiNetwork.signalStrength` are
   0..1 fractions while `UPowerDevice.healthPercentage` is 0..100; `HyprlandMonitor.width`/
   `height` are physical pixels while everything positional is logical; `expireTimeout` is
   milliseconds despite upstream's own comment. Check the unit against the source before
   writing a threshold.

---

## Next Steps (for implementation planning)

1. **Theming bridge** — generate a QML `Colors` singleton from `themes/current/colors.sh` on theme switch.
2. **Component structure** — modular QML (bar, launcher, notifications separately, each reloadable).
3. **Hyprland IPC depth** — workspace icons, window counts, active indicator patterns.
4. **Service integration** — wire audio/battery/notifications into the bar.
5. **Prototype** — build a minimal bar alongside Waybar to validate the pattern.
