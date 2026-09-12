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
// Items arrive normalised by MenuServer -- a plain string is a row whose payload
// is itself, so a caller that sends strings is answered with exactly what it
// sent, which is what every `case` statement in this repo matches on. A caller
// that sends objects gets the glyph column, a badge and section labels, and is
// answered with the payload rather than the visible title.
PickerSurface {
    id: root

    // 🚨 The haystack is the title and the subtitle, NEVER the payload: a slug
    // riding along as `payload` must not make its menu row match on text the
    // user cannot see. That is half the point of the object form.
    readonly property list<var> matches: {
        const needle = root.query.trim().toLowerCase();
        const kept = MenuServer.items.filter(i => i.header || !needle || `${i.title} ${i.subtitle}`.toLowerCase().includes(needle));
        // A section label whose rows all filtered out goes with them.
        return kept.filter((item, i) => !item.header || (kept[i + 1] !== undefined && !kept[i + 1].header));
    }
    readonly property int rowCount: root.matches.filter(i => !i.header).length
    readonly property int totalCount: MenuServer.items.filter(i => !i.header).length

    backEnabled: MenuServer.back !== ""
    counter: root.rowCount === root.totalCount ? String(root.totalCount) : `${root.rowCount}/${root.totalCount}`
    escapeClears: false
    footerLeft: root.backEnabled ? "↑↓ move · ↵ select · ← back · esc cancel" : "↑↓ move · ↵ select · esc cancel"
    headerGlyph: Config.menuGlyph
    // MenuServer normalises every item into the row contract, so there is
    // nothing to remap here.
    model: root.matches
    // The trail, when the caller sent one. `›` rather than a second header
    // line: the prompt already names where you are, and a submenu only needs
    // to say what it is under.
    placeholder: MenuServer.breadcrumb !== "" ? `${MenuServer.breadcrumb} › ${MenuServer.prompt}` : MenuServer.prompt

    // 🚨 With nothing matching, Return answers with the TYPED TEXT. That is
    // dmenu's contract, not a nicety: menu-install asks for a package name by
    // handing Wofi an empty list, and a picker that could only echo an existing
    // row would break it silently -- the surface would look right and the
    // caller would get nothing.
    onAccepted: {
        const row = root.matches[root.selected];
        // `payload` is what the caller matches on; the title is only what the
        // user read. They are the same string for a plain-string item.
        const chosen = row && !row.header ? row.payload : root.query.trim();
        if (chosen === "")
            return;
        MenuServer.respond(chosen);
        root.close();
    }
    // Covers Esc, a click outside, and the window being hidden any other way.
    // The caller is blocked on this connection, so every path out of the
    // surface has to answer it.
    // Going back is an ANSWER, not a cancellation: the caller is blocked either
    // way, and it dispatches this payload through the same `case` arm its Back
    // row uses. The surface closes because the parent script opens the next
    // one — one picker at a time is MenuServer's rule.
    onBack: {
        MenuServer.respond(MenuServer.back);
        root.close();
    }
    onCancelled: MenuServer.respond("")
    onMatchesChanged: root.selected = root.firstSelectable()

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
