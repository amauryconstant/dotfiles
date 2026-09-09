import "../"
import QtQuick

// The 1px x 16px hairline that groups related widgets in the right zone.
//
// Bound to the group that FOLLOWS it, so a group that collapses to nothing
// (every laptop widget, on a desktop) takes its leading separator with it
// rather than leaving a stray rule floating in the bar.
Item {
    id: root

    required property Item group

    implicitHeight: Config.barHeight
    implicitWidth: Config.hairline
    visible: root.group.implicitWidth > 0

    Rectangle {
        anchors.centerIn: parent
        color: Theme.edge
        height: 16
        width: Config.hairline
    }
}
