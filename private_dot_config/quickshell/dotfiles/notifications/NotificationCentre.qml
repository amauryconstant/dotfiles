pragma ComponentBehavior: Bound

import "../"
import "../bar"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Notification centre, design page Shell-07-Notifications. Replaces swaync's
// control center.
//
// Structurally the launcher and the power menu again: one window on the focused
// monitor, exclusive keyboard focus, no mask, a click outside dismisses. It
// differs in where the panel sits — top-right under the bar, where the toasts
// it archives were, rather than centred like a modal you summoned.
PanelWindow {
    id: root

    function close(): void {
        cardMenu.hide();
        root.visible = false;
    }

    function open(): void {
        root.visible = true;
    }

    // Same contract as bar/launcher/power: report the state actually reached,
    // never the one asked for, so quickshell-toggle can tell the truth.
    function toggle(): string {
        root.visible = !root.visible;
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

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.layer: WlrLayer.Overlay

    // Same key-catcher Item as PowerMenu: Keys handlers need a focused ITEM,
    // and a PanelWindow is not one.
    Item {
        anchors.fill: parent
        focus: true

        // Escape closes the card menu first, the centre only once it is gone.
        Keys.onEscapePressed: cardMenu.visible ? cardMenu.hide() : root.close()
    }

    MouseArea {
        anchors.fill: parent

        onClicked: root.close()
    }

    Rectangle {
        id: panel

        anchors.right: parent.right
        anchors.rightMargin: Config.barInset
        anchors.top: parent.top
        anchors.topMargin: Config.barHeight + Config.barInset * 2
        border.color: Theme.edge
        border.width: Config.hairline
        color: Theme.groundBase
        implicitHeight: layout.implicitHeight
        radius: Config.radiusPanel
        width: Config.notifWidth

        // Swallows clicks on the panel so the dismiss area underneath does not
        // close it mid-interaction.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: layout

            width: parent.width

            // Header: title, count badge, spacer, DND chip, Clear.
            Item {
                height: Config.notifHeaderHeight
                width: parent.width

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Config.pad
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Config.gap + 2

                    Text {
                        color: Theme.inkPrimary
                        font.family: Config.guiFont
                        font.pixelSize: Config.fontTitle
                        font.weight: Font.DemiBold
                        text: qsTr("Notifications")
                    }

                    // Action ground, inkOnAction text: an accent fill that
                    // carries text is Theme.action, never raw signalFocus.
                    Rectangle {
                        color: Theme.action
                        height: Config.notifBadgeHeight
                        radius: Config.radiusPill
                        visible: Notifications.unread > 0
                        width: Math.max(Config.notifBadgeHeight, count.implicitWidth + Config.padTight)

                        Text {
                            id: count

                            anchors.centerIn: parent
                            color: Theme.inkOnAction
                            font.family: Config.terminalFont
                            font.pixelSize: Config.fontMeta
                            font.weight: Font.DemiBold
                            text: Notifications.unread
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: Config.pad
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Config.gap

                    // DND. Same four bell glyphs the bar widget uses, from
                    // Config — one state, one glyph set, two surfaces. A
                    // toggle: neutral off, action-filled on. Its rest ground
                    // used to be groundRaised, 1.05-1.37 against this panel.
                    ActionButton {
                        emphasis: Notifications.dnd ? "primary" : "neutral"
                        glyph: Notifications.glyph()

                        onActivated: Notifications.toggleDnd()
                    }

                    // Ours, so neutral. Same tier-step defect as the DND chip.
                    ActionButton {
                        emphasis: "neutral"
                        text: qsTr("Clear")

                        onActivated: {
                            Notifications.clearAll();
                            root.close();
                        }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    color: Theme.edge
                    height: Config.hairline
                    width: parent.width
                }
            }

            // Body. Height is capped so a long history scrolls rather than
            // growing a panel taller than the screen.
            // Flickable, not a Controls ScrollView: this needs clipping and a
            // content height and nothing else, and QtQuick.Controls would drag
            // a styled scrollbar into a tree that has no other Controls type.
            Flickable {
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                contentHeight: cards.implicitHeight + Config.notifListPad * 2
                // Bounded at notifCentreMaxHeight, taller than a popover
                // because this is a list the user came to read — and still
                // bounded by the output, which a fixed number is not.
                implicitHeight: Math.min(contentHeight, Config.notifCentreMaxHeight, root.height * 0.7)
                width: parent.width

                Column {
                    id: cards

                    spacing: Config.gap
                    width: panel.width - Config.notifListPad * 2
                    x: Config.notifListPad
                    y: Config.notifListPad

                    Repeater {
                        model: Notifications.groups

                        NotificationCard {
                            id: card

                            required property var modelData

                            menu: cardMenu
                            notification: card.modelData.lead
                            rest: card.modelData.rest
                            width: parent.width

                            onDismissed: Notifications.dismiss(card.modelData.lead)
                        }
                    }
                }
            }

            // The empty state is the state a user sees most often, so it is
            // inkSecondary — legible — rather than a retired muted token.
            Text {
                color: Theme.inkSecondary
                font.family: Config.guiFont
                font.pixelSize: Config.fontBody
                height: Config.notifHeaderHeight
                horizontalAlignment: Text.AlignHCenter
                text: Notifications.dnd ? qsTr("Do not disturb") : qsTr("No notifications")
                verticalAlignment: Text.AlignVCenter
                visible: Notifications.groups.length === 0
                width: parent.width
            }

            // Footer: key hints. inkSecondary is legal here — the footer sits
            // on the panel's own groundBase, which is the one ground that
            // carries a second ink.
            Item {
                height: Config.notifFooterHeight
                width: parent.width

                Rectangle {
                    anchors.top: parent.top
                    color: Theme.edge
                    height: Config.hairline
                    width: parent.width
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Config.padTight + 2
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Config.pad - 2

                    Text {
                        color: Theme.inkSecondary
                        font.family: Config.terminalFont
                        font.pixelSize: Config.fontMeta
                        font.weight: Font.Medium
                        text: qsTr("super+shift+n toggle")
                    }

                    Text {
                        color: Theme.inkSecondary
                        font.family: Config.terminalFont
                        font.pixelSize: Config.fontMeta
                        font.weight: Font.Medium
                        text: qsTr("click → open · right → actions")
                    }
                }
            }
        }
    }

    // Over the whole window, so a card near the bottom can open its menu
    // upward past the panel's edge, and a click anywhere else closes the menu
    // without closing the centre.
    ContextMenu {
        id: cardMenu

        anchors.fill: parent
    }
}
