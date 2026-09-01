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
        root.level = Math.max(0, Math.min(1, level));
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
    // underneath. Without it this window would eat every click in its 320x56
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
        border.color: Theme.bgSecondary
        border.width: Config.hairline
        color: Theme.bgPrimary
        opacity: hideTimer.running ? 1 : 0
        radius: Config.radiusPanel

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        Text {
            id: glyph

            anchors.left: parent.left
            anchors.leftMargin: Config.pad
            anchors.verticalCenter: parent.verticalCenter
            color: root.dimmed ? Theme.fgMuted : Theme.fgPrimary
            font.family: Config.guiFont
            font.pixelSize: Config.fontSizeLarge
            text: root.icon
        }

        Text {
            id: value

            anchors.right: parent.right
            anchors.rightMargin: Config.pad
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.fgPrimary
            // Digits only line up in a fixed-pitch face, and the number changes
            // width on nearly every keypress.
            font.family: Config.terminalFont
            font.pixelSize: Config.fontSizeSmall
            horizontalAlignment: Text.AlignRight
            text: `${Math.round(root.level * 100)}%`
            width: Config.padLoose
        }

        Rectangle {
            anchors.left: glyph.right
            anchors.leftMargin: Config.gap
            anchors.right: value.left
            anchors.rightMargin: Config.gap
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.bgTertiary
            height: Config.osdTrackHeight
            radius: Config.radiusPill

            Rectangle {
                color: root.dimmed ? Theme.fgMuted : Theme.accentPrimary
                height: parent.height
                radius: parent.radius
                width: parent.width * root.level

                Behavior on width {
                    NumberAnimation {
                        duration: 120
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
