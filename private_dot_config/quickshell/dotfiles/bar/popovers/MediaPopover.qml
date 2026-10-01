pragma ComponentBehavior: Bound

import "../"
import "../../"
import Quickshell.Services.Mpris
import QtQuick

// Media popover, design page Shell-06-Popovers: title, artist, transport,
// position.
//
// 🚨 The ACTIVE player only, never a picker: switching players is the
// compositor's own binding, and a list of one is a choice that does not exist.
// Title and position are text replacing text and never animate.
BarPopover {
    id: root

    readonly property MprisPlayer player: {
        const usable = Mpris.players.values.filter(p => !root.ignored.some(name => (p.dbusName ?? "").toLowerCase().includes(name)));
        return usable.find(p => p.isPlaying) ?? usable[0] ?? null;
    }
    readonly property list<string> ignored: ["firefox", "chromium", "playerctld"]
    readonly property real progress: (root.player?.lengthSupported ?? false) && (root.player?.length ?? 0) > 0 ? (root.player?.position ?? 0) / root.player.length : 0

    function clockText(seconds: real): string {
        const whole = Math.max(0, Math.floor(seconds));
        const minutes = Math.floor(whole / 60);
        return `${minutes}:${String(whole % 60).padStart(2, "0")}`;
    }

    function run(index: int): void {
        if (index === 0)
            root.player?.previous();
        else if (index === 1)
            root.player?.togglePlaying();
        else if (index === 2)
            root.player?.next();
    }

    footerLeft: root.keyboardMode ? qsTr("←→ move · ↵ activate") : ""
    footerRight: root.player?.identity ?? ""
    glyph: root.player?.isPlaying ? "󰐊" : "󰏤"
    navCount: root.player ? 3 : 0
    title: qsTr("Media")

    onActivated: index => root.run(index)
    onStepped: delta => root.move(delta)

    // 🚨 `position` does NOT update reactively — the property is live when
    // read, but nothing notifies. Emitting the change signal on a timer is
    // upstream's own documented pattern, and it runs only while the popover is
    // up so a closed surface costs nothing.
    Timer {
        interval: 1000
        repeat: true
        running: root.visible && (root.player?.isPlaying ?? false)

        onTriggered: root.player?.positionChanged()
    }

    // A click on the title brings the player's window forward, where the
    // player says it can be raised.
    PopoverRow {
        glyph: "󰝚"
        label: root.player?.trackTitle ?? qsTr("Nothing playing")

        onClicked: {
            if (root.player?.canRaise)
                root.player.raise();
        }
    }

    PopoverRow {
        glyph: "󰠃"
        label: root.player?.trackArtist ?? ""
        visible: (root.player?.trackArtist ?? "") !== ""
    }

    Item {
        height: Config.rowH
        visible: root.player !== null
        width: parent.width

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Config.gap

            Repeater {
                model: ["󰒮", root.player?.isPlaying ? "󰏤" : "󰐊", "󰒭"]

                Item {
                    id: control

                    required property int index
                    required property string modelData

                    readonly property bool cursor: root.keyboardMode && root.selected === control.index

                    height: Config.hitMin
                    width: Config.hitMin

                    Rectangle {
                        anchors.centerIn: parent
                        border.color: control.cursor ? Theme.focusRing : "transparent"
                        border.width: control.cursor ? Config.popRingWidth : 0
                        color: transport.containsMouse ? Theme.groundRaised : "transparent"
                        height: Config.chipSize
                        radius: Config.radiusChip
                        width: Config.chipSize
                    }

                    // 🚨 Transport glyphs are ink-primary. The design gives the
                    // play control signalFocus only while it HOLDS FOCUS, and
                    // playing is shown by the glyph rather than by a hue.
                    Text {
                        anchors.centerIn: parent
                        color: Theme.inkPrimary
                        font.family: Config.guiFont
                        font.pixelSize: Config.glyphRow
                        text: control.modelData
                    }

                    MouseArea {
                        id: transport

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: root.run(control.index)
                    }
                }
            }
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.inkSecondary
            font.family: Config.terminalFont
            font.pixelSize: Config.fontMeta
            text: root.player?.lengthSupported ? `${root.clockText(root.player?.position ?? 0)} / ${root.clockText(root.player?.length ?? 0)}` : root.clockText(root.player?.position ?? 0)
            visible: root.player?.positionSupported ?? false
        }
    }

    // Seekable where the player allows it: the same slider as volume, so a
    // control looks like a control. A player that cannot seek keeps the
    // read-only bar below, because a thumb that moves nothing is a lie.
    PopoverSlider {
        step: 10 / Math.max(1, root.player?.length ?? 1)
        value: root.progress
        visible: (root.player?.canSeek ?? false) && (root.player?.lengthSupported ?? false) && (root.player?.length ?? 0) > 0
        width: parent.width

        onMoved: v => {
            if (root.player)
                root.player.position = v * root.player.length;
        }
    }

    Rectangle {
        color: Theme.groundRaised
        height: Config.popSliderTrack
        radius: Config.radiusPill
        visible: !(root.player?.canSeek ?? false) && (root.player?.lengthSupported ?? false) && (root.player?.length ?? 0) > 0
        width: parent.width

        Rectangle {
            color: Theme.inkSecondary
            height: parent.height
            radius: parent.radius
            width: Math.max(0, Math.min(1, root.progress)) * parent.width
        }
    }
}
