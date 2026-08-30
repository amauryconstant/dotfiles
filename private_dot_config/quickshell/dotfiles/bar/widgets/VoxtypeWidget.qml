import "../"
import "../../"
import Quickshell
import QtQuick

// Waybar's custom/voxtype. voxtype-waybar-status is reused unchanged: it
// wraps `voxtype status --follow` and layers a synthetic "loading" state that
// voxtype itself has no equivalent for, which is worth more than a
// reimplementation would be.
BarWidget {
    id: root

    readonly property string voxState: source.alt

    tooltipText: source.tooltip

    onClicked: Quickshell.execDetached(["systemctl", "--user", "restart", "voxtype"])

    WaybarJsonSource {
        id: source

        command: [`${Config.scriptsDir}/desktop/voxtype-waybar-status`]
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        // Mic activity and daemon lifecycle, per waybar/CLAUDE.md: recording
        // is the loud one, stopped stays visible so failures are not silent.
        color: {
            switch (root.voxState) {
            case "recording":
            case "stopped":
                return Theme.accentError;
            case "streaming":
            case "loading":
                return Theme.accentInfo;
            case "transcribing":
                return Theme.accentWarning;
            default:
                return Theme.fgMuted;
            }
        }
        font.family: Config.guiFont
        font.pixelSize: Config.fontSize
        text: {
            switch (root.voxState) {
            case "recording":
                return "󰑋";
            case "streaming":
                return "󱜠";
            case "transcribing":
                return "󰔮";
            case "loading":
                return "󰝲";
            case "stopped":
                return "󰍭";
            default:
                return "";
            }
        }
    }
}
