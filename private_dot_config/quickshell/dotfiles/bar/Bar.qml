import "../"
import "widgets"
import Quickshell
import QtQuick

// One bar per screen. Waybar ran with all-outputs:false, i.e. a bar on every
// monitor showing only that monitor's workspaces; Variants over
// Quickshell.screens in shell.qml reproduces that, and `screen` is what makes
// the per-monitor workspace filter possible in Phase 1 task 2.
PanelWindow {
    id: root

    required property var modelData

    color: Theme.bgPrimary
    implicitHeight: Config.barHeight
    screen: root.modelData

    anchors {
        left: true
        right: true
        top: true
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Config.barSpacing
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.barSpacing

        WorkspacesWidget {
            barScreen: root.modelData
        }

        WindowTitleWidget {}
    }

    Row {
        anchors.centerIn: parent
        spacing: Config.barSpacing

        ClockWidget {}
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Config.barSpacing
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.barSpacing

        // Tray, audio, media, and the rest land here in tasks 3 and 4.
    }
}
