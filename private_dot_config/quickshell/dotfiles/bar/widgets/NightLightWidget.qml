import "../"
// Config is only reached from inside a template literal, which the linter
// does not trace, so the import reads as unused while being load-bearing.
// qmllint disable unused-imports
import "../../"
// qmllint enable unused-imports
import QtQuick

// Mode indicator (surface §5). Until 2026-09-12 the blue-light filter was the
// one switched-on state with no marker anywhere — nightlight-toggle sent a
// notification that timed out, and after that the only way to know was to
// look at the screen and wonder.
//
// Like every mode indicator here the glyph is the whole carrier: no colour,
// because `signalWarn` measures 2.05 in rose-pine-dawn and colouring a state
// that is not a fault would make it less visible, not more.
BarWidget {
    id: root

    icon: source.text
    tooltipText: source.tooltip
    // Off is the normal case, and normal shows nothing.
    visible: source.text !== ""

    signal popoverRequested

    function refresh(): void {
        source.refresh();
    }

    // The click opens the popover rather than toggling, because the popover is
    // only reachable while the filter is on and carries the off row itself. A
    // chip that both opens a surface and performs an action is the one shape a
    // user cannot undo by looking.
    onClicked: root.popoverRequested()

    WaybarJsonSource {
        id: source

        command: [`${Config.scriptsDir}/desktop/nightlight-indicator`]
        oneShot: true
    }

    // Safety net only. The real signal is the IPC refresh nightlight-toggle
    // sends, the same arrangement IdleWidget has with idle-toggle.
    Timer {
        interval: 30000
        repeat: true
        running: true

        onTriggered: source.refresh()
    }
}
