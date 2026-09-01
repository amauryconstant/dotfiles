pragma ComponentBehavior: Bound

import "../"
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick

// The one notification card, artboard pan-a. Used by BOTH the centre and the
// popup stack — a toast is the same object at the same width, not a second
// narrower design.
//
// 🚨 Two structural rules from the artboard, both easy to "improve" wrongly:
//
//  1. NO coloured left-border stripe. The canvas sets `border-left:0`
//     explicitly. Every card keeps an identical silhouette; severity is
//     carried by the TITLE COLOUR ALONE.
//  2. Every string on the card is fgPrimary — app label, timestamp, body,
//     collapsed siblings, all of it. The card ground is elevated, so
//     themes/CLAUDE.md forbids fgSecondary and fgMuted on it. Hierarchy comes
//     from size, weight and mono-vs-sans, never from dimming. The only
//     non-fgPrimary foreground on this card is the OUTLINE on the secondary
//     action buttons, because borders are foreground-class and a background
//     token cannot carry one. It was fgMuted until the 2026-09-01 contrast
//     pass measured it below the 3:1 a UI component needs in four themes;
//     fgSecondary is the quietest token that clears 3:1 in all eight.
Rectangle {
    id: root

    required property var notification
    // Collapsed siblings from the same app, rendered as one line each.
    property list<var> rest: []
    // Popups have no actions row: the pointer is not reliably over a toast
    // that is about to vanish, and a mis-click on Dismiss loses the message.
    property bool showActions: true

    signal dismissed

    readonly property bool critical: root.notification.urgency === NotificationUrgency.Critical

    color: Theme.bgOverlay
    implicitHeight: layout.implicitHeight
    radius: Config.radiusTile

    Column {
        id: layout

        width: parent.width

        // App row: icon, APP NAME in caps, group count, spacer, relative time.
        Item {
            height: appName.implicitHeight + Config.padTight
            width: parent.width

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Config.padTight
                anchors.verticalCenter: parent.verticalCenter
                spacing: Config.gap + 1

                IconImage {
                    implicitSize: Config.notifIconSize + 4
                    source: root.notification.appIcon ? Quickshell.iconPath(root.notification.appIcon, true) : ""
                    visible: source !== ""
                }

                Text {
                    id: appName

                    color: Theme.fgPrimary
                    font.capitalization: Font.AllUppercase
                    font.family: Config.terminalFont
                    font.letterSpacing: 0.4
                    font.pixelSize: Config.fontSizeTiny
                    font.weight: Font.Medium
                    text: root.notification.appName || root.notification.desktopEntry || "unknown"
                }

                // Group count. Present only when siblings were collapsed into
                // this card, so it never renders a lone "1".
                Rectangle {
                    anchors.verticalCenter: appName.verticalCenter
                    color: Theme.bgSecondary
                    height: Config.notifGroupBadgeHeight
                    radius: Config.radiusPill
                    visible: root.rest.length > 0
                    width: groupCount.implicitWidth + Config.padTight

                    Text {
                        id: groupCount

                        anchors.centerIn: parent
                        color: Theme.fgPrimary
                        font.family: Config.terminalFont
                        font.pixelSize: Config.fontSizeTiny - 1
                        font.weight: Font.Medium
                        text: root.rest.length + 1
                    }
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: Config.padTight
                // parent, not appName: that Text lives inside the Row, so it is
                // neither this item's parent nor its sibling and the anchor is
                // rejected at runtime with only a warning.
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fgPrimary
                font.family: Config.terminalFont
                font.pixelSize: Config.fontSizeTiny
                text: age.label
            }
        }

        // Content: title, then body.
        Column {
            spacing: 4
            width: parent.width

            Text {
                color: root.critical ? Theme.accentError : Theme.fgPrimary
                elide: Text.ElideRight
                font.family: Config.guiFont
                font.pixelSize: Config.fontSize
                font.weight: Font.DemiBold
                text: root.notification.summary
                // bodyMarkupSupported is false, so anything tag-shaped in here
                // is literal text a sender did not mean as markup.
                textFormat: Text.PlainText
                width: parent.width - Config.padTight * 2
                x: Config.padTight
            }

            Text {
                color: Theme.fgPrimary
                elide: Text.ElideRight
                font.family: Config.guiFont
                font.pixelSize: Config.fontSizeSmall
                lineHeight: 1.35
                maximumLineCount: 4
                text: root.notification.body
                textFormat: Text.PlainText
                visible: text !== ""
                width: parent.width - Config.padTight * 2
                wrapMode: Text.WordWrap
                x: Config.padTight
            }

            // Bottom padding, as an item rather than a margin so the Column
            // keeps one spacing rule.
            Item {
                height: Config.padTight
                width: 1
            }
        }

        // Actions. The first is the primary and is filled; Dismiss is the
        // outlined one, and is ours rather than the sender's.
        Row {
            spacing: Config.gap
            visible: root.showActions && root.notification.actions.length > 0
            width: parent.width
            x: Config.padTight

            Repeater {
                model: root.notification.actions

                Rectangle {
                    id: action

                    required property var modelData
                    required property int index

                    color: action.index === 0 ? Theme.bgSecondary : "transparent"
                    // fgSecondary, not fgMuted: an outline is a UI component
                    // and wants 3:1, which fgMuted on this card's bgOverlay
                    // ground misses in four of the eight themes (2.18 at worst).
                    // Still foreground-class, so Amendment C's rule holds.
                    border.color: action.index === 0 ? "transparent" : Theme.fgSecondary
                    border.width: action.index === 0 ? 0 : Config.hairline
                    height: Config.notifActionHeight
                    radius: Config.radiusChip
                    width: actionLabel.implicitWidth + Config.padLoose

                    Text {
                        id: actionLabel

                        anchors.centerIn: parent
                        color: Theme.fgPrimary
                        font.family: Config.guiFont
                        font.pixelSize: Config.fontSizeSmall - 1
                        font.weight: Font.Medium
                        text: action.modelData.text
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            action.modelData.invoke();
                            // resident asks to survive its own action.
                            if (!root.notification.resident)
                                root.dismissed();
                        }
                    }
                }
            }

            Rectangle {
                // Same 3:1 outline rule as the action buttons above.
                border.color: Theme.fgSecondary
                border.width: Config.hairline
                color: "transparent"
                height: Config.notifActionHeight
                radius: Config.radiusChip
                width: dismissLabel.implicitWidth + Config.padLoose

                Text {
                    id: dismissLabel

                    anchors.centerIn: parent
                    color: Theme.fgPrimary
                    font.family: Config.guiFont
                    font.pixelSize: Config.fontSizeSmall - 1
                    font.weight: Font.Medium
                    text: qsTr("Dismiss")
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: root.dismissed()
                }
            }
        }

        Item {
            height: Config.padTight
            visible: root.showActions && root.notification.actions.length > 0
            width: 1
        }

        // Collapsed siblings, under a divider. bgPrimary, not bgSecondary: on
        // an elevated card the divider has to be DARKER than its ground to read
        // as a division rather than as another chip.
        Column {
            width: parent.width

            Rectangle {
                color: Theme.bgPrimary
                height: Config.hairline
                visible: root.rest.length > 0
                width: parent.width - Config.padTight * 2
                x: Config.padTight
            }

            Repeater {
                model: root.rest

                Text {
                    id: sibling

                    required property var modelData

                    // A collapsed sibling keeps its severity. Without this a
                    // critical battery warning grouped under a chatty sender
                    // reads as one more ordinary line — and everything our own
                    // scripts send shares the app name `notify-send`, so that
                    // grouping is the common case here, not the rare one.
                    color: sibling.modelData.urgency === NotificationUrgency.Critical ? Theme.accentError : Theme.fgPrimary
                    elide: Text.ElideRight
                    font.family: Config.guiFont
                    font.pixelSize: Config.fontSizeSmall - 1
                    leftPadding: Config.padTight
                    rightPadding: Config.padTight
                    text: sibling.modelData.summary
                    textFormat: Text.PlainText
                    topPadding: 9
                    width: root.width
                }
            }

            Item {
                height: Config.padTight
                visible: root.rest.length > 0
                width: 1
            }
        }
    }

    // Relative timestamps ("2 min", "1 h"), like swaync's
    // relative-timestamps. Notification carries no arrival time, so it is
    // recorded here on creation.
    QtObject {
        id: age

        readonly property double created: Date.now()
        property string label: "now"

        function refresh(): void {
            const seconds = Math.max(0, (Date.now() - age.created) / 1000);
            if (seconds < 45)
                age.label = qsTr("now");
            else if (seconds < 3600)
                age.label = `${Math.round(seconds / 60)} min`;
            else if (seconds < 86400)
                age.label = `${Math.round(seconds / 3600)} h`;
            else
                age.label = `${Math.round(seconds / 86400)} d`;
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: true

        onTriggered: age.refresh()
    }
}
