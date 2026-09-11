pragma ComponentBehavior: Bound

import "../"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

// Auto-hiding dock, artboard comp-a (Phase 5.5). One per screen, like the bar
// and unlike every modal here — a dock is furniture, not something you summon,
// so it belongs wherever the pointer reaches the bottom edge.
//
// Genuinely new: nothing in this config did this job, and Omarchy has no dock
// to read from. Its geometry is measured off the artboard rather than taken
// from the geometry scale (see Config.dock*) — the dock is a peer of the bar.
PanelWindow {
    id: root

    required property var modelData
    // Raised by the trailing tile; shell.qml owns the Launcher window, exactly
    // as it does for the bar's launcher chip.
    signal launcherRequested

    // 🚨 Held true for a grace period after the pointer leaves, so a moment of
    // lost hover cannot retract the dock out from under a click.
    readonly property bool revealed: hoverHandler.hovered || hideDelay.running

    color: "transparent"
    // 0, not the dock's height: it hides. Reserving a strip for a surface that
    // is off-screen most of the time is the opposite of what it is for.
    exclusiveZone: 0
    implicitHeight: Config.dockHeight + Config.barInset
    screen: root.modelData
    visible: Config.dockEnabled

    // 🚨 An unmasked layer-shell window swallows every click over its whole
    // surface, whether or not anything in it accepts mouse events. Hidden, the
    // input region is the 4px hot edge and nothing else.
    //
    // 🚨 Revealed, it is the UNION of the (grown) hot edge and the panel's
    // LIVE rect — `regions` is Region's default property and Intersection
    // defaults to Combine, so a nested Region unions in. Both halves matter:
    // binding the region to the panel alone leaves the pointer outside it
    // while the panel is still sliding, and a single static centred band
    // drops the pointer whenever it entered off-centre. caelestia's drawers
    // size their regions off the live animation for exactly this reason.
    mask: Region {
        item: hotEdge

        Region {
            item: panel
        }
    }

    // qmllint disable unqualified unresolved-type
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    // qmllint enable unqualified unresolved-type

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    // Top, not Overlay: the launcher and the power menu are Overlay modals and
    // must draw over the dock, not under it.
    WlrLayershell.layer: WlrLayer.Top

    // Grows while revealed so it MEETS the panel: at rest the panel's bottom
    // edge sits barInset above the window's, and a 4px strip left a dead band
    // between the two that the pointer had to cross to reach the tiles. Staying
    // full-width is what lets the dock be entered anywhere along the edge and
    // still hold while it slides in.
    Item {
        id: hotEdge

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.revealed ? Config.barInset + Config.dockHotEdge : Config.dockHotEdge
    }

    // 🚨 A HoverHandler, NOT a MouseArea. A hover-enabled MouseArea only
    // reports hover while nothing above it has it, so every tile's own
    // MouseArea stole it: the pointer reached a tile, containsMouse went false,
    // and the dock retracted out from under the click it was about to receive.
    // Pointer handlers are passive and run in parallel with child grabs, which
    // is why quickshell's own ReloadPopup.qml uses one for the same job.
    Item {
        anchors.fill: parent

        HoverHandler {
            id: hoverHandler

            onHoveredChanged: {
                if (hoverHandler.hovered)
                    hideDelay.stop();
                else
                    hideDelay.restart();
            }
        }
    }

    Timer {
        id: hideDelay

        interval: Config.dockHideDelayMs
    }

    Rectangle {
        id: panel

        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.revealed ? Config.barInset : -Config.dockHeight
        anchors.horizontalCenter: parent.horizontalCenter
        border.color: Theme.edge
        border.width: Config.hairline
        color: Theme.groundBase
        height: Config.dockHeight
        radius: Config.dockRadius
        width: row.implicitWidth + Config.dockPad * 2

        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: Config.dockRevealMs
                easing.type: Easing.OutCubic
            }
        }

        // Swallows clicks that land on the panel but miss a tile, so they do
        // not fall through to the window behind. First sibling, so every tile's
        // own MouseArea still stacks above it.
        MouseArea {
            anchors.fill: parent
        }

        Row {
            id: row

            anchors.centerIn: parent
            spacing: Config.dockGap

            Repeater {
                model: Config.dockApps

                Item {
                    id: tile

                    required property string modelData
                    // Resolved off the model rather than through
                    // DesktopEntries.byId(): a plain function call is not a
                    // dependency, so it would never re-evaluate when the
                    // manager rescans after a .desktop file changes.
                    readonly property var entry: DesktopEntries.applications.values.find(e => e.id === tile.modelData) ?? null
                    // The desktop id's last dot-segment: com.mitchellh.ghostty
                    // matches a `com.mitchellh.ghostty` window class and a bare
                    // `thunar` matches `thunar`, from one key either way. Same
                    // rule Config.windowGlyphs already uses for the bar pills.
                    readonly property string classKey: tile.modelData.split(".").pop().toLowerCase()
                    // appId, not lastIpcObject.class: the latter is only
                    // populated by a `clients` fetch, so a window opened after
                    // the shell started never matches. See WorkspacesWidget.
                    readonly property var windows: [...Hyprland.toplevels.values].filter(t => (t.wayland?.appId ?? "").toLowerCase().includes(tile.classKey))
                    readonly property string iconSource: tile.entry ? Quickshell.iconPath(tile.entry.icon, true) : ""

                    height: Config.dockHeight - Config.dockPad
                    width: Config.dockTileSize

                    // 🚨 Hover marks the tile with an OUTLINE, not a lighter
                    // ground. The only ground above bgSecondary is bgTertiary,
                    // and that is the trap tier: fg-primary on it measures 1.70
                    // in solarized-dark and 1.67 in solarized-light, so the
                    // glyph would vanish. Neutral fg-secondary rather than the
                    // accent, because a pointer affordance is not "the focused
                    // thing" the one-accent rule is about.
                    Rectangle {
                        anchors.top: parent.top
                        border.color: Theme.inkSecondary
                        border.width: area.containsMouse ? Config.hairline : 0
                        color: Theme.groundRaised
                        height: Config.dockTileSize
                        radius: Config.dockTileRadius
                        width: Config.dockTileSize

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: Config.dockIconSize
                            source: tile.iconSource
                            visible: tile.iconSource !== ""
                        }

                        // An app with no themed icon still renders something —
                        // the same contract the workspace pills' glyph fallback
                        // has. fg-primary because bg-secondary is a lit ground.
                        Text {
                            anchors.centerIn: parent
                            color: Theme.inkPrimary
                            font.family: Config.guiFont
                            font.pixelSize: Config.dockIconSize
                            text: Config.windowGlyph(tile.classKey)
                            visible: tile.iconSource === ""
                        }
                    }

                    // Kept against the artboard, which draws no indicator: a
                    // dock that cannot show what is running is a strictly worse
                    // SUPER+D. Amendment E in the frozen _plans/archive/QUICKSHELL_SHELL.md.
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.signalFocus
                        height: Config.dockIndicator
                        radius: Config.radiusPill
                        visible: tile.windows.length > 0
                        width: Config.dockIndicator
                    }

                    MouseArea {
                        id: area

                        anchors.fill: parent
                        hoverEnabled: true

                        // 🚨 activate() on the workspace, never a raw
                        // Hyprland.dispatch(): it is the one call Quickshell
                        // translates for the Lua config provider, which is the
                        // whole reason Phase 2 converted 30 dispatch sites.
                        // HyprlandToplevel exposes no focus or move invokable.
                        onClicked: {
                            if (tile.windows.length > 0)
                                tile.windows[0].workspace?.activate();
                            else
                                tile.entry?.execute();
                        }
                    }
                }
            }

            // Hairline between the pinned apps and the launcher, matching the
            // bar's group separators — same tier, same colour.
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.groundRaised
                height: 26
                width: Config.hairline
            }

            Item {
                height: Config.dockHeight - Config.dockPad
                width: Config.dockTileSize

                // The one accent ground in the dock, mirroring the bar's
                // launcher chip: a single fixed anchor, everything else neutral.
                Rectangle {
                    anchors.top: parent.top
                    color: Qt.alpha(Theme.signalFocus, launcherArea.containsMouse ? 0.2 : 0.14)
                    height: Config.dockTileSize
                    radius: Config.dockTileRadius
                    width: Config.dockTileSize

                    Text {
                        anchors.centerIn: parent
                        color: Theme.signalFocus
                        font.family: Config.guiFont
                        font.pixelSize: Config.dockIconSize
                        text: Config.dockLauncherGlyph
                    }
                }

                MouseArea {
                    id: launcherArea

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: root.launcherRequested()
                }
            }
        }
    }
}
