import "../"
import "../../"
import Quickshell
import QtQuick

// The bar's single load readout (design page Shell-04-Bar). New — Waybar's
// config here carried no cpu, memory or temperature module, so there is nothing
// this replaces.
//
// 🚨 ONE number, always present. Not one per source: two permanent readouts
// side by side is the noise the accent rule exists to stop, and the tooltip is
// where the breakdown belongs. And not a widget that appears only in trouble —
// that teaches nobody where to look and reflows the bar at the worst possible
// moment.
BarWidget {
    id: root

    readonly property int value: Meters.highest
    readonly property bool warning: root.value >= Config.meterWarnPercent

    // A tint UNDER the number, never a colour on the digits: a percentage has
    // to stay readable at exactly the moment it is worth reading.
    groundColor: root.value >= Config.meterCriticalPercent ? Qt.alpha(Theme.signalError, 0.18) : root.warning ? Qt.alpha(Theme.signalWarn, 0.18) : Theme.groundRaised
    icon: Config.meterGlyph
    label: `${root.value}%`
    // Digits only line up in a fixed-pitch face, and this one changes width.
    monoLabel: true
    // A permanent ground, like the battery: this is the other number on the bar
    // that has to be readable without a hover.
    pill: true
    tooltipText: `${qsTr("CPU")}  ${Meters.cpu}%\n${qsTr("Memory")}  ${Meters.memory}%`
    tooltipMonospace: true

    onClicked: Quickshell.execDetached([Config.terminal, "-e", "btop"])
}
