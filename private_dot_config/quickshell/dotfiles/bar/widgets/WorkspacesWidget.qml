pragma ComponentBehavior: Bound

import "../"
import "../../"
import Quickshell.Hyprland
import QtQuick

// Waybar's hyprland/workspaces with all-outputs:false — each bar shows only
// its own monitor's workspaces, hence the barScreen filter.
//
// Amendment A turns the one-glyph square into a pill carrying the workspace
// number plus a glyph for its top window, so the layout of a workspace is
// readable without switching to it. "Visible on another monitor" and
// "occupied" deliberately share one appearance: our ramp has fewer tiers than
// the mockup, and collapsing two beats inventing a colour.
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

    // Each pill paints its own state ground, so the shared widget-wide hover
    // would just muddy them.
    hoverBackground: false

    Repeater {
        model: root.workspaces

        Row {
            id: entry

            required property int index
            required property var modelData

            anchors.verticalCenter: parent.verticalCenter
            spacing: Config.gap / 2

            // A missing workspace id reads as a gap rather than as a
            // renumbering: the canvas shows `1 2 3 4 · 6`.
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.bgTertiary
                height: 6
                radius: Config.radiusPill
                visible: entry.index > 0 && root.workspaces[entry.index - 1].id !== entry.modelData.id - 1
                width: 6
            }

            Rectangle {
                id: button

                // Waybar's five states. Precedence matters: urgent wins, then
                // the workspace with input focus, then one merely occupied.
                readonly property bool hasWindows: entry.modelData.toplevels.values.length > 0
                readonly property bool isFocused: entry.modelData.focused
                readonly property bool isUrgent: entry.modelData.urgent
                readonly property var topWindow: entry.modelData.toplevels.values[0] ?? null

                // Urgent is a text colour on a quiet ground, not a red fill:
                // the accent marks the FOCUSED workspace and nothing else, so
                // a second filled pill would compete with it.
                color: button.isFocused ? Theme.accentPrimary : button.isUrgent ? Theme.bgSecondary : button.hasWindows || area.containsMouse ? Theme.bgTertiary : "transparent"
                height: Config.pillHeight
                radius: Config.radiusPill
                // An empty workspace is a number in a 24px round square; every
                // other state grows from that to fit its glyph.
                //
                // The mockup gives "empty" a faint ground of its own. Ours stays
                // transparent deliberately: themes/CLAUDE.md requires fg-primary
                // on any elevated surface, which would un-recess the very state
                // that needs to recede. On the bar ground, fg-muted is allowed.
                width: Math.max(height, contents.implicitWidth + Config.padTight)

                Row {
                    id: contents

                    anchors.centerIn: parent
                    spacing: Config.gap / 2

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        // fg-contrast on an accent ground; fg-primary on the
                        // elevated bg-tertiary, per themes/CLAUDE.md.
                        color: button.isFocused ? Theme.fgContrast : button.isUrgent ? Theme.accentError : button.hasWindows ? Theme.fgPrimary : Theme.fgMuted
                        font.family: Config.terminalFont
                        font.pixelSize: Config.fontSizeSmall
                        text: entry.modelData.name
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: button.isFocused ? Theme.fgContrast : Theme.fgSecondary
                        font.family: Config.guiFont
                        font.pixelSize: Config.fontSize
                        // Subordinate to the number it annotates.
                        opacity: 0.75
                        text: Config.windowGlyph(button.topWindow?.lastIpcObject?.class ?? "")
                        visible: button.hasWindows && !button.isUrgent
                    }

                    // Urgent replaces the app glyph rather than adding to it:
                    // which app is shouting matters less than that one is.
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.accentError
                        height: 5
                        radius: Config.radiusPill
                        visible: button.isUrgent
                        width: 5
                    }
                }

                MouseArea {
                    id: area

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: entry.modelData.activate()
                }
            }
        }
    }
}
