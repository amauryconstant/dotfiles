import "../"
import "../../"
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// A muted microphone, and nothing else. The AudioWidget beside it owns the
// SINK; this owns the one source state worth a permanent place in the bar.
//
// Follows IdleWidget: a mode indicator is INVISIBLE while the state is normal.
// A live mic is normal, so only muted draws.
BarWidget {
    id: root

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool muted: root.source?.audio?.muted ?? false

    icon: Config.micMutedGlyph
    // The glyph IS the state, and it only ever renders in one state, so there
    // is nothing for a colour to distinguish. signalError is reserved for a
    // failure, and a deliberately muted mic is not one.
    iconColor: root.restColor
    clickHint: qsTr("L unmute · R audio panel")
    tooltipText: qsTr("Microphone muted")
    visible: root.muted

    signal popoverRequested

    // Via the script, never `source.audio.muted = false` — the script is what
    // keeps the ThinkPad mic-mute LED in step. omarchy's Microphone.qml writes
    // the property directly and its LED desyncs from the widget as a result.
    onClicked: Quickshell.execDetached(Config.detach.concat([`${Config.scriptsDir}/desktop/mic-mute`]))
    // The audio popover carries the input slider, so it is this widget's
    // panel too; Bar.qml anchors it under the speaker widget.
    onRightClicked: root.popoverRequested()

    // 🚨 Pipewire node properties stay unbound unless a tracker holds the node.
    // Reading source.properties is deliberately avoided here: doing so while
    // capture streams appear (every voxtype recording) destabilizes the
    // Pipewire service — see omarchy shell/plugins/panels/audio/Panel.qml:60-68.
    PwObjectTracker {
        objects: [root.source]
    }
}
