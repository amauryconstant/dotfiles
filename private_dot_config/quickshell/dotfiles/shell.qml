pragma ComponentBehavior: Bound

import "bar"
import "launcher"
import "osd"
import "power"
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

        // Returns the state actually reached, not the one intended, so the
        // toggle script can report truthfully — the same reasoning
        // waybar-toggle applies after killing or starting Waybar.
        function toggle(): string {
            barVariants.visible = !barVariants.visible;
            return barVariants.visible ? "shown" : "hidden";
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

    // SUPER+SHIFT+D, from hypr/conf.d/quickshell.lua, via quickshell-toggle.
    // Coexists with Wofi on SUPER+D rather than replacing the binding: Wofi
    // still serves cliphist and every --dmenu caller, and this only has to be
    // better as an app launcher before SUPER+D moves.
    IpcHandler {
        target: "launcher"

        function toggle(): string {
            return launcher.toggle();
        }
    }

    // SUPER+ALT+Q, coexisting with wlogout on SUPER+SHIFT+Q for the same
    // reason.
    IpcHandler {
        target: "power"

        function toggle(): string {
            return power.toggle();
        }
    }

    // One OSD, not one per screen: it follows the focused monitor itself.
    Osd {}

    // Both are single windows that follow the focused monitor: a launcher and a
    // power menu are modals you summoned, so they belong where you are looking.
    Launcher {
        id: launcher
    }

    PowerMenu {
        id: power
    }

    Variants {
        id: barVariants

        property bool visible: true

        model: Quickshell.screens

        Bar {
            visible: barVariants.visible

            onLauncherRequested: launcher.toggle()
        }
    }
}
