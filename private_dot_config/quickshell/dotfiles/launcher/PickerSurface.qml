pragma ComponentBehavior: Bound

import "../"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

// The chrome three surfaces share: the launcher (page 05), the clipboard
// (page 11) and the script-driven menu (page 10's chrome rules). Design page 11
// says outright that the clipboard is "deliberately the launcher's shape,
// because it is the same interaction and a second layout would be a second
// thing to learn" -- so there is one layout here rather than three that drift.
//
// 🚨 Consumers supply DATA, not a delegate. Passing a Component through a
// `property Component` breaks qmllint: it cannot know the component is a
// delegate, so the `index`/`modelData` required properties that
// `pragma ComponentBehavior: Bound` forces read as unsatisfiable and every use
// site fails the build. The three row shapes were the same shape anyway --
// leading icon or glyph, title, optional subtitle, a return mark when current
// -- so one delegate over a small row contract is both lintable and less code.
//
// A row is a plain object:
//   title         required
//   subtitle      optional; its absence is what makes the row 34 tall instead
//                 of 48, which is exactly page 10's menu row against page 05's
//   glyph         optional leading glyph
//   iconSource    optional themed icon path; wins over glyph
//   mono          title in terminalFont -- content that will be pasted verbatim
//   elideMiddle   for a path, whose identifying half is its tail
//   subtitleError subtitle in signalError, for a failure reported in place
PanelWindow {
    id: root

    // Rows to draw. Plain objects, see the contract above.
    property var model: []

    // Header: a glyph, the field's placeholder, and a right-aligned counter.
    // `headerAccent` switches the glyph to the accent colour in the terminal
    // face, which is how the launcher renders an active prefix.
    property string headerGlyph: ""
    property bool headerAccent: false
    property string placeholder: ""
    property string counter: ""

    property string footerLeft: ""
    property string footerRight: ""

    // Selection cursor. Consumers read it in `accepted`; the list keeps it
    // visible.
    property int selected: 0

    // 🚨 Esc clears the query, and a second Esc closes -- the launcher's rule,
    // because losing a half-typed query to a stray keypress is worse than one
    // extra keystroke. A menu invoked from a script sets this false: there the
    // query is incidental and Esc means "the caller gets nothing".
    property bool escapeClears: true

    property int panelWidth: Config.launcherWidth
    property int listPad: Config.launcherListPad
    // The list scrolls past this: page 06's cap, and the reason a payload stays
    // a glance rather than a wall.
    property int maxListHeight: Config.popMaxH

    // An alias, so a consumer's filter binding re-evaluates on every keystroke.
    readonly property alias query: queryInput.text

    signal accepted
    signal cancelled
    // Shift+Delete. NOT plain Delete: the query field always holds focus, so a
    // bare Delete mid-query would destroy a row while the user meant to edit
    // text. Design page 11 draws "del"; this is one modifier further, and the
    // footer says so.
    signal removed
    signal opened

    function open(): void {
        queryInput.text = "";
        root.selected = 0;
        root.visible = true;
        queryInput.forceActiveFocus();
        root.opened();
    }

    function close(): void {
        root.visible = false;
    }

    // Reports the state actually reached, matching the bar.toggle() contract so
    // a caller can say what happened rather than what was asked.
    function toggle(): string {
        if (root.visible)
            root.close();
        else
            root.open();
        return root.visible ? "shown" : "hidden";
    }

    // 🚨 NOT called escape(): that is an illegal method name in QML and the
    // engine rejects the whole file with "Illegal method name" at LOAD time.
    // The linter does not catch it.
    function clearOrClose(): void {
        if (!root.escapeClears || queryInput.text === "") {
            root.cancelled();
            root.close();
        } else {
            queryInput.text = "";
        }
    }

    function moveSelection(delta: int): void {
        if (list.count === 0)
            return;
        root.selected = Math.max(0, Math.min(root.selected + delta, list.count - 1));
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

    // 🚨 Exclusive, not OnDemand: the surface must receive keys the moment it
    // maps, without a click first. Deliberately NOT masked, unlike the OSD --
    // this window wants the whole surface, so a click anywhere outside the
    // panel dismisses it.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.layer: WlrLayer.Overlay

    MouseArea {
        anchors.fill: parent

        onClicked: {
            root.cancelled();
            root.close();
        }
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        border.color: Theme.edge
        border.width: Config.hairline
        color: Theme.groundBase
        implicitHeight: layout.implicitHeight
        radius: Config.radiusPanel
        width: root.panelWidth
        // A modal, not a dropdown: high enough to read without covering the bar
        // it was summoned from.
        y: parent.height * 0.18

        // Swallows clicks that land on the panel so the dismiss MouseArea
        // underneath does not close it mid-interaction.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: layout

            width: parent.width

            // Header: glyph, query, counter, hairline.
            Item {
                height: Config.launcherInputHeight
                width: parent.width

                Text {
                    id: headerGlyphText

                    anchors.left: parent.left
                    anchors.leftMargin: Config.padTight + 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.headerAccent ? Theme.signalFocus : Theme.inkSecondary
                    font.family: root.headerAccent ? Config.terminalFont : Config.guiFont
                    font.pixelSize: root.headerAccent ? Config.fontBody : Config.glyphRow
                    font.weight: Font.Medium
                    text: root.headerGlyph
                }

                TextInput {
                    id: queryInput

                    anchors.left: headerGlyphText.right
                    anchors.leftMargin: Config.gap + 2
                    anchors.right: counterText.left
                    anchors.rightMargin: Config.gap
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    color: Theme.inkPrimary
                    focus: true
                    font.family: Config.guiFont
                    font.pixelSize: Config.fontTitle
                    selectByMouse: true
                    selectedTextColor: Theme.inkOnSignal
                    selectionColor: Theme.signalFocus

                    // A 2px accent bar, not the platform caret.
                    cursorDelegate: Rectangle {
                        color: Theme.signalFocus
                        width: 2
                    }

                    Keys.onDeletePressed: event => {
                        // Shift only; a bare Delete stays a text edit.
                        if (event.modifiers & Qt.ShiftModifier) {
                            root.removed();
                            event.accepted = true;
                        } else {
                            event.accepted = false;
                        }
                    }
                    Keys.onDownPressed: root.moveSelection(1)
                    Keys.onEnterPressed: root.accepted()
                    Keys.onEscapePressed: root.clearOrClose()
                    Keys.onReturnPressed: root.accepted()
                    Keys.onUpPressed: root.moveSelection(-1)

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.inkSecondary
                        font.family: Config.guiFont
                        font.pixelSize: Config.fontBody
                        text: root.placeholder
                        visible: queryInput.text === ""
                    }
                }

                Text {
                    id: counterText

                    anchors.right: parent.right
                    anchors.rightMargin: Config.padTight + 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.inkSecondary
                    font.family: Config.terminalFont
                    font.pixelSize: Config.fontMeta
                    font.weight: Font.Medium
                    text: root.counter
                    visible: root.counter !== ""
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    color: Theme.edge
                    height: Config.hairline
                    width: parent.width
                }
            }

            // The rows. A ListView rather than the Repeater-in-a-Column this
            // started as: a menu built from a script can be far longer than the
            // launcher's capped result set, and ListView is what scrolls and
            // keeps the cursor on screen without any of it being written here.
            Item {
                height: list.count > 0 ? list.height + root.listPad * 2 : 0
                visible: list.count > 0
                width: parent.width

                ListView {
                    id: list

                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    currentIndex: root.selected
                    height: Math.min(list.contentHeight, root.maxListHeight)
                    model: root.model
                    width: parent.width - root.listPad * 2
                    x: root.listPad
                    y: root.listPad

                    delegate: Rectangle {
                        id: row

                        required property int index
                        required property var modelData
                        readonly property bool current: row.index === root.selected
                        readonly property string iconSource: row.modelData.iconSource ?? ""
                        readonly property string subtitle: row.modelData.subtitle ?? ""

                        // The selected row pairs the 13% tint with an accent
                        // glyph AND a return mark: three carriers, because the
                        // tint alone reaches only 1.10-1.98 on its own ground.
                        color: row.current ? Theme.select : "transparent"
                        // One line is a menu row, two is a launcher row. The
                        // data decides, so neither consumer sets a height.
                        height: row.subtitle === "" ? Config.rowH : Config.launcherRowHeight
                        radius: Config.radiusChip
                        width: ListView.view.width

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                root.selected = row.index;
                                root.accepted();
                            }
                            onEntered: root.selected = row.index
                        }

                        Item {
                            id: iconTile

                            anchors.left: parent.left
                            anchors.leftMargin: Config.padTight - 2
                            anchors.verticalCenter: parent.verticalCenter
                            height: Config.launcherIconSize
                            visible: row.iconSource !== "" || (row.modelData.glyph ?? "") !== ""
                            width: Config.launcherIconSize

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: Config.launcherIconSize
                                source: row.iconSource
                                visible: row.iconSource !== ""
                            }

                            // An entry with no themed icon still renders
                            // something, the same contract the workspace pills'
                            // glyph fallback has.
                            Text {
                                anchors.centerIn: parent
                                color: row.current ? Theme.signalFocus : Theme.inkSecondary
                                font.family: Config.guiFont
                                font.pixelSize: Config.glyphRow
                                text: row.modelData.glyph ?? ""
                                visible: row.iconSource === ""
                            }
                        }

                        Column {
                            anchors.left: iconTile.visible ? iconTile.right : parent.left
                            anchors.leftMargin: Config.padTight
                            anchors.right: enterHint.left
                            anchors.rightMargin: Config.gap
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                color: Theme.inkPrimary
                                // A path elides mid-string: the tail is the
                                // identifying part. Same rule as the bar title.
                                elide: (row.modelData.elideMiddle ?? false) ? Text.ElideMiddle : Text.ElideRight
                                font.family: (row.modelData.mono ?? false) ? Config.terminalFont : Config.guiFont
                                font.pixelSize: Config.fontBody
                                text: row.modelData.title ?? ""
                                width: parent.width
                            }

                            Text {
                                // ink-secondary, NOT a disabled treatment: this
                                // line is information, not an inert control.
                                color: (row.modelData.subtitleError ?? false) ? Theme.signalError : Theme.inkSecondary
                                elide: Text.ElideRight
                                font.family: Config.guiFont
                                font.pixelSize: Config.fontMeta
                                text: row.subtitle
                                visible: row.subtitle !== ""
                                width: parent.width
                            }
                        }

                        Text {
                            id: enterHint

                            anchors.right: parent.right
                            anchors.rightMargin: Config.padTight
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.signalFocus
                            font.family: Config.terminalFont
                            font.pixelSize: Config.fontMeta
                            text: "↵"
                            visible: row.current
                        }
                    }

                    onCurrentIndexChanged: list.positionViewAtIndex(list.currentIndex, ListView.Contain)
                }
            }

            // Anything a consumer needs between the list and the footer: the
            // launcher's prefix row and its zero-match block, the clipboard's
            // empty state. Default property, so a consumer just nests them.
            Column {
                id: extras

                width: parent.width
            }

            // Footer. Permanent, per page 06: the left side names the keys, the
            // right names the escape hatch.
            Item {
                height: Config.launcherFooterHeight
                visible: root.footerLeft !== "" || root.footerRight !== ""
                width: parent.width

                Rectangle {
                    anchors.top: parent.top
                    color: Theme.edge
                    height: Config.hairline
                    width: parent.width
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Config.padTight + 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.inkSecondary
                    font.family: Config.terminalFont
                    font.pixelSize: Config.fontMeta
                    text: root.footerLeft
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Config.padTight + 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.inkSecondary
                    font.family: Config.terminalFont
                    font.pixelSize: Config.fontMeta
                    text: root.footerRight
                }
            }
        }
    }

    // Declared last so it is the default property target: everything a consumer
    // nests inside a PickerSurface lands in the extras column above.
    default property alias content: extras.data
}
