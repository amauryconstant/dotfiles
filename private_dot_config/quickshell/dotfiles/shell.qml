pragma ComponentBehavior: Bound

import "bar"
import Quickshell
import Quickshell.Io

// Root scope. Deliberately thin: it wires IPC and fans the bar out over the
// screens, and owns no widget of its own.
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

    // SUPER+SHIFT+B, from hypr/conf.d/quickshell.lua. SUPER+B still toggles
    // Waybar, so either bar can be hidden while both run.
    IpcHandler {
        target: "bar"

        function toggle(): void {
            barVariants.visible = !barVariants.visible;
        }
    }

    // idle-toggle and idle-toggle-nolock call this after flipping state:
    //   quickshell -c dotfiles ipc call idle refresh
    // The indicator is otherwise only re-read on its 30s safety-net timer.
    IpcHandler {
        target: "idle"

        function refresh(): void {
            for (const bar of barVariants.instances)
                bar.refreshIdle();
        }
    }

    Variants {
        id: barVariants

        property bool visible: true

        model: Quickshell.screens

        Bar {
            visible: barVariants.visible
        }
    }
}
