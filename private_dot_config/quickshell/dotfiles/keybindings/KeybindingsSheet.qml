pragma ComponentBehavior: Bound

import "../"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Keybindings reference, surface §9 — the one summoned surface that is NOT a
// chooser. It shipped as a picker whose answer was thrown away, which made
// every row look actionable and none of them was.
//
// 🚨 The data still comes from `desktop/keybindings --json`, not from parsing
// the config tree: hyprctl is the only source that knows what is actually
// bound right now, and the script already owns the four translators. What moved
// here is the drawing, which is the part a fixed-width picker could not do.
//
// 🚨 The filter DIMS, it does not remove. A document whose rows move as you
// type is a list again: the value of a sheet is that a chord stays where it
// was the last time you looked.
PanelWindow {
    id: root

    property list<var> rows: []
    property string query: ""

    readonly property list<string> categories: {
        const seen = [];
        for (const row of root.rows)
            if (!seen.includes(row.category))
                seen.push(row.category);
        return seen;
    }
    // Split so both columns end at about the same height, counting section
    // headers as a row of their own. A parity split puts Workspaces' 31 rows
    // beside Input's 2 and leaves half the panel empty; so does stopping at the
    // FIRST boundary past the midpoint, which lands 73/51 on this machine. Take
    // the boundary with the smallest imbalance instead -- one pass, nine
    // categories, and it is the difference between a balanced page and one
    // column running off the bottom on its own.
    readonly property int splitAt: {
        const total = root.rows.length + root.categories.length;
        let seen = 0;
        let best = 0;
        let bestGap = total;
        for (let i = 0; i < root.categories.length; i++) {
            seen += 1 + root.rows.filter(r => r.category === root.categories[i]).length;
            const gap = Math.abs(total - 2 * seen);
            if (gap < bestGap) {
                bestGap = gap;
                best = i + 1;
            }
        }
        return best;
    }

    function matches(row: var): bool {
        if (root.query === "")
            return true;
        const q = root.query.toLowerCase();
        return row.keys.toLowerCase().includes(q) || row.description.toLowerCase().includes(q);
    }

    function scroll(delta: real): void {
        body.contentY = Math.max(0, Math.min(body.contentHeight - body.height, body.contentY + delta));
    }

    function close(): void {
        root.visible = false;
        root.query = "";
    }

    function open(): void {
        root.query = "";
        root.visible = true;
        // Re-read on every open anyway: a binding added since the last one is
        // exactly what someone opens this to check.
        loader.running = true;
        Qt.callLater(root.claimFocus);
    }

    // 🚨 Deferred. A focus claim from a child's Component.onCompleted is
    // silently dropped, because the content item is reparented into the real
    // window only when the SURFACE completes — after every child of it.
    function claimFocus(): void {
        filter.forceActiveFocus();
    }

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

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.layer: WlrLayer.Overlay

    Process {
        id: loader

        command: [`${Config.scriptsDir}/desktop/keybindings`, "--json"]
        // Once at startup as well as on every open: the panel sizes itself to
        // its content, so opening with an empty model draws a small empty card
        // that then grows. A list from a second ago is a better first frame.
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.rows = JSON.parse(this.text);
                } catch (e) {
                    root.rows = [];
                }
            }
        }
    }

    // Theme.scrim is a shade, never a background token: groundBase measures
    // 0.71-0.96 luminance in all four light colorsets, so a wash built from it
    // renders near-white.
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.scrim, Config.scrimOpacity)

        MouseArea {
            anchors.fill: parent

            onClicked: root.close()
        }
    }

    Rectangle {
        id: panel

        anchors.centerIn: parent
        border.color: Theme.edge
        border.width: Config.hairline
        color: Theme.groundBase
        height: Math.min(header.height + body.contentHeight + footer.height + Config.padLoose * 3, root.height * Config.sheetMaxHeightFraction)
        radius: Config.radiusPanel
        width: Math.min(Config.sheetWidth, root.width - Config.padLoose * 2)

        // Swallows the scrim's dismiss click; the panel itself is not a button.
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: header

            anchors.left: parent.left
            anchors.leftMargin: Config.pad
            anchors.right: parent.right
            anchors.rightMargin: Config.pad
            anchors.top: parent.top
            anchors.topMargin: Config.pad
            height: Config.rowH

            Text {
                id: title

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.inkPrimary
                font.family: Config.guiFont
                font.pixelSize: Config.fontTitle
                font.weight: Font.Medium
                text: qsTr("Keybindings")
            }

            // The filter is a field rather than a mode: it always has focus, so
            // typing narrows and there is no key to learn first.
            TextInput {
                id: filter

                anchors.left: title.right
                anchors.leftMargin: Config.padLoose
                anchors.right: counter.left
                anchors.rightMargin: Config.pad
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                color: Theme.inkPrimary
                font.family: Config.terminalFont
                font.pixelSize: Config.fontBody
                selectByMouse: true
                selectedTextColor: Theme.inkOnAction
                selectionColor: Theme.action

                // The field is single-line, so Up/Down and the page keys do
                // nothing in it -- and they are what a document is scrolled
                // with. Without this the sheet is wheel-only, which is a
                // strange thing to require of a surface opened from a chord.
                Keys.onDownPressed: root.scroll(Config.rowH * 3)
                Keys.onEscapePressed: root.close()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_PageDown)
                        root.scroll(body.height * 0.9);
                    else if (event.key === Qt.Key_PageUp)
                        root.scroll(-body.height * 0.9);
                    else
                        return;
                    event.accepted = true;
                }
                Keys.onUpPressed: root.scroll(-Config.rowH * 3)

                onTextChanged: root.query = filter.text

                Text {
                    anchors.fill: parent
                    color: Theme.inkSecondary
                    font: filter.font
                    text: qsTr("filter")
                    verticalAlignment: Text.AlignVCenter
                    visible: filter.text === ""
                }
            }

            Text {
                id: counter

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.inkSecondary
                font.family: Config.terminalFont
                font.pixelSize: Config.fontMeta
                text: `${root.rows.filter(r => root.matches(r)).length}/${root.rows.length}`
            }
        }

        Rectangle {
            id: rule

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.topMargin: Config.gap
            color: Theme.edge
            height: Config.hairline
        }

        Text {
            id: footer

            anchors.bottom: parent.bottom
            anchors.bottomMargin: Config.pad
            anchors.left: parent.left
            anchors.leftMargin: Config.pad
            color: Theme.inkSecondary
            font.family: Config.terminalFont
            font.pixelSize: Config.fontMeta
            text: qsTr("type to filter · esc close")
        }

        Flickable {
            id: body

            anchors.bottom: footer.top
            anchors.bottomMargin: Config.gap
            anchors.left: parent.left
            anchors.leftMargin: Config.pad
            anchors.right: parent.right
            anchors.rightMargin: Config.pad
            anchors.top: rule.bottom
            anchors.topMargin: Config.pad
            clip: true
            contentHeight: columns.height
            contentWidth: width

            Row {
                id: columns

                spacing: Config.padLoose
                width: parent.width

                Repeater {
                    model: 2

                    Column {
                        id: column

                        required property int index

                        spacing: Config.padTight
                        width: (columns.width - Config.padLoose) / 2

                        Repeater {
                            model: column.index === 0 ? root.categories.slice(0, root.splitAt) : root.categories.slice(root.splitAt)

                            Column {
                                id: section

                                required property string modelData

                                readonly property list<var> sectionRows: root.rows.filter(r => r.category === section.modelData)

                                spacing: 2
                                width: parent.width

                                Text {
                                    bottomPadding: 2
                                    color: Theme.inkSecondary
                                    font.capitalization: Font.AllUppercase
                                    font.family: Config.terminalFont
                                    font.letterSpacing: 1
                                    font.pixelSize: Config.fontMeta
                                    text: section.modelData
                                    textFormat: Text.PlainText
                                }

                                Repeater {
                                    model: section.sectionRows

                                    Item {
                                        id: entry

                                        required property var modelData

                                        height: Config.fontBody + Config.gap
                                        // Dimmed, never removed: a chord keeps
                                        // its place on the page.
                                        opacity: root.matches(entry.modelData) ? 1 : 1 - Theme.disabledOpacity
                                        width: parent.width

                                        Text {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: Theme.inkPrimary
                                            elide: Text.ElideRight
                                            font.family: Config.terminalFont
                                            font.pixelSize: Config.fontMeta
                                            text: entry.modelData.keys
                                            // Foreign: the chord comes out of
                                            // hyprctl, not out of this tree.
                                            textFormat: Text.PlainText
                                            width: Config.sheetKeysWidth
                                        }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: Config.sheetKeysWidth + Config.gap
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: Theme.inkPrimary
                                            elide: Text.ElideRight
                                            font.family: Config.guiFont
                                            font.pixelSize: Config.fontBody
                                            text: entry.modelData.description
                                            textFormat: Text.PlainText
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
