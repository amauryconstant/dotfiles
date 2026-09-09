pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Reads the theme's format-neutral colorset at runtime. colors.sh is uniform
// (readonly KEY="#hex"), so parsing it costs ~15 lines and adds no new
// per-theme file. If the colors.toml project lands later, only this file
// changes: swap the path and the parser.
//
// The colorset now names ROLES rather than the modules that spend them (design
// page Shell-01-Colour), so this file no longer translates: a property here
// reads the key of the same name. What is left is the DERIVED tier — the
// materials no theme binds because they are computed from a ground, plus the
// three picks no single token can make across all eight colorsets.
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

    // ---- Tier 1 · GROUND — "what surface am I on?". Fixed at three, plus one
    // material. A theme that cannot supply three separable surfaces is
    // unsupportable, not degraded.
    // Bars, panels, popovers, OSD. The only ground that may carry quiet text.
    readonly property color groundBase: root.c.GROUND_BASE ?? "#1e1e2e"
    // Rows at hover, chips, slider tracks. Carries inkPrimary only.
    readonly property color groundRaised: root.c.GROUND_RAISED ?? "#313244"
    // Anything that casts a shadow — notification cards, tooltips, modals.
    readonly property color groundFloat: root.c.GROUND_FLOAT ?? "#181825"
    // 🚨 NOT a ground — a material, and the one tier that never accepts text.
    // inkPrimary on it measures 1.67 in solarized-light. Meter and trough fill,
    // scrollbar thumb, the body of a disabled control.
    readonly property color fillInert: root.c.FILL_INERT ?? "#45475a"

    // ---- Tier 2 · INK — "how loud is this text?". One required, a second
    // offered per ground.
    readonly property color inkPrimary: root.c.INK_PRIMARY ?? "#cdd6f4"
    // Dates, footers, exec lines, empty states, secondary outlines. Legal on
    // groundBase only — the other two grounds carry inkPrimary alone.
    //
    // 🚨 OFFERED, not guaranteed. Design page 01: the quiet ink is "offered per
    // ground, per theme, and withdrawn where it fails". It measures 4.02 on
    // groundBase in rose-pine-dawn and 4.13 in the solarized pair — under the
    // 4.5 a body of text owes — so in those themes the ground carries
    // inkPrimary alone and the hierarchy is one step flatter there. Withdrawing
    // by MEASUREMENT rather than by editing two palettes fixes every colorset,
    // including any added later, and turns page 13's "solarized ink-primary is
    // a colorset bug" into something no theme has to remember.
    readonly property color inkSecondaryOffered: root.c.INK_SECONDARY ?? "#bac2de"
    readonly property color inkSecondary: root.contrast(root.inkSecondaryOffered, root.groundBase) >= 4.5 ? root.inkSecondaryOffered : root.inkPrimary

    // 🚨 Read, never drawn. INK_CONTRAST_CANDIDATE is retired as a drawing
    // token (it has no site left once inkOnSignal exists) but is still one of
    // the two candidates that computation picks between, so it must stay
    // readable. INK_MUTED is not bound here AT ALL: it is banned as text (2.48
    // worst) and fails 3:1 as an outline, so it survives in the colorset only
    // for the terminal scripts, and every former site here is now inkSecondary
    // or the `disabled` derivation.
    readonly property color inkContrastCandidate: root.c.INK_CONTRAST_CANDIDATE ?? "#11111b"

    // ---- Tier 3 · SIGNAL — "what is the system telling me?". Fixed at five,
    // mutually separable in every theme. This is the one hard floor.
    // The one accent: attention, selection, the active thing.
    readonly property color signalFocus: root.c.SIGNAL_FOCUS ?? "#89b4fa"
    readonly property color signalError: root.c.SIGNAL_ERROR ?? "#f38ba8"
    // Degraded but working — including the battery's 20-30% band, which used
    // to spend ACCENT_URGENT_SECONDARY (peach) for no stated reason.
    readonly property color signalWarn: root.c.SIGNAL_WARN ?? "#f9e2af"
    // Confirmation the user asked for. NOT "normal" — a healthy system is
    // neutral, not green.
    readonly property color signalOk: root.c.SIGNAL_OK ?? "#a6e3a1"
    readonly property color signalInfo: root.c.SIGNAL_INFO ?? "#94e2d5"

    // ---- Tier 5 · IDENTITY — "which of several like things is this?".
    // Elastic and never load-bearing: always redundant with a label, glyph or
    // position, so a theme answering with zero slots still renders correctly.
    // Excluded by measurement, not taste: maroon (ACCENT_PERFORMANCE) sits too
    // near signalError, and lavender/sapphire/sky (ACCENT_BORDER,
    // ACCENT_SECONDARY, ACCENT_ALTERNATIVE) too near signalFocus.
    readonly property color identity1: root.c.IDENTITY_1 ?? "#f5e0dc"
    readonly property color identity2: root.c.IDENTITY_2 ?? "#f2cdcd"
    readonly property color identity3: root.c.IDENTITY_3 ?? "#f5c2e7"
    readonly property color identity4: root.c.IDENTITY_4 ?? "#cba6f7"
    readonly property color identity5: root.c.IDENTITY_5 ?? "#fab387"

    // ---- Tier 4 · MATERIALS — derived, never named by a theme. These end the
    // hand-repetition of the same four rules on every surface in the tree.

    // Every 1px hairline, border and separator. One token means a separator can
    // never out-shout the content beside it.
    readonly property color edge: root.groundRaised
    // One opaque step up the ground stack: base -> raised, float -> raised.
    // Opaque, so it never composites differently over a tinted row.
    readonly property color hover: root.groundRaised
    // Ink-derived, so it darkens in Latte and lightens in Mocha with no
    // per-flavour value. Drawn OVER the current ground.
    readonly property color press: Qt.alpha(root.inkPrimary, 0.08)
    // 🚨 The selection tint reaches only 1.10-1.98 against its own ground, so
    // it can never carry a selection alone. Every site pairs it with a
    // signal-coloured glyph, a weight change or a return mark.
    readonly property color select: Qt.alpha(root.signalFocus, 0.13)
    // No fixed token survives all eight colorsets; resolves to inkPrimary in
    // both Catppuccins. 2px outside the paint, never animated.
    readonly property color focusRing: root.contrast(root.signalFocus, root.groundRaised) >= root.contrast(root.inkPrimary, root.groundRaised) ? root.signalFocus : root.inkPrimary

    // Text drawn ON a signalFocus fill — the focused workspace pill, the
    // notification count badge, a primary card action, the launcher selection.
    //
    // 🚨 Design page 01 binds this to groundBase outright; pages 04 and 07 call
    // it computed. The computation wins because it cannot lose: it picks
    // whichever of inkContrastCandidate / groundBase contrasts MORE against the
    // accent, and groundBase is one of the two candidates, so the result is >=
    // the fixed binding in every theme. FG_CONTRAST alone is not an option —
    // gruvbox-dark's lands at 1.49:1 on its own accent, which would make the
    // focused workspace number unreadable in that theme.
    readonly property color inkOnSignal: root.contrast(root.inkContrastCandidate, root.signalFocus) >= root.contrast(root.groundBase, root.signalFocus) ? root.inkContrastCandidate : root.groundBase

    // 🚨 Disabled is OPACITY, never a token swap: swapping makes a disabled
    // control look like a different role — a greyed error reads as a muted
    // label. It is transient and non-interactive (the siblings of a row with an
    // operation in flight are its only site), so it floors at 3:1 rather than
    // 4.5. Anything at or below 55% measures 1.90-2.66 and fails in six of the
    // eight colorsets, so the value is measured against the LIVE theme rather
    // than fixed: the lowest 5% step still clearing 3:1 on groundBase.
    readonly property real disabledOpacity: {
        for (let a = 0.6; a < 1.0; a += 0.05) {
            const blended = Qt.rgba(root.inkSecondary.r * a + root.groundBase.r * (1 - a), root.inkSecondary.g * a + root.groundBase.g * (1 - a), root.inkSecondary.b * a + root.groundBase.b * (1 - a), 1);
            if (root.contrast(blended, root.groundBase) >= 3.0)
                return a;
        }
        return 1.0;
    }

    // 🚨 The modal scrim, the one value NO token can supply. A scrim's job is
    // to darken whatever is behind it, which is a shade rather than a theme
    // colour. Measured luminance, 2026-09-02:
    //   BG_OVERLAY  is 0.71-0.96 in all four LIGHT themes (latte 0.81,
    //               gruvbox-light 0.72, rose-pine-dawn 0.96, solarized-light
    //               0.81) — a scrim built from it washes the screen out.
    //   FG_CONTRAST inverts per theme: 0.006 in mocha but 0.88 in
    //               gruvbox-dark and 0.92 in solarized-dark.
    // So neither is usable, and this is a deliberate literal — the same
    // exemption the fallbacks above have, for the same reason. Alpha lives in
    // Config so the depth stays tunable without touching the colour.
    readonly property color scrim: Qt.rgba(0, 0, 0, 1)

    // 🚨 Anything drawn ON the scrim needs the same per-theme pick inkOnSignal
    // needs, and for a sharper reason: the scrim is dark in EVERY theme, so a
    // light theme's own foregrounds land on it at 1.81 (gruvbox-light) and
    // 2.63 (latte) — the labels simply are not there. Picking the better of
    // inkPrimary / groundBase takes the worst case across all 8 to 6.64.
    readonly property color fgOnScrim: root.contrast(root.inkPrimary, root.scrim) >= root.contrast(root.groundBase, root.scrim) ? root.inkPrimary : root.groundBase

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
                // 🚨 [A-Z0-9_]+, not [A-Z_]+: IDENTITY_1..5 carry a digit, and
                // a character class without one drops them silently — the
                // properties then fall back to hardcoded Catppuccin with no
                // error anywhere, which is this file's whole failure mode.
                const match = /^readonly\s+([A-Z0-9_]+)="(#[0-9a-fA-F]{3,8})"/.exec(line);
                if (match)
                    map[match[1]] = match[2];
            }
            root.c = map;
        }
    }
}
