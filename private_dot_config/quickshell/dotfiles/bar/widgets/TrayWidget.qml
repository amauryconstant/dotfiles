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

    hoverBackground: false

    Repeater {
        model: SystemTray.items

        Item {
            id: entry

            required property SystemTrayItem modelData
            // SystemTrayItem.menu is a DBusMenuHandle, which Quickshell does
            // not expose declaratively, so qmllint cannot resolve its type.
            // Suppressed inline, on this one line, rather than by adding
            // --unresolved-type to the tree-wide exemption list: that category
            // is also how a genuinely missing import shows up everywhere else.
            // qmllint disable unresolved-type
            readonly property var menuHandle: entry.modelData.menu
            // qmllint enable unresolved-type

            height: Config.barHeight
            width: Config.iconSize + 8

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
}
