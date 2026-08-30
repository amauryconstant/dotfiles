import "../"
import "../../"
import Quickshell
import QtQuick

// Waybar's custom/idle-indicator. The script prints one object and exits, so
// this polls on Waybar's own 30s safety-net interval — but the real signal is
// the IPC refresh that idle-toggle sends, mirroring the `pkill -RTMIN+9
// waybar` those scripts already do. Without it the state goes stale for up to
// half a minute after every toggle.
BarWidget {
    id: root

    tooltipText: source.tooltip
    // Empty text is the armed-and-healthy case: nothing to say, nothing shown.
    visible: source.text !== ""

    function refresh(): void {
        source.refresh();
    }

    onClicked: Quickshell.execDetached([`${Config.scriptsDir}/desktop/idle-toggle`])
    onRightClicked: Quickshell.execDetached([`${Config.scriptsDir}/desktop/idle-toggle-nolock`])

    WaybarJsonSource {
        id: source

        command: [`${Config.scriptsDir}/desktop/idle-indicator`]
        oneShot: true
    }

    Timer {
        interval: 30000
        repeat: true
        running: true

        onTriggered: source.refresh()
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: source.text === "󰒲" ? Theme.accentError : Theme.accentWarning
        font.family: Config.guiFont
        font.pixelSize: Config.fontSize
        text: source.text
    }
}
