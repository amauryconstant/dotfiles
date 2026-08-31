import "../"
import QtQuick

// Shared base for every bar widget: the chip, the accent rule, the tooltip,
// and the click/scroll plumbing. A widget file is then only its data binding
// and its format string, which is what keeps 14 of them readable.
//
// 🚨 The accent rule lives here and nowhere else. `iconColor` defaults to
// fg-secondary, so a widget is neutral at rest unless it explicitly overrides
// for a real state — that is the whole rule from Amendment A ("exactly one
// accent marks the focused thing, everything else neutral, semantic colours
// only for state"), enforced in one place instead of eleven.
Item {
    id: root

    default property alias content: layout.data
    property bool hoverBackground: true
    readonly property alias hovered: mouse.containsMouse
    // A lit ground is an elevated surface, and themes/CLAUDE.md forbids
    // fg-secondary there — hence the swap rather than one fixed rest colour.
    readonly property bool grounded: root.pill || root.tinted || (root.hoverBackground && mouse.containsMouse)
    // 🚨 The neutral a widget falls back to when no state applies. A widget
    // overriding iconColor/labelColor for a state MUST end its ternary on this,
    // never on a flat Theme.fgSecondary: that pins the ungrounded colour onto a
    // lit ground and reintroduces the banned fg-secondary/bg-secondary pair.
    readonly property color restColor: root.grounded ? Theme.fgPrimary : Theme.fgSecondary
    property string icon: ""
    property color iconColor: root.restColor
    property string label: ""
    // Split from iconColor so a widget can colour its glyph for a state while
    // the number it carries stays readable, as the battery pill does.
    property color labelColor: root.restColor
    // Digits only line up in a fixed-pitch face, and a proportional one
    // reflows the bar every time the number changes width.
    property bool monoLabel: false
    // A pill is a widget carrying a number that must actually be read at a
    // glance. Amendment A grants exactly one: the battery.
    property bool pill: false
    // Only the launcher chip sets this: a permanent ground that is not a pill.
    property bool tinted: false
    property color groundColor: Theme.bgSecondary
    // Calendars and device lists only line up in a fixed-pitch font.
    property bool tooltipMonospace: false
    property string tooltipText: ""

    signal clicked
    signal middleClicked
    signal rightClicked
    signal scrolledDown
    signal scrolledUp

    implicitHeight: Config.barHeight
    // A lone glyph lands on a 26px square; anything with a label grows from it.
    implicitWidth: Math.max(Config.chipSize, layout.implicitWidth + Config.padTight)
    visible: layout.implicitWidth > 0

    Rectangle {
        anchors.centerIn: parent
        color: root.pill || root.tinted ? root.groundColor : Theme.bgSecondary
        height: Config.chipSize
        opacity: root.grounded ? 1 : 0
        radius: root.pill ? Config.radiusPill : Config.radiusChip
        width: parent.width

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
    }

    Row {
        id: layout

        anchors.centerIn: parent
        spacing: Config.gap / 2

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: root.iconColor
            font.family: Config.guiFont
            font.pixelSize: Config.fontSize
            text: root.icon
            visible: root.icon !== ""
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: root.labelColor
            font.family: root.monoLabel ? Config.terminalFont : Config.guiFont
            font.pixelSize: root.monoLabel ? Config.fontSizeSmall : Config.fontSize
            text: root.label
            visible: root.label !== ""
        }
    }

    // 🚨 `z: -1` is load-bearing. Content goes into `layout`, which is declared
    // above this, so at the default z this MouseArea covers every child and
    // consumes their events — that is what killed the per-workspace and
    // per-tray-item clicks (and left WorkspacesWidget's hover highlight dead,
    // since its own `containsMouse` could never become true).
    //
    // Below the Row, a child MouseArea wins where one exists, and everywhere
    // else the event falls through to this one, because Text and Rectangle do
    // not accept mouse events.
    MouseArea {
        id: mouse

        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        anchors.fill: parent
        hoverEnabled: true
        z: -1

        onClicked: event => {
            if (event.button === Qt.RightButton)
                root.rightClicked();
            else if (event.button === Qt.MiddleButton)
                root.middleClicked();
            else
                root.clicked();
        }
        onWheel: event => {
            if (event.angleDelta.y > 0)
                root.scrolledUp();
            else if (event.angleDelta.y < 0)
                root.scrolledDown();
        }
    }

    BarTooltip {
        anchorItem: root
        monospace: root.tooltipMonospace
        text: root.tooltipText
        visible: mouse.containsMouse && root.tooltipText !== ""
    }
}
