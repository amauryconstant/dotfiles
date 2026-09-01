pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
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
    // the point of the mode. In memory, no state file: swaync's DND does not
    // survive its own daemon restart either, and nothing outside this shell
    // toggles it.
    property bool dnd: false
    // Popups currently on screen. Plain list rather than a filter over the
    // server's model: see the header — the two lifetimes are unrelated.
    property list<var> popups: []

    // Null whenever this shell does not own notifications, so every read below
    // has to tolerate that rather than assume a server exists.
    readonly property var server: serverLoader.item

    // Newest first, capped, transients excluded. `trackedNotifications` is
    // insertion-ordered, uncapped and includes transients, so all three are
    // this file's job.
    readonly property list<var> history: {
        if (!root.server)
            return [];
        const all = root.server.trackedNotifications.values.filter(n => !n.transient);
        all.reverse();
        return all.slice(0, Config.notifHistoryMax);
    }
    readonly property int unread: root.history.length

    // Groups history entries by app into one card each, so three messages from
    // one app read as one stack with a count, the way pan-a draws it. Order is
    // preserved: a group sorts where its NEWEST member sat.
    readonly property list<var> groups: {
        const out = [];
        const byApp = {};
        for (const n of root.history) {
            const key = n.appName || n.desktopEntry || "?";
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
        return out;
    }

    function clearAll(): void {
        if (root.server)
            // Copy first: dismiss() mutates the model this iterates.
            for (const n of [...root.server.trackedNotifications.values])
                n.dismiss();
        root.popups = [];
    }

    // The popup for a notification goes away; the notification does not —
    // unless it was transient, in which case the popup WAS its whole life and
    // there is nowhere for it to go.
    function hidePopup(notification: var): void {
        root.popups = root.popups.filter(n => n !== notification);
        if (notification.transient)
            notification.expire();
    }

    // A real dismissal: destroys the notification, so it leaves history too.
    function dismiss(notification: var): void {
        root.hidePopup(notification);
        notification.dismiss();
    }

    function toggleDnd(): bool {
        root.dnd = !root.dnd;
        if (root.dnd)
            root.popups = [];
        return root.dnd;
    }

    // <dnd?>-<unread?>, the same four keys the swaync module reported.
    function glyph(): string {
        const key = `${root.dnd ? "dnd-" : ""}${root.unread > 0 ? "notification" : "none"}`;
        return Config.notifGlyphs[key] ?? Config.notifGlyphs["none"];
    }

    // 0 from a client means "no expiry, decide yourself"; -1 means the
    // server's default. Critical never auto-hides, matching swaync's
    // timeout-critical: 0 — an alert you can miss is not an alert.
    function popupTimeout(notification: var): int {
        if (notification.urgency === NotificationUrgency.Critical)
            return 0;
        const requested = notification.expireTimeout;
        if (requested > 0)
            return requested * 1000;
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

                // DND suppresses popups only; history still fills, which is the
                // point of the mode. A reload replays the previous generation,
                // and those already had their moment on screen.
                if (root.dnd || notification.lastGeneration)
                    return;
                root.popups = [notification, ...root.popups].slice(0, Config.notifPopupMaxVisible);
            }
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
        }

        target: root.server?.trackedNotifications ?? null
    }
}
