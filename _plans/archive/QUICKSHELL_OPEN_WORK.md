# Quickshell — what was still open (ARCHIVED)

🚨 **This document is FROZEN at 2026-09-13 and is not a roadmap.** Every item in it was resolved
the same day it was written. It is kept for the measurements and the rulings, which are the part
worth having; the live decisions moved into the files named below, beside the code they govern.

**Created** 2026-09-13 by extracting the live items out of three documents that had become records
of a finished build. **Closed** 2026-09-13.

**Still live**: `_plans/QUICKSHELL_TOOL_RETIREMENT.md` — the *removal* work (wlogout, swaync,
Waybar, the two polkit agents). It is the only open Quickshell plan.

---

## The defect — the meter pill's number on its tinted ground

**Resolved: measured and accepted. No QML changed.**

`bar/widgets/MetersWidget.qml` tints its pill 18% `signalWarn` / `signalError` over `groundBase`,
and the `inkPrimary` number on it measures **3.46** and **3.19** in solarized-light against the 4.5
a text pair owes. Three measurements settled it, none of which this document had when it called it
a defect:

| | solar-L | solar-D | worst of the other six |
|---|---|---|---|
| untinted pill (`INK_PRIMARY` on `GROUND_RAISED`) | **3.64** | 4.11 | 5.17 (latte) |
| 18% warn tint | 3.46 | 3.80 | 5.86 (rp-dawn) |
| 18% error tint | 3.19 | 4.42 | 5.21 (latte) |
| 14% error tint — `BatteryWidget`, which this document missed entirely | 3.39 | 4.52 | 5.58 (latte) |

1. The **untinted** pill in solarized-light is already 3.64 and was already excused in
   `theme-contrast.py`'s `ACCEPTED` as *"solarized base00 by design"*. The tint costs 0.45 on top
   of a pair that is under the floor before it is tinted.
2. **No alpha recovers it.** The limit as alpha → 0 is `INK_PRIMARY` on `GROUND_BASE`, which is
   4.13 there. Every candidate tint is bracketed by two failing numbers.
3. The **palette swap** — the obvious fix, exchanging `INK_PRIMARY` and `INK_SECONDARY` in both
   solarized sets — was measured and still misses: 4.39 on `GROUND_RAISED` in solarized-light,
   4.49 on the warn tint in solarized-dark, while demoting Solarized's own body value to the quiet
   role.

The tint is also load-bearing: the glyph substitution every other widget took is unavailable here,
because `signalError` on `groundRaised` is 2.81 in solarized-dark — the same measurement that moved
`PowerMenu`'s tiles off that tier.

So the resolution was to **measure it**: `.mise/tasks/lint/theme-contrast.py` grew a `COMPOSITES`
table that blends a tint the way `Qt.alpha` paints it, covering both pills, with the four solarized
cells in `ACCEPTED`. The rule now keeps its evidence. Commit `9c52c0d7`.

## The two open questions

**Solarized's `INK_PRIMARY` is worse than its own `INK_SECONDARY`** — 4.13 / 4.75 against their own
`GROUND_BASE` while `INK_SECONDARY` measures 4.99 / 5.61. Stays unfixed, now for a measured reason
rather than an unexamined one: the swap above does not clear the floor either.

**`signalInfo` and `signalOk` have no legal use left** — both stay bound and undrawn. Deleting them
would save two lines and break the rule `themes/*/colors.sh` states in its own header, that the five
SIGNAL roles stay mutually separable in every theme.

Both rulings now live in `.claude/rules/quickshell-qml.md`, beside the colour rules they qualify.
Commit `066a2325`.

## The optional work — all four built

| # | Surface | What shipped | Commit |
|---|---|---|---|
| 9 | Keybindings reference | `keybindings/KeybindingsSheet.qml`, a two-column document; `desktop/keybindings --json` feeds it and keeps its picker as the fallback | `0319cd46` |
| 12 | Session save/restore prompt | an interrupt: `notify-send --wait -t 0` with two actions. The stale-session branch keeps its picker, being a chooser over N slots | `a7c0aeb8` |
| 13 | Colour-temperature control | `bar/popovers/NightLightPopover.qml`, the eighth popover, a `PopoverSlider` over 3500–6500 K driving `nightlight-config <K>` | `d6fe2c39` |
| — | Meters temperature | the third source, resolved from hwmon by driver name and expressed against the ceiling the driver itself declares | `bc0f2294` |

Four defects surfaced while building them, each recorded at its site:

- **Popups refused to draw actions at all**, on the reasoning that a toast is about to vanish from
  under the pointer — which is not true of a card with no timeout. `showActions` now follows that
  reason rather than ignoring it.
- The popup's dismiss-on-click `MouseArea` needed `z: -1`, or it would have swallowed every click
  on those actions. Same stacking rule `BarWidget`'s catch-all already follows.
- **Under the Lua config provider every bind reports dispatcher `__lua`**, so `desktop/keybindings`
  classified all 115 of them as "Other Bindings / __lua 15". The declared description is the fix.
- **The four arrow key symbols in that script were empty string literals** — third instance of that
  trap here, and every arrow binding had been drawing a blank key.

**Temperature deliberately does NOT join `Meters.highest`**: idle measures 52 °C of a 100 °C
ceiling while load and memory sit far below it, so feeding it in would pin the bar's one number to
the thermometer for the life of the session.
