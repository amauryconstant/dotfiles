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
// Temperature was the third source the design asks for and was missing until
// 2026-09-13, on the grounds that it is not a percentage until something names
// the threshold it is a percentage OF. The hardware names it: every driver that
// exposes temp1_input beside a temp1_crit (or temp1_max) has declared its own
// ceiling, so the percentage is the hardware's, not an invented constant. A
// sensor with no ceiling is skipped rather than given a default.
//
// 🚨 hwmon numbering is NOT stable across boots and FileView cannot glob, so
// the directory is resolved ONCE by a one-shot process that matches on `name`.
// A path baked in at apply time would point at a different chip after a reboot.
//
// 🚨 Temperature does NOT join `highest`. Measured on this machine at idle: the
// CPU package sits at 78 of a 100 degree ceiling, which is 78% while load and
// memory are well under it. Feeding that into `highest` would pin the bar's one
// number to the thermometer for the life of the session and turn a load readout
// into a temperature readout. The popover draws it; the bar does not.
Singleton {
    id: root

    // 0..100, integers — these are read as numbers on a bar, not plotted.
    property int cpu: 0
    property int memory: 0
    // Seconds since boot, for the meters popover. Not a percentage and never
    // on the bar: it is context for the two numbers that are.
    property int uptime: 0

    // Degrees C, and the ceiling the driver itself declares. -1 until the
    // resolver answers; 0 on a machine with no usable sensor, which is the
    // desktop chassis and anything whose driver is not in the list below.
    property int temperature: -1
    property int tempCeiling: 0
    property string tempInputPath: ""
    property string tempCeilingPath: ""

    readonly property bool hasTemperature: root.temperature >= 0 && root.tempCeiling > 0
    // The percentage the bands and the fill read, expressed against the
    // driver's own ceiling rather than a number this repo picked.
    readonly property int tempPercent: root.hasTemperature ? Math.round(100 * root.temperature / root.tempCeiling) : 0

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

    // "<input path> <ceiling path>", or nothing at all.
    function readSensorPaths(line: string): void {
        const parts = line.trim().split(" ");
        if (parts.length !== 2)
            return;
        root.tempInputPath = parts[0];
        root.tempCeilingPath = parts[1];
    }

    function readUptime(text: string): void {
        root.uptime = Math.floor(Number(text.trim().split(/\s+/)[0]) || 0);
    }

    // Formatted where it is read rather than stored as a string: the popover is
    // the only consumer, and a number survives a locale change.
    function uptimeText(): string {
        const days = Math.floor(root.uptime / 86400);
        const hours = Math.floor((root.uptime % 86400) / 3600);
        const minutes = Math.floor((root.uptime % 3600) / 60);
        if (days > 0)
            return `${days}d ${hours}h`;
        if (hours > 0)
            return `${hours}h ${minutes}m`;
        return `${minutes}m`;
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

    // millidegrees in the file, degrees everywhere above it.
    FileView {
        id: tempInput

        path: root.tempInputPath
        printErrors: false

        onLoaded: root.temperature = Math.round(Number(tempInput.text().trim()) / 1000)
    }

    // Read once: a thermal ceiling is a property of the chip, not a reading.
    FileView {
        id: tempCeilingFile

        path: root.tempCeilingPath
        printErrors: false

        onLoaded: root.tempCeiling = Math.round(Number(tempCeilingFile.text().trim()) / 1000)
    }

    // One shot at startup. Preference order is CPU-package drivers only --
    // acpitz is a chassis sensor with no ceiling of its own, and a fan
    // controller reporting 30 degrees is not what "the machine is hot" means.
    Process {
        running: true
        command: ["sh", "-c", "for w in coretemp k10temp zenpower; do for d in /sys/class/hwmon/hwmon*; do [ \"$(cat \"$d/name\" 2>/dev/null)\" = \"$w\" ] || continue; [ -r \"$d/temp1_input\" ] || continue; for c in temp1_crit temp1_max; do [ -r \"$d/$c\" ] && { echo \"$d/temp1_input $d/$c\"; exit 0; }; done; done; done"]

        stdout: SplitParser {
            onRead: line => root.readSensorPaths(line)
        }
    }

    FileView {
        id: uptimeFile

        path: "/proc/uptime"
        printErrors: false

        onLoaded: root.readUptime(uptimeFile.text())
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            stat.reload();
            meminfo.reload();
            uptimeFile.reload();
            if (root.tempInputPath !== "")
                tempInput.reload();
        }
    }
}
