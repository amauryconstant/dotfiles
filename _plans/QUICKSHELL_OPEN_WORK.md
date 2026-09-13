# Quickshell — what is still open

**Status**: Open. Created 2026-09-13 by extracting the live items out of three documents that had
become records of a finished build.
**Companion**: `_plans/QUICKSHELL_TOOL_RETIREMENT.md` — the *removal* work (wlogout, swaync,
Waybar, the two polkit agents). Nothing here duplicates it.
**Where the extracted-from documents went**: `_research/archive/QUICKSHELL_SURFACE_INVENTORY.md`
(what each of the 30 surfaces is made of, how it must behave, and what it shipped as) and
`_research/archive/QUICKSHELL_DESIGN_AUDIT.md` (every measurement and every ruling against the
design). Both are still the evidence; neither is a backlog any more.

**The build is closed.** 21 of the 23 surfaces shipped, §15's region overlay and §23's greeter are
recorded refusals, and the seven foundations are rules rather than surfaces. Everything below is
either a **defect**, an **open question**, or **optional** work on a surface that already exists.
Nothing here blocks anything.

---

## 🚨 Defect — the meter pill's number is under the text floor when it matters

**Found 2026-09-13, by re-measuring rather than re-reading. Not fixed: the fix is a choice.**

`bar/widgets/MetersWidget.qml:22` tints its pill's ground 18% `signalWarn` at the warn band and
18% `signalError` at the critical band, over `groundBase`. The number on it is `inkPrimary`,
because `pill: true` makes it a grounded widget. Composited and measured across all eight
colorsets:

| Band | Worst | Where | Floor |
|---|---|---|---|
| critical (18% `SIGNAL_ERROR`) | **3.19** | solarized-light | 4.5 (text) |
| warn (18% `SIGNAL_WARN`) | **3.46** | solarized-light | 4.5 (text) |

The widget's own comment says the tint exists so that "a percentage has to stay readable at
exactly the moment it is worth reading" — which is the requirement it misses, and only in the
themes nobody had applied.

**Why it went unseen**: `.mise/tasks/lint/theme-contrast.py` harvests `INK_PRIMARY` /
`GROUND_RAISED` for "meter and battery pills". The *tinted* grounds are not in its `PAIRS` table at
all, so no run has ever measured them.

Three ways out, none decided:

1. **A lighter tint** — cheapest, and keeps the signal. Needs remeasuring at each step; the tint
   has to clear 4.5 against `inkPrimary` in solarized-light, which is the binding case.
2. **A different ink on the tinted state** — the same computed-pick shape as `Theme.inkOnSignal`,
   which already exists for exactly this problem on a *full* signal fill.
3. **Move the band onto the glyph**, as the battery's low band did on 2026-09-01 and as the meter's
   own warning *word* already does in the popover. Then the pill ground never leaves
   `groundRaised` and the question disappears.

**Whichever is chosen, add the pair to `theme-contrast.py`.** A fix with no row in that table is
one recolour away from coming back.

---

## Open questions, no work attached

### Solarized's `INK_PRIMARY` is worse than its own `INK_SECONDARY`

Re-measured 2026-09-13, unchanged since the first pass: **4.13** (solarized-light) and **4.75**
(solarized-dark) against their own `GROUND_BASE`, while each set's `INK_SECONDARY` measures better
(4.99 / 5.61). Design page 13 independently calls this a colorset bug.

Deliberately unfixed, and the reason is structural: it belongs to `themes/*/colors.sh`, not to any
consumer, and `Theme.qml` already withdraws the *secondary* ink by measurement where it fails.
There is no equivalent escape for the primary — it **is** the fallback. Fixing it means editing two
palettes' `INK_PRIMARY`, which is a theme decision, not a shell one.

### `signalInfo` and `signalOk` have no legal use left

Both are under 3:1 on their own ground in four of eight colorsets, so neither is drawn anywhere;
they sit bound in `Theme.qml`. (`signalWarn` has exactly one site — the meter tint above, which is
a ground rather than a graphic, and is the defect above.) Either a future surface finds a ground
they clear, or the palette owes them a value that works. Deleting them is the third option and has
not been argued for.

---

## Optional — surfaces that shipped thinner than their entry described

None of these is a gap. Each works; each is smaller than the surface inventory's description of it.

| # | Surface | Shipped as | What the entry asked for |
|---|---|---|---|
| 9 | Keybindings reference | a picker list (`desktop/keybindings`) | a *document* — the one summoned surface that is not a chooser. The design question is legibility at density |
| 12 | Session save/restore prompt | a picker (`desktop/session-prompt`) | the picker-or-interrupt question is still unanswered. It behaves like one of the few things the shell asks unprompted, which is interrupt-shaped |
| 13 | Colour-temperature control | a picker of presets (`desktop/nightlight-config`) | a continuous control. `PopoverSlider` now exists and would serve it — the entry's own caveat is that any preview inside the surface is lying, since the screen is being tinted while it is adjusted |

### The meters payload has no temperature

Design page 06 asks for CPU, memory, **temperature**, uptime; `Meters.qml` ships the first two plus
uptime and carries the note at `Meters.qml:16`. Not a contrast question and not an oversight: a
temperature is not a percentage until someone names the hwmon path and the threshold it is a
percentage **of**. The file marks where it goes.

### The native nested menu (design page 10)

Page 10 designs a menu tree drawn natively in the shell. What shipped on 2026-09-13 moved the
**navigation** into the shell — breadcrumb trail and a back gesture on `MenuPicker` — and left the
tree in the scripts, deliberately: eighteen scripts already speak dmenu, and a native tree would
re-implement what they encode. Reopening this means moving the tree, not adding a surface.
