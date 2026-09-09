pragma ComponentBehavior: Bound

import "../"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Toast stack, top-right, under the floating bar. One window per screen rather
// than one following the focus, unlike the launcher and the power menu: a
// notification arrives on its own schedule, so "wherever you were looking when
// it fired" is the wrong answer — it has to be where you are looking NOW, and
// the per-monitor hint below can override even that.
Variants {
    id: root

    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        // Which notifications belong on THIS screen. `x-canonical-monitor` is
        // the hint our own ui_notify_focused (core/gum-ui.sh) already sends;
        // extraHints does not have to declare it — that property only affects
        // the advertised capability list, every client hint arrives in `hints`
        // regardless. Anything unhinted lands on the focused monitor.
        readonly property list<var> mine: Notifications.popups.filter(n => {
            const wanted = n.hints?.["x-canonical-monitor"];
            return wanted ? wanted === win.modelData.name : win.modelData.name === Hyprland.focusedMonitor?.name;
        })
        // Three cards at once and a count for the rest: past that the stack
        // stops being a glance and starts being a wall, and the overflow is
        // already in the centre, which is where it belongs.
        readonly property list<var> shown: win.mine.slice(0, Config.notifPopupMaxVisible)
        readonly property int overflow: win.mine.length - win.shown.length

        color: "transparent"
        // Toasts must not push windows around; the bar already reserves its
        // own strip and this floats inside the workspace.
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: Config.notifWidth
        screen: win.modelData
        visible: win.mine.length > 0

        // qmllint disable unqualified unresolved-type
        anchors.right: true
        anchors.top: true
        // Clears the floating bar rather than sliding under it.
        margins.right: Config.barInset
        margins.top: Config.barHeight + Config.barInset * 2
        // qmllint enable unqualified unresolved-type

        // Popups are clickable (dismiss, action) but must never take keyboard
        // focus: a toast stealing keys mid-typing is worse than a missed
        // notification. `None` is also what the bar and the OSD use.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.layer: WlrLayer.Overlay
        // Its own layer namespace, so a Hyprland layerrule can animate the
        // toasts without also animating the bar, the OSD, the dock and the
        // launcher — every other surface here shares `quickshell`. The
        // open/close effect is Hyprland's, not QML's: a layer surface is
        // animated compositor-side, so there is nothing in this file to tune.
        // The rule is in hypr/conf.d/quickshell.{lua,conf}.
        //
        // 🚨 Settable only before the window connects (wlr_layershell.hpp:106),
        // which a property declaration is; assigning it later is a silent no-op.
        WlrLayershell.namespace: "quickshell-notifications"

        // Without a mask a layer-shell window swallows every click over its
        // whole surface. The stack is as tall as its content, so the mask is
        // the content — not the empty region above and below it.
        mask: Region {
            item: stack
        }

        implicitHeight: Math.max(1, stack.implicitHeight)

        Column {
            id: stack

            spacing: Config.gap
            width: parent.width

            Repeater {
                model: win.shown

                NotificationCard {
                    id: card

                    required property var modelData

                    // A popup is a glance, so its body clamps to three lines;
                    // the full text is in the centre.
                    bodyMaxLines: 3
                    notification: card.modelData
                    // A toast's actions are a mis-click waiting to happen: it
                    // is about to vanish from under the pointer. The centre is
                    // where you act on a notification.
                    showActions: false
                    width: parent.width

                    onDismissed: Notifications.dismiss(card.modelData)

                    // Click dismisses the popup only, keeping the notification
                    // in history — the whole reason popup lifetime is separate
                    // from the server's tracking.
                    MouseArea {
                        anchors.fill: parent

                        onClicked: Notifications.hidePopup(card.modelData)
                    }

                    // No lifetime Timer here: this delegate is destroyed and
                    // recreated on every arrival, so its timer would restart
                    // too. Deadlines live in the Notifications singleton.
                }
            }

            Text {
                color: Theme.inkPrimary
                font.family: Config.terminalFont
                font.pixelSize: Config.fontMeta
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("+%1 more").arg(win.overflow)
                visible: win.overflow > 0
                width: parent.width
            }
        }
    }
}
