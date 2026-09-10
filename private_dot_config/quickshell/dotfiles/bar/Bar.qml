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
// not, so Auto would reserve more than the bar occupies.
//
// 🚨 The compositor ADDS the margin: an exclusive zone is measured from the
// surface's own edge, so Hyprland reserves `margins.top + exclusiveZone`.
// Verified live 2026-09-10 — a 4 margin with a 44 zone gave `hyprctl monitors`
// reserved=48, four PAST the bar's own bottom edge. So `barHeight + barInset`
// counts the inset twice on purpose: the gap below the bar comes out as
// barInset + gaps_out (8), deliberately double the 4 the bar's side edges get.
// Chosen by eye over the symmetric `barHeight` alone — the bar reads as
// separated from the windows rather than as one more tile among them.
PanelWindow {
    id: root

    required property var modelData

    // Raised by the launcher chip; shell.qml owns the Launcher window.
    signal launcherRequested
    signal notificationCentreRequested

    // Called over IPC from idle-toggle / idle-toggle-nolock, which already
    // send `pkill -RTMIN+9 waybar` for the same reason.
    function refreshIdle(): void {
        idle.refresh();
    }

    color: "transparent"
    exclusiveZone: Config.barHeight + Config.barInset
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
        border.color: Theme.edge
        border.width: Config.hairline
        color: Theme.groundBase
        radius: Config.radiusPanel
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Config.gap
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.gap

        LauncherWidget {
            onLauncherRequested: root.launcherRequested()
        }

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
        // its hairlines are Amendment A's. The meter leads, as the design draws
        // it — everything after it keeps the order it already had.
        Row {
            id: gMeter

            spacing: Config.gap / 2

            MetersWidget {}
        }

        BarSeparator {
            group: gTray
        }

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

            NotificationWidget {
                onCentreRequested: root.notificationCentreRequested()
            }
        }
    }
}
