pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// System load, for the bar's single meter readout (design page Shell-04-Bar).
//
// Genuinely new: Waybar's config here carried no cpu, memory or temperature
// module at all, so there is nothing to port and no configured sensor to
// inherit. Read straight from /proc rather than through a script and
// WaybarJsonSource — two files and eleven lines of arithmetic do not need a
// process, and a process would have to be respawned on every tick.
//
// ponytail: CPU and memory only. The design's readout is "the highest of CPU,
// memory and temperature", but a temperature is not a percentage until someone
// picks the threshold it is a percentage OF, and this repo has never named a
// hwmon path or a critical value. Add the third source when a machine actually
// needs it; the `highest` binding below is where it goes.
Singleton {
    id: root

    // 0..100, integers — these are read as numbers on a bar, not plotted.
    property int cpu: 0
    property int memory: 0

    // What the bar draws. One number, never two: a second permanent readout
    // beside the battery is exactly the noise the accent rule exists to stop.
    readonly property int highest: Math.max(root.cpu, root.memory)
    // Which source is currently loudest, for the tooltip — so the number is
    // attributable without a second widget.
    readonly property string source: root.cpu >= root.memory ? qsTr("CPU") : qsTr("Memory")

    // Previous /proc/stat sample. CPU load is a DELTA: the file carries
    // cumulative jiffies since boot, so a single read reports the average since
    // startup and never moves.
    property double lastIdle: 0
    property double lastTotal: 0

    function readCpu(text: string): void {
        const fields = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        if (fields.length < 5)
            return;
        const total = fields.reduce((a, b) => a + b, 0);
        // idle + iowait: both are time the CPU had nothing to run.
        const idle = fields[3] + fields[4];
        const prevTotal = root.lastTotal;
        const prevIdle = root.lastIdle;
        root.lastTotal = total;
        root.lastIdle = idle;
        // The first sample has no predecessor to subtract from, and reporting
        // the since-boot average instead would be a number that never moves.
        if (prevTotal === 0)
            return;
        const dTotal = total - prevTotal;
        if (dTotal > 0)
            root.cpu = Math.round(100 * (1 - (idle - prevIdle) / dTotal));
    }

    function readMemory(text: string): void {
        const value = key => {
            const m = new RegExp(`^${key}:\\s+(\\d+)`, "m").exec(text);
            return m ? parseInt(m[1], 10) : 0;
        };
        const total = value("MemTotal");
        // MemAvailable, not MemFree: free excludes reclaimable cache and reads
        // as a permanently full machine.
        const available = value("MemAvailable");
        if (total > 0)
            root.memory = Math.round(100 * (1 - available / total));
    }

    FileView {
        id: stat

        path: "/proc/stat"
        printErrors: false

        onLoaded: root.readCpu(stat.text())
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        printErrors: false

        onLoaded: root.readMemory(meminfo.text())
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            stat.reload();
            meminfo.reload();
        }
    }
}
