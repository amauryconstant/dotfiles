# Quickshell Component Mapping
**Purpose**: Document what each existing desktop component does and how it maps to Quickshell QML capabilities
**Created**: June 2026

---

## Overview: Current Components & Their Scope

| Component | Type | Lines of Config | Purpose | Status |
|-----------|------|-----------------|---------|--------|
| **Waybar** | Bar | 504 (config) + 625 (CSS) | Status bar with modules (workspaces, clock, audio, battery, tray, media, etc.) | ✅ Feature-rich |
| **Wofi** | Launcher | 222 | Application launcher with fuzzy search, icons, grid view | ✅ Lightweight |
| **swaync** | Notifications | JSON config | Notification daemon + persistent history/control panel | ✅ Full-featured |
| **wlogout** | Power menu | 37 (6 buttons) | Shutdown/reboot/suspend/hibernate/logout/lock buttons with icons | ✅ Simple |

---

## Component-by-Component Mapping

### 1. WAYBAR → Bar in Quickshell

#### What Waybar does (504 config lines)

**Layout**:
- Single horizontal bar, top edge, 30px height
- Left: workspaces + active window title
- Center: clock
- Right: system tray + network + Bluetooth + backlight (laptop) + battery (laptop) + audio + media + custom indicators + notification bell

**Modules** (19 total):

| Module | Displays | Behavior |
|--------|----------|----------|
| `hyprland/workspaces` | Workspace buttons (icons per state) | Click to switch, shows urgent indicator |
| `hyprland/window` | Active window title, max 50 chars truncated | Reactive, updates on focus change |
| `clock` | Date + time, click toggles calendar | Updates every 60s |
| `pulseaudio` | Volume icon + percentage | Scroll to adjust, click opens pavucontrol, right-click mute |
| `mpris` | Media player: status icon + song/artist (truncated) | Click play/pause, scroll volume, right-click next, middle prev |
| `tray` | System tray icons (Nextcloud, network, Bluetooth) | Dynamic, icon-managed |
| `network` | Network status icon | Click opens nmtui, shows SSID/bandwidth tooltip |
| `bluetooth` | Bluetooth icon + device count | Click opens blueman, shows device list |
| `backlight` | Brightness icon + % | Scroll to adjust, click presets (25/50/75%) |
| `battery` | Battery icon + % or time remaining | Shows charge/discharge state, color-coded (ok/warning/critical), click power profile, right-click info |
| `custom/kanata-layer` | Active keyboard layer name | Exec-persistent to TCP socket, click toggles layer |
| `custom/idle-indicator` | Idle lock state | Hidden when idle-lock on, visible when off; click toggles |
| `custom/voxtype` | Mic state (idle/recording/transcribing/stopped) | Exec-persistent to `voxtype status --follow`, click restarts |
| `custom/swaync` | Notification bell + unread count | Exec-persistent to `swaync-client -swb`, click toggles panel, right-click DND, middle clears |

**Interaction**:
- Scroll (volume/brightness adjust)
- Left/right/middle click (mode-dependent per module)
- Tooltips (hover for details)

**Styling**:
- 625 lines of CSS, imports `themes/current/waybar.css`
- Semantic colors (backgrounds, foregrounds, accents)
- Responsive (flexbox layout)

#### Quickshell QML mapping

**Canvas**: `PanelWindow` with anchors (top, left, right) and 30px height.

**Layout**: `RowLayout` with left/center/right sections.

**Workspace module**:
```qml
Repeater {
  model: Hyprland.workspaces
  delegate: Rectangle {
    required property HyprlandWorkspace modelData
    width: 30
    height: 30
    color: modelData.focused ? colors.accentPrimary : colors.bgSecondary
    Text { text: workspaceIcon(modelData) } // icon logic
    MouseArea { onClicked: Hyprland.dispatch(`workspace ${modelData.id}`) }
  }
}
```

**Window title**: Direct binding to `Hyprland.activeToplevel.title`, truncate to 50 chars.

**Clock**: `Clock { interval: 60000 }` + `Text { text: currentTime }` (Qt.formatTime).

**Audio**: Bind to `PipeWire.defaultAudioPlayback`:
```qml
Rectangle {
  Text { text: volumeIcon(device.volume) + ` ${Math.round(device.volume * 100)}%` }
  MouseArea {
    onWheel: device.volume = Math.max(0, Math.min(1, device.volume + wheel.angleDelta.y / 120 * 0.05))
    onClicked: Qt.openUrl("pavucontrol") // or exec script
  }
}
```

**Media**: Bind to `Mpris` singleton:
```qml
Text {
  text: Mpris.currentPlayer ? `${Mpris.currentPlayer.title} - ${Mpris.currentPlayer.artist}` : "—"
}
MouseArea {
  onClicked: Mpris.currentPlayer?.play_pause()
  onRightClicked: Mpris.currentPlayer?.next()
}
```

**Battery**: Bind to `UPower.displayDevice`:
```qml
Text { text: batteryIcon(device.percentage) + ` ${device.percentage}%` }
```

**System tray**: Bind to `StatusNotifier` singleton (icon model).

**Network**: Bind to `NetworkManager` singleton.

**Bluetooth**: Bind to `Bluetooth` singleton.

**Backlight**: Shell out to `light` command (no native Quickshell module):
```qml
Slider {
  value: getBacklight()
  onMoved: { Hyprland.dispatch(`exec light -S ${value * 100}`) }
}
```

**Custom indicators** (kanata, voxtype, idle, swaync):
- Kanata: TCP socket to kanata server (same pattern as Waybar — exec-persistent wrapper)
- Voxtype: Exec `voxtype status --follow --format json`, parse state
- Idle: Shell script, poll / signal
- swaync: Shell script `swaync-client -swb`, parse JSON state

**Challenge**: Quickshell has no native "custom script module" like Waybar. Options:
1. **Shell process wrapper** — spawn a long-lived process, read from stdout/IPC (voxtype, kanata)
2. **Timer-based polling** — `Timer { interval: 1000; onTriggered: updateIndicator() }` (less efficient)
3. **D-Bus signals** — listen to system events (swaync already does this for notifications)

**Styling**: Pure QML (Rectangle colors, Text colors), no CSS. Theming bridge needed (Colors singleton from colors.sh).

#### Feasibility

✅ **Easy**: workspaces, window title, clock, audio, media, battery, network, Bluetooth, tray (all have native bindings)
⚠️ **Medium**: backlight (shell script wrapper), custom indicators (need IPC wrappers)
❌ **Hard**: real-time polling without executor abstraction (Waybar's `exec-persistent` has no direct Quickshell analog)

---

### 2. WOFI → Launcher in Quickshell

#### What Wofi does (22 lines config)

**Features**:
- Floating window, center of screen, 600×400px
- Desktop app search (`.desktop` files, icons, exec)
- Fuzzy matching, case-insensitive
- Shows app icons (32px)
- Click to launch
- Keyboard navigation (arrows, Tab, Enter, Escape)
- No actions/right-click menu

**Styling**:
- 1 CSS import from theme
- Window bg, input field, item hover, selected item colors

#### Quickshell QML mapping

**Canvas**: `FloatingWindow` centered on screen.

**Model**: Use `DesktopEntry` or iterate `/usr/share/applications/*.desktop` manually (no native bulk-load, but QProcess can list).

```qml
import Quickshell

FloatingWindow {
  width: 600
  height: 400
  
  ColumnLayout {
    TextField {
      id: searchInput
      placeholderText: "Search Applications..."
      onTextChanged: filterApps()
    }
    
    ListView {
      model: filteredApps // JavaScript array, filtered on each keystroke
      delegate: Rectangle {
        height: 50
        color: mouseArea.containsMouse ? colors.accentPrimary : colors.bgPrimary
        Text { text: modelData.name }
        Image { source: modelData.icon; width: 32 }
        
        MouseArea {
          id: mouseArea
          anchors.fill: parent
          onClicked: {
            Qt.openUrl(`file://${modelData.exec}`)
            // or: Hyprland.dispatch(`exec ${modelData.exec}`)
            parent.parent.parent.visible = false
          }
        }
      }
    }
  }
}
```

**Keyboard nav**: `Keys.onPressed` for arrow/tab/enter/escape.

**Fuzzy match**: QML string operations (simple substring / Levenshtein distance if needed).

**Challenge**: `.desktop` file parsing (exec extraction, icon resolution) requires custom logic or a QProcess call to `desktop-file-utils`.

#### Feasibility

✅ **Easy**: window, search field, list, click to launch
⚠️ **Medium**: `.desktop` file parsing (need custom exec extractor or system call)
❌ **Hard**: icon loading without explicit path resolution

---

### 3. SWAYNC → Notifications in Quickshell

#### What swaync does (JSON config, 39 lines)

**Components**:
1. **Notification daemon** — listens for Freedesktop notifications (D-Bus)
2. **Notification popup** — transient window showing latest notification (top-right, 500px wide, auto-timeout 10s)
3. **Control center panel** — persistent slide-out panel (top-right, 500×600px) showing:
   - Title + "Clear All" button
   - Do-Not-Disturb toggle
   - MPRIS widget (media player, show album art)
   - Grouped notifications with action buttons

**Features**:
- Notification grouping by app
- Persistent history (survives daemon restart if `keepOnReload: true`)
- Action buttons (reply, dismiss, open)
- DND mode (suppress notifications)
- Custom timeout per urgency (critical = 0/infinite)
- Markup + hyperlink + image support (config flags)

**Styling**:
- `style.css` imports theme
- Button colors (accent per action state)
- Background/foreground hierarchy
- Spacing/padding

#### Quickshell QML mapping

**Daemon**: Quickshell has native `NotificationServer` QML singleton. Just instantiate:

```qml
NotificationServer {
  id: notifServer
  bodySupported: true
  bodyMarkupSupported: true
  persistenceSupported: true
}
```

All notifications arrive in `notifServer.notifications` array, reactive.

**Popup** (transient notification):

```qml
PanelWindow {
  id: notifPopup
  anchors {
    right: true
    top: true
  }
  width: 500
  
  // Show latest notification, auto-hide after timeout
  Loader {
    sourceComponent: {
      if (notifServer.notifications.length > 0) {
        let notif = notifServer.notifications[0];
        return notificationComponent;
      }
      return null;
    }
  }
  
  Timer {
    interval: 10000 // 10s
    running: notifPopup.visible
    onTriggered: notifPopup.visible = false
  }
}
```

**Control center panel**:

```qml
PanelWindow {
  id: controlCenter
  anchors {
    right: true
    top: true
  }
  margins { top: 0; right: 0 }
  
  Column {
    Text { text: "Notifications" }
    Button { text: "Clear All"; onClicked: notifServer.notifications.forEach(n => n.close()) }
    
    Switch {
      text: "Do Not Disturb"
      onToggled: dndMode = checked
    }
    
    // MPRIS widget (if Mpris player exists)
    Loader {
      sourceComponent: mprisComponent
      visible: Mpris.currentPlayer !== null
    }
    
    // Notification list
    Repeater {
      model: notifServer.notifications
      delegate: Rectangle {
        required property Notification modelData
        
        Column {
          Text { text: modelData.appName }
          Text { text: modelData.summary; font.bold: true }
          Text { text: modelData.body }
          
          // Action buttons
          Row {
            Repeater {
              model: modelData.actions
              Button {
                text: modelData.action
                onClicked: modelData.invoke(modelData.action)
              }
            }
          }
          
          Button { text: "Dismiss"; onClicked: modelData.close() }
        }
      }
    }
  }
}
```

**DND mode**: Store locally (no native Quickshell DND, so implement as property + filter).

**MPRIS widget**: Use `Mpris` singleton (album art, title, artist, controls).

**Challenge**: Notification actions (Freedesktop notification spec has action IDs, not text). Model must provide a way to invoke actions.

#### Feasibility

✅ **Easy**: daemon (native), notification list, DND toggle, basic styling
⚠️ **Medium**: action button routing (need custom Notification subclass or signal mapping)
❌ **Hard**: rich notification rendering (markup, images, custom layouts per app)

---

### 4. WLOGOUT → Power Menu in Quickshell

#### What wlogout does (37 lines)

**Features**:
- 6 buttons arranged in grid:
  1. **Lock** (`hyprlock`)
  2. **Logout** (`hyprctl dispatch exit`)
  3. **Suspend** (`systemctl suspend`)
  4. **Hibernate** (`systemctl hibernate`)
  5. **Reboot** (`systemctl reboot`)
  6. **Shutdown** (`systemctl poweroff`)
- Each button has icon + label + keybind (l, e, u, h, r, s)
- Trigger: `Super+Shift+E`
- Positioned on screen (layout file specifies position, usually center)

**Styling**:
- Each button gets a semantic accent color (warning, error, primary, etc.)
- GTK CSS import from theme
- Button size, spacing, rounding

#### Quickshell QML mapping

**Canvas**: `PopupWindow` (transient, closes on focus loss) or `FloatingWindow` (persistent until closed).

```qml
FloatingWindow {
  width: 400
  height: 300
  
  GridLayout {
    columns: 3
    rows: 2
    
    // Lock
    PowerButton {
      icon: "󰌾"
      label: "Lock"
      color: colors.accentTertiary
      keybind: "L"
      onClicked: Hyprland.dispatch("exec hyprlock")
    }
    
    // Logout
    PowerButton {
      icon: "󰍃"
      label: "Logout"
      color: colors.accentWarning
      keybind: "E"
      onClicked: {
        Qt.openUrl("exec ~/.local/lib/scripts/desktop/session-save")
        Hyprland.dispatch("exit")
      }
    }
    
    // Suspend
    PowerButton {
      icon: ""
      label: "Suspend"
      color: colors.accentPrimary
      keybind: "U"
      onClicked: Qt.openUrl("systemctl suspend")
    }
    
    // Hibernate
    PowerButton {
      icon: "󰜗"
      label: "Hibernate"
      color: colors.accentHighlight
      keybind: "H"
      onClicked: Qt.openUrl("systemctl hibernate")
    }
    
    // Reboot
    PowerButton {
      icon: "󰜉"
      label: "Reboot"
      color: colors.accentInfo
      keybind: "R"
      onClicked: {
        Qt.openUrl("exec ~/.local/lib/scripts/desktop/session-save reboot")
        Qt.openUrl("systemctl reboot")
      }
    }
    
    // Shutdown
    PowerButton {
      icon: "󰤂"
      label: "Shutdown"
      color: colors.accentError
      keybind: "S"
      onClicked: {
        Qt.openUrl("exec ~/.local/lib/scripts/desktop/session-save shutdown")
        Qt.openUrl("systemctl poweroff")
      }
    }
  }
  
  // Keyboard handler
  Keys.onPressed: (event) => {
    switch (String.fromCharCode(event.key).toUpperCase()) {
      case "L": Hyprland.dispatch("exec hyprlock"); break;
      case "E": Hyprland.dispatch("dispatch exit"); break;
      // ... etc
    }
  }
}
```

**Keybinding trigger**: Hyprland binding `Super+Shift+E` → `hyprctl dispatch exec "quickshell --show power-menu"` (or similar).

**Styling**: Rectangle colors (buttons), Text colors (labels), Icon colors (semantic).

#### Feasibility

✅ **Easy**: window, buttons, icons, keybinds, system commands
⚠️ **Medium**: confirm dialogs (optional, safety for destructive actions)

---

## Summary: Quickshell Feature Coverage

| Component | Coverage | Key blockers | Quickshell modules needed |
|-----------|----------|--------------|--------------------------|
| **Waybar bar** | 85% | Custom script exec (kanata, voxtype, swaync indicator), backlight abstraction | `Hyprland`, `PipeWire`, `UPower`, `Mpris`, `StatusNotifier`, `NetworkManager`, `Bluetooth` |
| **Wofi launcher** | 80% | `.desktop` file parsing, icon resolution | Custom QML (or wrap `gio open` / QDesktopServices) |
| **swaync notifications** | 90% | Rich notification rendering (markup, images), action routing | `NotificationServer`, `Mpris` |
| **wlogout power menu** | 95% | Confirm dialog, session-save integration | `Hyprland` (for dispatch), QProcess (for systemctl) |

---

## Integration Challenges

### 1. Custom script execution & IPC (kanata, voxtype, swaync indicator)

Waybar has `exec-persistent` and `exec` directives that continuously read from a subprocess. Quickshell has:
- `QProcess` (C++ / Qt, accessible from QML via custom C++ modules)
- No built-in persistent-read abstraction

**Solution**: Wrap these in QML helper components or rewrite them as D-Bus services (swaync already emits D-Bus; kanata TCP could be watched via a QProcess loop).

### 2. `.desktop` file parsing (wofi launcher)

Wofi uses GTK's desktop file loader. Quickshell has no native `.desktop` parser.

**Solution**:
- QML wrapper around `gio desktop-entry` or `desktop-file-utils`
- Or: pre-parse `.desktop` files at startup via shell script, cache JSON

### 3. Theming bridge (colors.sh → QML)

Current: semantic colors in `colors.sh` (Bash vars), consumed by shell scripts.
Needed: same vars in QML (Colors singleton or JSON).

**Solution**:
- Generate `Colors.qml` from `colors.sh` at theme switch time
- Or: `colors.json` consumed at app startup
- Both triggered by `theme switch` (add to theme-switcher)

### 4. Backlight control (requires `light` command)

Quickshell has no native backlight module. Need QProcess wrapper.

**Solution**: `Hyprland.dispatch("exec light -S X")` or custom QProcess + Slider binding.

---

## Next Steps

1. **Theming bridge design** — decide colors.sh → QML Colors mechanism
2. **Component prioritization** — which to build first (bar → launcher → notifications → power menu)
3. **Shared module patterns** — extract reusable QML components (buttons, icons, lists, etc.)
4. **Script executor abstraction** — unified pattern for long-lived processes (kanata, voxtype, swaync) + fallback for non-persistent commands
5. **Prototype** — build bar + launcher skeleton alongside current stack, validate coexistence + theme bridge before full migration
