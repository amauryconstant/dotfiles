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


# Known-and-accepted cells: a property of the shipped colorset, not of a choice
# this tree can make differently. Each needs a reason, and the reason must be
# "the theme's own palette does this to every consumer", never "we gave up".
# (foreground, background, theme) -> why
ACCEPTED = {
    # Solarized puts body text at base0/base00 (#839496 / #657b83) by design —
    # roughly 4:1 on its own backgrounds. Every consumer renders this, and the
    # only fix is a different FG_PRIMARY, i.e. editing the colorset.
    #
    # Design page 13 names this an open COLORSET bug and it is right: in BOTH
    # Solarized sets, FG_SECONDARY measures BETTER on the same ground than
    # FG_PRIMARY does (4.99 vs 4.13 light, 5.61 vs 4.75 dark), so the mapping
    # has the two foregrounds the wrong way round. The fix belongs to the
    # colorsets, not to any consumer of them.
    ("FG_PRIMARY", "BG_SECONDARY", "solarized-dark"): "solarized base0 by design",
    ("FG_PRIMARY", "BG_SECONDARY", "solarized-light"): "solarized base00 by design",
    ("FG_PRIMARY", "BG_OVERLAY", "solarized-dark"): "solarized base0 by design",
    ("FG_PRIMARY", "BG_OVERLAY", "solarized-light"): "solarized base00 by design",
    ("FG_PRIMARY", "BG_PRIMARY", "solarized-light"): "solarized base00 by design",
    # themes/CLAUDE.md already documents fg-secondary on bg-primary as
    # "± AA (theme-dependent)" and permits it for less critical text.
    ("FG_SECONDARY", "BG_PRIMARY", "rose-pine-dawn"): "documented as theme-dependent",
    # 🚨 NO accent role clears 3:1 in all eight colorsets, and gruvbox-light is
    # the worst case for every one of them. That measurement IS the reason the
    # design makes everything load-bearing foreground-class and leaves accent as
    # decoration: every site below pairs it with a glyph, a number or a return
    # mark, so a faint accent degrades rather than losing the state.
    ("ACCENT_PRIMARY", "BG_SECONDARY", "gruvbox-light"): "gruvbox-light accent is mid-yellow; never the sole carrier",
    ("ACCENT_PRIMARY", "BG_PRIMARY", "gruvbox-light"): "gruvbox-light accent is mid-yellow; never the sole carrier",
    # ACCENT_BORDER is the Hyprland active-window border in every theme, so
    # these ratios are what the compositor already draws around the focused
    # window today. The overview that uses it is dormant besides.
    ("ACCENT_BORDER", "BG_OVERLAY", "catppuccin-latte"): "accent-border is the compositor's own border colour",
    ("ACCENT_BORDER", "BG_OVERLAY", "gruvbox-light"): "accent-border is the compositor's own border colour",
    ("ACCENT_BORDER", "BG_OVERLAY", "solarized-dark"): "accent-border is the compositor's own border colour",
    # ACCENT_ERROR on the card ground is the critical card's 1px border, drawn
    # alongside a tinted chip AND a different glyph — three carriers.
    # The critical card's 1px border. The card MUST ground on BG_OVERLAY — it is
    # a thing on top of the desktop, not part of a panel — so unlike the power
    # tile below there is no ground to move it to. It is the third carrier
    # anyway: the chip takes a signalError tint AND the glyph itself changes.
    ("ACCENT_ERROR", "BG_OVERLAY", "solarized-dark"): "critical card border; the chip tint and the glyph carry it",
}

# (foreground token, background token, minimum ratio, where it renders)
#
# Harvested BY PARENTING, not by grepping colour lines: most Theme.edge /
# BG_SECONDARY uses in that tree are 1px hairlines and borders, and reading one
# two lines above an FG_ token invents failures that are not on screen.
#
# 🚨 There is no INHERENT escape hatch any more. It used to excuse five
# accent-as-text pairs on the grounds that Waybar renders the same ratios, and
# parity with an older tool is not a reason to ship failing text. The rules
# changed instead: no accent is drawn as text in this tree now, and the warn and
# info roles are not drawn as graphics either — the battery, the idle
# indicator, the bell and the dictation widget all moved their non-error states
# onto the glyph, which is what they should always have carried.
PAIRS = [
    # --- text, floor 4.5
    ("FG_PRIMARY", "BG_PRIMARY", 4.5, "OSD readout, launcher row name and zero-match line, panel headers and titles"),
    ("FG_PRIMARY", "BG_SECONDARY", 4.5, "BarWidget grounded, occupied workspace pill, meter and battery pills, PowerMenu tile label + avatar"),
    ("FG_PRIMARY", "BG_OVERLAY", 4.5, "NotificationCard, every string on it"),
    ("FG_SECONDARY", "BG_PRIMARY", 4.5, "BarWidget rest colour, clock date, empty workspace pill, launcher second line + footer + placeholder, centre empty state + footer"),

    # --- graphics and UI components, floor 3.0
    ("ACCENT_PRIMARY", "BG_SECONDARY", 3.0, "OSD progress fill on its track"),
    ("ACCENT_PRIMARY", "BG_PRIMARY", 3.0, "launcher caret, prefix mark and return mark; dock running dot"),
    ("FG_SECONDARY", "BG_SECONDARY", 3.0, "OSD dimmed progress fill"),
    ("FG_SECONDARY", "BG_OVERLAY", 3.0, "NotificationCard action outlines"),
    ("ACCENT_ERROR", "BG_PRIMARY", 3.0, "audio failed-service glyph, network no-route glyph, battery critical glyph, DND bell, idle inhibitor, PowerMenu power-off glyph and border"),
    ("ACCENT_ERROR", "BG_OVERLAY", 3.0, "critical NotificationCard border and chip glyph"),
    ("ACCENT_BORDER", "BG_OVERLAY", 3.0, "overview focused card outline (dormant surface)"),
]

# Pairs the design BANS. Measured on purpose: the reason a rule exists is the
# number, and deleting the row leaves the next reader free to reintroduce it.
# None of these is drawn anywhere in the tree.
BANNED = [
    ("FG_PRIMARY", "BG_TERTIARY", 4.5, "no text on fill-inert. This is the 1.67 that moved the occupied workspace pill onto BG_SECONDARY"),
    ("FG_MUTED", "BG_PRIMARY", 4.5, "FG_MUTED is retired: banned as text, and under 3:1 as an outline. There is no successor token"),
    ("ACCENT_ERROR", "BG_PRIMARY", 4.5, "signal-error is never a TEXT colour. The notification title and the urgent workspace number both moved off it"),
    ("ACCENT_WARNING", "BG_PRIMARY", 3.0, "not drawn as a graphic either: 2.05 in rose-pine-dawn. The battery band and the dictation state carry glyphs instead"),
    ("ACCENT_INFO", "BG_PRIMARY", 3.0, "same, at 2.80: charging and streaming are distinct glyphs, not tinted ones"),
    ("ACCENT_SUCCESS", "BG_PRIMARY", 3.0, "no green anywhere in this shell — a healthy system is neutral, not green"),
]

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
        accepted = (fg, bg, name) in ACCEPTED
        if bad and not accepted:
            failures.append((fg, bg, name, ratio, minimum))
        cells.append(f"{'!' if bad and not accepted else '~' if bad else ' '}{ratio:8.2f}")
    print(f"{fg + ' on ' + bg:<40}{minimum:>4}  " + "".join(cells))
    print(f"{'':<44}  {where}")

print()
print("BANNED pairs — measured so a rule keeps its evidence. None of these is drawn.")
for fg, bg, minimum, why in BANNED:
    worst, worst_theme = 99.0, ""
    for name in names:
        colours = themes[name]
        if fg not in colours or bg not in colours:
            continue
        ratio = contrast(colours[fg], colours[bg])
        if ratio < worst:
            worst, worst_theme = ratio, name
    print(f"  {fg + ' on ' + bg:<32}worst {worst:5.2f} ({SHORT.get(worst_theme, worst_theme)}) vs {minimum}")
    print(f"  {'':<32}{why}")

# focusRing and disabledOpacity are DERIVED in Theme.qml rather than named by a
# theme, so no PAIRS row can express them. Both are reproduced from the same
# rule the QML uses, which is the only way they stay in step.
print()
print("focusRing — better of ACCENT_PRIMARY / FG_PRIMARY against BG_SECONDARY, floor 3.0:")
for name in names:
    colours = themes[name]
    on_accent = contrast(colours["ACCENT_PRIMARY"], colours["BG_SECONDARY"])
    on_ink = contrast(colours["FG_PRIMARY"], colours["BG_SECONDARY"])
    picked = "signalFocus" if on_accent >= on_ink else "inkPrimary"
    ratio = max(on_accent, on_ink)
    if ratio < 3.0:
        failures.append(("FOCUS_RING", "BG_SECONDARY", name, ratio, 3.0))
    print(f"  {SHORT.get(name, name):<12}{ratio:8.2f}  {picked}{'  !' if ratio < 3.0 else ''}")

print()
print("disabledOpacity — lowest 5% step of FG_SECONDARY over BG_PRIMARY clearing 3.0:")
for name in names:
    colours = themes[name]
    fgc = tuple(int(colours["FG_SECONDARY"][i:i + 2], 16) for i in (1, 3, 5))
    bgc = tuple(int(colours["BG_PRIMARY"][i:i + 2], 16) for i in (1, 3, 5))
    chosen = None
    for step in range(12, 21):
        alpha = step / 20
        blend = "#" + "".join(f"{round(f * alpha + b * (1 - alpha)):02x}" for f, b in zip(fgc, bgc))
        if contrast(blend, colours["BG_PRIMARY"]) >= 3.0:
            chosen = alpha
            break
    if chosen is None:
        failures.append(("DISABLED", "BG_PRIMARY", name, 0.0, 3.0))
    print(f"  {SHORT.get(name, name):<12}{'none clears 3:1 — falls back to full opacity' if chosen is None else f'{chosen:.2f}'}")

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
