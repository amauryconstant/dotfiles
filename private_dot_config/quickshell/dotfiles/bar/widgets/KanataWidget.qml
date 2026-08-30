import "../"
import "../../"
import Quickshell
import QtQuick

// Waybar's custom/kanata-layer.
//
// The plan called for a Quickshell Socket straight to kanata's TCP server on
// port 5829. That is not possible: Quickshell's Socket is a UNIX socket — its
// only address property is `path`, with no host or port. The existing
// kanata-layer script already bridges that TCP stream to line-delimited JSON
// and reconnects on its own, so it is reused rather than reimplemented.
BarWidget {
    id: root

    tooltipText: source.tooltip
    // Waybar used exec-if to hide this when kanata is not running; here the
    // absence of any layer line is the same signal, without the extra poll.
    visible: source.text !== ""

    onClicked: Quickshell.execDetached([`${Config.scriptsDir}/desktop/kanata-layer-toggle`])

    WaybarJsonSource {
        id: source

        command: [`${Config.scriptsDir}/desktop/kanata-layer`]
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.accentAlternative
        font.family: Config.guiFont
        font.pixelSize: Config.fontSize
        text: `󰌌 ${source.text}`
    }
}
