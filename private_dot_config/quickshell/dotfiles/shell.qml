pragma ComponentBehavior: Bound

import "bar"
import "clipboard"
import "dock"
import "launcher"
import "menu"
import "notifications"
import "osd"
import "overview"
import "polkit"
import "power"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// Root scope. Deliberately thin: it wires IPC and fans the bar out over the
// screens, and owns no widget of its own.
// What is built and what is not: _research/QUICKSHELL_SURFACE_INVENTORY.md
ShellRoot {
    // theme-switcher calls this after swapping the themes/current symlink:
    //   quickshell -c dotfiles ipc call theme reload
    IpcHandler {
        target: "theme"

        function reload(): void {
            Theme.reload();
        }
    }

    // SUPER+B, from hypr/conf.d/quickshell.lua. The Waybar drop-in claims the
    // same key, which is safe because .chezmoiignore deploys exactly one of the
    // two — they are mutually exclusive, not concurrent.
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

    // SUPER+D, from hypr/conf.d/quickshell.lua, via quickshell-toggle. Took
    // the primary key on 2026-09-01; the Wofi binding is GATED OFF on the same
    // flag rather than shadowed, because duplicate binds stack in Hyprland.
    // Wofi itself stays — cliphist and every --dmenu caller.
    IpcHandler {
        target: "launcher"

        function toggle(): string {
            return launcher.toggle();
        }
    }

    // SUPER+C, taken from `cliphist list | wofi --dmenu | cliphist decode |
    // wl-copy`. The old binding is gated off on the same flag rather than
    // shadowed, and SUPER+SHIFT+C goes away entirely: deletion is Shift+Delete
    // inside the surface, so it no longer needs a key of its own.
    IpcHandler {
        target: "clipboard"

        function toggle(): string {
            return clipboard.toggle();
        }
    }

    // SUPER+SHIFT+Q, taken from wlogout the same way and on the same day.
    IpcHandler {
        target: "power"

        function toggle(): string {
            return power.toggle();
        }
    }

    // SUPER+grave (Phase 5.5), when Config.overviewEnabled. The handler stays
    // registered either way so `ipc show` still answers for it rather than
    // reporting a missing target, which reads like a broken wiring.
    IpcHandler {
        target: "overview"

        function toggle(): string {
            // Loader.item is typed QObject, so the linter cannot see the
            // Overview's own members through it. Suppressed over this one line.
            // qmllint disable missing-property
            return overviewLoader.item?.toggle() ?? "disabled";
            // qmllint enable missing-property
        }
    }

    // The `popovers` submap in hypr/conf.d/quickshell.lua, via quickshell-toggle.
    // This is the ONLY way a popover opens in keyboard mode: a pointer click
    // opens the same surface with no grab and no ring (design page 03).
    //
    // 🚨 Both the argument and the return type must be annotated or the handler
    // is never registered at all (ipchandler.hpp) — and `ipc call` exits 0 for
    // a missing target, so the failure would be silent from both ends.
    IpcHandler {
        target: "popover"

        function toggle(id: string): string {
            const name = Hyprland.focusedMonitor?.name ?? "";
            for (const bar of barVariants.instances) {
                if (bar.modelData?.name !== name)
                    continue;
                bar.togglePopover(id, true);
                return bar.openPopover === id ? "shown" : "hidden";
            }
            return "no bar";
        }
    }

    // SUPER+SHIFT+N, taken from swaync-client --toggle-panel. Phase 4 masks
    // swaync outright — one bus name, one owner — so this is a replacement
    // rather than a coexistence.
    IpcHandler {
        target: "notifications"

        function dnd(): string {
            return Notifications.toggleDnd() ? "on" : "off";
        }

        function toggle(): string {
            return centre.toggle();
        }
    }

    // One OSD, not one per screen: it follows the focused monitor itself.
    Osd {}

    // Toasts ARE one per screen, unlike every other window here: a
    // notification arrives on its own schedule, so it belongs where you are
    // looking now — or on the monitor its x-canonical-monitor hint names.
    NotificationPopups {}

    NotificationCentre {
        id: centre
    }

    // Both are single windows that follow the focused monitor: a launcher and a
    // power menu are modals you summoned, so they belong where you are looking.
    Launcher {
        id: launcher
    }

    PowerMenu {
        id: power
    }

    // Opened by a SOCKET rather than IPC or a binding: it answers a blocked
    // script. See MenuServer for why a socket and not an IpcHandler.
    MenuPicker {}

    ClipboardPicker {
        id: clipboard
    }

    // 🚨 Behind a Loader for the same reason NotificationServer is: a session
    // may have exactly ONE polkit agent and merely CONSTRUCTING PolkitAgent
    // registers it, so the only way not to own polkit is not to build this.
    // With the flag off, hypr/conf.d/polkit-gnome keeps the existing agent.
    Loader {
        active: Config.polkitOwned

        sourceComponent: PolkitDialog {}
    }

    // Behind a Loader rather than `visible: false`: with the flag off there is
    // no window, no screencopy and no carousel bindings at all.
    Loader {
        id: overviewLoader

        active: Config.overviewEnabled

        sourceComponent: Overview {}
    }

    Variants {
        id: barVariants

        property bool visible: true

        model: Quickshell.screens

        Bar {
            visible: barVariants.visible

            onLauncherRequested: launcher.toggle()
            onNotificationCentreRequested: centre.toggle()
        }
    }

    // The dock is furniture rather than a modal, so it fans out over the
    // screens like the bar — not onto the focused monitor like the rest.
    Variants {
        model: Quickshell.screens

        Dock {
            onLauncherRequested: launcher.toggle()
        }
    }
}
