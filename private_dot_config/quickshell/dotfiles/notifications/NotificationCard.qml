pragma ComponentBehavior: Bound

import "../"
import "../bar"
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick

// The one notification card, design page Shell-07-Notifications. Used by BOTH
// the centre and the popup stack — a toast is the same object at the same
// width, not a second narrower design.
//
// 🚨 Three structural rules, all easy to "improve" wrongly:
//
//  1. NO coloured left-border stripe. Every card keeps an identical
//     silhouette.
//  2. Severity is carried by the GLYPH CHIP — its tint AND the glyph itself
//     changing — never by a title colour. signalError as text measures 2.81 at
//     worst across the eight colorsets and is banned outright, so the title
//     colour this card used to vary was unreadable exactly when it mattered
//     most. There is likewise no severity TITLE: it repeats what the glyph and
//     body already say, and at 12.5px it would owe 4.5 rather than 3:1.
//  3. Every string on the card is inkPrimary — app label, timestamp, body,
//     collapsed siblings, all of it. The card grounds on groundFloat, which
//     design page 01's own tier table says "carries INK_PRIMARY only". Page 07
//     draws the timestamp in inkSecondary; the two disagree, and the
//     foundation page wins. Hierarchy comes from size, weight and
//     mono-vs-sans, never from dimming. The one non-inkPrimary foreground here
//     is the OUTLINE on the secondary action buttons — a graphic at 3:1, not
//     text, and page 13 rules explicitly that it is inkSecondary.
Rectangle {
    id: root

    required property var notification
    // Collapsed siblings from the same app, rendered as one line each.
    property list<var> rest: []
    // A popup is a glance: its body clamps to three lines. The centre is a list
    // the user came to read, so 0 means unclamped there.
    property int bodyMaxLines: 0
    // Popups have no actions row: the pointer is not reliably over a toast
    // that is about to vanish, and a mis-click on Dismiss loses the message.
    property bool showActions: true
    // Set by the centre only. With it, a left click on the card invokes the
    // sender's `default` action (or dismisses, where there is none) and a
    // right click opens this menu. Popups keep their own click: hide the toast.
    property ContextMenu menu: null

    signal dismissed

    // The action a sender means by "the notification itself was clicked" —
    // Slack's opens the thread. Freedesktop names it `default`.
    readonly property var defaultAction: root.notification.actions.find(a => a.identifier === "default") ?? null
    // Where the card itself is clickable, the default action is the click, so
    // a button repeating it would offer the same act twice.
    readonly property var buttonActions: root.menu ? root.notification.actions.filter(a => a.identifier !== "default") : root.notification.actions

    function activate(): void {
        if (root.defaultAction) {
            root.defaultAction.invoke();
            // resident asks to survive its own action, as with the buttons.
            if (root.notification.resident)
                return;
        }
        root.dismissed();
    }

    function menuActions(): var {
        const actions = [];
        if (root.defaultAction)
            actions.push({
                label: qsTr("Open"),
                glyph: Config.menuGlyphs.open,
                run: () => root.activate()
            });
        for (const action of root.buttonActions)
            actions.push({
                label: action.text,
                run: () => {
                    action.invoke();
                    if (!root.notification.resident)
                        root.dismissed();
                }
            });
        actions.push({
            label: qsTr("Dismiss"),
            glyph: Config.menuGlyphs.dismiss,
            run: () => root.dismissed()
        });
        return actions;
    }

    readonly property bool critical: root.notification.urgency === NotificationUrgency.Critical

    // 🚨 The identity a sender supplies can be a decoded pixmap, a theme icon
    // NAME, or a bare filesystem path — and quickshell hands all three over in
    // the same two properties: an `image-path` hint or an app_icon that is not
    // a file: URL is wrapped as image://icon/<it> either way. The icon provider
    // then answers a MAGENTA CHECKERBOARD for anything it cannot resolve
    // (`iconimageprovider.cpp` missingPixmap) rather than failing, and that
    // loads as Image.Ready — so gating on load status alone DRAWS the
    // checkerboard instead of falling back to the chip. Live case: timeshift
    // sends `notify-send -i gtk-dialog-info`, a legacy GTK stock name no
    // current icon theme carries.
    //
    // So classify first, and check every name through iconPath(.., true),
    // which is the only reliable "does this resolve" answer.
    readonly property string rawIdentity: {
        const s = root.notification.image || root.notification.appIcon || "";
        return s.startsWith("image://icon/") ? s.slice(13) : s;
    }
    // A real picture: a pixmap the server already decoded, or a file on disk.
    readonly property string imageSource: {
        const s = root.rawIdentity;
        if (s.startsWith("/"))
            return "file://" + s;
        return /^(file:|image:|https?:)/.test(s) ? s : "";
    }
    // Otherwise a theme name, with the sender's desktop entry as the second
    // chance — the name passed is often junk while the entry's icon is right.
    readonly property string iconSource: {
        if (root.imageSource)
            return "";
        const checked = root.rawIdentity ? Quickshell.iconPath(root.rawIdentity, true) : "";
        if (checked)
            return checked;
        const entryIcon = Notifications.entryFor(root.notification)?.icon ?? "";
        return entryIcon ? Quickshell.iconPath(entryIcon, true) : "";
    }

    // The hairline is what makes a toast read as a card over an arbitrary
    // wallpaper — without it the popup is a bare rounded rect. Same tier as
    // every other border in this tree. Critical takes it in signalError, which
    // is legal as a GRAPHIC at 3:1 and changes no silhouette — the second
    // carrier beside the chip glyph, for a critical whose summary is off
    // screen.
    border.color: root.critical ? Theme.signalError : Theme.edge
    border.width: Config.hairline
    color: Theme.groundFloat
    implicitHeight: layout.implicitHeight
    radius: Config.radiusChip

    Column {
        id: layout

        width: parent.width

        // App row: icon, APP NAME in caps, group count, spacer, relative time.
        Item {
            height: Math.max(appRow.implicitHeight, appName.implicitHeight) + Config.padTight
            width: parent.width

            Row {
                id: appRow

                anchors.left: parent.left
                anchors.leftMargin: Config.padTight
                anchors.verticalCenter: parent.verticalCenter
                spacing: Config.gap + 1

                // The identity slot: a 38px image thumbnail where the sender
                // supplied one, otherwise a 26px chip holding the app icon or
                // the severity glyph. Same slot and same alignment either way,
                // so a card with an image is the same shape as one without.
                Item {
                    id: identity

                    // Bound to STATUS, not to the source string: a failed
                    // decode must fall back to the glyph chip rather than
                    // leaving a hole where a thumbnail was promised.
                    readonly property bool hasImage: thumb.status === Image.Ready

                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: identity.hasImage ? Config.notifThumbSize : Config.chipSize
                    implicitWidth: identity.implicitHeight

                    Rectangle {
                        anchors.fill: parent
                        clip: true
                        color: root.critical ? Qt.alpha(Theme.signalError, 0.18) : Theme.groundRaised
                        radius: Config.radiusChip

                        Image {
                            id: thumb

                            anchors.fill: parent
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            source: root.imageSource
                            // 🚨 Decoded AT thumbnail size. A screenshot
                            // notification that stalls the shell for a full 4K
                            // decode is worse than no thumbnail at all.
                            sourceSize.height: Config.notifThumbSize
                            sourceSize.width: Config.notifThumbSize
                            visible: identity.hasImage
                        }

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: Config.notifIconSize + 4
                            source: root.iconSource
                            visible: !identity.hasImage && !root.critical && source !== ""
                        }

                        Text {
                            anchors.centerIn: parent
                            color: root.critical ? Theme.signalError : Theme.inkPrimary
                            font.family: Config.guiFont
                            font.pixelSize: Config.glyphRow
                            text: root.critical ? Config.notifCriticalGlyph : Config.notifGlyphs.notification
                            visible: !identity.hasImage && (root.critical || root.iconSource === "")
                        }
                    }
                }

                Text {
                    id: appName

                    color: Theme.inkPrimary
                    font.capitalization: Font.AllUppercase
                    font.family: Config.terminalFont
                    font.letterSpacing: 0.4
                    font.pixelSize: Config.fontMeta
                    font.weight: Font.Medium
                    text: Notifications.appLabel(root.notification)
                    textFormat: Text.PlainText
                }

                // Group count. Present only when siblings were collapsed into
                // this card, so it never renders a lone "1".
                Rectangle {
                    anchors.verticalCenter: appName.verticalCenter
                    color: Theme.groundRaised
                    height: Config.notifGroupBadgeHeight
                    radius: Config.radiusPill
                    visible: root.rest.length > 0
                    width: groupCount.implicitWidth + Config.padTight

                    Text {
                        id: groupCount

                        anchors.centerIn: parent
                        color: Theme.inkPrimary
                        font.family: Config.terminalFont
                        font.pixelSize: Config.fontMeta - 1
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
                color: Theme.inkPrimary
                font.family: Config.terminalFont
                font.pixelSize: Config.fontMeta
                text: age.label
            }
        }

        // Content: title, then body.
        Column {
            spacing: 4
            width: parent.width

            Text {
                // Not severity-coloured: see rule 2 in the header.
                color: Theme.inkPrimary
                elide: Text.ElideRight
                font.family: Config.guiFont
                font.pixelSize: Config.fontTitle
                font.weight: Font.DemiBold
                text: root.notification.summary
                // bodyMarkupSupported is false, so anything tag-shaped in here
                // is literal text a sender did not mean as markup.
                textFormat: Text.PlainText
                width: parent.width - Config.padTight * 2
                x: Config.padTight
            }

            Text {
                color: Theme.inkPrimary
                elide: Text.ElideRight
                font.family: Config.guiFont
                font.pixelSize: Config.fontBody
                lineHeight: 1.35
                maximumLineCount: root.bodyMaxLines > 0 ? root.bodyMaxLines : Number.MAX_SAFE_INTEGER
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
                model: root.buttonActions

                Rectangle {
                    id: action

                    required property var modelData
                    required property int index

                    color: action.index === 0 ? Theme.groundRaised : "transparent"
                    // fgSecondary, not fgMuted: an outline is a UI component
                    // and wants 3:1, which fgMuted on this card's bgOverlay
                    // ground misses in four of the eight themes (2.18 at worst).
                    // Still foreground-class, so Amendment C's rule holds.
                    border.color: action.index === 0 ? "transparent" : Theme.inkSecondary
                    border.width: action.index === 0 ? 0 : Config.hairline
                    height: Config.notifActionHeight
                    radius: Config.radiusChip
                    width: actionLabel.implicitWidth + Config.padLoose

                    Text {
                        id: actionLabel

                        anchors.centerIn: parent
                        color: Theme.inkPrimary
                        font.family: Config.guiFont
                        font.pixelSize: Config.fontBody - 1
                        font.weight: Font.Medium
                        text: action.modelData.text
                        textFormat: Text.PlainText
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
                border.color: Theme.inkSecondary
                border.width: Config.hairline
                color: "transparent"
                height: Config.notifActionHeight
                radius: Config.radiusChip
                width: dismissLabel.implicitWidth + Config.padLoose

                Text {
                    id: dismissLabel

                    anchors.centerIn: parent
                    color: Theme.inkPrimary
                    font.family: Config.guiFont
                    font.pixelSize: Config.fontBody - 1
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
                color: Theme.groundBase
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
                    color: Theme.inkPrimary
                    // A collapsed sibling keeps its severity through its GLYPH,
                    // for the same reason the lead card does — signalError as
                    // text is banned in every theme.
                    font.bold: sibling.modelData.urgency === NotificationUrgency.Critical
                    elide: Text.ElideRight
                    font.family: Config.guiFont
                    font.pixelSize: Config.fontBody - 1
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
    // relative-timestamps. Notification carries no arrival time, so the
    // singleton records one — here rather than in the delegate, because a card
    // restored from the last session must not read as having just arrived.
    QtObject {
        id: age

        readonly property double created: Notifications.arrivedAt(root.notification)
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

    // The centre's card click. 🚨 z: -1, the rule BarWidget and the popup stack
    // follow: declared after the content it would sit ABOVE every child's
    // MouseArea and swallow the buttons' clicks. Under the content, a button
    // wins where one exists and the card takes the click everywhere else.
    MouseArea {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: root.menu !== null
        z: -1

        onClicked: event => {
            if (event.button === Qt.RightButton)
                root.menu.show(root, root.menuActions(), false);
            else
                root.activate();
        }
    }
}
