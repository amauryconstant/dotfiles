import "../"
import QtQuick

// One row inside a popover: rowH tall, radiusChip, a leading glyph, a label,
// and one trailing slot. Design page Shell-06-Popovers for the shape, page 03
// for the states.
//
// 🚨 Hover and the keyboard cursor are ONE state, deliberately: two visuals
// would let a row be both at once, which has no defined appearance. So both
// draw `groundRaised`, and only the ring separates a keyboard cursor from a
// pointer sitting on the row.
//
// 🚨 There is ONE trailing slot. A row reporting an operation in flight says so
// in `status`, which takes the slot over — an operation cannot collide with a
// badge, because the row that started it is the row that reports it.
Item {
    id: root

    property string badge: ""
    // What a right click on this row offers, in ContextMenu's shape. Empty
    // means the right button does nothing here.
    property var menuActions: []
    // The host surface's menu. Set by the payload, never found: the row cannot
    // know which surface it is drawn in.
    property ContextMenu menu: null
    // A row whose sibling is mid-operation. Page 03: disabled is opacity, never
    // a token swap, and it exists in exactly this one situation.
    property bool dimmed: false
    property string glyph: ""
    readonly property bool grounded: root.hovered || root.cursor
    readonly property alias hovered: mouse.containsMouse
    property string label: ""
    // The keyboard cursor is on this row.
    property bool cursor: false
    property bool showRing: false
    property string status: ""
    property bool selected: false

    signal clicked

    function openMenu(keyboard: bool): void {
        if (root.menu && root.menuActions.length > 0)
            root.menu.show(root, root.menuActions, keyboard);
    }

    height: Config.rowH
    implicitHeight: Config.rowH
    opacity: root.dimmed ? Theme.disabledOpacity : 1
    width: parent ? parent.width : 0

    Rectangle {
        anchors.fill: parent
        // 🚨 `select` is SIGNAL_FOCUS at 13% and reaches only 1.10–1.98 against
        // its own ground, so it never carries the state alone — the ↵ mark in
        // the trailing slot is the second carrier, exactly as the launcher does.
        border.color: root.showRing ? Theme.focusRing : "transparent"
        border.width: root.showRing ? Config.popRingWidth : 0
        color: root.selected ? Theme.select : root.grounded ? Theme.groundRaised : "transparent"
        radius: Config.radiusChip

        Behavior on color {
            ColorAnimation {
                duration: Config.motionFast
            }
        }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Config.gap + Config.hairline
        anchors.right: trailing.left
        anchors.rightMargin: Config.gap
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.gap + 2

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: root.selected ? Theme.signalFocus : Theme.inkPrimary
            font.family: Config.guiFont
            font.pixelSize: Config.glyphRow
            text: root.glyph
            visible: root.glyph !== ""
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.inkPrimary
            elide: Text.ElideRight
            font.family: Config.guiFont
            font.pixelSize: Config.fontBody
            text: root.label
            textFormat: Text.PlainText
            width: Math.min(implicitWidth, root.width - Config.padLoose * 2)
        }
    }

    Text {
        id: trailing

        anchors.right: parent.right
        anchors.rightMargin: Config.gap + Config.hairline
        anchors.verticalCenter: parent.verticalCenter
        color: root.selected ? Theme.signalFocus : Theme.inkSecondary
        font.family: Config.terminalFont
        font.pixelSize: Config.fontMeta
        // 🚨 The ↵ follows the CURSOR, never `selected`. They mean different
        // things here than in the launcher: `selected` is "this is the current
        // device / the active route", which Enter would not change, and a mark
        // saying otherwise on a row that does nothing is a lie about the key.
        text: root.status !== "" ? root.status : root.cursor ? "↵" : root.badge
    }

    MouseArea {
        id: mouse

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        anchors.fill: parent
        enabled: !root.dimmed
        hoverEnabled: true

        onClicked: event => {
            if (event.button === Qt.RightButton)
                root.openMenu(false);
            else
                root.clicked();
        }
    }

    // The Menu key reaches the row under the keyboard cursor, and only it.
    Connections {
        function onKeyRequested(): void {
            root.openMenu(true);
        }

        enabled: root.cursor && !root.dimmed
        target: root.menu
    }
}
