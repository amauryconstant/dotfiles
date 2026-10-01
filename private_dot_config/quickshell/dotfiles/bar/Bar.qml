import "../"
import "popovers"
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

    // 🚨 The per-output popover coordinator, and it costs one string: a Bar is
    // created per screen by the Variants in shell.qml, so "one popover per
    // OUTPUT, not one per shell" (design page Shell-06-Popovers) needs no
    // registry and no singleton. Two screens may each show one, which is
    // correct on a multi-head desk; an output vanishing takes its Bar, its
    // popovers and this string with it.
    property string openPopover: ""
    readonly property var popovers: ({
            audio: pAudio,
            bluetooth: pBluetooth,
            calendar: pCalendar,
            media: pMedia,
            meters: pMeters,
            network: pNetwork,
            nightlight: pNightLight,
            power: pPower
        })

    // Raised by the launcher chip; shell.qml owns the Launcher window.
    signal launcherRequested
    signal notificationCentreRequested

    // Called over IPC from idle-toggle / idle-toggle-nolock, which already
    // send `pkill -RTMIN+9 waybar` for the same reason.
    function refreshIdle(): void {
        idle.refresh();
    }

    // Every mode indicator at once, for `ipc call indicators refresh`. Each
    // one is a one-shot script read on demand rather than a poll, so the
    // toggles have to say when they have flipped something.
    function refreshIndicators(): void {
        idle.refresh();
        nightLight.refresh();
        recording.refresh();
    }

    // `keyboard` is what separates the two open modes of design page 03: by
    // pointer there is no grab at all, by binding the popover grabs the
    // keyboard and draws a focus ring. The IPC target passes true; a widget
    // click passes false.
    function togglePopover(id: string, keyboard: bool): void {
        const target = root.popovers[id] ?? null;
        if (!target)
            return;
        const wasOpen = root.openPopover === id;
        if (root.openPopover !== "")
            root.popovers[root.openPopover]?.close();
        if (wasOpen)
            return;
        root.openPopover = id;
        target.open(keyboard);
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
        id: wClock

        anchors.centerIn: parent
        popoverOpen: root.openPopover === "calendar"

        onPopoverRequested: root.togglePopover("calendar", false)
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

            MetersWidget {
                id: wMeters

                popoverOpen: root.openPopover === "meters"

                onPopoverRequested: root.togglePopover("meters", false)
            }
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

            NetworkWidget {
                id: wNetwork

                popoverOpen: root.openPopover === "network"

                onPopoverRequested: root.togglePopover("network", false)
            }

            BluetoothWidget {
                id: wBluetooth

                popoverOpen: root.openPopover === "bluetooth"

                onPopoverRequested: root.togglePopover("bluetooth", false)
            }
        }

        BarSeparator {
            group: gPower
        }

        Row {
            id: gPower

            spacing: Config.gap / 2

            BacklightWidget {}

            BatteryWidget {
                id: wBattery

                popoverOpen: root.openPopover === "power"

                onPopoverRequested: root.togglePopover("power", false)
            }
        }

        BarSeparator {
            group: gSound
        }

        Row {
            id: gSound

            spacing: Config.gap / 2

            AudioWidget {
                id: wAudio

                popoverOpen: root.openPopover === "audio"

                onPopoverRequested: root.togglePopover("audio", false)
            }

            MediaWidget {
                id: wMedia

                popoverOpen: root.openPopover === "media"

                onPopoverRequested: root.togglePopover("media", false)
            }
        }

        BarSeparator {
            group: gStatus
        }

        // 🚨 Mode indicators, ordered by how far the state departs from normal
        // — surface §5's "the strongest relaxation of normal behaviour wins".
        // The order is FIXED, not most-recent-first as omarchy's
        // `shell/plugins/bar/widgets/Indicators.qml` does it: these appear and
        // disappear on their own, and a set that also reorders itself has to
        // be re-read from scratch every time one of them changes.
        //
        // Strongest first: the screen is being captured > the machine will not
        // lock or sleep > the microphone is live > the microphone is muted >
        // the keys are remapped > the colours are shifted.
        //
        // Live outranks muted: dictation is something happening to the room,
        // muted is something not happening. They are also mutually exclusive in
        // practice, so the pair never draws twice.
        Row {
            id: gStatus

            spacing: Config.gap / 2

            RecordingWidget {
                id: recording
            }

            IdleWidget {
                id: idle
            }

            VoxtypeWidget {}

            // Its panel is the audio one, which carries the input slider; the
            // popover still hangs under the speaker widget it belongs to.
            MicrophoneWidget {
                onPopoverRequested: root.togglePopover("audio", false)
            }

            KanataWidget {}

            NightLightWidget {
                id: nightLight

                popoverOpen: root.openPopover === "nightlight"

                onPopoverRequested: root.togglePopover("nightlight", false)
            }
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

    // Popovers are declared here rather than inside their widgets: the widget
    // is what they anchor to, and the coordinator above needs to reach every
    // one of them by name.
    AudioPopover {
        id: pAudio

        anchorHovered: wAudio.hovered
        anchorItem: wAudio

        onDismissed: {
            if (root.openPopover === "audio")
                root.openPopover = "";
        }
    }

    BluetoothPopover {
        id: pBluetooth

        anchorHovered: wBluetooth.hovered
        anchorItem: wBluetooth

        onDismissed: {
            if (root.openPopover === "bluetooth")
                root.openPopover = "";
        }
    }

    CalendarPopover {
        id: pCalendar

        anchorHovered: wClock.hovered
        anchorItem: wClock

        onDismissed: {
            if (root.openPopover === "calendar")
                root.openPopover = "";
        }
    }

    MediaPopover {
        id: pMedia

        anchorHovered: wMedia.hovered
        anchorItem: wMedia

        onDismissed: {
            if (root.openPopover === "media")
                root.openPopover = "";
        }
    }

    MetersPopover {
        id: pMeters

        anchorHovered: wMeters.hovered
        anchorItem: wMeters

        onDismissed: {
            if (root.openPopover === "meters")
                root.openPopover = "";
        }
    }

    NightLightPopover {
        id: pNightLight

        anchorHovered: nightLight.hovered
        anchorItem: nightLight

        onDismissed: {
            if (root.openPopover === "nightlight")
                root.openPopover = "";
        }
    }

    NetworkPopover {
        id: pNetwork

        anchorHovered: wNetwork.hovered
        anchorItem: wNetwork

        onDismissed: {
            if (root.openPopover === "network")
                root.openPopover = "";
        }
    }

    PowerPopover {
        id: pPower

        anchorHovered: wBattery.hovered
        anchorItem: wBattery

        onDismissed: {
            if (root.openPopover === "power")
                root.openPopover = "";
        }
    }
}
