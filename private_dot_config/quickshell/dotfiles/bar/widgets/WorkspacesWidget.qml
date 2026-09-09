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
                color: Theme.edge
                height: 6
                radius: Config.radiusPill
                visible: entry.index > 0 && root.workspaces[entry.index - 1].id !== entry.modelData.id - 1
                width: 6
            }

            Rectangle {
                id: button

                // Four states and no fifth. Precedence matters: urgent wins,
                // then the workspace with input focus, then one merely
                // occupied. "Visible on another monitor" and "occupied"
                // deliberately share one appearance.
                readonly property bool hasWindows: entry.modelData.toplevels.values.length > 0
                readonly property bool isFocused: entry.modelData.focused
                readonly property bool isUrgent: entry.modelData.urgent
                readonly property var topWindow: entry.modelData.toplevels.values[0] ?? null

                // 🚨 Occupied is groundRaised, NEVER fillInert. inkPrimary on
                // fillInert measures 1.67 in solarized-light, 1.70 in
                // solarized-dark and 4.39 in Latte — the number on the most
                // common pill state was unreadable in three of the eight
                // colorsets, which no amount of looking at Mocha would show.
                //
                // Urgent is the 13% selection tint plus a weight change, never
                // a colour alone: signalError as TEXT measures 2.81 at worst
                // and is banned outright.
                color: button.isFocused ? Theme.signalFocus : button.isUrgent ? Theme.select : button.hasWindows || area.containsMouse ? Theme.hover : "transparent"
                height: Config.pillHeight
                radius: Config.radiusPill
                // An empty workspace is a number in a 24px round square; every
                // other state grows from that to fit its glyph.
                //
                // The mockup gives "empty" a faint ground of its own. Ours stays
                // transparent deliberately: an elevated surface would force
                // inkPrimary onto the one state that has to recede. On the bar
                // ground, inkSecondary is legal and is what it uses.
                width: Math.max(height, contents.implicitWidth + Config.padTight)

                Row {
                    id: contents

                    anchors.centerIn: parent
                    spacing: Config.gap / 2

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: button.isFocused ? Theme.inkOnSignal : button.hasWindows || button.isUrgent ? Theme.inkPrimary : Theme.inkSecondary
                        font.family: Config.terminalFont
                        // The number is L3's carrier for urgent: the tint alone
                        // reaches 1.10-1.98 and cannot say anything by itself.
                        font.weight: button.isUrgent ? Font.Bold : Font.Normal
                        font.pixelSize: Config.fontBody
                        text: entry.modelData.name
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        // Only ever drawn on a lit ground, so inkPrimary —
                        // subordination comes from opacity, not from a quieter
                        // token, because inkSecondary is illegal on groundRaised.
                        color: button.isFocused ? Theme.inkOnSignal : Theme.inkPrimary
                        font.family: Config.guiFont
                        font.pixelSize: Config.glyphRow
                        // Subordinate to the number it annotates.
                        opacity: 0.75
                        text: Config.windowGlyph(button.topWindow?.lastIpcObject?.class ?? "")
                        visible: button.hasWindows
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
