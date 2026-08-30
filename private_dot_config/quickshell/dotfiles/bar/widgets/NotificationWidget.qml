import "../"
import "../../"
import Quickshell
import QtQuick

// Waybar's custom/swaync. Still shelling out to swaync-client: Phase 4
// replaces the notification backend wholesale, and until then the bell has to
// report swaync's real state or the primary bar simply has no bell.
BarWidget {
    id: root

    readonly property bool dnd: source.alt.startsWith("dnd")

    tooltipText: source.tooltip

    onClicked: Quickshell.execDetached(["swaync-client", "-t", "-sw"])
    onMiddleClicked: Quickshell.execDetached(["swaync-client", "-c", "-sw"])
    onRightClicked: Quickshell.execDetached(["swaync-client", "-d", "-sw"])

    WaybarJsonSource {
        id: source

        command: ["swaync-client", "-swb"]
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: root.dnd ? Theme.accentError : source.text !== "" && source.text !== "0" ? Theme.accentWarning : Theme.fgPrimary
        font.family: Config.guiFont
        font.pixelSize: Config.fontSize
        text: {
            const icons = {
                "notification": "󰂚",
                "none": "󰂜",
                "dnd-notification": "󰂛",
                "dnd-none": "󰪑"
            };
            const icon = icons[source.alt] ?? "󰂜";
            return source.text !== "" && source.text !== "0" ? `${icon}${source.text}` : icon;
        }
    }
}
