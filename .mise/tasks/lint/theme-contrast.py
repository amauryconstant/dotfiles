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
    # only fix is a different INK_PRIMARY, i.e. editing the colorset.
    #
    # Design page 13 names this an open COLORSET bug and it is right: in BOTH
    # Solarized sets, INK_SECONDARY measures BETTER on the same ground than
    # INK_PRIMARY does (4.99 vs 4.13 light, 5.61 vs 4.75 dark), so the mapping
    # has the two foregrounds the wrong way round. The fix belongs to the
    # colorsets, not to any consumer of them.
    ("INK_PRIMARY", "GROUND_RAISED", "solarized-dark"): "solarized base0 by design",
    ("INK_PRIMARY", "GROUND_RAISED", "solarized-light"): "solarized base00 by design",
    ("INK_PRIMARY", "GROUND_FLOAT", "solarized-dark"): "solarized base0 by design",
    ("INK_PRIMARY", "GROUND_FLOAT", "solarized-light"): "solarized base00 by design",
    ("INK_PRIMARY", "GROUND_BASE", "solarized-light"): "solarized base00 by design",
    # The same property, seen through a tinted pill (see COMPOSITES). The tint
    # costs ~0.45 on top of a pair that is already under the floor untinted --
    # solarized-light's plain pill is 3.64 -- and no alpha recovers it: the
    # limit as alpha -> 0 is INK_PRIMARY on GROUND_BASE, 4.13 there. Measured
    # 2026-09-13; a swap of the two solarized inks was measured too and still
    # misses (4.39 on GROUND_RAISED light, 4.49 on the warn tint dark).
    ("INK_PRIMARY", "SIGNAL_WARN@18%/GROUND_BASE", "solarized-light"): "solarized base00 by design",
    ("INK_PRIMARY", "SIGNAL_WARN@18%/GROUND_BASE", "solarized-dark"): "solarized base0 by design",
    ("INK_PRIMARY", "SIGNAL_ERROR@18%/GROUND_BASE", "solarized-light"): "solarized base00 by design",
    ("INK_PRIMARY", "SIGNAL_ERROR@18%/GROUND_BASE", "solarized-dark"): "solarized base0 by design",
    ("INK_PRIMARY", "SIGNAL_ERROR@14%/GROUND_BASE", "solarized-light"): "solarized base00 by design",
    # 🚨 NO accent role clears 3:1 in all eight colorsets, and gruvbox-light is
    # the worst case for every one of them. That measurement IS the reason the
    # design makes everything load-bearing foreground-class and leaves accent as
    # decoration: every site below pairs it with a glyph, a number or a return
    # mark, so a faint accent degrades rather than losing the state.
    ("SIGNAL_FOCUS", "GROUND_RAISED", "gruvbox-light"): "gruvbox-light accent is mid-yellow; never the sole carrier",
    ("SIGNAL_FOCUS", "GROUND_BASE", "gruvbox-light"): "gruvbox-light accent is mid-yellow; never the sole carrier",
    ("SIGNAL_ERROR", "GROUND_FLOAT", "solarized-dark"): "critical card border; the chip tint and the glyph carry it",
}

# (foreground token, background token, minimum ratio, where it renders)
#
# Harvested BY PARENTING, not by grepping colour lines: most Theme.edge /
# GROUND_RAISED uses in that tree are 1px hairlines and borders, and reading one
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
    ("INK_PRIMARY", "GROUND_BASE", 4.5, "OSD readout, launcher row name and zero-match line, panel headers and titles"),
    ("INK_PRIMARY", "GROUND_RAISED", 4.5, "BarWidget grounded and hovered, occupied workspace pill, the two pills UNTINTED, PowerMenu tile label + avatar"),
    ("INK_PRIMARY", "GROUND_FLOAT", 4.5, "NotificationCard, every string on it"),
    ("INK_SECONDARY_EFF", "GROUND_BASE", 4.5, "BarWidget rest colour, clock date, empty workspace pill, launcher second line + footer + placeholder, centre empty state + footer"),

    # --- graphics and UI components, floor 3.0
    ("SIGNAL_FOCUS", "GROUND_RAISED", 3.0, "OSD progress fill on its track"),
    ("SIGNAL_FOCUS", "GROUND_BASE", 3.0, "launcher caret, prefix mark and return mark; dock running dot"),
    ("INK_SECONDARY_EFF", "GROUND_RAISED", 3.0, "OSD dimmed progress fill"),
    ("INK_SECONDARY_EFF", "GROUND_FLOAT", 3.0, "NotificationCard action outlines"),
    ("SIGNAL_ERROR", "GROUND_BASE", 3.0, "audio failed-service glyph, network no-route glyph, battery critical glyph, DND bell, idle inhibitor, PowerMenu power-off glyph and border"),
    ("SIGNAL_ERROR", "GROUND_FLOAT", 3.0, "critical NotificationCard border and chip glyph"),

    # --- popovers (design page Shell-06-Popovers). The chrome grounds on
    # GROUND_BASE, so its text pairs are the two rows above; what is new is the
    # slider and the meter fill.
    #
    # The calendar's "today" number is inkOnSignal on SIGNAL_FOCUS and is NOT a
    # row here: inkOnSignal is COMPUTED in Theme.qml rather than bound in
    # colors.sh, so this table's parser cannot see it. The fgOnAccent section
    # below already measures exactly that pick, per theme, and the number is the
    # same pairing the focused workspace pill has shipped since Phase 2.5.
    ("SIGNAL_FOCUS", "GROUND_RAISED", 3.0, "popover slider fill on its track, and the thumb"),
    ("INK_SECONDARY_EFF", "GROUND_RAISED", 3.0, "meter and media-position fill on its track"),
]

# Pairs the design BANS. Measured on purpose: the reason a rule exists is the
# number, and deleting the row leaves the next reader free to reintroduce it.
# None of these is drawn FLAT anywhere in the tree. SIGNAL_WARN and SIGNAL_ERROR
# are each drawn as a ~15% tint under a pill's number, which is a ground rather
# than a graphic and has its own floor -- see COMPOSITES below.
BANNED = [
    ("INK_PRIMARY", "FILL_INERT", 4.5, "no text on fill-inert. This is the 1.67 that moved the occupied workspace pill onto GROUND_RAISED"),
    ("FILL_INERT", "GROUND_RAISED", 3.0, "design page 06 calls this the slider's 'one legal use' of fill-inert; it is under the 3:1 that page 13 sets for a graphic, so the popover slider fills with SIGNAL_FOCUS instead — the same ruling the OSD already took"),
    ("INK_MUTED", "GROUND_BASE", 4.5, "INK_MUTED is retired: banned as text, and under 3:1 as an outline. There is no successor token"),
    ("SIGNAL_ERROR", "GROUND_BASE", 4.5, "signal-error is never a TEXT colour. The notification title and the urgent workspace number both moved off it"),
    ("SIGNAL_WARN", "GROUND_BASE", 3.0, "not drawn as a graphic either: 2.05 in rose-pine-dawn. The battery band and the dictation state carry glyphs instead; its ONE site is the meter pill tint in COMPOSITES"),
    ("SIGNAL_INFO", "GROUND_BASE", 3.0, "same, at 2.80: charging and streaming are distinct glyphs, not tinted ones"),
    ("SIGNAL_OK", "GROUND_BASE", 3.0, "no green anywhere in this shell — a healthy system is neutral, not green"),
]

# 🚨 A tinted ground is a COMPOSITE, not a token, so no PAIRS row can express
# it -- luminance() parses #rrggbb and the table is flat token-vs-token. That is
# why no run measured these until 2026-09-13, while two pills have shipped a
# tinted ground since Phase 2.5.
#
# (ink, (signal, alpha, ground under it), minimum, where it renders)
COMPOSITES = [
    ("INK_PRIMARY", ("SIGNAL_WARN", 0.18, "GROUND_BASE"), 4.5, "meter pill, warn band -- bar/widgets/MetersWidget.qml"),
    ("INK_PRIMARY", ("SIGNAL_ERROR", 0.18, "GROUND_BASE"), 4.5, "meter pill, critical band -- same ternary"),
    ("INK_PRIMARY", ("SIGNAL_ERROR", 0.14, "GROUND_BASE"), 4.5, "battery pill, <=10% and discharging -- bar/widgets/BatteryWidget.qml"),
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


def blend(fg, bg, alpha):
    """fg at `alpha` over an opaque bg -- what Qt.alpha() actually paints."""
    return "#" + "".join(f"{round(int(fg[i:i + 2], 16) * alpha + int(bg[i:i + 2], 16) * (1 - alpha)):02x}" for i in (1, 3, 5))


themes = {}
for path in sorted(glob.glob(f"{REPO}/private_dot_config/themes/*/colors.sh")):
    name = path.split("/")[-2]
    with open(path) as fh:
        themes[name] = dict(re.findall(r'readonly\s+([A-Z0-9_]+)="(#[0-9a-fA-F]{6})"', fh.read()))

# 🚨 The second ink is OFFERED, not guaranteed. Theme.qml withdraws it wherever
# it fails 4.5:1 on GROUND_BASE, and that ground then carries INK_PRIMARY alone,
# so every pair spending it has to measure what is actually drawn. Design page
# 01 states the rule; this is where it is checked.
for _name, _colours in themes.items():
    _offered = _colours.get("INK_SECONDARY")
    _base = _colours.get("GROUND_BASE")
    if _offered and _base:
        _colours["INK_SECONDARY_EFF"] = _offered if contrast(_offered, _base) >= 4.5 else _colours["INK_PRIMARY"]

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
print("COMPOSITED grounds — a signal tint over a ground, and the ink on top of it.")
print("Not expressible as a PAIRS row; measured with the same blend Qt.alpha paints.")
for fg, (signal, alpha, under), minimum, where in COMPOSITES:
    label = f"{signal}@{round(alpha * 100)}%/{under}"
    # Display only: the full role names do not fit the column the other tables use.
    shown = label.replace("SIGNAL_", "").replace("GROUND_", "")
    cells = []
    for name in names:
        colours = themes[name]
        if fg not in colours or signal not in colours or under not in colours:
            cells.append("     MISS")
            continue
        ratio = contrast(colours[fg], blend(colours[signal], colours[under], alpha))
        bad = ratio < minimum
        accepted = (fg, label, name) in ACCEPTED
        if bad and not accepted:
            failures.append((fg, label, name, ratio, minimum))
        cells.append(f"{'!' if bad and not accepted else '~' if bad else ' '}{ratio:8.2f}")
    print(f"{fg + ' on ' + shown:<40}{minimum:>4}  " + "".join(cells))
    print(f"{'':<44}  {where}")

print()
print("BANNED pairs — measured so a rule keeps its evidence. None is drawn FLAT;")
print("the two pill tints above are the only sites either signal role has.")
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
print("focusRing — better of SIGNAL_FOCUS / INK_PRIMARY against GROUND_RAISED, floor 3.0:")
for name in names:
    colours = themes[name]
    on_accent = contrast(colours["SIGNAL_FOCUS"], colours["GROUND_RAISED"])
    on_ink = contrast(colours["INK_PRIMARY"], colours["GROUND_RAISED"])
    picked = "signalFocus" if on_accent >= on_ink else "inkPrimary"
    ratio = max(on_accent, on_ink)
    if ratio < 3.0:
        failures.append(("FOCUS_RING", "GROUND_RAISED", name, ratio, 3.0))
    print(f"  {SHORT.get(name, name):<12}{ratio:8.2f}  {picked}{'  !' if ratio < 3.0 else ''}")

print()
print("second ink — offered per theme, withdrawn where it fails 4.5 on GROUND_BASE:")
for name in names:
    colours = themes[name]
    ratio = contrast(colours["INK_SECONDARY"], colours["GROUND_BASE"])
    print(f"  {SHORT.get(name, name):<12}{ratio:8.2f}  {'offered' if ratio >= 4.5 else 'WITHDRAWN -> INK_PRIMARY'}")

print()
print("disabledOpacity — lowest 5% step of INK_SECONDARY over GROUND_BASE clearing 3.0:")
for name in names:
    colours = themes[name]
    chosen = None
    for step in range(12, 21):
        alpha = step / 20
        blended = blend(colours["INK_SECONDARY"], colours["GROUND_BASE"], alpha)
        if contrast(blended, colours["GROUND_BASE"]) >= 3.0:
            chosen = alpha
            break
    if chosen is None:
        failures.append(("DISABLED", "GROUND_BASE", name, 0.0, 3.0))
    print(f"  {SHORT.get(name, name):<12}{'none clears 3:1 — falls back to full opacity' if chosen is None else f'{chosen:.2f}'}")

# fgOnAccent is computed in Theme.qml rather than being a fixed token, because
# neither INK_CONTRAST_CANDIDATE nor GROUND_BASE clears 4.5:1 on SIGNAL_FOCUS in all 8.
# The overview scrim is a SHADE (black at alpha), not a colorset token, so the
# PAIRS table above cannot express it. Measured against pure black: the scrim
# composites over the wallpaper, and this is the limiting case.
print()
print("fgOnScrim — the scrim is dark in EVERY theme, so a light theme's own")
print("foregrounds vanish on it. Theme.qml picks INK_PRIMARY / GROUND_BASE per theme:")
BLACK = "#000000"
for name in names:
    colours = themes[name]
    fgp = contrast(colours["INK_PRIMARY"], BLACK)
    bgp = contrast(colours["GROUND_BASE"], BLACK)
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
    ratio = contrast(themes[name]["SIGNAL_FOCUS"], BLACK)
    if ratio < 3.0:
        failures.append(("SIGNAL_FOCUS", "SCRIM", name, ratio, 3.0))
    print(f"  {SHORT.get(name, name):<12}{ratio:8.2f}{'  !' if ratio < 3.0 else ''}")

# The lock screen (surface §22) reports a failed password inline. Design page 12
# draws that line in signal-error; this measures whether it could be. It is NOT
# a BANNED row because SCRIM is a shade rather than a colorset key, so the table
# above cannot express it — same reason fgOnScrim is measured here.
print()
print("signalError as TEXT on the scrim — the lock screen's failure line.")
print("NOT drawn: two colorsets miss 4.5:1, so the line stays fgOnScrim and the")
print("words carry the failure, which page 12 requires of it anyway.")
for name in names:
    ratio = contrast(themes[name]["SIGNAL_ERROR"], BLACK)
    print(f"  {SHORT.get(name, name):<12}{ratio:8.2f}{'  !' if ratio < 4.5 else ''}")

print()
print("fgOnAccent — Theme.qml picks the better of INK_CONTRAST_CANDIDATE / GROUND_BASE per theme:")
for name in names:
    colours = themes[name]
    on_contrast = contrast(colours["INK_CONTRAST_CANDIDATE"], colours["SIGNAL_FOCUS"])
    on_bg = contrast(colours["GROUND_BASE"], colours["SIGNAL_FOCUS"])
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
