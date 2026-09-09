pragma ComponentBehavior: Bound

import "../"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Workspace overview, artboard comp-b (Phase 5.5). A carousel, not a grid: the
// focused workspace stays legible at real proportions while its neighbours are
// peripheral context.
//
// One window on the focused monitor, like the launcher and the power menu — an
// overview is a modal you summoned, so it belongs where you are looking.
//
// 🚨 No ScreencopyView. The artboard draws window CHROME (a titlebar with an
// app glyph and a name), not screenshots, and lastIpcObject already carries
// every field needed to draw that at real proportions. Two behaviours the
// artboard does draw are out because both need a raw Hyprland.dispatch(),
// which is exactly what the Phase 2 Lua cutover removed: dragging a window
// between workspaces, and the dashed "+" card that creates one.
PanelWindow {
    id: root

    property int selected: 0
    readonly property var monitor: Hyprland.focusedMonitor
    // Same expression the bar's workspace pills use. Hyprland's models
    // populate lazily over ~1s, so this is a binding, never a one-shot read.
    readonly property var workspaces: [...Hyprland.workspaces.values].filter(ws => ws.monitor && ws.monitor.name === root.monitor?.name).sort((a, b) => a.id - b.id)
    readonly property real cardWidth: root.width * Config.overviewFocusedFraction
    // 🚨 Derived from the monitor, NOT from the carousel Row: a slot height of
    // `carousel.height` is a binding loop, because a Row sizes itself from the
    // very children that would be reading it back. This is the focused card at
    // full scale, which is the tallest a slot ever needs to be.
    readonly property real cardHeight: root.cardWidth * ((root.monitor?.height ?? 1080) / (root.monitor?.width ?? 1920)) + Config.overviewFooterHeight

    function activate(): void {
        const ws = root.workspaces[root.selected];
        root.close();
        // 🚨 activate(), never Hyprland.dispatch(): it is the one call
        // Quickshell translates for Hyprland's Lua config provider.
        ws?.activate();
    }

    function close(): void {
        root.visible = false;
    }

    function open(): void {
        root.selected = Math.max(0, root.workspaces.findIndex(ws => ws.focused));
        root.visible = true;
        keys.forceActiveFocus();
    }

    // Returns the state actually reached, matching every other surface's
    // toggle() contract so quickshell-toggle reports what happened.
    function toggle(): string {
        if (root.visible)
            root.close();
        else
            root.open();
        return root.visible ? "shown" : "hidden";
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    visible: false

    // qmllint disable unqualified unresolved-type
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    anchors.top: true
    // qmllint enable unqualified unresolved-type

    // Exclusive, like the launcher: arrow keys must work the moment it maps,
    // without a click first. Deliberately unmasked — a click anywhere outside
    // a card dismisses it.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.layer: WlrLayer.Overlay

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.scrim, Config.scrimOpacity)
    }

    MouseArea {
        anchors.fill: parent

        onClicked: root.close()
    }

    FocusScope {
        id: keys

        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: root.selected = Math.max(0, root.selected - 1)
        Keys.onReturnPressed: root.activate()
        Keys.onRightPressed: root.selected = Math.min(root.workspaces.length - 1, root.selected + 1)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Config.padLoose * 2
            color: Theme.fgOnScrim
            font.family: Config.terminalFont
            font.letterSpacing: 2
            font.pixelSize: Config.fontBody
            // Subordination by opacity, not by a dimmer token: the scrim is a
            // bg-overlay ground, where themes/CLAUDE.md bans fg-secondary and
            // fg-muted alike.
            opacity: 0.6
            text: `${root.monitor?.name ?? ""} · WORKSPACES`
        }

        // A fixed five-slot window centred on the selection, rather than the
        // whole list: the falloff is symmetric, so this keeps the focused card
        // optically centred even at either end of the list, where a plain
        // centred Row would drift.
        Row {
            id: carousel

            anchors.centerIn: parent
            spacing: Config.overviewGap

            Repeater {
                model: [-2, -1, 0, 1, 2]

                Item {
                    id: slot

                    required property int modelData
                    readonly property int step: Math.abs(slot.modelData)
                    readonly property int target: root.selected + slot.modelData
                    readonly property var workspace: root.workspaces[slot.target] ?? null
                    readonly property real factor: Config.overviewCardScale[slot.step]

                    height: root.cardHeight
                    visible: slot.workspace !== null
                    width: root.cardWidth * slot.factor

                    WorkspaceCard {
                        active: root.visible
                        anchors.verticalCenter: parent.verticalCenter
                        detail: slot.factor
                        focused: slot.step === 0
                        monitor: root.monitor
                        opacity: Config.overviewCardOpacity[slot.step]
                        previewWidth: parent.width
                        workspace: slot.workspace

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                root.selected = slot.target;
                                root.activate();
                            }
                        }
                    }
                }
            }
        }

        Row {
            anchors.bottom: hint.top
            anchors.bottomMargin: Config.padLoose
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Config.gap

            Repeater {
                model: root.workspaces

                Rectangle {
                    id: dot

                    required property int index

                    anchors.verticalCenter: parent.verticalCenter
                    // 🚨 fgOnScrim, not fgSecondary. These sit on the scrim,
                    // which is dark in every theme, so a light theme's own
                    // fg-secondary lands at 2.38 (gruvbox-light) and vanishes.
                    // The earlier bgSecondary was worse still — it EQUALS
                    // bgOverlay in five of eight themes and measured 1.00.
                    color: dot.index === root.selected ? Theme.signalFocus : Theme.fgOnScrim
                    height: Config.overviewDotSize
                    radius: Config.radiusPill
                    width: dot.index === root.selected ? Config.overviewDotActiveWidth : Config.overviewDotSize
                }
            }
        }

        Text {
            id: hint

            anchors.bottom: parent.bottom
            anchors.bottomMargin: Config.padLoose * 2
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.fgOnScrim
            font.family: Config.terminalFont
            font.pixelSize: Config.fontBody
            opacity: 0.6
            // The artboard's third clause, "drag window to move", is absent
            // because the behaviour is — see the header.
            text: "← → switch  ·  ↵ activate  ·  esc close"
        }
    }
}
