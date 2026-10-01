pragma ComponentBehavior: Bound

import "../"
import Quickshell
import Quickshell.Io
import QtQuick

// Application launcher, design page Shell-05-Launcher. Replaces Wofi as THE APP
// LAUNCHER; the dmenu callers move to MenuPicker and the clipboard to
// ClipboardPicker, so Wofi survives only as those two surfaces' fallback.
//
// The chrome -- window, panel, header, list, footer, keyboard model -- is
// PickerSurface, shared with the clipboard and the menu. What is left here is
// what makes this surface a LAUNCHER: ranking, the two prefix modes, and the
// desktop-entry row.
PickerSurface {
    id: root

    // 🚨 A prefix takes effect on the FIRST keystroke, and Backspace out of it
    // returns to application search. Two modes, not the five an older mockup
    // drew: `:` runs a command in a terminal, `=` evaluates an expression.
    readonly property string prefix: root.query.startsWith(":") ? ":" : root.query.startsWith("=") ? "=" : ""
    readonly property string term: root.prefix ? root.query.slice(1).trim() : root.query.trim()
    readonly property bool appsMode: root.prefix === ""

    readonly property list<var> results: root.appsMode ? (root.term ? root.rank(root.term) : root.quickAccessCache) : []
    // The picker draws rows, not desktop entries. Remapped rather than
    // special-cased inside a shared delegate: the launcher is the only one of
    // the three surfaces with a themed icon and a spawn failure to report.
    readonly property list<var> rows: root.results.map((entry, i) => ({
                title: entry.name,
                subtitle: i === root.selected && root.launchError !== "" ? root.launchError : (entry.genericName || entry.comment || entry.execString || " "),
                subtitleError: i === root.selected && root.launchError !== "",
                iconSource: Quickshell.iconPath(entry.icon, true),
                glyph: Config.windowGlyphFallback
            }))
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
    // second usage tracker — Wofi stays installed as the picker fallback and
    // keeps writing that file whenever it runs, so the data is real.
    // ponytail: read-only — a launch from here does not increment the cache, so
    // it drifts stale as Wofi is used less. That is also why the footer's prefix
    // hint is permanent rather than fading after a few uses: it costs one line
    // and never claims knowledge the shell does not have.
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

    // Return does nothing where there is nothing to act on: a control that
    // would do nothing is removed, not left to fail silently.
    function activate(): void {
        if (root.prefix === ":") {
            if (!root.term)
                return;
            Quickshell.execDetached(Config.detach.concat([Config.terminal, "-e", "sh", "-c", root.term]));
            root.close();
            return;
        }
        if (root.prefix === "=") {
            // Copies, launches nothing — an expression has no process.
            if (root.calcResult)
                Quickshell.execDetached(Config.detach.concat(["wl-copy", "--", root.calcResult]));
            root.close();
            return;
        }
        const entry = root.results[root.selected];
        if (!entry)
            return;
        try {
            Quickshell.execDetached({
                command: Config.detach.concat(entry.command),
                workingDirectory: entry.workingDirectory
            });
        } catch (e) {
            root.launchError = String(e.message ?? e);
            return;
        }
        root.close();
    }

    counter: root.appsMode && root.results.length > 0 ? String(root.results.length) : ""
    footerLeft: "↑↓ move · ↵ launch · esc clear"
    footerRight: ": run · = calc"
    // The prefix stays visible in accent at the field's left edge, so the mode
    // is legible without reading the query.
    headerAccent: !root.appsMode
    headerGlyph: root.appsMode ? Config.searchGlyph : root.prefix
    model: root.appsMode ? root.rows : []
    placeholder: qsTr("Search applications")

    onAccepted: root.activate()
    onOpened: {
        root.launchError = "";
        usageFile.reload();
    }
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

    // The single row a prefix mode produces. Not folded into `results`: that
    // list is desktop entries, and a synthetic member of it would have to be
    // special-cased at every read.
    Item {
        height: Config.launcherRowHeight + Config.launcherListPad * 2
        visible: !root.appsMode && root.term !== ""
        width: parent.width

        Rectangle {
            anchors.centerIn: parent
            color: Theme.select
            height: Config.launcherRowHeight
            radius: Config.radiusChip
            width: parent.width - Config.launcherListPad * 2

            Text {
                id: prefixGlyph

                anchors.left: parent.left
                anchors.leftMargin: Config.padTight
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.signalFocus
                font.family: Config.guiFont
                font.pixelSize: Config.glyphRow
                text: root.prefix === ":" ? Config.terminalGlyph : Config.calcGlyph
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

    // Zero matches. Two lines, never one: the fact, then the exit. The block
    // keeps the height of a row so the surface does not jump as the query
    // narrows.
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
}
