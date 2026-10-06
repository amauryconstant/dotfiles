import "../"
import Quickshell
import Quickshell.Hyprland
import QtQuick

// The shared popover chrome, design page Shell-06-Popovers: one chrome, seven
// payloads. Ground `groundBase` and never an elevated tier, a 34 header with
// glyph and title, the payload, and a 32 footer carrying the keys on the left
// and the escape hatch on the right, both hairline-separated.
//
// 🚨 `grabFocus` MUST stay false. Setting it makes Qt request an xdg_popup
// grab, and a PopupWindow whose parent is a LAYER-SHELL window cannot be one.
// Measured 2026-09-10 with `quickshell -p`:
//
//   WARN qt.qpa.wayland: Failed to create grabbing popup. Ensure popup has a
//   transientParent set and that parent window has received input.
//   WARN: Cannot attach popup ... as the popup is not an xdg_popup.
//
// and the popup then set itself back to invisible. So the click-outside
// dismissal that `grabFocus` exists for is simply not available here, and the
// two open modes are built out of what is:
//
//   POINTER — no grab of any kind, so the keyboard stays with the application
//   the user was typing into (design page 03 requires exactly that). Nothing
//   reports a click landing elsewhere, so losing the pointer is the close
//   signal, with Config.popHideDelayMs of slack for the crossing.
//
//   KEYBOARD — HyprlandFocusGrab, which does deliver keys to a focused Item in
//   here (verified: `q` and Escape both arrived) and signals `cleared` when the
//   user clicks outside. It takes the keyboard away from the focused
//   application for as long as it is up, which is the trap page 03 describes
//   and the reason the ring is mandatory in this mode.
PopupWindow {
    id: root

    // The BarWidget this popover hangs from. Its hover state is passed in
    // rather than read, because the widget lives in another window.
    required property Item anchorItem
    property bool anchorHovered: false
    // The payload, with the chrome's own padding and row spacing applied.
    default property alias body: bodyColumn.data
    readonly property int bodyMaxHeight: Config.popMaxH - Config.popHeaderHeight - Config.popFooterHeight
    // argv for the escape hatch. Null draws the footer's right side as a plain
    // label, which is what the design asks for where nothing is launchable.
    property var footerCommand: null
    property string footerLeft: ""
    property string footerRight: ""
    property string glyph: ""
    // Opened from the `popovers` submap rather than by pointer: keyboard grab,
    // a cursor on the first interactive row, and a visible focus ring.
    property bool keyboardMode: false
    // How many things arrows and Tab step through. The payload counts them; the
    // chrome only moves the cursor, because what a row DOES is the payload's.
    property int navCount: 0
    readonly property bool pointerHeld: root.anchorHovered || bodyHover.hovered
    // Split from `visible` so the arrival animation has something to run from:
    // the window maps first, then this flips one event loop later.
    property bool revealed: false
    // The rows' right-click menu. Payload rows take it as `menu: root.rowMenu`.
    readonly property alias rowMenu: rowMenu
    property int selected: -1
    property bool shown: false
    property string title: ""

    signal activated(int index)
    // 🚨 NOT `closed`: PopupWindow already carries a signal of that name, and
    // overriding it is only a runtime warning — qmllint says nothing.
    signal dismissed
    // Up/Down/Tab. The chrome moves its own cursor when the payload is a list;
    // a payload that is not a list (the calendar) reads the delta instead.
    signal moved(int delta)
    // PageUp/PageDown. Only the calendar has anything to page.
    signal paged(int delta)
    // Left/Right, which is a step within the cursor's own item rather than a
    // move between items — a slider's increment, a day.
    signal stepped(int delta)

    function close(): void {
        rowMenu.hide();
        root.shown = false;
        root.revealed = false;
        root.keyboardMode = false;
        root.selected = -1;
        root.dismissed();
    }

    function move(delta: int): void {
        root.moved(delta);
        if (root.navCount <= 0)
            return;
        root.selected = (root.selected + delta + root.navCount) % root.navCount;
    }

    function open(keyboard: bool): void {
        root.keyboardMode = keyboard;
        root.selected = keyboard ? 0 : -1;
        // 🚨 The anchor rect is computed only when the popup is FIRST shown and
        // does not follow the item (popupanchor.hpp). Bar widgets move — the
        // window title changes width, a workspace appears — so without this a
        // reopened popover lands where its widget used to be.
        // qmllint disable unresolved-type
        root.anchor.updateAnchor();
        // qmllint enable unresolved-type
        root.shown = true;
        Qt.callLater(() => {
            root.revealed = true;
        });
    }

    function runEscapeHatch(): void {
        if (root.footerCommand)
            Quickshell.execDetached(Config.detach.concat(root.footerCommand));
        root.close();
    }

    color: "transparent"
    grabFocus: false
    implicitHeight: Config.popHeaderHeight + Config.popFooterHeight + bodyWrap.height
    implicitWidth: Config.popMaxW
    visible: root.shown

    // 🚨 `edges`/`gravity` MUST be set — see BarTooltip.qml for the full
    // rationale. SlideX keeps a popover under a widget near the screen edge on
    // the output ("clamped to the output", page 06); flipping is wrong here,
    // since there is nothing above the bar to flip into.
    anchor {
        // qmllint disable missing-type
        adjustment: PopupAdjustment.SlideX
        edges: Edges.Bottom
        gravity: Edges.Bottom
        // qmllint enable missing-type
        item: root.anchorItem
    }

    onPointerHeldChanged: {
        if (root.pointerHeld)
            hideDelay.stop();
        else if (root.shown && !root.keyboardMode)
            hideDelay.restart();
    }

    // Pointer mode's only close signal. Keyboard mode ignores it: a popover you
    // opened from a binding must not evaporate because the pointer is elsewhere.
    Timer {
        id: hideDelay

        interval: Config.popHideDelayMs

        onTriggered: {
            if (!root.pointerHeld && !root.keyboardMode)
                root.close();
        }
    }

    // qmllint disable unresolved-type
    HyprlandFocusGrab {
        active: root.shown && root.keyboardMode
        windows: [root]

        onCleared: root.close()
    }
    // qmllint enable unresolved-type

    Rectangle {
        id: chrome

        border.color: Theme.edge
        border.width: Config.hairline
        color: Theme.groundBase
        height: parent.height
        opacity: root.revealed ? 1 : 0
        radius: Config.radiusPanel
        width: parent.width
        y: root.revealed ? 0 : -Config.gap

        Behavior on opacity {
            NumberAnimation {
                duration: Config.motionEnter
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: Config.motionEnter
            }
        }

        HoverHandler {
            id: bodyHover
        }

        // Keys handlers need a focused ITEM — a window is not one. Focus is
        // taken only in keyboard mode, so a pointer-opened popover cannot
        // swallow anything even if a grab existed.
        //
        // 🚨 While the row menu is up it owns every key: Escape closes the
        // MENU, never the popover under it, and the arrows move its cursor.
        Item {
            anchors.fill: parent
            focus: root.keyboardMode

            Keys.onBacktabPressed: rowMenu.visible ? rowMenu.move(-1) : root.move(-1)
            Keys.onDownPressed: rowMenu.visible ? rowMenu.move(1) : root.move(1)
            Keys.onEnterPressed: rowMenu.visible ? rowMenu.run(rowMenu.cursor) : root.activated(root.selected)
            Keys.onEscapePressed: rowMenu.visible ? rowMenu.hide() : root.close()
            Keys.onLeftPressed: {
                if (!rowMenu.visible)
                    root.stepped(-1);
            }
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) {
                    if (rowMenu.visible)
                        rowMenu.hide();
                    else
                        rowMenu.keyRequested();
                } else if (rowMenu.visible) {
                    return;
                } else if (event.key === Qt.Key_PageUp) {
                    root.paged(-1);
                } else if (event.key === Qt.Key_PageDown) {
                    root.paged(1);
                } else {
                    return;
                }
                event.accepted = true;
            }
            Keys.onReturnPressed: rowMenu.visible ? rowMenu.run(rowMenu.cursor) : root.activated(root.selected)
            Keys.onRightPressed: {
                if (!rowMenu.visible)
                    root.stepped(1);
            }
            Keys.onTabPressed: rowMenu.visible ? rowMenu.move(1) : root.move(1)
            Keys.onUpPressed: rowMenu.visible ? rowMenu.move(-1) : root.move(-1)
        }

        Column {
            anchors.fill: parent

            Item {
                height: Config.popHeaderHeight
                width: parent.width

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Config.padTight
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Config.gap

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.inkPrimary
                        font.family: Config.guiFont
                        font.pixelSize: Config.glyphRow
                        text: root.glyph
                        visible: root.glyph !== ""
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.inkPrimary
                        font.family: Config.guiFont
                        font.pixelSize: Config.fontTitle
                        font.weight: Font.DemiBold
                        text: root.title
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    color: Theme.edge
                    height: Config.hairline
                    width: parent.width
                }
            }

            Item {
                id: bodyWrap

                clip: true
                height: Math.min(root.bodyMaxHeight, bodyColumn.implicitHeight + Config.padTight)
                width: parent.width

                Column {
                    id: bodyColumn

                    anchors.left: parent.left
                    anchors.leftMargin: Config.padTight
                    anchors.right: parent.right
                    anchors.rightMargin: Config.padTight
                    anchors.top: parent.top
                    anchors.topMargin: Config.gap
                    spacing: Config.gap
                }
            }

            Item {
                height: Config.popFooterHeight
                width: parent.width

                Rectangle {
                    color: Theme.edge
                    height: Config.hairline
                    width: parent.width
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Config.padTight
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.inkSecondary
                    font.family: Config.terminalFont
                    font.pixelSize: Config.fontMeta
                    text: root.footerLeft
                }

                Text {
                    id: hatch

                    anchors.right: parent.right
                    anchors.rightMargin: Config.padTight
                    anchors.verticalCenter: parent.verticalCenter
                    // A launchable hatch is a LINK, so it is Theme.action —
                    // until 2026-10-06 it was inkSecondary, identical to the
                    // key hints on the left and to a hatch that does nothing.
                    // Underlined on hover; colour stays put.
                    color: root.footerCommand ? Theme.action : Theme.inkSecondary
                    font.family: Config.terminalFont
                    font.pixelSize: Config.fontMeta
                    font.underline: root.footerCommand !== null && hatchMouse.containsMouse
                    text: root.footerRight
                    textFormat: Text.PlainText
                }

                // Where it launches, launching closes the popover. Where
                // footerCommand is null the name is a label and nothing happens.
                MouseArea {
                    id: hatchMouse

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.footerCommand !== null
                    height: parent.height
                    hoverEnabled: true
                    width: hatch.width + Config.padTight * 2

                    onClicked: root.runEscapeHatch()
                }
            }
        }

        // Last child, so it stacks over the body and the footer alike.
        ContextMenu {
            id: rowMenu

            anchors.fill: parent
        }
    }
}
