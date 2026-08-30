pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Reads the theme's format-neutral colorset at runtime. colors.sh is already
// machine-generated, header-marked DO NOT EDIT MANUALLY, and uniform
// (readonly KEY="#hex"), so parsing it costs ~15 lines and adds no new
// per-theme file. If the colors.toml project lands later, only this file
// changes: swap the path and the parser.
Singleton {
    id: root

    // Raw KEY -> "#hex" map. Prefer the semantic properties below.
    property var c: ({})

    // Background hierarchy
    readonly property color bgPrimary: root.c.BG_PRIMARY ?? "#1e1e2e"
    readonly property color bgSecondary: root.c.BG_SECONDARY ?? "#181825"
    readonly property color bgTertiary: root.c.BG_TERTIARY ?? "#313244"
    readonly property color bgOverlay: root.c.BG_OVERLAY ?? "#313244"

    // Foreground hierarchy. themes/CLAUDE.md mandates fgPrimary on
    // bgSecondary/bgTertiary/bgOverlay — QML gets no automatic enforcement,
    // so follow that mapping by hand.
    readonly property color fgPrimary: root.c.FG_PRIMARY ?? "#cdd6f4"
    readonly property color fgSecondary: root.c.FG_SECONDARY ?? "#a6adc8"
    readonly property color fgMuted: root.c.FG_MUTED ?? "#6c7086"
    readonly property color fgContrast: root.c.FG_CONTRAST ?? "#1e1e2e"

    // Accents
    readonly property color accentPrimary: root.c.ACCENT_PRIMARY ?? "#cba6f7"
    readonly property color accentInfo: root.c.ACCENT_INFO ?? "#89dceb"
    readonly property color accentSuccess: root.c.ACCENT_SUCCESS ?? "#a6e3a1"
    readonly property color accentWarning: root.c.ACCENT_WARNING ?? "#f9e2af"
    readonly property color accentError: root.c.ACCENT_ERROR ?? "#f38ba8"
    readonly property color accentBorder: root.c.ACCENT_BORDER ?? "#cba6f7"

    // The colorset carries 24 variables; these ten complete the set. Waybar's
    // module mapping (waybar/CLAUDE.md) needs accentHighlight for interactive
    // widgets and accentUrgentSecondary for the battery 20-30% band, so an
    // incomplete Theme silently falls back to hardcoded Catppuccin here.
    readonly property color accentHighlight: root.c.ACCENT_HIGHLIGHT ?? "#cba6f7"
    readonly property color accentUrgentSecondary: root.c.ACCENT_URGENT_SECONDARY ?? "#fab387"
    readonly property color accentSecondary: root.c.ACCENT_SECONDARY ?? "#74c7ec"
    readonly property color accentTertiary: root.c.ACCENT_TERTIARY ?? "#fab387"
    readonly property color accentAlternative: root.c.ACCENT_ALTERNATIVE ?? "#89dceb"
    readonly property color accentSubtle: root.c.ACCENT_SUBTLE ?? "#f5e0dc"
    readonly property color accentSpecial: root.c.ACCENT_SPECIAL ?? "#f2cdcd"
    readonly property color accentMedia: root.c.ACCENT_MEDIA ?? "#cba6f7"
    readonly property color accentModification: root.c.ACCENT_MODIFICATION ?? "#f5c2e7"
    readonly property color accentPerformance: root.c.ACCENT_PERFORMANCE ?? "#eba0ac"

    // Called over IPC by theme-switcher; watchChanges only covers hand edits,
    // because switching swaps the themes/current SYMLINK and inotify on the
    // resolved path never fires.
    function reload(): void {
        file.reload();
    }

    FileView {
        id: file

        path: `${Quickshell.env("HOME")}/.config/themes/current/colors.sh`
        watchChanges: true

        onFileChanged: file.reload()
        onLoaded: {
            const map = {};
            for (const line of file.text().split("\n")) {
                const match = /^readonly\s+([A-Z_]+)="(#[0-9a-fA-F]{3,8})"/.exec(line);
                if (match)
                    map[match[1]] = match[2];
            }
            root.c = map;
        }
    }
}
