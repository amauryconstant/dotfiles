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

    // 🚨 Every fallback below is a VERBATIM copy of the matching value in
    // themes/catppuccin-mocha/colors.sh. Nine of them used to be the design
    // canvas's own Mocha palette instead, which is a different mapping —
    // the canvas makes mauve the primary accent, our colorset makes it blue,
    // and its background tier NAMES are offset by one from ours. Copy from
    // colors.sh, never from a mockup.

    // Background hierarchy
    readonly property color bgPrimary: root.c.BG_PRIMARY ?? "#1e1e2e"
    readonly property color bgSecondary: root.c.BG_SECONDARY ?? "#313244"
    readonly property color bgTertiary: root.c.BG_TERTIARY ?? "#45475a"
    readonly property color bgOverlay: root.c.BG_OVERLAY ?? "#181825"

    // Foreground hierarchy. themes/CLAUDE.md mandates fgPrimary on
    // bgSecondary/bgTertiary/bgOverlay — QML gets no automatic enforcement,
    // so follow that mapping by hand.
    readonly property color fgPrimary: root.c.FG_PRIMARY ?? "#cdd6f4"
    readonly property color fgSecondary: root.c.FG_SECONDARY ?? "#bac2de"
    readonly property color fgMuted: root.c.FG_MUTED ?? "#9399b2"
    readonly property color fgContrast: root.c.FG_CONTRAST ?? "#11111b"

    // Accents
    readonly property color accentPrimary: root.c.ACCENT_PRIMARY ?? "#89b4fa"
    readonly property color accentInfo: root.c.ACCENT_INFO ?? "#94e2d5"
    readonly property color accentSuccess: root.c.ACCENT_SUCCESS ?? "#a6e3a1"
    readonly property color accentWarning: root.c.ACCENT_WARNING ?? "#f9e2af"
    readonly property color accentError: root.c.ACCENT_ERROR ?? "#f38ba8"
    readonly property color accentBorder: root.c.ACCENT_BORDER ?? "#b4befe"

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

    // Text drawn ON an accentPrimary fill — the focused workspace pill, the
    // notification count badge, an active DND chip, the launcher's selection.
    //
    // 🚨 Neither fixed token works across the 8 themes. FG_CONTRAST is the one
    // named for this job, but gruvbox-dark's lands at 1.49:1 on its own accent
    // — the focused workspace number, the single most-read thing in the bar,
    // is unreadable there. BG_PRIMARY is better in gruvbox-dark (8.69) and
    // worse in gruvbox-light (2.19). So pick per theme, by measurement:
    // WCAG relative luminance, whichever of the two contrasts more. Verified
    // 2026-09-01 across all 8 colorsets; the worst case goes 1.49 -> 3.47.
    readonly property color fgOnAccent: root.contrast(root.fgContrast, root.accentPrimary) >= root.contrast(root.bgPrimary, root.accentPrimary) ? root.fgContrast : root.bgPrimary

    // WCAG 2.1 relative luminance / contrast ratio. Qt's `color` exposes r/g/b
    // as 0..1 floats already, so there is no hex parsing here.
    function luminance(colour: color): real {
        const channel = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * channel(colour.r) + 0.7152 * channel(colour.g) + 0.0722 * channel(colour.b);
    }

    function contrast(a: color, b: color): real {
        const la = root.luminance(a);
        const lb = root.luminance(b);
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
    }

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
