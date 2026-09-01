pragma ComponentBehavior: Bound

import "../"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Power / session menu (Phase 5, artboard 1h). A front-end over the exact
// commands `wlogout/layout` already ran — including `session-save` before every
// destructive action — so this changes the surface and nothing about what the
// machine does.
//
// 🚨 It also keeps wlogout's activation model: a tile fires on one activation,
// with no confirmation step, because the wrapper it replaces has none either.
// Adding one here would be a behaviour change smuggled in as a redesign. The
// safe default is the selection, not a dialog: Lock is selected on open, so
// Return alone can never power anything off.
PanelWindow {
    id: root

    // Six, not the canvas's five. Hibernate exists here and does real work on
    // the laptop; Amendment A's rule for the bar's eleven widgets applies just
    // as well to this row — do not delete a function to match the drawing.
    // Mnemonics are wlogout's own, so the muscle memory survives.
    readonly property list<var> actions: [
        {
            key: "l",
            label: "Lock",
            glyph: "󰌾",
            destructive: false,
            command: `${Config.scriptsDir}/desktop/immediate-lock`
        },
        {
            key: "u",
            label: "Suspend",
            glyph: "󰤄",
            destructive: false,
            command: "systemctl suspend"
        },
        {
            key: "e",
            label: "Log out",
            glyph: "󰍃",
            destructive: false,
            command: `${Config.scriptsDir}/desktop/session-save && hyprctl dispatch exit`
        },
        {
            key: "h",
            label: "Hibernate",
            glyph: "󰜗",
            destructive: false,
            command: `${Config.scriptsDir}/desktop/session-save hibernate && systemctl hibernate`
        },
        {
            key: "r",
            label: "Reboot",
            glyph: "󰜉",
            destructive: false,
            command: `${Config.scriptsDir}/desktop/session-save reboot && systemctl reboot`
        },
        {
            key: "s",
            label: "Shut down",
            glyph: "󰤂",
            destructive: true,
            command: `${Config.scriptsDir}/desktop/session-save shutdown && systemctl poweroff`
        }
    ]
    property int selected: 0
    property string identity: ""
    property string uptime: ""

    function close(): void {
        root.visible = false;
    }

    function open(): void {
        root.selected = 0;
        root.visible = true;
        identityProc.running = true;
        keys.forceActiveFocus();
    }

    function toggle(): string {
        if (root.visible)
            root.close();
        else
            root.open();
        return root.visible ? "shown" : "hidden";
    }

    // Every command is a shell line with `&&` in it, exactly as wlogout ran
    // them, so it goes through sh rather than being split into an argv.
    function run(action: var): void {
        root.close();
        Quickshell.execDetached(["sh", "-c", action.command]);
    }

    function activateKey(text: string): bool {
        const at = root.actions.findIndex(a => a.key === text.toLowerCase());
        if (at < 0)
            return false;
        root.selected = at;
        root.run(root.actions[at]);
        return true;
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

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.layer: WlrLayer.Overlay

    // A full-surface scrim: the menu is modal, and dimming what is behind it is
    // what makes a destructive row read as a decision rather than a toolbar.
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bgPrimary, 0.86)

        MouseArea {
            anchors.fill: parent

            onClicked: root.close()
        }
    }

    Item {
        id: keys

        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: root.selected = Math.max(root.selected - 1, 0)
        Keys.onRightPressed: root.selected = Math.min(root.selected + 1, root.actions.length - 1)
        Keys.onReturnPressed: root.run(root.actions[root.selected])
        Keys.onEnterPressed: root.run(root.actions[root.selected])
        Keys.onPressed: event => {
            if (event.text && root.activateKey(event.text))
                event.accepted = true;
        }

        Column {
            anchors.centerIn: parent
            spacing: Config.powerColumnGap

            // Identity.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Config.padTight - 1

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.bgTertiary
                    height: Config.powerAvatarSize
                    radius: Config.radiusPill
                    width: Config.powerAvatarSize

                    Text {
                        anchors.centerIn: parent
                        color: Theme.accentPrimary
                        font.family: Config.terminalFont
                        font.pixelSize: Config.fontSizeSmall
                        text: root.identity.substring(0, 1).toUpperCase() || "?"
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        color: Theme.fgPrimary
                        font.family: Config.guiFont
                        font.pixelSize: Config.fontSize
                        text: root.identity
                    }

                    Text {
                        color: Theme.fgMuted
                        font.family: Config.terminalFont
                        font.pixelSize: Config.fontSizeTiny
                        text: root.uptime
                    }
                }
            }

            // Tile row.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Config.powerTileGap

                Repeater {
                    model: root.actions

                    delegate: Rectangle {
                        id: tile

                        required property int index
                        required property var modelData
                        readonly property bool current: tile.index === root.selected

                        // The accent marks the selection and nothing else. A
                        // destructive tile is red in its GLYPH only, so the row
                        // keeps one rhythm and the selection stays the only
                        // thing the eye is pulled to.
                        border.color: tile.current ? Theme.accentPrimary : Theme.bgTertiary
                        border.width: Config.hairline
                        color: Theme.bgSecondary
                        height: Config.powerTileSize
                        radius: Config.powerTileRadius
                        width: Config.powerTileSize

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: root.run(tile.modelData)
                            onEntered: root.selected = tile.index
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: Config.padTight

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: tile.modelData.destructive ? Theme.accentError : tile.current ? Theme.accentPrimary : Theme.fgPrimary
                                font.family: Config.guiFont
                                font.pixelSize: Config.powerGlyphSize
                                text: tile.modelData.glyph
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                // bgSecondary is elevated, so fg-primary is the
                                // only legal neutral here (themes/CLAUDE.md).
                                color: Theme.fgPrimary
                                font.family: Config.guiFont
                                font.pixelSize: Config.fontSizeSmall
                                text: tile.modelData.label
                            }
                        }
                    }
                }
            }

            // Mnemonic row.
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.fgMuted
                font.family: Config.terminalFont
                font.pixelSize: Config.fontSizeTiny
                text: `${root.actions.map(a => a.key).join("  ")}   \u00b7   esc cancel`
            }
        }
    }

    // Identity line. One shell call on open rather than three bindings: none of
    // it changes while the menu is up.
    Process {
        id: identityProc

        // Three plain lines; the separator is composed in QML, because POSIX
        // printf does not interpret \u escapes in a format string.
        command: ["sh", "-c", 'printf "%s@%s\\n%s\\n%s" "$USER" "$(hostname)" "$(uptime -p)" "$(who | wc -l)"']

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n");
                root.identity = lines[0] ?? "";
                const sessions = parseInt(lines[2] ?? "", 10);
                root.uptime = [lines[1], isNaN(sessions) ? "" : `${sessions} session${sessions === 1 ? "" : "s"}`].filter(v => v).join(" \u00b7 ");
            }
        }
    }
}
