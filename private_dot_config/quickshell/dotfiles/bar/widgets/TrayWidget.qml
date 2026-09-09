import "../"
import "../../"
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

// Waybar's tray module: icon-size 16, spacing 8.
//
// Right-click opens the item's own DBusMenu. QsMenuAnchor renders that
// natively, so the menu is the application's real menu rather than a
// reimplementation of it — the one popup strict parity actually requires.
BarWidget {
    id: root

    // Capped, with the overflow folded behind one glyph — the same cap the
    // launcher's result list uses. An uncapped tray is the one widget that can
    // push every other one off a narrow output.
    readonly property var shown: SystemTray.items.values.slice(0, Config.trayMaxItems)
    readonly property int overflow: SystemTray.items.values.length - root.shown.length

    hoverBackground: false

    Repeater {
        model: root.shown

        Item {
            id: entry

            required property var modelData
            // SystemTrayItem.menu is a DBusMenuHandle, which Quickshell does
            // not expose declaratively, so qmllint cannot resolve its type.
            // Suppressed inline, on this one line, rather than by adding
            // --unresolved-type to the tree-wide exemption list: that category
            // is also how a genuinely missing import shows up everywhere else.
            // qmllint disable unresolved-type
            readonly property var menuHandle: entry.modelData.menu
            // qmllint enable unresolved-type

            height: Config.chipSize
            width: Config.chipSize

            IconImage {
                id: icon

                anchors.centerIn: parent
                implicitSize: Config.iconSize
                source: entry.modelData.icon
            }

            QsMenuAnchor {
                id: menu

                anchor.item: icon
                menu: entry.menuHandle
            }

            MouseArea {
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                anchors.fill: parent
                hoverEnabled: true

                // onlyMenu items have no activate action at all; showing their
                // menu on left click is what a tray host is expected to do.
                onClicked: event => {
                    if (event.button === Qt.MiddleButton) {
                        entry.modelData.secondaryActivate();
                        return;
                    }
                    if (event.button === Qt.RightButton || entry.modelData.onlyMenu) {
                        if (entry.modelData.hasMenu)
                            menu.open();
                        return;
                    }
                    entry.modelData.activate();
                }
                onWheel: event => entry.modelData.scroll(event.angleDelta.y, false)
            }
        }
    }

    Item {
        height: Config.chipSize
        visible: root.overflow > 0
        width: Config.chipSize

        Text {
            anchors.centerIn: parent
            color: root.restColor
            font.family: Config.guiFont
            font.pixelSize: Config.glyphBar
            text: Config.overflowGlyph
        }
    }
}
