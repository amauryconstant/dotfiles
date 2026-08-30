import "../"
import "../../"
import Quickshell
import Quickshell.Io
import QtQuick

// Waybar's backlight module never actually rendered: it was gated on
// `exec-if: which light`, and `light` is neither installed nor in
// packages.yaml. So this is not a port of a working module — it is the first
// time the bar has shown brightness at all.
//
// Reads sysfs directly and event-driven via watchChanges, rather than
// Waybar's 2s poll. Writes go through brightness-set, which is already
// DDC/CI-aware and bound to XF86MonBrightnessUp/Down.
BarWidget {
    id: root

    property int maxValue: 0
    property int rawValue: 0
    // The device name is machine-specific (intel_backlight here, amdgpu_bl0
    // elsewhere), so it is resolved at runtime rather than hardcoded.
    property string device: ""
    readonly property int percent: root.maxValue > 0 ? Math.round(root.rawValue / root.maxValue * 100) : 0

    tooltipText: `Brightness: ${root.percent}%`
    // No internal backlight means a desktop with a DDC monitor, where reading
    // the current value costs a ~200ms ddcutil probe per update. Not worth a
    // bar widget; those machines keep using the brightness keys alone.
    visible: Config.isLaptop && root.device !== ""

    onScrolledDown: Quickshell.execDetached([`${Config.scriptsDir}/desktop/brightness-set`, "down"])
    onScrolledUp: Quickshell.execDetached([`${Config.scriptsDir}/desktop/brightness-set`, "up"])

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

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.accentWarning
        font.family: Config.guiFont
        font.pixelSize: Config.fontSize
        text: {
            const icons = ["", "", "", "", "", "", "", "", ""];
            return `${icons[Math.min(8, Math.floor(root.percent / 12.5))]} ${root.percent}%`;
        }
    }
}
