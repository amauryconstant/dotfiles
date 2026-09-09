pragma ComponentBehavior: Bound

import "../"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick

// Volume and brightness overlay (Phase 3). One window that follows the focused
// monitor rather than one per screen: an OSD reports what the key you just
// pressed did, and that only needs saying where you are looking.
//
// Nothing triggers it explicitly — no keybinding and no IPC. Both sources are
// already observable: Pipewire notifies on the sink's volume, and the sysfs
// backlight file is watched by the Backlight singleton, so an OSD appears
// whether the change came from a media key, the bar, or another app entirely.
PanelWindow {
    id: root

    // Set by show(); the card renders these, not the sources directly, so a
    // volume change does not repaint a brightness card mid-fade.
    property string icon: ""
    property real level: 0
    // Muted volume: the glyph and the fill recede rather than turning a colour.
    property bool dimmed: false
    // 🚨 Startup guard. Pipewire's first binding and the first sysfs read both
    // land a beat after launch, and without this the OSD flashes on every
    // login and on every `quickshell` restart.
    property bool armed: false

    // qmllint disable unresolved-type
    readonly property PwNode sink: Pipewire.defaultAudioSink
    // qmllint enable unresolved-type
    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property real volume: root.sink?.audio?.volume ?? 0

    function show(glyph: string, level: real, dimmed: bool): void {
        if (!root.armed)
            return;
        root.icon = glyph;
        // Not clamped to 1: the bar clamps, the number does not, so an
        // over-100% volume still reports the value it actually reached.
        root.level = Math.max(0, level);
        root.dimmed = dimmed;
        hideTimer.restart();
    }

    function showVolume(): void {
        root.show(Config.volumeGlyph(root.volume, root.muted, root.sink?.properties["device.form-factor"] ?? ""), root.volume, root.muted);
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitHeight: Config.osdHeight
    implicitWidth: Config.osdWidth
    // Follows the focused monitor. HyprlandMonitor carries no `screen`, so the
    // two are matched by name — both expose one.
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    // Stays mapped through the fade-out, then unmaps: an unmapped window has no
    // surface at all, which is cheaper than an always-present transparent one.
    visible: hideTimer.running || card.opacity > 0

    // An empty mask is an empty input region, so clicks land on whatever is
    // underneath. Without it this window would eat every click in its 200x96
    // patch while it is up, and it has no interactive element to justify that.
    mask: Region {}

    // qmllint disable unqualified unresolved-type
    anchors.bottom: true
    margins.bottom: Config.osdMargin
    // qmllint enable unqualified unresolved-type

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay

    onMutedChanged: root.showVolume()
    onVolumeChanged: root.showVolume()

    Rectangle {
        id: card

        anchors.fill: parent
        border.color: Theme.edge
        border.width: Config.hairline
        color: Theme.groundBase
        opacity: hideTimer.running ? 1 : 0
        radius: Config.radiusPanel

        // 🚨 Fade-OUT only. A readout you have to wait for has already failed,
        // so the appearance is instant and only the disappearance is animated —
        // hence the Behavior being live only while the hold timer is not.
        Behavior on opacity {
            enabled: !hideTimer.running

            NumberAnimation {
                duration: Config.motionSlow
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: Config.padTight - 1

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Config.padTight + 1

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    // A 28px glyph is a GRAPHIC at 3:1, not text at 4.5 — and
                    // it is the one size where a seven-step brightness ramp is
                    // genuinely distinguishable, which is why three steps are
                    // the rule everywhere else in the shell.
                    color: root.dimmed ? Theme.inkSecondary : Theme.inkPrimary
                    font.family: Config.guiFont
                    font.pixelSize: Config.glyphOsd
                    text: root.icon
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.inkPrimary
                    // No percent sign: the bar underneath already says what the
                    // scale is. Over 100% the number keeps counting while the
                    // bar clamps, because clamping the number would hide a real
                    // state.
                    font.family: Config.guiFont
                    font.pixelSize: Config.fontDisplay
                    font.weight: Font.DemiBold
                    text: Math.round(root.level * 100)
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                // groundRaised, not fillInert: fillInert on groundRaised is
                // roughly 1.3:1 in Mocha, far under the 3:1 a graphic owes, so
                // the design's own track/fill pairing fails its own floor. This
                // pair was measured at 3:1 in 7 of 8 on 2026-09-01.
                color: Theme.groundRaised
                height: Config.osdTrackHeight
                radius: Config.radiusPill
                width: Config.osdTrackWidth

                Rectangle {
                    // inkSecondary rather than a muted token: FG_MUTED equals
                    // BG_TERTIARY exactly in both solarized themes, so the
                    // dimmed fill used to be invisible at 1.00:1.
                    color: root.dimmed ? Theme.inkSecondary : Theme.signalFocus
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * Math.min(1, root.level)

                    Behavior on width {
                        NumberAnimation {
                            duration: Config.motionFast
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: hideTimer

        interval: Config.osdHideMs
    }

    Timer {
        interval: 1000
        running: true

        onTriggered: root.armed = true
    }

    Connections {
        function onPercentChanged(): void {
            root.show(Config.brightnessGlyph(Backlight.percent), Backlight.percent / 100, false);
        }

        target: Backlight
    }

    // 🚨 Pipewire node properties stay unbound unless a tracker holds the node:
    // without this the OSD would read a permanent 0%.
    PwObjectTracker {
        objects: [root.sink]
    }
}
