import "../"
import Quickshell
import QtQuick

// Hover tooltip. Waybar gave every module a tooltip for free; Quickshell has
// no such affordance, so BarWidget composes this and every widget gets it by
// setting `tooltipText`.
//
// PopupWindow comes from the Quickshell._Window indirection, the same as
// PanelWindow — it trips qmllint's uncreatable-type check, which the lint task
// already exempts. That exemption covers this; it must not be widened further.
PopupWindow {
    id: root

    required property Item anchorItem
    property bool monospace: false
    required property string text

    color: "transparent"
    implicitHeight: label.implicitHeight + 12
    implicitWidth: label.implicitWidth + 20

    // `edges`/`gravity` are deliberately left at their defaults, which already
    // place the popup below the anchor — exactly what a top bar wants. Setting
    // them explicitly would need `--missing-type disable`, because PopupAnchor
    // declares them as Edges::Flags and qmllint cannot resolve that type across
    // Quickshell's module split. Widening the exemption list to buy two
    // redundant lines is the trade the lint task exists to prevent.
    anchor {
        item: root.anchorItem
    }

    Rectangle {
        anchors.fill: parent
        border.color: Theme.accentBorder
        border.width: 1
        color: Theme.bgOverlay
        radius: 6

        // themes/CLAUDE.md: fg-primary on an elevated surface, never
        // fg-secondary. bgOverlay is elevated.
        Text {
            id: label

            anchors.centerIn: parent
            color: Theme.fgPrimary
            font.family: root.monospace ? Config.terminalFont : Config.guiFont
            font.pixelSize: Config.fontSize
            text: root.text
        }
    }
}
