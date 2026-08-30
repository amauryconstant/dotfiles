import "../"
import "../../"
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Waybar's pulseaudio module. Volume and mute are native now; only the GUI
// (pavucontrol) is still a shell-out, matching Waybar's on-click.
BarWidget {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property real volume: root.sink?.audio?.volume ?? 0

    tooltipText: root.sink ? `${root.sink.description}\nVolume: ${Math.round(root.volume * 100)}%${root.muted ? " (muted)" : ""}` : "No audio sink"

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

    onClicked: Quickshell.execDetached(["pavucontrol"])
    onMiddleClicked: root.nextSink()
    onRightClicked: {
        if (root.sink?.audio)
            root.sink.audio.muted = !root.sink.audio.muted;
    }
    onScrolledDown: root.setVolume(root.volume - Config.volumeStep)
    onScrolledUp: root.setVolume(root.volume + Config.volumeStep)

    // 🚨 Pipewire node properties stay unbound unless a tracker holds the
    // node: without this the widget renders a permanent 0% with no error.
    PwObjectTracker {
        objects: [root.sink]
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        // accent-highlight is the interactive-module colour; muted drops to
        // fg-muted, as in waybar/CLAUDE.md.
        color: root.muted ? Theme.fgMuted : Theme.accentHighlight
        font.family: Config.guiFont
        font.pixelSize: Config.fontSize
        text: {
            if (root.muted)
                return "󰝟";
            const form = root.sink?.properties["device.form-factor"] ?? "";
            if (form === "headset")
                return "󰋎";
            if (form === "headphone")
                return "󰋋";
            return root.volume < 0.34 ? "󰕿" : root.volume < 0.67 ? "󰖀" : "󰕾";
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: root.muted ? Theme.fgMuted : Theme.accentHighlight
        font.family: Config.guiFont
        font.pixelSize: Config.fontSize
        text: root.muted ? "" : `${Math.round(root.volume * 100)}%`
        visible: !root.muted
    }
}
