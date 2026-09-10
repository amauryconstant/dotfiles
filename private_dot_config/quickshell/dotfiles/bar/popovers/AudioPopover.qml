pragma ComponentBehavior: Bound

import "../"
import "../../"
import Quickshell.Services.Pipewire
import QtQuick

// Audio popover, design page Shell-06-Popovers: output slider, device list, and
// an input slider when a source exists. Device switching is native —
// `Pipewire.preferredDefaultAudioSink` is writable — so nothing here shells out
// except the escape hatch.
BarPopover {
    id: root

    readonly property bool busy: root.switching !== null
    readonly property bool failed: root.armed && !root.sink
    property bool armed: false
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property list<PwNode> sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
    readonly property PwNode source: Pipewire.defaultAudioSource
    // The node a switch is in flight to. Its own row reports it and its
    // siblings dim; there is no toast and no global spinner, because a spinner
    // in a corner cannot say WHICH device is being switched to.
    property var switching: null

    function deviceGlyph(node: PwNode): string {
        const form = node?.properties["device.form-factor"] ?? "";
        if (form === "headset")
            return Config.volumeGlyphHeadset;
        if (form === "headphone")
            return Config.volumeGlyphHeadphone;
        return Config.volumeGlyphs[2];
    }

    function selectDevice(node: PwNode): void {
        if (!node || node.id === root.sink?.id)
            return;
        root.switching = node;
        Pipewire.preferredDefaultAudioSink = node;
        switchTimeout.restart();
    }

    function setSinkVolume(value: real): void {
        if (root.sink?.audio)
            root.sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function setSourceVolume(value: real): void {
        if (root.source?.audio)
            root.source.audio.volume = Math.max(0, Math.min(1, value));
    }

    footerCommand: root.failed ? null : ["pavucontrol"]
    footerLeft: root.keyboardMode ? qsTr("↑↓ move · ↵ select") : ""
    footerRight: root.failed ? qsTr("systemctl --user restart wireplumber") : "pavucontrol"
    glyph: Config.volumeGlyph(root.sink?.audio?.volume ?? 0, root.sink?.audio?.muted ?? false, root.sink?.properties["device.form-factor"] ?? "")
    // Output slider, one row per sink, then the input slider when there is one.
    navCount: root.failed ? 0 : 1 + root.sinks.length + (root.source ? 1 : 0)
    title: qsTr("Audio")

    onActivated: index => {
        const at = index - 1;
        if (at >= 0 && at < root.sinks.length)
            root.selectDevice(root.sinks[at]);
    }
    onStepped: delta => {
        if (root.selected === 0)
            root.setSinkVolume((root.sink?.audio?.volume ?? 0) + delta * Config.volumeStep);
        else if (root.source && root.selected === root.navCount - 1)
            root.setSourceVolume((root.source?.audio?.volume ?? 0) + delta * Config.volumeStep);
    }

    // Same reason the widget arms: Pipewire's first binding lands a beat after
    // launch, so "not yet arrived" must not render as "failed".
    Timer {
        interval: 1000
        running: true

        onTriggered: root.armed = true
    }

    // A switch that never lands must not leave the list dimmed forever.
    Timer {
        id: switchTimeout

        interval: 3000

        onTriggered: root.switching = null
    }

    // 🚨 Every node read here needs a tracker or its volume reads a permanent 0
    // with no error — the same trap AudioWidget documents.
    PwObjectTracker {
        objects: root.sinks.concat([root.sink, root.source]).filter(n => n)
    }

    Connections {
        function onDefaultAudioSinkChanged(): void {
            root.switching = null;
            switchTimeout.stop();
        }

        target: Pipewire
    }

    component ValueRow: Column {
        id: valueRow

        property bool cursor: false
        property string label: ""
        property bool muted: false
        property real value: 0

        signal moved(real value)

        spacing: Config.gap - 2
        width: parent ? parent.width : 0

        Item {
            height: Config.fontBody + 2
            width: parent.width

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.inkPrimary
                font.family: Config.guiFont
                font.pixelSize: Config.fontBody
                text: valueRow.label
            }

            // The number is the carrier: the accent fill under it is decoration
            // and never states the value on its own.
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.inkPrimary
                font.family: Config.terminalFont
                font.pixelSize: Config.fontBody
                text: valueRow.muted ? qsTr("muted") : `${Math.round(valueRow.value * 100)}%`
            }
        }

        PopoverSlider {
            showRing: valueRow.cursor
            value: valueRow.value
            width: parent.width

            onMoved: v => valueRow.moved(v)
        }
    }

    // Absent hardware hides, a failed service shows: PipeWire down draws the
    // failed glyph with a label, and the footer names what to restart.
    PopoverRow {
        glyph: Config.audioFailedGlyph
        label: qsTr("PipeWire is not running")
        visible: root.failed
    }

    ValueRow {
        cursor: root.keyboardMode && root.selected === 0
        label: qsTr("Output")
        muted: root.sink?.audio?.muted ?? false
        value: root.sink?.audio?.volume ?? 0
        visible: !root.failed

        onMoved: v => root.setSinkVolume(v)
    }

    Text {
        color: Theme.inkSecondary
        font.capitalization: Font.AllUppercase
        font.family: Config.terminalFont
        font.letterSpacing: 1
        font.pixelSize: Config.fontSection
        height: Config.menuSectionHeight
        text: qsTr("Devices")
        verticalAlignment: Text.AlignBottom
        visible: !root.failed && root.sinks.length > 1
    }

    Repeater {
        model: root.failed ? [] : root.sinks

        PopoverRow {
            id: deviceRow

            required property int index
            required property PwNode modelData

            badge: deviceRow.modelData.id === root.sink?.id ? qsTr("current") : ""
            cursor: root.keyboardMode && root.selected === deviceRow.index + 1
            dimmed: root.busy && root.switching?.id !== deviceRow.modelData.id
            glyph: root.deviceGlyph(deviceRow.modelData)
            label: deviceRow.modelData.description ?? deviceRow.modelData.name
            selected: deviceRow.modelData.id === root.sink?.id
            showRing: deviceRow.cursor
            status: root.switching?.id === deviceRow.modelData.id ? qsTr("switching") : ""

            onClicked: root.selectDevice(deviceRow.modelData)
        }
    }

    ValueRow {
        cursor: root.keyboardMode && root.selected === root.navCount - 1
        label: qsTr("Input")
        muted: root.source?.audio?.muted ?? false
        value: root.source?.audio?.volume ?? 0
        visible: !root.failed && root.source !== null

        onMoved: v => root.setSourceVolume(v)
    }
}
