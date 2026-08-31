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
    readonly property bool unread: source.text !== "" && source.text !== "0"

    icon: {
        const icons = {
            "notification": "󰂚",
            "none": "󰂜",
            "dnd-notification": "󰂛",
            "dnd-none": "󰪑"
        };
        return icons[source.alt] ?? "󰂜";
    }
    // Both do-not-disturb and a waiting notification are states; an idle bell
    // is the resting case and stays neutral.
    iconColor: root.dnd ? Theme.accentError : root.unread ? Theme.accentWarning : root.restColor
    label: root.unread ? source.text : ""
    monoLabel: true
    tooltipText: source.tooltip

    onClicked: Quickshell.execDetached(["swaync-client", "-t", "-sw"])
    onMiddleClicked: Quickshell.execDetached(["swaync-client", "-c", "-sw"])
    onRightClicked: Quickshell.execDetached(["swaync-client", "-d", "-sw"])

    WaybarJsonSource {
        id: source

        command: ["swaync-client", "-swb"]
    }
}
