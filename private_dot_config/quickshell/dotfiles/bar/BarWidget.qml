import "../"
import QtQuick

// Shared base for every bar widget: padding, hover background, tooltip, and
// the click/scroll plumbing. A widget file is then only its data binding and
// its format string, which is what keeps 14 of them readable.
//
// Children go into a Row, so the common icon-plus-label shape needs no layout
// code of its own.
Item {
    id: root

    default property alias content: layout.data
    property bool hoverBackground: true
    readonly property alias hovered: mouse.containsMouse
    // Calendars and device lists only line up in a fixed-pitch font.
    property bool tooltipMonospace: false
    property string tooltipText: ""

    signal clicked
    signal middleClicked
    signal rightClicked
    signal scrolledDown
    signal scrolledUp

    implicitHeight: Config.barHeight
    implicitWidth: layout.implicitWidth + Config.widgetPadding * 2
    visible: layout.implicitWidth > 0

    Rectangle {
        anchors.fill: parent
        anchors.bottomMargin: 2
        anchors.topMargin: 2
        color: Theme.bgSecondary
        opacity: root.hoverBackground && mouse.containsMouse ? 1 : 0
        radius: 4

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
    }

    Row {
        id: layout

        anchors.centerIn: parent
        spacing: Config.barSpacing
    }

    MouseArea {
        id: mouse

        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        anchors.fill: parent
        hoverEnabled: true

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
