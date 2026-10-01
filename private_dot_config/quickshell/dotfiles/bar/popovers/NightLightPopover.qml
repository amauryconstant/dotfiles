pragma ComponentBehavior: Bound

import "../"
import "../../"
import Quickshell
import Quickshell.Io
import QtQuick

// Night-light popover, surface 13: the continuous colour-temperature control
// the preset picker (desktop/nightlight-config) stood in for.
//
// 🚨 The widget it hangs off is a MODE INDICATOR -- NightLightWidget is
// `visible` only while the filter is on -- so this popover is reachable only
// while the filter is on. Turning it ON stays SUPER+N and the Toggle submenu.
// That is surface 5's rule (a mode indicator draws only while its state is
// active), not a gap: a popover on a chip that is not there cannot be opened.
//
// The inventory's caveat that any preview inside this surface would be lying
// does not apply. There is no preview: the slider moves the real screen as it
// is dragged, so the screen IS the readout.
//
// 🚨 Every apply shells out to nightlight-config, which already persists the
// preference nightlight-toggle turns on with, starts hyprsunset when it is not
// running, and verifies by reading the temperature back -- `hyprctl hyprsunset`
// exits 0 even on invalid input. Duplicating any of that here would give the
// slider and the picker two different notions of the same setting.
BarPopover {
    id: root

    // What the file says, and what the slider is showing. They differ only
    // between a drag step and the debounced write below.
    property int tempK: Config.nightlightDefaultK
    // Non-zero while a write is queued: the file watch must not pull the slider
    // back to the value we are in the middle of leaving.
    property int pendingK: 0

    readonly property real fraction: (root.tempK - Config.nightlightMinK) / (Config.nightlightMaxK - Config.nightlightMinK)

    function apply(kelvin: int): void {
        const clamped = Math.max(Config.nightlightMinK, Math.min(Config.nightlightMaxK, kelvin));
        root.tempK = clamped;
        root.pendingK = clamped;
        // One process per drag would be one per pixel. The screen keeps up
        // because hyprsunset transitions anyway; the writes do not need to.
        debounce.restart();
    }

    function fromFraction(value: real): int {
        const raw = Config.nightlightMinK + value * (Config.nightlightMaxK - Config.nightlightMinK);
        return Math.round(raw / Config.nightlightStepK) * Config.nightlightStepK;
    }

    footerCommand: null
    footerLeft: root.keyboardMode ? qsTr("←→ adjust · esc close") : ""
    footerRight: `${root.tempK} K`
    glyph: Config.nightlightGlyph
    // The slider, then the off row.
    navCount: 2
    title: qsTr("Night light")

    onActivated: index => {
        if (index === 1)
            Quickshell.execDetached(Config.detach.concat([`${Config.scriptsDir}/desktop/nightlight-toggle`]));
    }
    onStepped: delta => {
        if (root.selected === 0)
            root.apply(root.tempK + delta * Config.nightlightStepK);
    }

    Item {
        height: Config.fontBody + 2
        width: parent.width

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.inkPrimary
            font.family: Config.guiFont
            font.pixelSize: Config.fontBody
            text: qsTr("Temperature")
        }

        // The number is the carrier; the fill under it is decoration. Kelvin
        // rather than a percentage: a colour temperature has a unit, and the
        // presets this replaces named it.
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.inkPrimary
            font.family: Config.terminalFont
            font.pixelSize: Config.fontBody
            text: `${root.tempK} K`
        }
    }

    PopoverSlider {
        showRing: root.keyboardMode && root.selected === 0
        step: Config.nightlightStepK / (Config.nightlightMaxK - Config.nightlightMinK)
        value: root.fraction
        width: parent.width

        onMoved: v => root.apply(root.fromFraction(v))
    }

    PopoverRow {
        cursor: root.keyboardMode && root.selected === 1
        glyph: Config.nightlightOffGlyph
        label: qsTr("Turn off")
        showRing: root.keyboardMode && root.selected === 1

        onClicked: {
            Quickshell.execDetached(Config.detach.concat([`${Config.scriptsDir}/desktop/nightlight-toggle`]));
            root.close();
        }
    }

    Timer {
        id: debounce

        interval: Config.motionSlow

        onTriggered: {
            Quickshell.execDetached(Config.detach.concat([`${Config.scriptsDir}/desktop/nightlight-config`, String(root.pendingK)]));
            root.pendingK = 0;
        }
    }

    // The preference is a plain file, so the picker and the slider stay in step
    // without either knowing about the other.
    FileView {
        id: prefFile

        path: `${Quickshell.env("HOME")}/.local/state/dotfiles/nightlight-temp`
        printErrors: false
        watchChanges: true

        onFileChanged: prefFile.reload()
        onLoaded: {
            if (root.pendingK !== 0)
                return;
            const parsed = parseInt(prefFile.text().trim(), 10);
            if (!isNaN(parsed))
                root.tempK = parsed;
        }
    }
}
