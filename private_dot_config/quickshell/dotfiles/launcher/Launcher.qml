pragma ComponentBehavior: Bound

import "../"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

// Application launcher (Phase 5, artboard 1d). Replaces Wofi as THE APP
// LAUNCHER and nothing more: Wofi still serves cliphist and every --dmenu
// caller, so it is not going anywhere.
//
// One window on the focused monitor, like the OSD — a launcher is a modal you
// summoned, so it belongs where you are looking rather than on all screens.
//
// The panel grows downward from the input row: an empty query renders the bar
// alone, which is what makes SUPER feel like a prompt instead of a menu.
PanelWindow {
    id: root

    readonly property list<var> results: query.text.trim() ? root.rank(query.text) : root.quickAccessCache
    property int selected: 0
    property var quickAccessCache: []

    // Empty-query quick access, artboard launch-b. Reuses Wofi's own usage
    // cache (~/.cache/wofi-drun, "<count> <desktop file path>" per line)
    // rather than building a second usage tracker — Wofi stays installed
    // (cliphist, --dmenu callers) and keeps writing it, so the data is real.
    // ponytail: read-only — a launch from here does not increment the cache,
    // so it drifts stale if Wofi itself stops being used. Fine until proven
    // otherwise; a write-back needs the entry's full desktop-file path, which
    // DesktopEntries does not expose, only its id.
    function parseQuickAccess(text: string): list<var> {
        const byId = {};
        for (const entry of DesktopEntries.applications.values)
            if (entry && !entry.noDisplay && entry.name)
                byId[entry.id] = entry;
        const counted = [];
        for (const line of text.split("\n")) {
            const m = /^(\d+)\s+(.+)$/.exec(line.trim());
            if (!m)
                continue;
            const entry = byId[m[2].split("/").pop().replace(/\.desktop$/, "")];
            if (entry)
                counted.push({
                    entry,
                    count: parseInt(m[1], 10)
                });
        }
        counted.sort((a, b) => b.count - a.count);
        return counted.slice(0, Config.launcherMaxResults).map(c => c.entry);
    }

    // Ranking, compressed from Omarchy's services/AppSearch.js: a prefix beats
    // a substring beats a keyword/comment hit beats an acronym. Their version
    // carries per-term matching and a hidden-entry callback we have no use for.
    function rank(q: string): list<var> {
        const needle = q.trim().toLowerCase();
        const apps = DesktopEntries.applications.values.filter(e => e && !e.noDisplay && e.name);
        if (!needle)
            return [];
        const scored = [];
        for (const entry of apps) {
            const score = root.score(entry, needle);
            if (score >= 0)
                scored.push({
                    entry,
                    score
                });
        }
        scored.sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name));
        return scored.slice(0, Config.launcherMaxResults).map(s => s.entry);
    }

    // -1 means "no match". Otherwise higher is better, and a shorter name wins
    // a tie so `Files` outranks `Files (Recent)` on the same prefix.
    function score(entry: var, needle: string): int {
        const name = (entry.name ?? "").toLowerCase();
        const id = (entry.id ?? "").toLowerCase();
        const haystack = [entry.name, entry.genericName, entry.comment, (entry.keywords ?? []).join(" "), entry.id].join(" ").toLowerCase();
        if (name.startsWith(needle))
            return 10000 - name.length;
        if (id.startsWith(needle))
            return 9500 - id.length;
        const inName = name.indexOf(needle);
        if (inName > 0)
            return 8000 - inName * 10 - name.length;
        const inHay = haystack.indexOf(needle);
        if (inHay >= 0)
            return 6000 - inHay;
        // Initials: "vsc" finds "Visual Studio Code".
        const acronym = name.split(/[^a-z0-9]+/i).filter(w => w).map(w => w[0].toLowerCase()).join("");
        return acronym.startsWith(needle) ? 5000 - acronym.length : -1;
    }

    function close(): void {
        root.visible = false;
    }

    function open(): void {
        query.text = "";
        root.selected = 0;
        root.visible = true;
        query.forceActiveFocus();
        usageFile.reload();
    }

    // Returns the state actually reached, matching the bar.toggle() contract so
    // the toggle script can report what happened rather than what was asked.
    function toggle(): string {
        if (root.visible)
            root.close();
        else
            root.open();
        return root.visible ? "shown" : "hidden";
    }

    function launch(): void {
        const entry = root.results[root.selected];
        root.close();
        if (entry)
            entry.execute();
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

    // 🚨 Exclusive, not OnDemand: the launcher must receive keys the moment it
    // maps, without a click first. Deliberately NOT masked, unlike the OSD —
    // this window wants the whole surface, so a click anywhere outside the
    // panel dismisses it.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.layer: WlrLayer.Overlay

    onResultsChanged: root.selected = 0

    FileView {
        id: usageFile

        path: `${Quickshell.env("HOME")}/.cache/wofi-drun`
        printErrors: false

        onLoadFailed: root.quickAccessCache = []
        onLoaded: root.quickAccessCache = root.parseQuickAccess(usageFile.text())
    }

    MouseArea {
        anchors.fill: parent

        onClicked: root.close()
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        border.color: Theme.bgTertiary
        border.width: Config.hairline
        color: Theme.bgPrimary
        // The panel is a modal, not a dropdown: high enough to read without
        // covering the bar it was summoned from.
        y: parent.height * 0.18
        implicitHeight: layout.implicitHeight
        radius: Config.radiusPanel
        width: Config.launcherWidth

        // Swallows clicks that land on the panel so the dismiss MouseArea
        // underneath does not close it mid-interaction.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: layout

            width: parent.width

            // Input row.
            Item {
                height: Config.launcherInputHeight
                width: parent.width

                Text {
                    id: searchGlyph

                    anchors.left: parent.left
                    anchors.leftMargin: Config.pad + 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.accentPrimary
                    font.family: Config.guiFont
                    font.pixelSize: Config.fontSizeLarge
                    text: "󰍉"
                }

                TextInput {
                    id: query

                    anchors.left: searchGlyph.right
                    anchors.leftMargin: Config.padTight
                    anchors.right: modeBadge.left
                    anchors.rightMargin: Config.gap
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fgPrimary
                    focus: true
                    font.family: Config.guiFont
                    font.pixelSize: Config.fontSizeInput
                    selectByMouse: true
                    selectedTextColor: Theme.fgContrast
                    selectionColor: Theme.accentPrimary

                    // The canvas draws a 2px accent bar, not the platform caret.
                    cursorDelegate: Rectangle {
                        color: Theme.accentPrimary
                        width: 2
                    }

                    Keys.onDownPressed: root.selected = Math.min(root.selected + 1, root.results.length - 1)
                    Keys.onEnterPressed: root.launch()
                    Keys.onEscapePressed: root.close()
                    Keys.onReturnPressed: root.launch()
                    Keys.onUpPressed: root.selected = Math.max(root.selected - 1, 0)
                }

                // Structure from the artboard, and honest about scope: apps is
                // the only mode built. The canvas's >, =, :, / and ? prefixes
                // are not implemented, so nothing here switches.
                Rectangle {
                    id: modeBadge

                    anchors.right: parent.right
                    anchors.rightMargin: Config.pad
                    anchors.verticalCenter: parent.verticalCenter
                    border.color: Theme.bgTertiary
                    border.width: Config.hairline
                    color: "transparent"
                    height: mode.implicitHeight + Config.gap
                    radius: Config.radiusTooltip
                    width: mode.implicitWidth + 14

                    Text {
                        id: mode

                        anchors.centerIn: parent
                        color: Theme.fgMuted
                        font.family: Config.terminalFont
                        font.pixelSize: Config.fontSizeTiny
                        text: "apps"
                    }
                }

                // Quick access, artboard launch-b: same row, same treatment as
                // the mode badge, so the state is a content change rather than
                // a second component. Only shows once there is history to name.
                Text {
                    anchors.right: modeBadge.left
                    anchors.rightMargin: Config.gap
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fgMuted
                    font.family: Config.terminalFont
                    font.letterSpacing: 1
                    font.pixelSize: Config.fontSizeTiny
                    text: "QUICK ACCESS"
                    visible: !query.text.trim() && root.quickAccessCache.length > 0
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    color: Theme.bgTertiary
                    height: Config.hairline
                    visible: root.results.length > 0
                    width: parent.width
                }
            }

            // Results. Absent entirely on an empty query, which is the point.
            Column {
                padding: Config.launcherListPad
                spacing: 0
                visible: root.results.length > 0
                width: parent.width

                Repeater {
                    model: root.results

                    delegate: Rectangle {
                        id: row

                        required property int index
                        required property var modelData
                        readonly property bool current: row.index === root.selected
                        readonly property string iconSource: Quickshell.iconPath(row.modelData.icon, true)

                        // The selected row is the only one with a ground.
                        color: row.current ? Qt.alpha(Theme.accentPrimary, 0.13) : "transparent"
                        height: Config.launcherRowHeight
                        radius: Config.radiusTile
                        width: Config.launcherWidth - Config.launcherListPad * 2

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                root.selected = row.index;
                                root.launch();
                            }
                            onEntered: root.selected = row.index
                        }

                        Rectangle {
                            id: iconTile

                            anchors.left: parent.left
                            anchors.leftMargin: Config.padTight
                            anchors.verticalCenter: parent.verticalCenter
                            color: row.current ? Qt.alpha(Theme.accentPrimary, 0.15) : Theme.bgTertiary
                            height: Config.launcherIconSize
                            radius: Config.radiusChip
                            width: Config.launcherIconSize

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: Config.iconSize
                                source: row.iconSource
                                visible: row.iconSource !== ""
                            }

                            // An app with no themed icon still renders
                            // something, the same contract the workspace pills'
                            // glyph fallback has.
                            Text {
                                anchors.centerIn: parent
                                // fg-primary, not fg-secondary: this tile is
                                // bg-tertiary, an elevated surface.
                                color: row.current ? Theme.accentPrimary : Theme.fgPrimary
                                font.family: Config.guiFont
                                font.pixelSize: Config.fontSizeSmall
                                text: Config.windowGlyphFallback
                                visible: row.iconSource === ""
                            }
                        }

                        Column {
                            anchors.left: iconTile.right
                            anchors.leftMargin: Config.padTight
                            anchors.right: enterHint.left
                            anchors.rightMargin: Config.gap
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                color: Theme.fgPrimary
                                elide: Text.ElideRight
                                font.family: Config.guiFont
                                font.pixelSize: Config.fontSize
                                text: row.modelData.name
                                width: parent.width
                            }

                            Text {
                                color: Theme.fgMuted
                                elide: Text.ElideRight
                                font.family: Config.terminalFont
                                font.pixelSize: Config.fontSizeTiny
                                text: row.modelData.execString ?? ""
                                width: parent.width
                            }
                        }

                        Text {
                            id: enterHint

                            anchors.right: parent.right
                            anchors.rightMargin: Config.padTight
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.accentPrimary
                            font.family: Config.guiFont
                            font.pixelSize: Config.fontSizeSmall
                            text: "󰌑"
                            visible: row.current
                        }
                    }
                }
            }

            // Footer.
            Item {
                height: Config.launcherFooterHeight
                visible: root.results.length > 0
                width: parent.width

                Rectangle {
                    anchors.top: parent.top
                    color: Theme.bgTertiary
                    height: Config.hairline
                    width: parent.width
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Config.padTight + 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fgMuted
                    font.family: Config.terminalFont
                    font.pixelSize: Config.fontSizeTiny
                    text: "\u2191\u2193 navigate   \u21b5 launch   esc close"
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Config.padTight + 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fgMuted
                    font.family: Config.terminalFont
                    font.pixelSize: Config.fontSizeTiny
                    text: query.text.trim() ? `${root.results.length} result${root.results.length === 1 ? "" : "s"}` : `${root.results.length} app${root.results.length === 1 ? "" : "s"}`
                }
            }
        }
    }
}
