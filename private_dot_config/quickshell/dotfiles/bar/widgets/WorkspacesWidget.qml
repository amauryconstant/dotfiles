import "../"
import "../../"
import Quickshell.Hyprland
import QtQuick

// Waybar's hyprland/workspaces with all-outputs:false — each bar shows only
// its own monitor's workspaces, hence the barScreen filter.
//
// 🚨 Click goes through `workspace.activate()`, never Hyprland.dispatch().
// activate() is the one call Quickshell translates for Hyprland's Lua config
// provider (it branches on Hyprland.usingLua and emits hl.dsp.focus), which is
// the entire reason this bar exists — a raw dispatch string would break at the
// Phase 2 cutover exactly the way Waybar's clicks already do.
BarWidget {
    id: root

    required property var barScreen
    readonly property var workspaces: [...Hyprland.workspaces.values].filter(ws => ws.monitor && ws.monitor.name === root.barScreen.name).sort((a, b) => a.id - b.id)

    // Each button paints its own state background, so the shared widget-wide
    // hover would just muddy them.
    hoverBackground: false

    Repeater {
        model: root.workspaces

        Rectangle {
            id: button

            required property var modelData

            // Waybar's five states. Precedence matters: urgent wins, then the
            // workspace with input focus, then one visible on another monitor.
            readonly property bool hasWindows: button.modelData.toplevels.values.length > 0
            readonly property bool isFocused: button.modelData.focused
            readonly property bool isUrgent: button.modelData.urgent
            readonly property bool isVisible: button.modelData.active && !button.modelData.focused
            readonly property bool lit: button.isUrgent || button.isFocused || area.containsMouse

            color: button.isUrgent ? Theme.accentError : button.lit ? Theme.accentPrimary : "transparent"
            height: Config.barHeight - 6
            radius: 4
            width: Math.max(height, label.implicitWidth + Config.widgetPadding)

            Text {
                id: label

                anchors.centerIn: parent
                // fg-contrast on an accent background, fg-muted when inactive.
                color: button.lit ? Theme.fgContrast : Theme.fgMuted
                font.family: Config.guiFont
                font.pixelSize: Config.fontSize
                text: button.isUrgent ? "" : button.isFocused ? "󰺕" : button.isVisible ? "" : button.hasWindows ? "" : "·"
            }

            MouseArea {
                id: area

                anchors.fill: parent
                hoverEnabled: true

                onClicked: button.modelData.activate()
            }
        }
    }
}
