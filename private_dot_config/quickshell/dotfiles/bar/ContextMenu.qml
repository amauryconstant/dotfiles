pragma ComponentBehavior: Bound

import "../"
import QtQuick

// The right-click menu of a row: a short list of what that row can do, under
// the bar's click grammar (left acts, right lists the acts).
//
// 🚨 An ITEM overlaid on its host surface, never a window. A PopupWindow
// parented to a popover that is itself parented to a layer surface stacks the
// grab failures BarPopover.qml documents; an Item has none of them, and inside
// the popover's chrome it keeps the chrome's HoverHandler satisfied, so a
// pointer-mode popover does not close while the pointer is on its menu.
//
// The host fills itself with this and calls `show()`. Anything outside the
// panel is a catcher: a click there closes the menu and nothing else.
//
// 🚨 The ground is `groundBase`, the popover's own, set apart by the hairline.
// An elevated ground would ban `inkSecondary` and force a second ink rule onto
// a list that already reads in `inkPrimary` alone.
Item {
    id: root

    // [{ label, glyph?, run: function, destructive? }]
    property var actions: []
    property int cursor: -1
    property bool keyboard: false

    // Raised by the host's Menu key. The row under the keyboard cursor answers
    // by calling show() on itself — the host knows the index, only the row
    // knows its own actions and where it sits.
    signal keyRequested

    function hide(): void {
        root.visible = false;
        root.actions = [];
        root.cursor = -1;
    }

    function move(delta: int): void {
        const n = root.actions.length;
        if (n > 0)
            root.cursor = (root.cursor + delta + n) % n;
    }

    function run(index: int): void {
        const action = root.actions[index] ?? null;
        root.hide();
        action?.run();
    }

    function show(row: Item, actions: var, keyboard: bool): void {
        if (!actions || actions.length === 0)
            return;
        root.actions = actions;
        root.keyboard = keyboard;
        root.cursor = keyboard ? 0 : -1;
        // Right-aligned under the row, or above it when the host has no room
        // below — the menu never leaves the surface it is drawn in.
        const at = row.mapToItem(root, 0, 0);
        const height = actions.length * Config.rowH + Config.gap;
        panel.x = Math.max(Config.gap, at.x + row.width - panel.width);
        panel.y = at.y + row.height + height + Config.gap <= root.height ? at.y + row.height : Math.max(Config.gap, at.y - height);
        root.visible = true;
    }

    visible: false
    z: 10

    MouseArea {
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        anchors.fill: parent

        onClicked: root.hide()
        // Swallowed, so a list under the menu does not scroll away from it.
        onWheel: event => event.accepted = true
    }

    Rectangle {
        id: panel

        border.color: Theme.edge
        border.width: Config.hairline
        color: Theme.groundBase
        height: items.implicitHeight + Config.gap
        radius: Config.radiusPanel
        width: Config.contextMenuWidth

        // Swallows clicks between items so the catcher behind does not close.
        MouseArea {
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            anchors.fill: parent
        }

        Column {
            id: items

            anchors.left: parent.left
            anchors.margins: Config.gap / 2
            anchors.right: parent.right
            anchors.top: parent.top

            Repeater {
                model: root.actions

                Item {
                    id: item

                    required property int index
                    required property var modelData

                    readonly property bool cursor: root.keyboard && root.cursor === item.index

                    height: Config.rowH
                    width: parent.width

                    Rectangle {
                        anchors.fill: parent
                        border.color: item.cursor ? Theme.focusRing : "transparent"
                        border.width: item.cursor ? Config.popRingWidth : 0
                        color: item.cursor || itemMouse.containsMouse ? Theme.groundRaised : "transparent"
                        radius: Config.radiusChip
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Config.gap
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Config.gap + 2

                        // signalError on the GLYPH only, the one semantic
                        // colour that clears 3:1 on groundBase in every theme.
                        // The label stays inkPrimary and carries the meaning.
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: item.modelData.destructive ? Theme.signalError : Theme.inkPrimary
                            font.family: Config.guiFont
                            font.pixelSize: Config.glyphRow
                            text: item.modelData.glyph ?? ""
                            visible: text !== ""
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.inkPrimary
                            font.family: Config.guiFont
                            font.pixelSize: Config.fontBody
                            text: item.modelData.label
                            textFormat: Text.PlainText
                        }
                    }

                    MouseArea {
                        id: itemMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: root.run(item.index)
                    }
                }
            }
        }
    }
}
