import Quickshell.Io
import QtQuick

// Four widgets (kanata, voxtype, idle, notifications) consume scripts that
// emit Waybar's custom-module JSON: {text, alt, class, tooltip}. Rather than
// port that contract, the scripts are reused as-is and parsed here once.
//
// `oneShot` covers idle-indicator, which prints a single object and exits;
// the others stream a line per state change, which is why Waybar ran them
// with exec-persistent and why there is no polling here either.
Item {
    id: root

    required property list<string> command
    property bool oneShot: false
    property string alt: ""
    property string text: ""
    property string tooltip: ""

    function refresh(): void {
        if (root.oneShot && !proc.running)
            proc.running = true;
    }

    Process {
        id: proc

        command: root.command
        running: true

        stdout: SplitParser {
            onRead: line => {
                if (line.trim() === "")
                    return;
                try {
                    const parsed = JSON.parse(line);
                    root.text = parsed.text ?? "";
                    root.alt = parsed.alt ?? "";
                    root.tooltip = parsed.tooltip ?? "";
                } catch (e) {
                    // A script that dies mid-line must not take the bar with
                    // it; a malformed line is simply the previous state kept.
                }
            }
        }
    }

    // Persistent sources are restarted if the underlying daemon dies, the
    // same reconnect-forever behaviour the kanata-layer script has itself.
    Timer {
        interval: 5000
        repeat: true
        running: !root.oneShot

        onTriggered: {
            if (!proc.running)
                proc.running = true;
        }
    }
}
