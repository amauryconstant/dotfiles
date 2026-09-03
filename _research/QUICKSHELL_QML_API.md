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

---

## Module Structure

| Module URI | Purpose | Key types / singleton |
|--------|---------|-----------|
| `Quickshell` | Core shell, window types, screen info, menus, utilities | `ShellRoot`, `PanelWindow`, `PopupWindow`, `Scope`, `Singleton`, `Variants`, `Quickshell` |
| `Quickshell.Io` | Process and file I/O, IPC | `Process`, `SplitParser`, `StdioCollector`, `Socket`, `FileView`, `JsonAdapter`, `IpcHandler` |
| `Quickshell.Wayland` | Wayland surfaces and protocols | `WlrLayershell`, `WlSessionLock`, `ScreencopyView` |
| `Quickshell.Hyprland` | Hyprland IPC | `Hyprland`, `HyprlandWorkspace`, `HyprlandMonitor` |
| `Quickshell.WindowManager` | Compositor-agnostic window layer | `WindowManager` |
| `Quickshell.Widgets` | Utility widgets | `ClippingRectangle`, `WrapperRectangle`, `IconImage` |
| `Quickshell.Networking` | Network state | `Networking` |
| `Quickshell.Bluetooth` | Bluetooth devices | `Bluetooth`, `BluetoothAdapter` |
| `Quickshell.Services.{Notifications,Mpris,Pipewire,UPower,SystemTray,Polkit,Pam,Greetd}` | Services | one singleton each |

🚨 **Singletons are not auto-available.** Each is `QML_SINGLETON` inside its own module and is
unusable without that module's import — `import Quickshell.Services.SystemTray` before
`SystemTray.items`. Hyprland types live in `Quickshell.Hyprland`, **not**
`Quickshell.WindowManager` (which is the newer compositor-agnostic layer).

Real singleton names, and the three this doc had wrong:

| Singleton | Import | Note |
|---|---|---|
| `Hyprland` | `Quickshell.Hyprland` | workspaces, monitors, toplevels, dispatch |
| `NotificationServer` | `Quickshell.Services.Notifications` | |
| `Mpris` | `Quickshell.Services.Mpris` | |
| `Pipewire` | `Quickshell.Services.Pipewire` | ❌ not `PipeWire` |
| `UPower`, `PowerProfiles` | `Quickshell.Services.UPower` | |
| `SystemTray` | `Quickshell.Services.SystemTray` | ❌ not `StatusNotifier` |
| `Networking` | `Quickshell.Networking` | ❌ not `NetworkManager` |
| `Bluetooth` | `Quickshell.Bluetooth` | |
| `DesktopEntries` | `Quickshell` | parsed `.desktop` index with icons |
| `Polkit`, `Pam`, `Greetd` | `Quickshell.Services.*` | |

There is no `Idle` singleton; idle monitoring is a `Quickshell.Wayland` type.

---

## Window Types (the canvas for shells)

### PanelWindow (bar / notification / launcher surfaces)
Layer-shell surface, desktop-aware positioning. Best for persistent bars, panels, docks, popups.

```qml
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: bar
  
  visible: true
  width: 1920
  height: 40
  
  // Anchoring (which screen edges to stick to)
  anchors {
    left: true
    right: true
    top: true
  }
  
  // Margin from screen edge
  margins {
    top: 0
    left: 0
    right: 0
    bottom: 0
  }
  
  // Layer-shell specific (available if running on Wayland with wlr_layershell)
  // Wayland-specific, but safely check: if (bar.WlrLayershell) { bar.WlrLayershell.layer = ... }
  // WlrLayer: Background=0, Bottom=1, Top=2, Overlay=3
  // WlrKeyboardFocus: None=0, Exclusive=1, OnDemand=2
  
  // Content
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

### FloatingWindow (standalone windows, test UIs)
Standard window, not anchored to edges.

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
Transient, closes on focus loss.

```qml
PopupWindow {
  width: 200
  height: 150
  
  Rectangle {
    anchors.fill: parent
    color: "#fff"
  }
}
```

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
    return `Workspace ${ws.id}, Monitor ${mon.name}, Window ${active ? active.title : 'none'}`;
  }
}
```

| Property | Type | Notes |
|----------|------|-------|
| `Hyprland.usingLua` | bool | True if Hyprland is in Lua mode (dispatcher syntax differs) |
| `Hyprland.focusedWorkspace` | `HyprlandWorkspace` | Current active workspace (may be null) |
| `Hyprland.focusedMonitor` | `HyprlandMonitor` | Current active monitor (may be null) |
| `Hyprland.activeToplevel` | `HyprlandToplevel` | Currently focused window (may be null) |
| `Hyprland.workspaces` | `ObjectModel<HyprlandWorkspace>` | All workspaces, sorted by ID |
| `Hyprland.monitors` | `ObjectModel<HyprlandMonitor>` | All monitors |
| `Hyprland.toplevels` | `ObjectModel<HyprlandToplevel>` | All windows |

### Methods

```qml
// Execute a Hyprland dispatcher (same as `hyprctl dispatch`)
Hyprland.dispatch("movefocus l");
Hyprland.dispatch("workspace 2");

// Refresh state (some Hyprland actions don't send events)
Hyprland.refreshMonitors();
Hyprland.refreshWorkspaces();
Hyprland.refreshToplevels();

// Get the HyprlandMonitor for a given screen
var mon = Hyprland.monitorFor(screen);
```

### HyprlandWorkspace (workspace objects in model)

```qml
Repeater {
  model: Hyprland.workspaces
  
  delegate: Rectangle {
    required property HyprlandWorkspace modelData
    color: modelData.focused ? "#80ff00" : "#333"
    
    Text {
      text: `WS ${modelData.id} (${modelData.windows.length} windows)`
    }
  }
}
```

| Property | Type | Notes |
|----------|------|-------|
| `modelData.id` | int | Workspace ID (negative for named workspaces) |
| `modelData.name` | string | Workspace name (if named) |
| `modelData.focused` | bool | Is currently active |
| `modelData.monitor` | `HyprlandMonitor` | Which monitor it's on |
| `modelData.windows` | array | Toplevels in this workspace |

### HyprlandMonitor (monitor objects in model)

```qml
Text {
  text: {
    let mon = Hyprland.focusedMonitor;
    return `${mon.name}: ${mon.width}x${mon.height} @ ${mon.refreshRate}Hz`;
  }
}
```

| Property | Type | Notes |
|----------|------|-------|
| `name` | string | Monitor name (e.g., "DP-1", "HDMI-A-1") |
| `width`, `height` | int | 🚨 **PHYSICAL** pixels, copied verbatim out of `hyprctl monitors`. Window `at`/`size` are **LOGICAL** — divide by `scale`, and subtract the monitor's logical `x`/`y` origin, before comparing |
| `x`, `y` | int | Position in workspace |
| `refreshRate` | double | Hz |
| `scale` | double | Scaling factor |
| `focused` | bool | Is actively focused |

### HyprlandToplevel (window objects in model)

```qml
Repeater {
  model: Hyprland.toplevels
  
  delegate: Rectangle {
    required property HyprlandToplevel modelData
    color: modelData.focused ? "#0ff" : "#333"
    
    Text {
      text: modelData.title
    }
  }
}
```

| Property | Type | Notes |
|----------|------|-------|
| `title` | string | Window title |
| `workspace` | `HyprlandWorkspace` | Which workspace |
| `initialClass` | string | XDG app class / WM_CLASS |
| `focused` | bool | Has focus |

---

## Notification Server (singleton `NotificationServer`)

Run a Freedesktop notification daemon in QML. Notifications arrive as a model.

```qml
import Quickshell

FloatingWindow {
  NotificationServer {
    id: notifServer
    // Advertise capabilities
    bodySupported: true
    bodyMarkupSupported: true
    persistenceSupported: true

    // 🚨 MANDATORY. A notification is NOT tracked by default: server.cpp DELETES it the
    // instant this handler returns unless tracked is set. Miss it and popups still appear
    // (the handler already captured the pointer) but history becomes a list of nulls.
    onNotification: notification => {
      notification.tracked = true;
    }
  }
  
  Column {
    Repeater {
      // history is trackedNotifications, not notifications
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
          onClicked: modelData.close() // Dismiss notification
        }
      }
    }
  }
}
```

| Property (NotificationServer) | Type | Notes |
|------|------|-------|
| `notifications` | array | Incoming notifications |
| `bodySupported` | bool | Advertise body text support |
| `bodyMarkupSupported` | bool | Advertise markup (HTML) support |
| `bodyHyperlinksSupported` | bool | Advertise hyperlink support |
| `persistenceSupported` | bool | Advertise persistence off-screen |

| Property (Notification object) | Type | Notes |
|------|------|-------|
| `summary` | string | Title |
| `body` | string | Body text (may contain markup if enabled) |
| `appName` | string | Sending application |
| `appIcon` | string | Icon name / URI |
| `urgency` | int | 0=low, 1=normal, 2=critical |

| Method (Notification object) | Effect |
|------|--------|
| `close()` | Dismiss notification |
| `replaceWithWidget(qml)` | Custom QML renderer (advanced) |

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

| Property | Type | Notes |
|----------|------|-------|
| `defaultAudioSink` | `PwNode` | Main speaker/headphone — ❌ not `defaultAudioPlayback` |
| `defaultAudioSource` | `PwNode` | Main microphone — ❌ not `defaultAudioCapture` |
| `outputDevices` | array | All speakers/headphones |
| `inputDevices` | array | All microphones |

| Device Property | Type | Notes |
|------|------|-------|
| `volume` | 0.0–1.0 | R/W, affects master volume |
| `muted` | bool | R/W |
| `name` | string | Device name |

---

## Battery / Power (singleton `UPower`)

```qml
Text {
  text: {
    let bat = UPower.displayDevice;
    if (!bat) return "No battery";
    return `${(bat.percentage * 100).toFixed(0)}% (${bat.state})`;  // percentage is 0.0-1.0
  }
}
```

| Property | Type | Notes |
|----------|------|-------|
| `displayDevice` | device | Primary battery (or AC status) |
| `batteries` | array | All batteries |
| `devices` | array | All power devices |

| Device Property | Type | Notes |
|------|------|-------|
| `percentage` | **0.0–1.0** | 🚨 A **fraction**, not the 0–100 that the UPower D-Bus API and `upower -i` both report. Verified: `upower` said 72%, the property read 0.72. Every threshold is 100× out if this is missed |
| `state` | string | "charging", "discharging", "empty", "fully-charged", "pending-charge", "pending-discharge" |
| `timeToEmpty` | seconds | Time until depleted (if discharging) |
| `timeToFull` | seconds | Time until full (if charging) |

---

## Services (Singletons)

| Singleton | Purpose | Example |
|-----------|---------|---------|
| `Mpris` | Media control | Access current playing song, pause/play |
| `SystemTray` | System tray | `SystemTray.items` |
| `Networking` | Network state | `Networking.devices.values`; `signalStrength` is a 0..1 fraction |
| `Bluetooth` | BT devices | Paired devices, connection state |
| `Polkit` | Privilege dialogs | Registers a real polkit agent — see below |
| `Greetd` + `Pam` | Authentication | Password prompts, for a custom lock — see below |

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
| `path` | R/W string | session path to register for |
| `isRegistered` | bindable bool | whether registration succeeded |
| `isActive` | bindable bool | a request is in flight |
| `flow` | bindable `AuthFlow*` | the current request, or null |

### `AuthFlow` (`polkit/flow.hpp`) — one authentication request

| Member | Kind | Maps to the `pf-d` artboard |
|---|---|---|
| `message` | string | polkit's own reason string, unedited |
| `actionId` | string | the mono action-id line (`org.freedesktop.systemd1.manage-units`) |
| `iconName` | string | |
| `identities`, `selectedIdentity` | list / R-W | which user to authenticate as — **the artboard does not draw this** |
| `isResponseRequired` | bindable bool | whether to show the field |
| `inputPrompt` | bindable string | the field's label ("Password") |
| `responseVisible` | bindable bool | echo on/off |
| `supplementaryMessage` | bindable string | the "Wrong password — 2 attempts left" line |
| `supplementaryIsError` | bindable bool | whether that line is an error |
| `isCompleted` / `isSuccessful` / `isCancelled` / `failed` | bindable bool | terminal states, incl. the exhausted case |
| `submit(value)` | invokable | |
| `cancelAuthenticationRequest()` | invokable | |

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
| `active` | R/W bool | |
| `config`, `configDirectory` | R/W string | PAM service name (e.g. `login`) |
| `user` | R/W string | |
| `message`, `messageIsError` | read-only | prompt / failure text |
| `responseRequired`, `responseVisible` | read-only bool | |
| `start()`, `respond(value)`, `abort()` | invokable | |

Plus `PamResult` and `PamError` singletons with `toString()`. This is what a `WlSessionLock`
screen authenticates against — note it is a **separate object**, not a property of the lock.

---

## Other Core Types

### Scope
Root container for a config file. One `Scope` = one shell config.

```qml
import Quickshell

Scope {
  // All windows, singletons, services defined here
  PanelWindow { ... }
  FloatingWindow { ... }
}
```

### SystemClock (periodic timer)
Emit signals on intervals (useful for time displays, polling).

```qml
SystemClock {   // the type is SystemClock, not Clock
  precision: SystemClock.Seconds
  
  onTriggered: {
    text = new Date().toLocaleTimeString()
  }
}
```

### DesktopEntry (app info)
Load .desktop file metadata (icon, name, exec).

```qml
DesktopEntry {
  id: entry
  appId: "firefox.desktop"
  
  Text {
    text: entry.name + " (" + entry.exec + ")"
  }
}
```

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
`edges = Top | Left`, `gravity = Bottom | Right`, and setting `anchor.item` without
`anchor.rect` makes the anchor rect the item's **full** `boundingRect()`. So `anchorY` is the
item's *top* edge and the popup lands on top of the widget it describes — it then steals the
pointer, `containsMouse` drops, a `visible:`-bound popup hides, the pointer returns, and it
flickers forever while swallowing every click meant for the widget. `edges: Edges.Bottom` plus
`gravity: Edges.Bottom` (which also centres it horizontally) is the fix; both lines need a
`missing-type` qmllint suppression, since `Edges::Flags` is unresolvable across the module split.

See `bar/BarTooltip.qml` and `.claude/rules/quickshell-qml.md`.

---

## Session Lock (for custom lock screens)

Secure lock surface using Wayland `ext-session-lock-v1` + PAM auth.

⚠️ **The example below is illustrative, not verified.** `WlSessionLock` has no `pam` sub-object
and no `onPasswordAccepted` signal in 0.3.1 — PAM is the separate `PamContext` element documented
above (`start()` / `respond()` / `abort()`, with `message` and `responseRequired`). Rewrite
against `PamContext` before relying on this. Verified: `WlSessionLock` is in `Quickshell.Wayland`
and `PamContext` in `Quickshell.Services.Pam`.

```qml
import Quickshell
import Quickshell.Wayland

Scope {
  WlSessionLock {
    id: lock
    pam {
      service: "system-login" // or "login"
    }
    
    onPasswordAccepted: {
      // User authenticated, unlock
      lock.destroyLater();
    }
  }
  
  PanelWindow {
    anchors.centerIn: screen
    width: 300
    height: 200
    
    Column {
      Text { text: "Locked" }
      TextField {
        id: pwInput
        echoMode: TextInput.Password
        onAccepted: {
          if (lock.pam) {
            lock.pam.authenticate(pwInput.text);
            pwInput.clear();
          }
        }
      }
    }
  }
}
```

---

## Concrete Example: Minimal Bar + Workspace Indicator

This bar shows focused workspace and current window title.

```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland   // NOT Quickshell.WindowManager

Scope {
  PanelWindow {
    anchors {
      left: true
      right: true
      top: true
    }
    
    margins { top: 0; left: 0; right: 0; bottom: 0 }
    
    width: 1920
    height: 30
    
    color: "#1e1e2e"
    
    RowLayout {
      anchors.fill: parent
      anchors.margins: 5
      
      // Workspace buttons
      Row {
        spacing: 5
        
        Repeater {
          model: Hyprland.workspaces
          
          delegate: Rectangle {
            required property HyprlandWorkspace modelData
            
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
              onClicked: Hyprland.dispatch(`workspace ${modelData.id}`);
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
      
      // Time
      Text {
        text: new Date().toLocaleTimeString()
        color: "#cdd6f4"
        font.pixelSize: 12
      }
    }
  }
}
```

---

## Key Observations for Desktop Shell Design

1. **Singletons need their module imported** — `Hyprland`, `NotificationServer`, `Pipewire`, `UPower` each live in their own module and are undefined without its import. They are singletons, so no instantiation; bind directly once imported.

2. **Models are reactive** — changes to workspace focus, windows, battery state, etc. automatically trigger QML property updates. No polling.

3. **PanelWindow is the core** — layer-shell surfaces are how bars/panels stick to edges. `WlrLayershell` attachment gives full control (anchoring, layer, keyboard focus).

4. **Hyprland IPC is rich** — access to workspace list, monitor list, window list, plus ability to execute dispatchers. Enough for a full bar + workspace switcher.

5. **Services are batteries-included** — notification daemon, audio control, battery/power, system tray, media, network, Bluetooth all available as QML singletons with live models.

6. **No CSS** — styling is pure QML (Rectangle, palette, gradients, etc.). This is where the semantic-color bridge (JSON or QML singleton) fits in.

7. **Lock screens are possible but secondary** — `WlSessionLock` exists, but correctness is critical; leave as last phase.

---

## Next Steps (for implementation planning)

1. **Theming bridge** — generate a QML `Colors` singleton from `themes/current/colors.sh` on theme switch.
2. **Component structure** — modular QML (bar, launcher, notifications separately, each reloadable).
3. **Hyprland IPC depth** — workspace icons, window counts, active indicator patterns.
4. **Service integration** — wire audio/battery/notifications into the bar.
5. **Prototype** — build a minimal bar alongside Waybar to validate the pattern.
