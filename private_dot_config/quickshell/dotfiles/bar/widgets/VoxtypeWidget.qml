import "../"
import "../../"
import Quickshell
import QtQuick

// Waybar's custom/voxtype. `voxtype status --follow` is event-driven (no
// polling) and read directly: since voxtype 1.0 the daemon stays up and
// unloads its model at idle itself, so there is no restart window left for a
// wrapper to report.
BarWidget {
    id: root

    readonly property string voxState: source.alt

    icon: {
        switch (root.voxState) {
        case "recording":
            return "󰑋";
        case "streaming":
            return "󱜠";
        case "transcribing":
            return "󰔮";
        case "stopped":
            return "󰍭";
        default:
            return "";
        }
    }
    // Mic activity and daemon lifecycle, per waybar/CLAUDE.md: recording is
    // the loud one, stopped stays visible so failures are not silent. Every
    // state this renders is off-normal, so all of them keep their colour.
    iconColor: {
        switch (root.voxState) {
        case "recording":
        case "stopped":
            return Theme.signalError;
        // streaming and transcribing both have their own glyph, which is the
        // carrier. They used to take signalInfo and signalWarn, both of
        // which measure under 3:1 on a light ground in four of the eight
        // colorsets — a state colour nobody could see is worse than none.
        case "streaming":
        case "transcribing":
            return root.restColor;
        default:
            return root.restColor;
        }
    }
    tooltipText: source.tooltip

    onClicked: Quickshell.execDetached(["systemctl", "--user", "restart", "voxtype"])

    WaybarJsonSource {
        id: source

        command: ["voxtype", "status", "--follow", "--format", "json"]
    }
}
