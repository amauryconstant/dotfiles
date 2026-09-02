#!/usr/bin/env python3
#MISE description="Check the Quickshell QML colour pairs against WCAG, across all 8 themes"
"""WCAG contrast check for the colour pairs the Quickshell QML actually renders.

themes/CLAUDE.md states the contrast rules and says outright that nothing
enforces them in QML. This is that enforcement, and it is the only check here
that reads all 8 colorsets rather than the one currently symlinked.

Deliberately NOT in [tasks.lint].depends, for the same reason lint:hypr-lua is
not: PAIRS below is harvested BY HAND from the QML, so it goes stale silently
when a widget changes a colour. Run it after touching colours in the tree, and
re-harvest the table when the tree grows a surface.

Harvesting rule: read the PARENTING, not a grep of colour lines. Most
Theme.bgSecondary uses in that tree are 1px hairlines and borders, not grounds —
taking them for grounds invents failures that do not exist on screen.

Two thresholds, per WCAG 2.1: 4.5:1 for text, 3:1 for UI components and
graphics (an outline, a progress fill). Pairs marked INHERENT are properties of
the shipped colorsets — Waybar, wofi and swaync render the same ratios today —
so they are reported for the record and are not defects in this tree.
"""
import glob
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

# (foreground token, background token, minimum ratio, where it renders)
PAIRS = [
    ("FG_PRIMARY", "BG_SECONDARY", 4.5, "BarWidget grounded, PowerMenu tile label + avatar"),
    ("FG_PRIMARY", "BG_OVERLAY", 4.5, "NotificationCard, every string"),
    ("FG_PRIMARY", "BG_PRIMARY", 4.5, "workspace pill occupied, OSD value"),
    ("FG_SECONDARY", "BG_PRIMARY", 4.5, "BarWidget rest colour, ungrounded"),
    ("FG_SECONDARY", "BG_OVERLAY", 3.0, "NotificationCard action outlines"),
    ("FG_SECONDARY", "BG_SECONDARY", 3.0, "OSD dimmed progress fill"),
    ("ACCENT_PRIMARY", "BG_SECONDARY", 3.0, "OSD progress fill on its track"),
    # The dock's and the bar's launcher glyphs are accent-on-accent-tint, a
    # blend no token pair describes; left unharvested here exactly as the bar's
    # has always been, so the omission is visible rather than silent.
    ("ACCENT_PRIMARY", "BG_PRIMARY", 3.0, "dock running dot on the dock panel"),
    ("ACCENT_BORDER", "BG_OVERLAY", 3.0, "overview focused card outline"),
    ("FG_MUTED", "BG_PRIMARY", 4.5, "INHERENT: footers, hints, clock date, empty pill"),
    ("ACCENT_ERROR", "BG_PRIMARY", 4.5, "INHERENT: urgent workspace, critical states"),
    ("ACCENT_ERROR", "BG_OVERLAY", 4.5, "INHERENT: NotificationCard urgent title"),
    ("ACCENT_WARNING", "BG_PRIMARY", 4.5, "INHERENT: backlight, transcribing, battery low"),
    ("ACCENT_INFO", "BG_PRIMARY", 4.5, "INHERENT: charging, streaming"),
    ("ACCENT_URGENT_SECONDARY", "BG_PRIMARY", 4.5, "INHERENT: battery 20-30%"),
]

# Known-and-accepted cells: a property of the shipped colorset, not of a choice
# this tree can make differently. Each needs a reason, and the reason must be
# "the theme's own palette does this to every consumer", never "we gave up".
# (foreground, background, theme) -> why
ACCEPTED = {
    # Solarized puts body text at base0/base00 (#839496 / #657b83) by design —
    # roughly 4:1 on its own backgrounds. Every consumer renders this, and the
    # only fix is a different FG_PRIMARY, i.e. editing the colorset.
    ("FG_PRIMARY", "BG_SECONDARY", "solarized-dark"): "solarized base0 by design",
    ("FG_PRIMARY", "BG_SECONDARY", "solarized-light"): "solarized base00 by design",
    ("FG_PRIMARY", "BG_OVERLAY", "solarized-dark"): "solarized base0 by design",
    ("FG_PRIMARY", "BG_OVERLAY", "solarized-light"): "solarized base00 by design",
    ("FG_PRIMARY", "BG_PRIMARY", "solarized-light"): "solarized base00 by design",
    # themes/CLAUDE.md already documents fg-secondary on bg-primary as
    # "± AA (theme-dependent)" and permits it for less critical text.
    ("FG_SECONDARY", "BG_PRIMARY", "rose-pine-dawn"): "documented as theme-dependent",
    # gruvbox-light's ACCENT_PRIMARY is #d79921 on a #ebdbb2 elevated ground.
    # Waybar's active workspace has the same ratio in this theme today.
    ("ACCENT_PRIMARY", "BG_SECONDARY", "gruvbox-light"): "gruvbox-light accent is mid-yellow",
    ("ACCENT_PRIMARY", "BG_PRIMARY", "gruvbox-light"): "gruvbox-light accent is mid-yellow",
    ("ACCENT_PRIMARY", "BG_OVERLAY", "gruvbox-light"): "gruvbox-light accent is mid-yellow",
    # ACCENT_BORDER is the Hyprland active-window border in every theme, so
    # these ratios are what the compositor already draws around the focused
    # window today. The overview's focused card additionally carries 2.2x the
    # scale, full opacity against 0.6/0.35, and the only accent footer pill —
    # so a faint outline in these three degrades rather than losing the state.
    ("ACCENT_BORDER", "BG_OVERLAY", "catppuccin-latte"): "accent-border is the compositor's own border colour",
    ("ACCENT_BORDER", "BG_OVERLAY", "gruvbox-light"): "accent-border is the compositor's own border colour",
    ("ACCENT_BORDER", "BG_OVERLAY", "solarized-dark"): "accent-border is the compositor's own border colour",
}

SHORT = {
    "catppuccin-latte": "latte",
    "catppuccin-mocha": "mocha",
    "gruvbox-dark": "gruv-D",
    "gruvbox-light": "gruv-L",
    "rose-pine-dawn": "rp-dawn",
    "rose-pine-moon": "rp-moon",
    "solarized-dark": "solar-D",
    "solarized-light": "solar-L",
}


def luminance(hexstr):
    """WCAG 2.1 relative luminance. Mirrors Theme.qml's luminance()."""
    r, g, b = (int(hexstr[i:i + 2], 16) / 255 for i in (1, 3, 5))

    def channel(c):
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)


def contrast(a, b):
    la, lb = luminance(a), luminance(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


themes = {}
for path in sorted(glob.glob(f"{REPO}/private_dot_config/themes/*/colors.sh")):
    name = path.split("/")[-2]
    with open(path) as fh:
        themes[name] = dict(re.findall(r'readonly\s+([A-Z_]+)="(#[0-9a-fA-F]{6})"', fh.read()))

if not themes:
    print("no colorsets found — run from the chezmoi source root", file=sys.stderr)
    sys.exit(1)

names = list(themes)
failures = []

print("!  = failure   ~ = known-and-accepted (see ACCEPTED)\n")
print(f"{'pair':<40}{'min':>4}  " + "".join(f"{SHORT.get(n, n):>9}" for n in names))
for fg, bg, minimum, where in PAIRS:
    cells = []
    for name in names:
        colours = themes[name]
        if fg not in colours or bg not in colours:
            cells.append("     MISS")
            continue
        ratio = contrast(colours[fg], colours[bg])
        bad = ratio < minimum
        accepted = (fg, bg, name) in ACCEPTED or where.startswith("INHERENT")
        if bad and not accepted:
            failures.append((fg, bg, name, ratio, minimum))
        cells.append(f"{'!' if bad and not accepted else '~' if bad else ' '}{ratio:8.2f}")
    print(f"{fg + ' on ' + bg:<40}{minimum:>4}  " + "".join(cells))
    print(f"{'':<44}  {where}")

# fgOnAccent is computed in Theme.qml rather than being a fixed token, because
# neither FG_CONTRAST nor BG_PRIMARY clears 4.5:1 on ACCENT_PRIMARY in all 8.
# The overview scrim is a SHADE (black at alpha), not a colorset token, so the
# PAIRS table above cannot express it. Measured against pure black: the scrim
# composites over the wallpaper, and this is the limiting case.
print()
print("fgOnScrim — the scrim is dark in EVERY theme, so a light theme's own")
print("foregrounds vanish on it. Theme.qml picks FG_PRIMARY / BG_PRIMARY per theme:")
BLACK = "#000000"
for name in names:
    colours = themes[name]
    fgp = contrast(colours["FG_PRIMARY"], BLACK)
    bgp = contrast(colours["BG_PRIMARY"], BLACK)
    pick, ratio = ("fgPrimary", fgp) if fgp >= bgp else ("bgPrimary", bgp)
    naive = fgp
    flag = "!" if ratio < 4.5 else " "
    print(f"  {SHORT.get(name, name):<12}{ratio:8.2f}  {pick:<10}{flag}   (naive fgPrimary would be {naive:.2f})")
    if ratio < 4.5:
        failures.append(("FG_ON_SCRIM", "SCRIM", name, ratio, 4.5))
# The active page dot is the one accent drawn on the scrim.
print()
print("accentPrimary on the scrim — the active page dot:")
for name in names:
    ratio = contrast(themes[name]["ACCENT_PRIMARY"], BLACK)
    if ratio < 3.0:
        failures.append(("ACCENT_PRIMARY", "SCRIM", name, ratio, 3.0))
    print(f"  {SHORT.get(name, name):<12}{ratio:8.2f}{'  !' if ratio < 3.0 else ''}")

print()
print("fgOnAccent — Theme.qml picks the better of FG_CONTRAST / BG_PRIMARY per theme:")
for name in names:
    colours = themes[name]
    on_contrast = contrast(colours["FG_CONTRAST"], colours["ACCENT_PRIMARY"])
    on_bg = contrast(colours["BG_PRIMARY"], colours["ACCENT_PRIMARY"])
    picked = "fgContrast" if on_contrast >= on_bg else "bgPrimary"
    # A theme where BOTH candidates fall short is a colorset property: there is
    # no third token to reach for. Marked, not failed.
    flag = " ~" if max(on_contrast, on_bg) < 4.5 else "  "
    print(f"  {name:<18}{max(on_contrast, on_bg):6.2f}  {picked}{flag}")

print()
if failures:
    print(f"❌ {len(failures)} pair(s) below threshold in this tree's own choices:")
    for fg, bg, name, ratio, minimum in failures:
        print(f"   {name}: {fg} on {bg} = {ratio:.2f} (needs {minimum})")
    sys.exit(1)
print("✅ every pair this tree chooses clears its threshold in all 8 themes")
