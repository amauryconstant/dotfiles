pragma Singleton

import Quickshell
import Quickshell.Io

// Internal-backlight state, read straight from sysfs. A singleton because two
// surfaces render it -- the bar widget and the OSD -- and a second FileView on
// the same file would just be a second inotify watch on the same bytes.
//
// Writes are NOT here: they go through desktop/brightness-set, which is
// DDC/CI-aware and already bound to XF86MonBrightnessUp/Down.
Singleton {
    id: root

    property int maxValue: 0
    property int rawValue: 0
    // Machine-specific (intel_backlight here, amdgpu_bl0 elsewhere), so it is
    // resolved at runtime rather than hardcoded.
    property string device: ""
    // False on a desktop with a DDC monitor: there is no sysfs backlight, and
    // reading the current value costs a ~200ms ddcutil probe per update. Those
    // machines keep using the brightness keys alone.
    readonly property bool available: root.device !== "" && root.maxValue > 0
    readonly property int percent: root.maxValue > 0 ? Math.round(root.rawValue / root.maxValue * 100) : 0

    Process {
        command: ["sh", "-c", "for d in /sys/class/backlight/*/; do printf %s \"$d\"; break; done"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.device = this.text.trim()
        }
    }

    FileView {
        path: root.device === "" ? "" : `${root.device}max_brightness`

        onLoaded: root.maxValue = parseInt(this.text().trim(), 10) || 0
    }

    FileView {
        path: root.device === "" ? "" : `${root.device}brightness`
        watchChanges: true

        onFileChanged: this.reload()
        onLoaded: root.rawValue = parseInt(this.text().trim(), 10) || 0
    }
}
