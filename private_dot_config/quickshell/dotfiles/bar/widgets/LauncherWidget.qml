import "../"
import "../../"
import Quickshell
import QtQuick

// The launcher chip that opens the bar's left zone. Not a Waybar port —
// Waybar had no such module; SUPER+D was the only way in.
//
// This is the one place the accent appears at rest (Amendment A): the chip
// carries a tinted accent ground so the bar has a single fixed anchor point,
// and every other widget stays neutral until something is actually happening.
BarWidget {
    id: root

    groundColor: Qt.alpha(Theme.accentPrimary, 0.12)
    icon: "󰣇"
    iconColor: Theme.accentPrimary
    tinted: true
    tooltipText: "Applications"

    onClicked: Quickshell.execDetached(["wofi", "--show", "drun"])
}
