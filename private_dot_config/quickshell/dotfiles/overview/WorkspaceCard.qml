pragma ComponentBehavior: Bound

import "../"
import Quickshell.Wayland
import QtQuick

// One workspace in the carousel. The SAME component at all three scales, so
// the falloff curve is a property rather than three near-identical files.
//
// 🚨 The artboard's cards are portrait (520x640, 300x440, 200x340 — three
// different aspect ratios, none of which is a screen), so they cannot host a
// truthful window layout. Ours take the MONITOR's aspect and keep the
// artboard note's scale/opacity curve. See Amendment E.
//
// Each window is a LIVE capture via hyprland-toplevel-export-v1, falling back
// to the app glyph and title when there is no content. Amendment E originally
// declined ScreencopyView on the grounds that the artboard draws chrome rather
// than screenshots; that read the mockup right and the requirement wrong.
Rectangle {
    id: root

    required property var workspace
    required property var monitor
    required property bool focused
    required property real previewWidth
    // 🚨 The overview's OWN visibility, passed down explicitly. Not
    // `root.visible`: a PanelWindow's `visible` is a window property and does
    // not reliably reach its content item, so binding capture to it would
    // leave every window being captured for the life of the session.
    required property bool active

    // 🚨 hyprctl reports monitor width/height in PHYSICAL pixels while window
    // geometry is LOGICAL, and HyprlandMonitor mirrors both plus the scale.
    // Divide first or every window draws `scale`x oversized — invisible on a
    // scale-1 laptop and obvious on a scale-1.25 desktop.
    readonly property real logicalWidth: (root.monitor?.width ?? 1920) / (root.monitor?.scale ?? 1)
    readonly property real logicalHeight: (root.monitor?.height ?? 1080) / (root.monitor?.scale ?? 1)
    readonly property real previewHeight: root.previewWidth * root.logicalHeight / root.logicalWidth
    // The carousel's own falloff step, 1.0 / 0.69 / 0.46. Type and padding
    // scale with it, so a peripheral card is a smaller version of the same
    // drawing rather than the same text crammed into a smaller box.
    required property real detail

    // Every ground here is bg-overlay and every string on it is fg-primary:
    // an elevated surface takes fg-primary for ALL text per themes/CLAUDE.md,
    // and hierarchy comes from size and opacity, never from dimming the token.
    border.color: root.focused ? Theme.accentBorder : Theme.bgSecondary
    border.width: Config.hairline
    color: Theme.bgOverlay
    height: root.previewHeight + (root.focused ? Config.overviewFooterHeight : 0)
    radius: Config.overviewCardRadius
    width: root.previewWidth

    Item {
        id: preview

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.previewHeight

        Repeater {
            model: root.workspace?.toplevels.values ?? []

            Rectangle {
                id: win

                required property var modelData
                readonly property var ipc: win.modelData?.lastIpcObject ?? null
                readonly property bool captured: capture.hasContent
                readonly property real sx: preview.width / root.logicalWidth
                readonly property real sy: preview.height / root.logicalHeight

                color: Theme.bgSecondary
                height: Math.max(4, (win.ipc?.size?.[1] ?? 0) * win.sy)
                radius: Config.radiusChip * root.detail
                width: Math.max(4, (win.ipc?.size?.[0] ?? 0) * win.sx)
                // Window `at` is absolute in the layout, so the monitor's own
                // logical origin comes off before scaling into the card.
                x: ((win.ipc?.at?.[0] ?? 0) - (root.monitor?.x ?? 0)) * win.sx
                y: ((win.ipc?.at?.[1] ?? 0) - (root.monitor?.y ?? 0)) * win.sy

                // 🚨 Two conditions, both of which cost an afternoon: the view
                // must live in a RENDERED window or no recording context is
                // ever created, and `live: true` avoids captureFrame()'s
                // timing entirely — calling it from Component.onCompleted logs
                // "no recording context is ready" and captures nothing.
                //
                // Live only while the overview is up, so nothing is captured
                // at rest. Verified 2026-09-02 that Hyprland re-renders windows
                // on INACTIVE workspaces for this protocol: all six toplevels
                // reported hasContent with only one workspace active.
                ScreencopyView {
                    id: capture

                    anchors.fill: parent
                    captureSource: win.modelData?.wayland ?? null
                    live: root.active
                    visible: win.captured
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Config.gap * root.detail
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: Config.gap * root.detail
                    spacing: Config.gap * root.detail * 0.75
                    // The fallback, not an overlay: a label sitting on top of a
                    // screenshot is unreadable at every one of these scales.
                    // Below about 10px the chrome is noise rather than
                    // information, so a very small card shows bare rectangles.
                    visible: !win.captured && Config.fontSizeSmall * root.detail >= 6

                    Text {
                        color: Theme.fgPrimary
                        font.family: Config.guiFont
                        font.pixelSize: Config.fontSizeSmall * root.detail
                        text: Config.windowGlyph(win.ipc?.class ?? "")
                    }

                    Text {
                        color: Theme.fgPrimary
                        elide: Text.ElideRight
                        font.family: Config.terminalFont
                        font.pixelSize: Config.fontSizeTiny * root.detail
                        // Subordinate to the glyph beside it by opacity, not by
                        // a dimmer token — fg-secondary on an elevated ground is
                        // the pair themes/CLAUDE.md bans outright.
                        opacity: 0.75
                        text: win.modelData?.title ?? ""
                        width: parent.width - Config.padTight * root.detail
                    }
                }
            }
        }
    }

    // Only the focused card is annotated: the neighbours are peripheral
    // context and a number on each would compete with the one that matters.
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: "transparent"
        height: Config.overviewFooterHeight
        visible: root.focused

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            color: Theme.bgSecondary
            height: Config.hairline
        }

        Row {
            anchors.centerIn: parent
            spacing: Config.gap

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.accentPrimary
                height: Config.pillHeight
                radius: Config.radiusPill
                width: Math.max(height, label.implicitWidth + Config.padTight)

                Text {
                    id: label

                    anchors.centerIn: parent
                    // fgOnAccent, never fgContrast: the named token lands at
                    // 1.49:1 on gruvbox-dark's own accent.
                    color: Theme.fgOnAccent
                    font.family: Config.terminalFont
                    font.pixelSize: Config.fontSizeSmall
                    text: root.workspace?.name ?? ""
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fgPrimary
                font.family: Config.guiFont
                font.pixelSize: Config.fontSizeSmall
                text: {
                    const n = root.workspace?.toplevels.values.length ?? 0;
                    return n === 1 ? "1 window" : `${n} windows`;
                }
            }
        }
    }
}
