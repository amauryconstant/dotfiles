import "../"
// Config is only reached from inside a template literal, which the linter
// does not trace, so the import reads as unused while being load-bearing.
// qmllint disable unused-imports
import "../../"
// qmllint enable unused-imports
import Quickshell
import QtQuick

// Mode indicator (surface §5) and the reachable stop affordance surface §15
// asks for. Both halves were missing until 2026-09-12: `screenrecord` fired
// `pkill -RTMIN+8 waybar` on start and stop, and no module in either bar had
// ever listened to that signal.
//
// 🚨 The elapsed time ticks in QML off a start epoch the script reports once,
// NOT by re-running the script every second. The epoch is the PID file's
// mtime, so a shell restart mid-recording still shows the true elapsed time —
// a timestamp captured when this widget first noticed would restart at zero.
BarWidget {
    id: root

    readonly property int startedAt: parseInt(source.alt, 10) || 0

    icon: source.text
    label: root.startedAt > 0 ? root.format(ticker.now - root.startedAt) : ""
    // Digits only line up fixed-pitch, and this label changes width every
    // second — a proportional face would reflow the whole bar as it counts.
    monoLabel: true
    tooltipText: source.tooltip
    visible: source.text !== ""

    function format(seconds: int): string {
        if (seconds < 0)
            return "0:00";
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        const s = seconds % 60;
        const pad = n => String(n).padStart(2, "0");
        return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${m}:${pad(s)}`;
    }

    function refresh(): void {
        source.refresh();
    }

    // screenrecord is a toggle, so the stop affordance is the same script the
    // keybinding runs — no second code path that could disagree about state.
    onClicked: Quickshell.execDetached(Config.detach.concat([`${Config.scriptsDir}/desktop/screenrecord`]))

    WaybarJsonSource {
        id: source

        command: [`${Config.scriptsDir}/desktop/recording-indicator`]
        oneShot: true
    }

    // Only the DISPLAY ticks here; nothing is re-read from disk.
    Timer {
        id: ticker

        property int now: Math.floor(Date.now() / 1000)

        interval: 1000
        repeat: true
        running: root.visible

        onTriggered: ticker.now = Math.floor(Date.now() / 1000)
    }

    // Safety net, for a recording that ends without the script reaching us.
    Timer {
        interval: 30000
        repeat: true
        running: true

        onTriggered: source.refresh()
    }
}
