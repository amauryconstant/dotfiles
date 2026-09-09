pragma ComponentBehavior: Bound

import "../"
import "../launcher"
import Quickshell
import Quickshell.Io
import QtQuick

// Clipboard history, design page Shell-11. The launcher's shape by design --
// page 11 says outright it is "deliberately the launcher's shape, because it is
// the same interaction" -- so it is PickerSurface with a different source.
//
// 🚨 Fronts cliphist; does NOT replace it. The store already exists, and
// media/clipboard-store is a four-layer secret filter in front of it (password
// manager windows, browser auth pages, terminal ssh/sudo/gpg/pass titles, then
// a gitleaks scan) wired to `wl-paste --watch` in hypr/conf/autostart. That is
// page 11's sensitive-source policy, implemented better than the page states
// it, and reimplementing storage in QML would throw it away.
//
// Two departures from page 11, both forced by what cliphist actually stores:
//
//   * No age and no source application on the meta line. cliphist records
//     neither, and there is no second store to join against. Inventing "2m ·
//     Neovim" would be a lie rendered in ink-secondary; the rows are one line
//     instead, which the shared delegate already sizes at 34.
//   * No thumbnail. Drawing one means decoding each visible image entry to a
//     temp file on every keystroke.
//     ponytail: add it when an image-heavy history actually gets hard to read;
//     the dimensions and format in the title are what distinguish two
//     screenshots, and those are already there.
PickerSurface {
    id: root

    // Parsed `cliphist list` output. `line` is kept verbatim because that is
    // what `cliphist delete` reads on stdin -- it takes the list line, not an
    // id and not the decoded content.
    property var entries: []

    // 🚨 Filtering matches the PREVIEW, which cliphist truncates at about a
    // hundred characters. A word past that point is unfindable here. That is
    // cliphist's interface, and it is what the Wofi pipeline searched too.
    readonly property list<var> matches: {
        const needle = root.query.trim().toLowerCase();
        if (!needle)
            return root.entries;
        return root.entries.filter(e => e.search.includes(needle));
    }

    // `cliphist list` prints "<id>\t<preview>", with newlines already collapsed
    // into the preview.
    function parse(text: string): void {
        const out = [];
        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t");
            if (tab <= 0)
                continue;
            const preview = line.slice(tab + 1);
            // `[[ binary data 1.2 MiB png 1920x1080 ]]` -- the size, format and
            // dimensions are what tell two screenshots apart, so they become
            // the label rather than a bare "Image".
            const binary = /^\[\[ binary data .* (\w+) (\d+)x(\d+) \]\]$/.exec(preview);
            out.push({
                id: line.slice(0, tab),
                line,
                search: preview.toLowerCase(),
                title: binary ? qsTr("Image · %1 × %2 · %3").arg(binary[2]).arg(binary[3]).arg(binary[1].toUpperCase()) : preview,
                glyph: binary ? Config.imageGlyph : "",
                // Content the user is about to paste verbatim: whitespace
                // matters, so it is set in the terminal face, never the GUI one.
                mono: !binary,
                // A path elides mid-string; its tail is the identifying half.
                elideMiddle: !binary && /^~?\//.test(preview) && !preview.includes(" ")
            });
        }
        root.entries = out;
        root.selected = 0;
    }

    function reload(): void {
        list.running = false;
        list.running = true;
    }

    counter: root.matches.length === root.entries.length ? String(root.entries.length) : `${root.matches.length}/${root.entries.length}`
    footerLeft: "↑↓ move · ↵ copy · ⇧del remove"
    footerRight: "cliphist"
    headerGlyph: Config.clipboardGlyph
    model: root.matches
    placeholder: qsTr("Search clipboard")

    // 🚨 Copies; it does NOT paste. Page 11 is right and the reason is not
    // taste: a shell that synthesises keystrokes into whatever happens to be
    // focused will eventually type a password into the wrong window.
    onAccepted: {
        const entry = root.matches[root.selected];
        if (!entry)
            return;
        // Positional argument rather than interpolation: an id is ours, but the
        // habit is what keeps a shell command safe.
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", entry.id]);
        root.close();
    }
    // Shift+Delete, and no confirmation: page 11's one unguarded destructive
    // act, because the entry is a copy of something that still exists.
    onRemoved: {
        const entry = root.matches[root.selected];
        if (!entry)
            return;
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "sh", entry.line]);
        // The delete is a separate process, so the list is re-read rather than
        // patched locally -- what cliphist holds is the only truth about it.
        reloadDelay.restart();
    }
    onOpened: root.reload()

    Process {
        id: list

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    Timer {
        id: reloadDelay

        interval: 120

        onTriggered: root.reload()
    }

    // Empty state. Two lines, never one: the fact, then what fills it. Never a
    // disabled treatment -- there is nothing here to disable.
    Column {
        height: Config.launcherRowHeight + Config.launcherListPad * 2
        spacing: 5
        visible: root.matches.length === 0
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
            text: root.entries.length === 0 ? qsTr("Clipboard history is empty") : qsTr("No entry matches “%1”").arg(root.query.trim())
            width: parent.width
        }

        Text {
            color: Theme.inkSecondary
            font.family: Config.guiFont
            font.pixelSize: Config.fontMeta
            horizontalAlignment: Text.AlignHCenter
            text: root.entries.length === 0 ? qsTr("Copy something and it appears here") : qsTr("Only the first line of an entry is searchable")
            width: parent.width
        }
    }
}
