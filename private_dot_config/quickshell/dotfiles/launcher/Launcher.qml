pragma ComponentBehavior: Bound

import "../"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

// Application launcher, design page Shell-05-Launcher. Replaces Wofi as THE APP
// LAUNCHER and nothing more: Wofi still serves cliphist and every --dmenu
// caller, so it is not going anywhere.
//
// A text field first, a list second — which is why it is the only surface in
// the shell that takes an EXCLUSIVE keyboard grab, and the only one where Esc
// has two meanings.
//
// One window on the focused monitor, like the OSD: a launcher is a modal you
// summoned, so it belongs where you are looking rather than on all screens.
PanelWindow {
    id: root

    // 🚨 A prefix takes effect on the FIRST keystroke, and Backspace out of it
    // returns to application search. Two modes, not the five an older mockup
    // drew: `:` runs a command in a terminal, `=` evaluates an expression.
    readonly property string prefix: query.text.startsWith(":") ? ":" : query.text.startsWith("=") ? "=" : ""
    readonly property string term: root.prefix ? query.text.slice(1).trim() : query.text.trim()
    readonly property bool appsMode: root.prefix === ""

    readonly property list<var> results: root.appsMode ? (root.term ? root.rank(root.term) : root.quickAccessCache) : []
    property int selected: 0
    property var quickAccessCache: []
    // The evaluated value of an `=` expression, or "" while there is none.
    property string calcResult: ""
    // 🚨 The only failure this surface can actually observe. DesktopEntry
    // .execute() reports nothing on success and gives no completion signal, so
    // the design's "Starting…" state would be a fixed delay pretending to be
    // feedback — theatre, not information. A spawn that THROWS is real, and it
    // is the case the design cares about: the row keeps the failure text and
    // the launcher refuses to close, the one place Return does not dismiss it.
    property string launchError: ""

    // Empty-query quick access. Reuses Wofi's own usage cache (~/.cache/
    // wofi-drun, "<count> <desktop file path>" per line) rather than building a
    // second usage tracker — Wofi stays installed (cliphist, --dmenu callers)
    // and keeps writing it, so the data is real.
    // ponytail: read-only — a launch from here does not increment the cache, so
    // it drifts stale if Wofi itself stops being used. That is also why the
    // footer's prefix hint is permanent rather than fading after a few uses: it
    // costs one line and never claims knowledge the shell does not have.
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

    // 🚨 Esc CLEARS the query; a second Esc closes. The one surface where Esc
    // is not a single-step close, because losing a half-typed query to a stray
    // keypress is worse than one extra keystroke.
    //
    // 🚨 NOT called escape(): that is an illegal method name in QML and the
    // engine rejects the whole file with "Illegal method name" at LOAD time.
    // The linter does not catch it — `mise run lint:qml` passed on it.
    function clearOrClose(): void {
        if (query.text === "")
            root.close();
        else
            query.text = "";
    }

    function open(): void {
        query.text = "";
        root.selected = 0;
        root.launchError = "";
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

    // Return does nothing where there is nothing to act on: a control that
    // would do nothing is removed, not left to fail silently.
    function activate(): void {
        if (root.prefix === ":") {
            if (!root.term)
                return;
            Quickshell.execDetached([Config.terminal, "-e", "sh", "-c", root.term]);
            root.close();
            return;
        }
        if (root.prefix === "=") {
            // Copies, launches nothing — an expression has no process.
            if (root.calcResult)
                Quickshell.execDetached(["wl-copy", "--", root.calcResult]);
            root.close();
            return;
        }
        const entry = root.results[root.selected];
        if (!entry)
            return;
        try {
            entry.execute();
        } catch (e) {
            root.launchError = String(e.message ?? e);
            return;
        }
        root.close();
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

    onResultsChanged: {
        root.selected = 0;
        root.launchError = "";
    }

    FileView {
        id: usageFile

        path: `${Quickshell.env("HOME")}/.cache/wofi-drun`
        printErrors: false

        onLoadFailed: root.quickAccessCache = []
        onLoaded: root.quickAccessCache = root.parseQuickAccess(usageFile.text())
    }

    // qalc ships in libqalculate. If it is not installed the process fails, the
    // result stays empty and the `=` row simply reports nothing — the same
    // degradation rule the rest of the shell follows, rather than a mode that
    // pretends to work.
    Process {
        id: calc

        stdout: StdioCollector {
            onStreamFinished: root.calcResult = this.text.trim()
        }
    }

    // Debounced: qalc is a process, and spawning one per keystroke would fork
    // on every character of a long expression.
    Timer {
        interval: 150
        running: root.prefix === "=" && root.term !== ""

        onTriggered: {
            // Cleared before each run rather than in an exit handler: a qalc
            // that is not installed never writes to stdout at all, so a stale
            // result would otherwise sit under a new expression.
            root.calcResult = "";
            calc.running = false;
            calc.command = ["qalc", "-t", "--", root.term];
            calc.running = true;
        }
    }

    MouseArea {
        anchors.fill: parent

        onClicked: root.close()
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        border.color: Theme.edge
        border.width: Config.hairline
        color: Theme.groundBase
        implicitHeight: layout.implicitHeight
        radius: Config.radiusPanel
        width: Config.launcherWidth
        // The panel is a modal, not a dropdown: high enough to read without
        // covering the bar it was summoned from.
        y: parent.height * 0.18

        // Swallows clicks that land on the panel so the dismiss MouseArea
        // underneath does not close it mid-interaction.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: layout

            width: parent.width

            // Header: glyph or prefix mark, query, match count.
            Item {
                height: Config.launcherInputHeight
                width: parent.width

                Text {
                    id: searchGlyph

                    anchors.left: parent.left
                    anchors.leftMargin: Config.padTight + 2
                    anchors.verticalCenter: parent.verticalCenter
                    // The prefix stays visible in accent at the field's left
                    // edge, so the mode is legible without reading the query.
                    color: root.appsMode ? Theme.inkSecondary : Theme.signalFocus
                    font.family: root.appsMode ? Config.guiFont : Config.terminalFont
                    font.pixelSize: root.appsMode ? Config.glyphRow : Config.fontBody
                    font.weight: Font.Medium
                    text: root.appsMode ? "󰍉" : root.prefix
                }

                TextInput {
                    id: query

                    anchors.left: searchGlyph.right
                    anchors.leftMargin: Config.gap + 2
                    anchors.right: matchCount.left
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

                    Keys.onDownPressed: root.selected = Math.min(root.selected + 1, root.results.length - 1)
                    Keys.onEnterPressed: root.activate()
                    Keys.onEscapePressed: root.clearOrClose()
                    Keys.onReturnPressed: root.activate()
                    Keys.onUpPressed: root.selected = Math.max(root.selected - 1, 0)

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.inkSecondary
                        font.family: Config.guiFont
                        font.pixelSize: Config.fontBody
                        text: qsTr("Search applications")
                        visible: query.text === ""
                    }
                }

                Text {
                    id: matchCount

                    anchors.right: parent.right
                    anchors.rightMargin: Config.padTight + 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.inkSecondary
                    font.family: Config.terminalFont
                    font.pixelSize: Config.fontMeta
                    font.weight: Font.Medium
                    text: root.appsMode ? root.results.length : ""
                    visible: root.appsMode && root.results.length > 0
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    color: Theme.edge
                    height: Config.hairline
                    width: parent.width
                }
            }

            // Application results.
            Column {
                padding: Config.launcherListPad
                spacing: 0
                visible: root.appsMode && root.results.length > 0
                width: parent.width

                Repeater {
                    model: root.appsMode ? root.results : []

                    delegate: Rectangle {
                        id: row

                        required property int index
                        required property var modelData
                        readonly property bool current: row.index === root.selected
                        readonly property string iconSource: Quickshell.iconPath(row.modelData.icon, true)

                        // The selected row pairs the 13% tint with an accent
                        // glyph AND a return mark: three carriers, because the
                        // tint alone reaches only 1.10-1.98 on its own ground.
                        color: row.current ? Theme.select : "transparent"
                        height: Config.launcherRowHeight
                        // Siblings of a row with an operation in flight go
                        // inert; disabled is opacity, never a token swap.
                        opacity: root.launchError !== "" && !row.current ? Theme.disabledOpacity : 1
                        radius: Config.radiusChip
                        width: Config.launcherWidth - Config.launcherListPad * 2

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                root.selected = row.index;
                                root.activate();
                            }
                            onEntered: root.selected = row.index
                        }

                        Item {
                            id: iconTile

                            anchors.left: parent.left
                            anchors.leftMargin: Config.padTight - 2
                            anchors.verticalCenter: parent.verticalCenter
                            height: Config.launcherIconSize
                            width: Config.launcherIconSize

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: Config.launcherIconSize
                                source: row.iconSource
                                visible: row.iconSource !== ""
                            }

                            // An app with no themed icon still renders
                            // something, the same contract the workspace pills'
                            // glyph fallback has.
                            Text {
                                anchors.centerIn: parent
                                color: row.current ? Theme.signalFocus : Theme.inkSecondary
                                font.family: Config.guiFont
                                font.pixelSize: Config.glyphRow
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
                            spacing: 3

                            Text {
                                color: Theme.inkPrimary
                                elide: Text.ElideRight
                                font.family: Config.guiFont
                                font.pixelSize: Config.fontBody
                                text: row.modelData.name
                                width: parent.width
                            }

                            Text {
                                // ink-secondary, NOT a disabled treatment: this
                                // line is information, not an inert control.
                                color: row.current && root.launchError !== "" ? Theme.signalError : Theme.inkSecondary
                                elide: Text.ElideRight
                                font.family: Config.guiFont
                                font.pixelSize: Config.fontMeta
                                text: row.current && root.launchError !== "" ? root.launchError : (row.modelData.genericName || row.modelData.comment || row.modelData.execString || "")
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
                }
            }

            // The single row a prefix mode produces. Not folded into `results`:
            // that list is desktop entries, and a synthetic member of it would
            // have to be special-cased at every read.
            Item {
                height: Config.launcherRowHeight + Config.launcherListPad * 2
                visible: !root.appsMode && root.term !== ""
                width: parent.width

                Rectangle {
                    anchors.centerIn: parent
                    color: Theme.select
                    height: Config.launcherRowHeight
                    radius: Config.radiusChip
                    width: Config.launcherWidth - Config.launcherListPad * 2

                    Text {
                        id: prefixGlyph

                        anchors.left: parent.left
                        anchors.leftMargin: Config.padTight
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.signalFocus
                        font.family: Config.guiFont
                        font.pixelSize: Config.glyphRow
                        text: root.prefix === ":" ? "󰆍" : "󰃬"
                    }

                    Column {
                        anchors.left: prefixGlyph.right
                        anchors.leftMargin: Config.padTight
                        anchors.right: parent.right
                        anchors.rightMargin: Config.padTight
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            color: Theme.inkPrimary
                            elide: Text.ElideRight
                            font.family: Config.guiFont
                            font.pixelSize: Config.fontBody
                            text: root.prefix === ":" ? qsTr("Run in terminal") : (root.calcResult || qsTr("Evaluating…"))
                            width: parent.width
                        }

                        Text {
                            color: Theme.inkSecondary
                            elide: Text.ElideRight
                            font.family: Config.terminalFont
                            font.pixelSize: Config.fontMeta
                            text: root.term
                            width: parent.width
                        }
                    }
                }
            }

            // Zero matches. Two lines, never one: the fact, then the exit. The
            // block keeps the height of a row so the surface does not jump as
            // the query narrows.
            Column {
                height: Config.launcherRowHeight + Config.launcherListPad * 2
                spacing: 5
                visible: root.appsMode && root.term !== "" && root.results.length === 0
                width: parent.width

                Item {
                    height: Config.launcherListPad
                    width: 1
                }

                Text {
                    color: Theme.inkPrimary
                    elide: Text.ElideRight
                    font.family: Config.guiFont
                    font.pixelSize: Config.fontBody
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("No applications match “%1”").arg(root.term)
                    width: parent.width
                }

                Text {
                    color: Theme.inkSecondary
                    font.family: Config.guiFont
                    font.pixelSize: Config.fontMeta
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Press : to run it as a command")
                    width: parent.width
                }
            }

            // Footer. Permanent, unlike the results above it: the prefix hint
            // is the only place the two non-app modes are named.
            Item {
                height: Config.launcherFooterHeight
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
                    text: "↑↓ move · ↵ launch · esc clear"
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Config.padTight + 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.inkSecondary
                    font.family: Config.terminalFont
                    font.pixelSize: Config.fontMeta
                    text: ": run · = calc"
                }
            }
        }
    }
}
