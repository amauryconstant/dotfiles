pragma ComponentBehavior: Bound

import "../"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Notification centre, artboard pan-a. Replaces swaync's control center.
//
// Structurally the launcher and the power menu again: one window on the focused
// monitor, exclusive keyboard focus, no mask, a click outside dismisses. It
// differs in where the panel sits — top-right under the bar, where the toasts
// it archives were, rather than centred like a modal you summoned.
PanelWindow {
    id: root

    function close(): void {
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

        Keys.onEscapePressed: root.close()
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
        border.color: Theme.bgSecondary
        border.width: Config.hairline
        color: Theme.bgPrimary
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
                        color: Theme.fgPrimary
                        font.family: Config.guiFont
                        font.pixelSize: Config.fontSizeLarge
                        font.weight: Font.DemiBold
                        text: qsTr("Notifications")
                    }

                    // Accent ground, fgContrast text: the one place in this
                    // panel the accent appears, marking the count.
                    Rectangle {
                        color: Theme.accentPrimary
                        height: Config.notifBadgeHeight
                        radius: Config.radiusPill
                        visible: Notifications.unread > 0
                        width: Math.max(Config.notifBadgeHeight, count.implicitWidth + Config.padTight)

                        Text {
                            id: count

                            anchors.centerIn: parent
                            color: Theme.fgContrast
                            font.family: Config.terminalFont
                            font.pixelSize: Config.fontSizeTiny
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
                    // Config — one state, one glyph set, two surfaces.
                    Rectangle {
                        color: Notifications.dnd ? Theme.accentPrimary : Theme.bgSecondary
                        height: Config.notifActionHeight
                        radius: Config.radiusChip
                        width: Config.notifActionHeight

                        Text {
                            anchors.centerIn: parent
                            color: Notifications.dnd ? Theme.fgContrast : Theme.fgPrimary
                            font.family: Config.guiFont
                            font.pixelSize: Config.fontSize
                            text: Notifications.glyph()
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: Notifications.toggleDnd()
                        }
                    }

                    Rectangle {
                        color: Theme.bgSecondary
                        height: Config.notifActionHeight
                        radius: Config.radiusChip
                        width: clear.implicitWidth + Config.padLoose - 2

                        Text {
                            id: clear

                            anchors.centerIn: parent
                            color: Theme.fgPrimary
                            font.family: Config.guiFont
                            font.pixelSize: Config.fontSizeSmall - 1
                            font.weight: Font.Medium
                            text: qsTr("Clear")
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                Notifications.clearAll();
                                root.close();
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    color: Theme.bgSecondary
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
                implicitHeight: Math.min(contentHeight, root.height * 0.7)
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

                            notification: card.modelData.lead
                            rest: card.modelData.rest
                            width: parent.width

                            onDismissed: Notifications.dismiss(card.modelData.lead)
                        }
                    }
                }
            }

            Text {
                color: Theme.fgMuted
                font.family: Config.guiFont
                font.pixelSize: Config.fontSizeSmall
                height: Config.notifHeaderHeight
                horizontalAlignment: Text.AlignHCenter
                text: Notifications.dnd ? qsTr("Do not disturb") : qsTr("No notifications")
                verticalAlignment: Text.AlignVCenter
                visible: Notifications.groups.length === 0
                width: parent.width
            }

            // Footer: key hints. fgMuted is allowed here — the footer sits on
            // the panel's own bgPrimary ground, not on a card.
            Item {
                height: Config.notifFooterHeight
                width: parent.width

                Rectangle {
                    anchors.top: parent.top
                    color: Theme.bgSecondary
                    height: Config.hairline
                    width: parent.width
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Config.padTight + 2
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Config.pad - 2

                    Text {
                        color: Theme.fgMuted
                        font.family: Config.terminalFont
                        font.pixelSize: Config.fontSizeTiny
                        font.weight: Font.Medium
                        text: qsTr("super+shift+n toggle")
                    }

                    Text {
                        color: Theme.fgMuted
                        font.family: Config.terminalFont
                        font.pixelSize: Config.fontSizeTiny
                        font.weight: Font.Medium
                        text: qsTr("click → dismiss")
                    }
                }
            }
        }
    }
}
