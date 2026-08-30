import Quickshell
import Quickshell.Io
import QtQuick

// Phase 0 skeleton: proves the whole pipeline (deployment, theme bridge, IPC
// reload, lint) on the cheapest possible payload — a clock.
// Roadmap: _plans/QUICKSHELL_SHELL.md
ShellRoot {
    // theme-switcher calls this after swapping the themes/current symlink:
    //   quickshell -c dotfiles ipc call theme reload
    IpcHandler {
        target: "theme"

        function reload(): void {
            Theme.reload();
        }
    }

    PanelWindow {
        color: Theme.bgPrimary
        implicitHeight: Config.barHeight

        anchors {
            left: true
            right: true
            top: true
        }

        Text {
            anchors.centerIn: parent
            color: Theme.fgPrimary
            font.family: Config.guiFont
            font.pixelSize: 13
            text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
        }

        SystemClock {
            id: clock

            precision: SystemClock.Minutes
        }
    }
}
