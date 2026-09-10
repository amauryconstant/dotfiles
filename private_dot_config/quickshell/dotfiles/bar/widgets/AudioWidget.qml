import "../"
import "../../"
import Quickshell.Services.Pipewire
import QtQuick

// Waybar's pulseaudio module. Volume and mute are native; the left click opens
// the audio popover (design page Shell-06-Popovers), which is where the device
// list lives and where pavucontrol is named as the escape hatch.
BarWidget {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property real volume: root.sink?.audio?.volume ?? 0
    // 🚨 A failed service SHOWS — with its own glyph AND a label, because the
    // user needs to know the thing they configured is broken. Only ABSENT
    // hardware hides, and nothing ever greys.
    //
    // Gated on `armed` for the same reason the OSD is: Pipewire's first binding
    // lands a beat after launch, so without it every login would flash "audio
    // failed" before the sink arrives. "Absent" and "not yet arrived" are
    // different states and must look different.
    readonly property bool failed: root.armed && !root.sink
    property bool armed: false

    // Icon-only: the three-step glyph already reads as a level, and the exact
    // percentage is one hover away in the tooltip.
    icon: {
        if (root.failed)
            return Config.audioFailedGlyph;
        if (root.muted)
            return "󰝟";
        const form = root.sink?.properties["device.form-factor"] ?? "";
        if (form === "headset")
            return "󰋎";
        if (form === "headphone")
            return "󰋋";
        return root.volume < 0.34 ? "󰕿" : root.volume < 0.67 ? "󰖀" : "󰕾";
    }
    // No colour override at rest: muted has its own codepoint, and a glyph
    // that already says "muted" does not need a second carrier. FG_MUTED, which
    // used to sit here, is retired — banned as text and under 3:1 as a graphic.
    // A failed service is the one state that does take colour.
    iconColor: root.failed ? Theme.signalError : root.restColor
    label: root.failed ? qsTr("audio") : ""
    tooltipText: root.failed ? qsTr("PipeWire is not running\nsystemctl --user restart pipewire wireplumber") : root.sink ? `${root.sink.description}\nVolume: ${Math.round(root.volume * 100)}%${root.muted ? " (muted)" : ""}` : ""

    signal popoverRequested

    // Waybar's on-click-middle was `pamixer --next-sink`; cycling the
    // preferred default is the native equivalent.
    function nextSink(): void {
        const sinks = Pipewire.nodes.values.filter(n => n.isSink && !n.isStream);
        if (sinks.length < 2)
            return;
        const at = sinks.findIndex(n => n.id === root.sink?.id);
        Pipewire.preferredDefaultAudioSink = sinks[(at + 1) % sinks.length];
    }

    function setVolume(value: real): void {
        if (root.sink?.audio)
            root.sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    onClicked: root.popoverRequested()
    onMiddleClicked: root.nextSink()
    onRightClicked: {
        if (root.sink?.audio)
            root.sink.audio.muted = !root.sink.audio.muted;
    }
    onScrolledDown: root.setVolume(root.volume - Config.volumeStep)
    onScrolledUp: root.setVolume(root.volume + Config.volumeStep)

    Timer {
        interval: 1000
        running: true

        onTriggered: root.armed = true
    }

    // 🚨 Pipewire node properties stay unbound unless a tracker holds the
    // node: without this the widget renders a permanent 0% with no error.
    PwObjectTracker {
        objects: [root.sink]
    }
}
