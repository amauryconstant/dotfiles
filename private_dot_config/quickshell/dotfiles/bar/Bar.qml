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

    // Called over IPC from idle-toggle / idle-toggle-nolock, which already
    // send `pkill -RTMIN+9 waybar` for the same reason.
    function refreshIdle(): void {
        idle.refresh();
    }

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

        // Order follows waybar/config.tmpl's modules-right.
        TrayWidget {}

        NetworkWidget {}

        BluetoothWidget {}

        BacklightWidget {}

        BatteryWidget {}

        AudioWidget {}

        MediaWidget {}

        KanataWidget {}

        IdleWidget {
            id: idle
        }

        VoxtypeWidget {}

        NotificationWidget {}
    }
}
