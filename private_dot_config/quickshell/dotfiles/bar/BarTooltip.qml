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
    // The click hint, under the text in the meta step. It is chrome this repo
    // authored, so it needs no PlainText pin — but it still gets one, because
    // it shares a Text type with `text`, which is foreign.
    property string hint: ""
    property bool monospace: false
    required property string text

    color: "transparent"
    implicitHeight: content.implicitHeight + 12
    implicitWidth: content.implicitWidth + 20

    // 🚨 `edges`/`gravity` MUST be set. The defaults are `Top | Left` /
    // `Bottom | Right` (popupanchor.hpp), and with `anchor.item` set the anchor
    // rect is the item's full boundingRect (popupanchor.cpp updateAnchor), so
    // the default anchorY is the widget's TOP edge — the tooltip lands on top
    // of the widget it describes. That steals the pointer, so containsMouse
    // drops, the tooltip hides, the pointer returns, and it flickers forever;
    // it also swallows every click meant for the widget.
    //
    // `Edges.Bottom` for both anchors the popup to the widget's bottom edge and
    // centres it horizontally (gravity with neither Left nor Right centres —
    // popupanchor.cpp calcEffectiveX).
    anchor {
        // qmllint disable missing-type
        edges: Edges.Bottom
        gravity: Edges.Bottom
        // qmllint enable missing-type
        item: root.anchorItem
    }

    Rectangle {
        anchors.fill: parent
        border.color: Theme.edge
        border.width: Config.hairline
        color: Theme.groundFloat
        radius: Config.radiusChip

        // themes/CLAUDE.md: fg-primary on an elevated surface, never
        // fg-secondary — the hint included. groundFloat is elevated, so the
        // hint is set apart by size alone.
        Column {
            id: content

            anchors.centerIn: parent
            spacing: Config.gap / 2

            Text {
                color: Theme.inkPrimary
                font.family: root.monospace ? Config.terminalFont : Config.guiFont
                font.pixelSize: Config.fontBody
                text: root.text
                textFormat: Text.PlainText
                visible: root.text !== ""
            }

            Text {
                color: Theme.inkPrimary
                font.family: Config.terminalFont
                font.pixelSize: Config.fontMeta
                text: root.hint
                textFormat: Text.PlainText
                visible: root.hint !== ""
            }
        }
    }
}
