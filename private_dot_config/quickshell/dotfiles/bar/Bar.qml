import "../"
import "widgets"
import Quickshell
import QtQuick

// One bar per screen. Waybar ran with all-outputs:false, i.e. a bar on every
// monitor showing only that monitor's workspaces; Variants over
// Quickshell.screens in shell.qml reproduces that, and `screen` is what makes
// the per-monitor workspace filter possible.
//
// 🚨 The bar floats (Amendment A): inset on every side, rounded, hairline
// border. `exclusiveZone` is set explicitly because ExclusionMode.Auto only
// reserves the margins of edges that are actually anchored — the bottom is
// not, so Auto would reserve 48 and windows would sit under the lower inset.
PanelWindow {
    id: root

    required property var modelData

    // Called over IPC from idle-toggle / idle-toggle-nolock, which already
    // send `pkill -RTMIN+9 waybar` for the same reason.
    function refreshIdle(): void {
        idle.refresh();
    }

    color: "transparent"
    exclusiveZone: Config.barHeight + Config.barInset * 2
    implicitHeight: Config.barHeight
    screen: root.modelData

    anchors {
        left: true
        right: true
        top: true
    }
    // qmllint disable unqualified unresolved-type
    margins.left: Config.barInset
    margins.right: Config.barInset
    margins.top: Config.barInset
    // qmllint enable unqualified unresolved-type

    Rectangle {
        anchors.fill: parent
        border.color: Theme.bgTertiary
        border.width: 1
        color: Theme.bgPrimary
        radius: Config.radiusPanel
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Config.gap
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.gap

        LauncherWidget {}

        WorkspacesWidget {
            barScreen: root.modelData
        }

        WindowTitleWidget {}
    }

    // Absolutely positioned rather than a third flex child, so the clock stays
    // optically centred however wide the left and right zones grow.
    ClockWidget {
        anchors.centerIn: parent
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Config.gap
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.gap / 2

        // Order follows waybar/config.tmpl's modules-right; the grouping and
        // its hairlines are Amendment A's.
        Row {
            id: gTray

            spacing: Config.gap / 2

            TrayWidget {}
        }

        BarSeparator {
            group: gConn
        }

        Row {
            id: gConn

            spacing: Config.gap / 2

            NetworkWidget {}

            BluetoothWidget {}
        }

        BarSeparator {
            group: gPower
        }

        Row {
            id: gPower

            spacing: Config.gap / 2

            BacklightWidget {}

            BatteryWidget {}
        }

        BarSeparator {
            group: gSound
        }

        Row {
            id: gSound

            spacing: Config.gap / 2

            AudioWidget {}

            MediaWidget {}
        }

        BarSeparator {
            group: gStatus
        }

        Row {
            id: gStatus

            spacing: Config.gap / 2

            KanataWidget {}

            IdleWidget {
                id: idle
            }

            VoxtypeWidget {}
        }

        BarSeparator {
            group: gNotif
        }

        Row {
            id: gNotif

            spacing: Config.gap / 2

            NotificationWidget {}
        }
    }
}
