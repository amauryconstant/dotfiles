pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// Phase 4. Owns org.freedesktop.Notifications for the session — swaync is
// masked by run_onchange_after_configure_notifications, because a bus name has
// exactly one owner and there is no coexistence to be had.
//
// 🚨 A popup timing out must NOT call expire() or dismiss(). Both destroy the
// Notification, which removes it from trackedNotifications — i.e. from the
// history the centre exists to show. Popup lifetime is therefore this file's
// own `popups` list with its own timers, entirely separate from what the server
// tracks. Only a real user dismissal, or Clear, may destroy anything.
//
// 🚨 And the mirror-image trap: a notification is NOT tracked by default.
// `isTracked()` is `mCloseReason == 0`, but `mCloseReason` is initialised to
// `NotificationCloseReason::Dismissed` — so unless the `notification` handler
// sets `tracked = true`, `server.cpp` DELETES the object the instant the signal
// returns. Reading `isTracked()`'s body alone says the opposite; the member's
// initialiser is the fact. Verified live: without it the history stays empty
// while the popups fill with nulls.
Singleton {
    id: root

    // Do not disturb. Suppresses POPUPS ONLY — history still fills, which is
    // the point of the mode. Persisted: the user set it deliberately and will
    // not think to re-set it after a restart.
    property bool dnd: false
    // 🚨 Undismissed notifications restored from the last session. These are
    // SNAPSHOTS, not live Notification objects — the process that sent them is
    // gone, so its actions cannot be invoked and none are offered. Everything
    // the card reads is present; `actions` is deliberately empty rather than
    // absent, so the card needs no special case. Drawing dead action buttons
    // would be worse than not restoring at all.
    property list<var> restored: []
    // Set once the state file has been read, so a write cannot race the load
    // and truncate the queue it was about to restore.
    property bool stateLoaded: false
    // Popups currently on screen. Plain list rather than a filter over the
    // server's model: see the header — the two lifetimes are unrelated.
    property list<var> popups: []
    // 🚨 Hide deadlines by notification id, ticked below. NOT a Timer in the
    // popup delegate: the Repeater's model is a JS array, which Qt does not
    // diff, so every arrival destroys and recreates all delegates — and a
    // per-delegate Timer would restart on each one, keeping the oldest toast up
    // forever under any steady stream (voxtype's start/stop pair does it).
    property var deadlines: ({})
    // Arrival times by notification id. Notification carries none, and the
    // card needs one to render a relative timestamp that survives a restart.
    property var arrivals: ({})

    // Null whenever this shell does not own notifications, so every read below
    // has to tolerate that rather than assume a server exists.
    readonly property var server: serverLoader.item

    // Newest first, capped, transients excluded. `trackedNotifications` is
    // insertion-ordered, uncapped and includes transients, so all three are
    // this file's job.
    readonly property list<var> history: {
        const all = root.server ? root.server.trackedNotifications.values.filter(n => !n.transient) : [];
        all.reverse();
        // Restored entries sort after everything from this session: they are
        // older than anything that has arrived since the shell started.
        return [...all, ...root.restored].slice(0, Config.notifHistoryMax);
    }
    readonly property int unread: root.history.length

    // Groups history entries by app into one card each, so three messages from
    // one app read as one stack with a count, the way pan-a draws it. Order is
    // preserved: a group sorts where its NEWEST member sat.
    readonly property list<var> groups: {
        const out = [];
        const byApp = {};
        for (const n of root.history) {
            const key = root.appKey(n);
            if (byApp[key] !== undefined) {
                out[byApp[key]].rest.push(n);
                continue;
            }
            byApp[key] = out.length;
            out.push({
                lead: n,
                rest: []
            });
        }
        // 🚨 A group collapses at THREE, not at two. Two messages from one app
        // are two things the user has to read; hiding one of them behind a
        // count saves a card and costs the message. So a pair is expanded back
        // into its members, in place.
        const expanded = [];
        for (const g of out) {
            if (g.rest.length + 1 >= 3) {
                expanded.push(g);
                continue;
            }
            expanded.push({
                lead: g.lead,
                rest: []
            });
            for (const n of g.rest)
                expanded.push({
                    lead: n,
                    rest: []
                });
        }
        return expanded;
    }

    // 🚨 `notify-send` reports ITS OWN name as appName, so timeshift, the
    // pacman hooks and every script in this repo all arrive as "notify-send" —
    // one useless label, and one group swallowing unrelated senders. The
    // `desktop-entry` hint is the sender's real identity and wins wherever it
    // is supplied.
    //
    // Resolved off the MODEL, never DesktopEntries.byId(): that is a plain
    // function call, so a binding on it never re-evaluates when the entry set
    // rescans.
    function entryFor(notification: var): var {
        const id = notification.desktopEntry ?? "";
        return id ? DesktopEntries.applications.values.find(e => e.id === id) : null;
    }

    function appLabel(notification: var): string {
        return root.entryFor(notification)?.name || notification.desktopEntry || notification.appName || "unknown";
    }

    function appKey(notification: var): string {
        return notification.desktopEntry || notification.appName || "?";
    }

    function clearAll(): void {
        if (root.server)
            // Copy first: dismiss() mutates the model this iterates.
            for (const n of [...root.server.trackedNotifications.values])
                n.dismiss();
        root.restored = [];
        root.popups = [];
        root.persist();
    }

    // The undismissed queue and the DND flag, and nothing else. Every other
    // surface in this shell persists nothing and should not: a popover or a
    // launcher coming back open after a restart would be reporting state the
    // user did not ask for. These two are the user's unread mail and a switch
    // they threw on purpose.
    function persist(): void {
        if (!root.stateLoaded)
            return;
        const queue = root.history.map(n => ({
                    appName: n.appName ?? "",
                    desktopEntry: n.desktopEntry ?? "",
                    summary: n.summary ?? "",
                    body: n.body ?? "",
                    appIcon: n.appIcon ?? "",
                    image: n.image ?? "",
                    urgency: n.urgency,
                    arrivedAt: root.arrivedAt(n)
                }));
        state.setText(JSON.stringify({
            dnd: root.dnd,
            queue
        }));
    }

    // The popup for a notification goes away; the notification does not —
    // unless it was transient, in which case the popup WAS its whole life and
    // there is nowhere for it to go.
    function hidePopup(notification: var): void {
        delete root.deadlines[notification.id];
        root.popups = root.popups.filter(n => n !== notification);
        if (notification.transient)
            notification.expire();
    }

    // A real dismissal: destroys the notification, so it leaves history too.
    // A restored snapshot has nothing to destroy — dropping it from the list is
    // the whole of its dismissal.
    function dismiss(notification: var): void {
        root.hidePopup(notification);
        if (notification.restored) {
            root.restored = root.restored.filter(n => n !== notification);
            root.persist();
            return;
        }
        notification.dismiss();
    }

    function toggleDnd(): bool {
        root.dnd = !root.dnd;
        if (root.dnd)
            root.popups = [];
        root.persist();
        return root.dnd;
    }

    // When this notification reached the shell. A restored snapshot carries its
    // own; a live one is looked up by id.
    function arrivedAt(notification: var): double {
        return notification.arrivedAt ?? root.arrivals[notification.id] ?? Date.now();
    }

    // <dnd?>-<unread?>, the same four keys the swaync module reported.
    function glyph(): string {
        const key = `${root.dnd ? "dnd-" : ""}${root.unread > 0 ? "notification" : "none"}`;
        return Config.notifGlyphs[key] ?? Config.notifGlyphs["none"];
    }

    // 🚨 expireTimeout is in MILLISECONDS. The fd.o spec's expire_timeout is,
    // and notification.cpp assigns the D-Bus argument verbatim — the property's
    // own doc comment ("Time in seconds") is wrong. Multiplying by 1000 turned
    // every `notify-send -t 2000` in this repo into a 33-minute toast, which is
    // what "notifications never disappear" was.
    //
    // -1 means "server decides"; 0 means never expire, and so does Critical —
    // matching swaync's timeout-critical: 0. An alert you can miss is not one.
    function popupTimeout(notification: var): int {
        if (notification.urgency === NotificationUrgency.Critical)
            return 0;
        const requested = notification.expireTimeout;
        if (requested >= 0)
            return requested;
        return notification.urgency === NotificationUrgency.Low ? Config.notifTimeoutLowMs : Config.notifTimeoutMs;
    }

    // 🚨 Loader, not a bare NotificationServer: CONSTRUCTING the server is what
    // claims the bus name, so the only way to not own notifications is to not
    // construct it. With Config.notificationsOwned false, swaync is unmasked
    // and a server here would race it for the name at login — which is the
    // exact failure the flag exists to prevent. See Config.notificationsOwned.
    Loader {
        id: serverLoader

        active: Config.notificationsOwned

        sourceComponent: NotificationServer {
            // Everything the cards can actually render is advertised; nothing
            // else is. Markup stays OFF: Text renders markup by default, so
            // advertising it would invite senders to ship tags that our
            // PlainText cards would then show raw.
            actionsSupported: true
            bodyImagesSupported: false
            bodyMarkupSupported: false
            bodySupported: true
            imageSupported: true
            // Not built: an inline reply needs a focused text field inside a
            // popup, and the popup stack deliberately takes no keyboard focus.
            inlineReplySupported: false
            // The centre IS a persistence area, so say so.
            persistenceSupported: true

            onNotification: notification => {
                // A transient nobody will see needs neither a popup nor a
                // history entry, and NOT tracking it is how it gets collected —
                // the one case where the default is what we want.
                if (root.dnd && notification.transient)
                    return;

                // 🚨 Everything else must opt in HERE, synchronously. See the
                // file header: an untracked notification is deleted as soon as
                // this handler returns, which empties the centre and leaves the
                // popup stack holding nulls.
                notification.tracked = true;
                root.arrivals[notification.id] = Date.now();

                // DND suppresses popups only; history still fills, which is the
                // point of the mode. A reload replays the previous generation,
                // and those already had their moment on screen.
                if (root.dnd || notification.lastGeneration)
                    return;
                const ms = root.popupTimeout(notification);
                if (ms > 0)
                    root.deadlines[notification.id] = Date.now() + ms;
                // Capped at the history bound, not at the visible count: the
                // stack shows notifPopupMaxVisible and reports the rest as a
                // count, so the list has to hold more than it draws.
                root.popups = [notification, ...root.popups].slice(0, Config.notifHistoryMax);
            }
        }
    }

    // One tick for every popup, rather than one Timer each: the delegates are
    // rebuilt too often to own their own lifetime (see `deadlines`). Idle
    // whenever nothing is on screen.
    Timer {
        interval: 500
        repeat: true
        running: root.popups.length > 0

        onTriggered: {
            const now = Date.now();
            // Copy: hidePopup mutates the list this iterates.
            for (const n of [...root.popups])
                if (n && root.deadlines[n.id] <= now)
                    root.hidePopup(n);
        }
    }

    // Undismissed queue + DND across a RESTART. keepOnReload covers a config
    // reload only; a fresh process starts empty, and the unread queue is the
    // one thing in this shell that a user would notice losing. FileView creates
    // the parent directory on write (fileview.cpp:231), so nothing has to
    // mkdir ~/.local/state/quickshell first.
    FileView {
        id: state

        path: `${Quickshell.env("HOME")}/.local/state/quickshell/notifications.json`
        // A first run has no file, and that is not an error worth logging.
        printErrors: false
        // Deliberately NOT watched: this file is ours alone, and re-reading our
        // own write would restore what we just persisted on top of the live
        // notifications it was serialised from.
        watchChanges: false

        onLoadFailed: root.stateLoaded = true
        onLoaded: {
            try {
                const saved = JSON.parse(state.text());
                root.dnd = saved.dnd ?? false;
                root.restored = (saved.queue ?? []).map(e => Object.assign({}, e, {
                        restored: true,
                        // The card reads all of these; a snapshot supplies them so
                        // it needs no branch of its own.
                        actions: [],
                        hints: ({}),
                        resident: false,
                        transient: false
                    }));
            } catch (e) {
                root.restored = [];
            }
            root.stateLoaded = true;
        }
    }

    // A dismissal from anywhere — the app itself, a script, our own Clear —
    // must also take the popup down. Objects destroyed elsewhere would
    // otherwise linger in `popups` as broken references.
    Connections {
        function onValuesChanged(): void {
            const live = root.server.trackedNotifications.values;
            // `n &&` is not defensive noise: a destroyed Notification leaves a
            // NULL entry in the list, and every popup binding then reads
            // properties off it.
            root.popups = root.popups.filter(n => n && live.includes(n));
            root.persist();
        }

        target: root.server?.trackedNotifications ?? null
    }
}
