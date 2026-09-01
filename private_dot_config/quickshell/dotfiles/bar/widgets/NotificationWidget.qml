import "../"
import "../../"
import QtQuick

// The bell. Phase 4 cut the last swaync dependency out of it: the count, the
// DND state and the glyph all come from the in-process Notifications singleton
// now, so there is no `swaync-client -swb` subscriber and no WaybarJsonSource.
BarWidget {
    id: root

    icon: Notifications.glyph()
    // Both do-not-disturb and a waiting notification are states; an idle bell
    // is the resting case and stays neutral.
    iconColor: Notifications.dnd ? Theme.accentError : root.unread ? Theme.accentWarning : root.restColor
    label: root.unread ? Notifications.unread : ""
    monoLabel: true
    // Hidden when this shell does not own notifications: swaync is then the
    // daemon and draws its own panel, and a bell wired to an unloaded server
    // would sit there reading zero forever.
    // ponytail: the rollback loses the bar's bell, not its notifications.
    // Restoring it would mean keeping the old WaybarJsonSource swaync
    // subscriber alongside this — two implementations of one widget for a
    // state that exists only to be temporary.
    visible: Config.notificationsOwned
    tooltipText: Notifications.dnd ? qsTr("Do not disturb — %1 in history").arg(Notifications.unread) : root.unread ? qsTr("%1 notifications").arg(Notifications.unread) : qsTr("No notifications")

    readonly property bool unread: Notifications.unread > 0

    // Relayed up through Bar to shell.qml, which owns the window — the same
    // route LauncherWidget takes. Going out through quickshell-toggle would
    // spawn a process for the shell to talk to itself.
    signal centreRequested

    // Left opens the centre, right toggles DND, middle clears — the same three
    // gestures the swaync module bound, so the muscle memory survives.
    onClicked: root.centreRequested()
    onMiddleClicked: Notifications.clearAll()
    onRightClicked: Notifications.toggleDnd()
}
