pragma ComponentBehavior: Bound

import "../"
import "../launcher"
import QtQuick

// The surface behind every `show_menu` call in this repo. Design page 10's
// chrome rules -- rowH 34 rows, hairline-separated header and footer, selection
// as tint plus accent glyph plus a return mark -- over PickerSurface, which is
// where all three of those already live.
//
// Two deliberate departures from page 10:
//
//   * 340 wide, not 260. Page 10 draws a menu of short verbs; these lists carry
//     strings this repo already wrote, such as "Power Profile (Current:
//     balanced)". Narrowing the surface would elide the only part that differs
//     between two rows.
//   * Esc cancels on the first press rather than clearing the query. Here the
//     query is incidental -- the caller is a blocked script, and Esc means "it
//     gets nothing", which should not take two keystrokes.
//
// Items arrive as plain strings and are answered as plain strings: whatever the
// caller sent back verbatim, because every caller matches on it with `case`.
PickerSurface {
    id: root

    readonly property list<var> matches: {
        const needle = root.query.trim().toLowerCase();
        const items = MenuServer.items;
        if (!needle)
            return items;
        return items.filter(i => i.toLowerCase().includes(needle));
    }

    counter: root.matches.length === MenuServer.items.length ? String(MenuServer.items.length) : `${root.matches.length}/${MenuServer.items.length}`
    escapeClears: false
    footerLeft: "↑↓ move · ↵ select · esc cancel"
    headerGlyph: Config.menuGlyph
    model: root.matches.map(item => ({
                title: item
            }))
    placeholder: MenuServer.prompt

    // 🚨 With nothing matching, Return answers with the TYPED TEXT. That is
    // dmenu's contract, not a nicety: menu-install asks for a package name by
    // handing Wofi an empty list, and a picker that could only echo an existing
    // row would break it silently -- the surface would look right and the
    // caller would get nothing.
    onAccepted: {
        const chosen = root.matches[root.selected] ?? root.query.trim();
        if (chosen === "")
            return;
        MenuServer.respond(chosen);
        root.close();
    }
    // Covers Esc, a click outside, and the window being hidden any other way.
    // The caller is blocked on this connection, so every path out of the
    // surface has to answer it.
    onCancelled: MenuServer.respond("")
    onMatchesChanged: root.selected = 0

    Connections {
        function onAborted(): void {
            root.close();
        }

        function onRequested(): void {
            root.open();
        }

        target: MenuServer
    }
}
