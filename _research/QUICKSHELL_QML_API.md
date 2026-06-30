# Quickshell QML API Reference
**Source**: Vendored upstream at `_ai/quickshell/` (git.outfoxxed.me/quickshell/quickshell, LGPL-3)
**Created**: June 2026
**Purpose**: API reference for building custom Quickshell desktop shell components (bar, launcher, notifications, etc.)

---

## Module Structure

Quickshell exposes four primary QML modules:

| Module | Purpose | Key Types |
|--------|---------|-----------|
| `Quickshell` | Core shell, window types, screen info, menus, utilities | `ShellRoot`, `PanelWindow`, `FloatingWindow`, `PopupWindow`, `Scope`, `Clock`, `DesktopEntry`, ... |
| `Quickshell.Wayland` | Wayland-specific surfaces and protocols | `WlrLayershell`, `WlSessionLock`, `WlrKeyboardFocus`, idle monitoring, screencopy, ... |
| `Quickshell.WindowManager` | Workspace/window introspection, multi-screen layout | `WindowManager`, `WindowsetProjection`, `HyprlandWorkspace`, `HyprlandMonitor`, ... |
| `Quickshell.Widgets` | Utility widgets (clipping, wrappers, icons) | `ClippingRectangle`, `WrapperRectangle`, `IconImage`, ... |

**Services** are exposed as **singletons** (auto-available, no module import needed):
- `Hyprland` — Hyprland IPC (workspaces, monitors, toplevels, dispatchers, focus)
- `NotificationServer` — Freedesktop notification daemon
- `Mpris` — Media player control
- `PipeWire` — Audio / volume
- `UPower` — Battery / power state
- `StatusNotifier` — System tray
- `NetworkManager` — Network state
- `Bluetooth` — Bluetooth devices
- `Polkit` — Privilege escalation agent
- `Greetd` + `Pam` — Authentication
- `Idle` — Idle detection

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
import Quickshell.WindowManager

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
| `width`, `height` | int | Dimensions in pixels |
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
  }
  
  Column {
    Repeater {
      model: notifServer.notifications
      
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

## Audio / Volume (singleton `PipeWire`)

```qml
Text {
  text: {
    let dev = PipeWire.defaultAudioPlayback;
    if (!dev) return "No audio";
    return `Volume: ${(dev.volume * 100).toFixed(0)}%`;
  }
}

MouseArea {
  onWheel: (wheel) => {
    let dev = PipeWire.defaultAudioPlayback;
    if (dev) dev.volume = Math.max(0, Math.min(1, dev.volume + wheel.angleDelta.y / 120 * 0.05));
  }
}
```

| Property | Type | Notes |
|----------|------|-------|
| `defaultAudioPlayback` | audio device | Main speaker/headphone |
| `defaultAudioCapture` | audio device | Main microphone |
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
    return `${(bat.percentage).toFixed(0)}% (${bat.state})`;
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
| `percentage` | 0–100 | Charge percentage |
| `state` | string | "charging", "discharging", "empty", "fully-charged", "pending-charge", "pending-discharge" |
| `timeToEmpty` | seconds | Time until depleted (if discharging) |
| `timeToFull` | seconds | Time until full (if charging) |

---

## Services (Singletons)

| Singleton | Purpose | Example |
|-----------|---------|---------|
| `Mpris` | Media control | Access current playing song, pause/play |
| `StatusNotifier` | System tray | Show/manage tray icons |
| `NetworkManager` | Network state | Wifi SSID, connected status |
| `Bluetooth` | BT devices | Paired devices, connection state |
| `Polkit` | Privilege dialogs | Prompt for sudo actions |
| `Greetd` + `Pam` | Authentication | Fingerprint, password (for custom lock) |

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

### Clock (periodic timer)
Emit signals on intervals (useful for time displays, polling).

```qml
Clock {
  interval: 1000 // update every 1s
  
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
Automatically position a PopupWindow adjacent to a target (e.g., context menus).

```qml
Rectangle {
  id: button
  
  MouseArea {
    onClicked: {
      popup.popupAnchor = PopupAnchor.rect(button, button.mapToGlobal(0, 0));
      popup.visible = !popup.visible;
    }
  }
}

PopupWindow {
  id: popup
  popupAnchor: PopupAnchor.rect(button, button.mapToGlobal(0, 0))
}
```

---

## Session Lock (for custom lock screens)

Secure lock surface using Wayland `ext-session-lock-v1` + PAM auth.

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
import Quickshell.WindowManager

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

1. **Singletons are auto-accessible** — `Hyprland`, `NotificationServer`, `PipeWire`, `UPower`, etc. work without import or instantiation. Bind directly in QML.

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
