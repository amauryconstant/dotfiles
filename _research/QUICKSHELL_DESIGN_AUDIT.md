# Quickshell design audit — rounds 1–4, and the round-5 rewrite

**Date**: 2026-09-03, extended 2026-09-08 · **Source**: Claude Design project
`1d494341-deaa-47cb-ac39-32ccb9c23862`.

🚨 **Parts 1–4 below audit the NINE-file set, which no longer exists.** The project was rewritten
as **fourteen pages**, `Shell-00-Index` … `Shell-13-Accessibility`. Every artboard id those parts
cite (`f-a`, `bar-a`, `pop-g`, `st-b`, `pf-a`, `comp-a`, `comp-b`, `pan-a`, `1a`–`1i`) is dead.
They are kept because the *measurements* are still valid and several of them are why the current
code looks the way it does — not because the files they cite can still be opened. **Part 5 is the
current set.**
**Rulings that act on this**: `_research/QUICKSHELL_DESIGN_BRIEF_R5.md`. This document is the
**evidence**; the brief is the decisions.

**Method**: every contrast pair the new rounds introduce was recomputed against all **8**
`private_dot_config/themes/*/colors.sh`, using the same WCAG 2.1 formula as
`.mise/tasks/lint/theme-contrast.py`. Tints and opacities are composited over their stated ground
before measuring. Numbers below are measured, not quoted.

## What changed since Amendment B

Amendment B read six files. There are now nine, and `Foundations` was **rewritten**: `f-a` as
recorded, plus new `f-b` (interaction states), `f-c` (motion), `f-d` (glyph inventory) — none of
which the plan ever recorded. `Popovers` (round 2), `States` (round 3) and `Proof` (round 4) are
new. `Bar - Dock`, `Launcher - Menu`, `Panels` and `Session` are unchanged — verified, not assumed.

The design's closing note says *"Round 1 is recorded as Amendment F, this round as Amendment G."*
No Amendment F or G exists here; the plan stops at E. The design tracks an amendment history we
never wrote.

---

## Part 1 — The design contradicts itself

| # | Conflict |
|---|---|
| 1.1 | **`fg-muted` is both the disabled colour and forbidden as it.** `f-a`: *"empty, disabled"*. `f-b`, same file: *"`@fg-muted` **cannot** be the disabled colour: it equals `@bg-tertiary` at 1.00:1 in both Solarized colorsets."* |
| 1.2 | **A popover's ground is named twice.** `f-a`: `@bg-tertiary` is *"popovers, notifications"*. `pop-a`: *"Ground `@bg-primary`."* `st-d` uses *"the same chrome as a popover"* and draws `bg-primary`. `f-a` is the outlier — and the file everything cites as authority |
| 1.3 | **`bg-tertiary` is banned and specified as a chip ground.** `pf-a`: *"no content ground is bg-tertiary in a light colorset."* `st-b`: the overflow chip is *"`@bg-tertiary` with `@fg-primary`, **which measures ≥4.6:1 in all eight**"*; `st-c` uses it for the prefix legend. Measured: **4.39** latte, **1.70** sol-dark, **1.67** sol-light. The claim is false in three of eight, by 2.7× at worst |
| 1.4 | **`U+F026` carries three meanings.** `f-d`: volume **step 1/3** (muted has its own `U+F0581`). `pop-b`, `st-d`: **muted**. `st-e`: **no audio server** |
| 1.5 | **Bluetooth glyphs inverted.** `f-d`: `U+F294` = *device connected*, and *"no 'bluetooth off' glyph is adopted"*. `pop-d`, `st-e`: `U+F294` = *off* |
| 1.6 | **Tray overflow disagrees twice.** `f-d`: `U+F0D7` at **>6**. `st-b`: `U+F142` at **>8** |
| 1.7 | **Workspaces: dots vs pills.** `f-d` specifies `U+F111`/`U+F10C` dots at 6–8px. `bar-a` and all three bars in `st-b` draw **numbered pills at every state**. `f-d` also abandons its own glyph mid-row (*"at 11px the ring closes up; drawn as a 6px outlined dot rather than the glyph"*) |
| 1.8 | **Motion tokens transposed in three files.** `f-c` defines `motion-slow 180` / `motion-enter 220`. `st-a`, `st-d`, `pf-a` all write them swapped. `f-c`'s own transition table is internally consistent |
| 1.9 | **The accent tint has five values for one idea** — 13% (`launch-a`), 16% (`f-b` list row), 18% (`f-b` bar chip, `pop-a`), 16%→28% (`f-b` pill hover), 24% (`pf-a` ruling) |
| 1.10 | **`st-b` assumes a meter state `pop-g` doesn't define.** `st-b`: *"two readouts → one → glyph only"*. `pop-g`: *"one mono percentage — the highest of the three"*, no two-readout state. `bar-a` draws a two-readout pill `pop-g` explicitly declines as the bar's forbidden second permanent pill |
| 1.11 | **"Two popovers never at once"** (`pop-a`) vs `pf-c`'s **per-output** coordinator, *"two screens may each show one"*. `pf-c` is right |
| 1.12 | **Network: hide the widget, but there's a wired glyph.** `st-e` hides it when the adapter is absent, *"since an ethernet-only desk has nothing to report"*. `f-d`: `U+F0E8` wired *"takes priority over wireless"* |
| 1.13 | **Session tile roles differ.** `ses-a`: suspend `@accent-subtle`, five tiles. `f-d`: suspend `@accent-border`, plus a hibernate tile at `@accent-info`. `f-d` also gives `accent-border` a second job while `f-a`/`f-b` reserve it for focus — which `pf-a` then strips |
| 1.14 | **`st-a`'s "the one place `@fg-secondary` is legal"** is wrong three times: `f-a`'s grounded rule makes every bar widget at rest `fg-secondary` on `bg-primary`; `pop-a`'s footer is too; so is `st-c`'s empty line |
| 1.15 | **`f-a`'s type "scale" is three sizes**; the artboards draw 9.5, 10, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 14, 16 plus 26/28/32 glyphs. `pf-b` derives *geometry* from `base-size` and leaves type an unstructured list |
| 1.16 | **`pop-a`'s arithmetic doesn't close.** *"8 × 34 + gaps = 336, which is where `popMaxH` lands"* — and `popMaxH` is **420**. 8×34 = 272; +7 gaps = 328; +header 34 +footer 32 = 394. Presented as derived; it is not |

---

## Part 2 — Claims that are numerically false

`pf-a` measured **two** colorsets. Its Latte and Solarized numbers reproduce here exactly, so its
method is sound — but six colorsets were never checked.

### 2.1 The focus-ring ruling doesn't fix what it was made for

`pf-a` demotes `@accent-border` (2.81 Latte) and moves the ring to `@accent-primary`. Worst case
across all 8, against **both** grounds a ring sits on:

| Candidate | Worst | Fails 3:1 in |
|---|---|---|
| `ACCENT_BORDER` | **1.81** | latte, gruvbox-light, solarized-dark |
| `ACCENT_PRIMARY` | **1.81** | gruvbox-light |
| `ACCENT_INFO` | 2.31 | latte, gruvbox-light, solarized-light |
| `ACCENT_ERROR` | 2.81 | solarized-dark |
| `FG_PRIMARY` | **3.64** | **none** |
| `FG_SECONDARY` | **4.02** | **none** |

**No accent role clears 3:1 in all eight.** The ring moved from failing in three themes to failing
in one — an improvement, not a fix, invisible to `pf-a` because gruvbox-light was not measured.

Computed per theme as the better of `ACCENT_PRIMARY` / `FG_PRIMARY` against the actual ground:

| latte | mocha | gruv-d | gruv-l | rp-dawn | rp-moon | sol-d | sol-l |
|---|---|---|---|---|---|---|---|
| 5.17 | 8.69 | 8.45 | 8.45 | 6.66 | 10.90 | 4.11 | **3.64** |

### 2.2 "Disabled at 55%" is off by ~1.6×

`f-b`: *"Disabled at 55% measures 3.4:1 in Mocha and 3.1:1 in the worst of the eight."* Measured,
compositing the rest state at 55% over its own ground:

| Composite | Worst | Fails 3:1 in |
|---|---|---|
| `fgSecondary` @55% on `bgPrimary` | **1.98** | latte 2.28, gruv-l 2.64, rp-dawn 1.98, rp-moon 2.44, sol-d 2.66, sol-l 2.18 |
| `fgPrimary` @55% on `bgSecondary` | **1.90** | latte 2.24, gruv-l 2.80, rp-dawn 2.52, sol-d 2.22, sol-l 1.90 |

Six of eight fail, both forms.

### 2.3 `pf-b`'s density ramp is not derived

The multipliers reproduce the `13` column exactly and neither other:

| Token | ×base | @12 computed | @12 table | @14 computed | @14 table |
|---|---|---|---|---|---|
| `barHeight` | 3.08 | 37 | **34** | 43 | **46** |
| `chipSize` | 2.0 | 24 | 24 ✓ | 28 | **30** |
| `pillHeight` | 1.85 | 22 | 22 ✓ | 26 | **28** |
| `rowH` | 2.62 | 31 | **30** | 37 | **38** |
| `launcherRowH` | 3.7 | 44 | **42** | 52 | **54** |
| `gap` | 0.62 | 7 | **6** | 9 | **10** |
| `pad s/m/l` | .92/1.23/1.85 | 11/15/22 | **10/12/20** | 13/17/26 | **14/18/28** |
| `popMinW·popMaxW` | 26 | 312 | **320** | 364 | **380** |
| `popMaxH` | 32 | 384 | **380** | 448 | **470** |

The floor argument fails likewise: *"at base-size 11 the ramp yields barHeight 31 and rowH 28"* —
3.08 × 11 = 34, 2.62 × 11 = 29.

### 2.4 "The tint rises to 24% in light colorsets" is backwards

`fgPrimary` on an `accentPrimary` tint over `bgPrimary`:

| Tint | latte | gruv-l | rp-dawn | sol-l | sol-d |
|---|---|---|---|---|---|
| 13% | 5.96 | 9.30 | 5.82 | **3.57** | **4.00** |
| 18% | 5.56 | 8.96 | 5.52 | **3.37** | **3.72** |
| 24% | 5.12 | 8.57 | 5.17 | **3.15** | **3.42** |

More tint is monotonically **worse everywhere**, Latte included. `pf-a` presents 24% as a rescue;
it is the least contrasty option measured. In both Solarized sets the pairing fails at every
level, so the tint is not the lever.

**But the tint's other obligation is real, and `pf-a`'s instinct was sound.** Measured against its
own *untinted* ground, a tint reaches only **1.10–1.98 at every level in all eight** — it can never
be a 3:1 UI component. The design already handles this (`f-b`'s selected row pairs the tint with an
accent glyph; `launch-a` adds a `↵` on the selected row only). The tint is a hint with a second
carrier, which is correct.

### 2.5 Failures in the six unmeasured colorsets

Floor in brackets:

| Pair · where | Worst | Fails in |
|---|---|---|
| `fgPrimary` / `bgSecondary` — `f-a` calls this *"the only legal pairing on an elevated ground"* [4.5] | 3.64 | sol-l 3.64, sol-d 4.11 |
| DND banner: `fgPrimary` on 12% warning tint (`st-a`) [4.5] | 3.68 | sol-l, sol-d 4.13 |
| Error block: `fgPrimary` on 14% error tint (`pop-c`) [4.5] | 3.38 | sol-l |
| Card action outline: `fgMuted` on `bgOverlay` (`pan-a`, `st-a`) [3.0] | 2.18 | sol-l, sol-d 2.42, rp-moon 2.25, rp-dawn 2.87 |
| Calendar outside-month days: `fgMuted` on `bgPrimary` (`pop-e`) [4.5] | 2.48 | six of eight |
| `accent-warning` as a glyph [3.0] | 2.05 | rp-dawn, gruv-l 2.19, latte 2.31, sol-l 2.98 |
| `accent-info` as a glyph [3.0] | 2.80 | gruv-l, sol-l 2.93 |
| `accent-tertiary` — `ses-a` Lock/Log out [3.0] | 2.60 | rp-dawn, latte 2.64 |
| `accent-alternative` — `ses-a` Reboot [3.0] | 2.47 | latte, gruv-l 2.80, sol-l 2.93 |
| `accent-subtle` — `ses-a` Suspend [3.0] | 2.34 | latte, sol-l 2.48, rp-dawn 2.73, sol-d 2.79 |

`accent-performance` (3.30), `accent-media` (3.43) and `accent-highlight` (3.43) pass — the three
roles the design most wants to introduce.

The `ses-a` rows matter: Amendment B declined the five-colour power menu on *aesthetic* grounds.
There is now a measured reason too.

### 2.6 The card-outline regression

`pan-a` and `st-a` specify the Dismiss/action outline as `@fg-muted`, *"the one legal use of that
token, since it carries no text."* Amendment D already measured that pair at **2.18:1** and moved
it to `fgSecondary`. Carrying no text does not exempt it — 3:1 applies to UI graphics, and an
outline is one.

### 2.7 The WCAG allowance, both directions

`pf-a` invokes large-text (3:1) for "≥12.5px/600" and for the 12.5px severity title. WCAG's
threshold is **18.66px/700 or 24px** — neither qualifies, so 4.46 and 4.06 are not rescued. The
repo's lint errs oppositely, applying 4.5 to 28px OSD and 32px power-tile glyphs that are graphics
at 3:1.

---

## Part 3 — Design against implementation

### 3.1 Shipped defects the design correctly identifies

| Site | Shipped | Measured | Design's fix |
|---|---|---|---|
| `WorkspacesWidget.qml:68,90` occupied/hover pill | `fgPrimary` on `bgTertiary` | **1.67** sol-l, **1.70** sol-d, **4.39** latte | `pf-a` — no content ground is `bg-tertiary` |
| `NotificationCentre.qml:238` empty state | `fgMuted` on `bgPrimary`, one line | 2.48–3.49 in six themes | `st-a` — two lines, `fg-primary` + `fg-secondary` |
| `WindowTitleWidget.qml:15`, `MediaWidget.qml:35` | truncate at 50 / 35 **characters** | a character budget does not bound pixels — `WWWW…` is ~3× `iiii…` | `st-b` — pixel elide at `titleMaxW`/`titleMinW` |
| `BacklightWidget.qml:17` | 7-step glyph ramp on the **bar** | `f-d`: 7 steps indistinguishable at 16px | `f-d` — 7 in the OSD only, 3 elsewhere |
| `ClockWidget.qml:25` | month calendar in a **hover tooltip** | — | `pop-e` — the strongest single argument in the popover round |
| `BluetoothWidget.qml:29` | `accentPrimary` when connected | — | `f-a`'s own rule reserves `accent-primary` for *the one active thing* |

`WorkspacesWidget` is the significant one: three failing themes, invisible to
`lint:theme-contrast` because `FG_PRIMARY`/`BG_TERTIARY` is not in its `PAIRS` table.

### 3.2 The `fg-muted`-on-`bg-primary` cluster

Six shipped sites use it as **text**: `ClockWidget` date, launcher footer and rest-row exec,
notification-centre empty state and footer, empty workspace pill. Measured 2.48–3.49 in six of
eight against a 4.5 floor. `theme-contrast.py:44` marks it `INHERENT` — excused because Waybar and
wofi render the same ratios.

Reasonable when the goal was parity with the tools being replaced; worth reopening now. The design
bans `fg-muted` as text on every *elevated* ground and then relies on it on the *primary* ground in
`pop-e`, `st-c` and `launch-a`. Either it is a text colour or it is not.

### 3.3 Where the design is out of date about the code

- `launch-a`: *"the zero-match case is undrawn"* — `st-c` draws it.
- `launch-b`: *"no frecency cache today"* — shipped 2026-09-01 (`f50ff501`), reading
  `~/.cache/wofi-drun`. That cache is **read-only** from the shell's side, which breaks `st-c`'s
  *"self-deleting after three launches"* legend: nothing counts launches.
- `pan-c` is still live while `pop-a` and `pop-g` both say they replace it.

### 3.4 Where the implementation is already ahead

- **Scrim** is 86%; `pf-a` measures 72% as the floor. Ours is stricter.
- **`@scrim`/`@scrim-fg`** are theme-invariant, so they are computed values, not the two extra
  colorset tokens `pf-a` describes. `Theme.qml` already computes both.
- **Battery green** is already off the bar — `BatteryWidget.qml:60` is neutral at rest. Measured
  `accent-success` on `bgPrimary` is 2.73–2.97 in three light themes, so `pf-a`'s ruling is right;
  the tree got there first.
- **Notification popups** already route by `x-canonical-monitor` with a focused-screen fallback and
  do not follow focus — exactly `pf-c`'s rule.
- **OSD** is already one window, click-through, focus-following, no keyboard grab.

### 3.5 One claim of ours that was wrong

A 2026-09-03 planning note deferred `pf-d` partly because *"Quickshell 0.3.1 exposes no polkit
module; this would be a hand-written `org.freedesktop.PolicyKit1.AuthenticationAgent`."*
**False.** `Quickshell.Services.Polkit` ships `PolkitAgent` + `AuthFlow`, and
`Quickshell.Services.Pam` ships `PamContext`; both are installed and both map onto `pf-d` closely.
See `_research/QUICKSHELL_QML_API.md`. The remaining risk is agent exclusivity, not implementation
cost.

---

## Part 4 — Decisions worth reopening

1. **`fg-muted` as a text colour** (3.2). The `INHERENT` exemption predates having a stated
   contrast law.
2. **Solarized's `FG_PRIMARY`** — 4.13 light / 4.75 dark on their own grounds, while each set's
   `FG_SECONDARY` measures better (4.99 / 5.61). A colorset bug, as `pf-a` says.
3. **`accent-border`'s role** — stripped of focus by `pf-a`, given a session tile by `f-d`, unused
   elsewhere. It currently means "whatever is left over".
4. **`bg-tertiary`'s role** — after `pf-a`'s ruling it may not ground content in four of eight
   themes, and `themes/CLAUDE.md` already bans `fg-muted` on it. Almost no legal use remains.
5. **Per-widget accent roles at rest** — declined twice on taste; now also measurable (2.5).
6. **The type scale** (1.15) — if geometry is worth systematising, so is type.
7. **`st-e`'s "no compositor socket → no bar at all"** — the clock, launcher and battery do not
   need Hyprland.

---

## Appendix — reproducing

Same formula as `.mise/tasks/lint/theme-contrast.py`, over the eight colorsets. That lint does
**not** cover most of these pairs: its `PAIRS` table is hand-harvested from the *shipped* tree, so
pairs the design introduces are invisible until they ship. The one it should already have had is
`FG_PRIMARY` / `BG_TERTIARY` — which is how 3.1's workspace-pill defect went unmeasured.

---

# Part 5 — the fourteen-page rewrite (2026-09-08)

**Source**: `Shell-00-Index` … `Shell-13-Accessibility`, read in full except page 12 (polkit and
lock screen), which the index marks deferred on safety and which nothing implemented depends on.

The rewrite is a genuine improvement on the nine-file set: it replaces module-named colour tokens
with a **role system**, states a **behaviour law**, and carries its own **worst-of-eight contrast
table** (page 13) rather than leaving the numbers to a reader. Most of Part 1's contradictions are
gone. What follows is what survived, plus what the new set gets wrong — measured the same way.

## 5.1 — It still contradicts itself, in four places

| # | Conflict | Ruling here |
|---|---|---|
| 5.1a | **`inkOnSignal` is a fixed binding, or it is computed.** Page 01's tier-4 table: *"GROUND_BASE always — a fixed binding, not a computation."* Pages 04 and 07 both say *"computed `inkOnSignal`"* | **Computed.** The computation picks whichever of `FG_CONTRAST` / `BG_PRIMARY` contrasts more against the accent, and `BG_PRIMARY` **is** `GROUND_BASE` — so its result is ≥ the fixed binding in every theme, and can never be worse |
| 5.1b | **`ground-float` carries `ink-primary` only, except where it doesn't.** Page 01's tier-1 table binds `GROUND_FLOAT` as *"Carries INK_PRIMARY only"*. Page 07 draws the notification card's timestamp in `ink-secondary`, on a card whose ground is `ground-float` | **Foundation wins.** Every string on the card stays `inkPrimary`; hierarchy comes from size, weight and mono-vs-sans |
| 5.1c | **The OSD's own fill fails the design's own graphic floor.** Page 08 puts the progress track on `ground-raised` and its fill on `fill-inert`, calling that *"the one legal use of that tier"*. Measured, `FILL_INERT` on `GROUND_RAISED` is `#45475a` on `#313244` in Mocha — about **1.3:1**, against the 3:1 page 13 sets for a graphic | **Rejected.** The fill stays `accentPrimary` on a `groundRaised` track, which was measured at ≥3:1 in seven of eight on 2026-09-01. Both candidate pairs are now rows in the contrast lint so the comparison is on record |
| 5.1d | **Page 13's own worst case for `inkOnSignal` is not the worst case.** The row reads *"4.34 · latte · bound"*. Measured across all eight, the bound value is worse than that in **rose-pine-dawn**, where even the computed pick reaches only **3.47** | Not a defect in the code — the computed pick is already the best available — but the *number* on page 13 is wrong, and it is the number that justifies "a signal fill carries glyphs only" |

## 5.2 — Where the design is right and this tree was wrong

All four were shipped defects, all four are fixed, and none was visible in Mocha.

| Site | Was | Measured | Now |
|---|---|---|---|
| Occupied workspace pill | `FG_PRIMARY` on `BG_TERTIARY` | **1.67** sol-light, 1.70 sol-dark, 4.39 latte | `inkPrimary` on `groundRaised` |
| Notification severity | the title in `ACCENT_ERROR` | **2.81** worst as text, banned in all eight | glyph chip tint **and** a different glyph; no severity title |
| PowerMenu scrim | `BG_PRIMARY` at 86% | that token is 0.71–0.96 luminance in all four light colorsets | `Theme.scrim` at `Config.scrimOpacity`, with `fgOnScrim` on everything drawn on it |
| Battery low band | `ACCENT_WARNING` glyph | **2.05** rose-pine-dawn, 2.19 gruvbox-light — under the 3:1 a graphic owes | shape only; `signalError` is the sole colour, and it clears 3:1 everywhere (worst 3.25) |

The last row generalises, and it is the sharpest thing the new set says: **no accent role clears
3:1 in all eight colorsets, and gruvbox-light is the worst case for every one of them.** That is
the evidence for L1 — anything load-bearing is foreground-class — and acting on it removed the
`INHERENT` exemption block from `.mise/tasks/lint/theme-contrast.py` entirely, because the pairs it
excused are no longer drawn rather than being excused.

## 5.3 — Deliberate departures

Recorded in full, with reasons, in `private_dot_config/quickshell/CLAUDE.md`. In brief: six session
tiles rather than five (hibernate works here); Lock still pre-selected; the OSD fill above; one
density column rather than three, because the only thing that could select a column is the system
menu, which is not built.

## 5.4 — Still open

1. **Solarized's `FG_PRIMARY`** — Part 4.2's finding, which page 13 independently confirms and
   calls a colorset bug. Unfixed: it belongs to `themes/*/colors.sh`, not to any consumer.
2. ~~**The colorset rename.**~~ **Done 2026-09-09** (commit `60cd3300`): the colorsets carry the
   18 role names themselves, `Theme.qml` reads the key of the same name, and six keys with no
   consumer were deleted.
3. **`signal-warn` / `signal-info` have no legal graphic use left.** Both are under 3:1 on their own
   ground in four of eight, so nothing in the shell draws them; they sit in `Theme.qml` bound and
   unused. Either a future surface finds a ground they clear, or the palette owes them one.

## 5.5 — Page 06 rulings (2026-09-10, when the popovers were built)

Five, in the same style as 5.1. The first two are contradictions inside the set; the rest are
places the design assumes hardware or data this machine does not have.

| # | Page 06 says | Ruling | Measurement |
|---|---|---|---|
| 5.5a | The slider's filled portion is `fill-inert` on a `ground-raised` track — *"the one legal use of that tier, and the reason it exists"* | **Rejected.** Fill is `signalFocus` | `FILL_INERT` on `GROUND_RAISED` measures **1.15** (rose-pine-dawn) and 1.3 (mocha) against the 3:1 page 13 sets for a graphic. Identical to 5.1c, which page 08 had already produced for the OSD; both are now BANNED rows in `theme-contrast.py` so the number survives |
| 5.5b | The thumb carries *"the `accent-border` hairline inside it, which is that token's one remaining job"* | **Rejected.** `Theme.edge` | `ACCENT_BORDER` was one of the six keys deleted from all 8 colorsets on 2026-09-09 for having no consumer — and page **13** itself lists it as *"compositor decoration — outside the shell's set, measured here only so nobody re-adopts it"* at 1.81. Page 06 contradicts page 13; page 13 wins |
| 5.5c | The meters payload is CPU, memory, **temperature**, uptime | Temperature **not built**; uptime added | Not a contrast question: a temperature is not a percentage until someone names the hwmon path and the threshold it is a percentage OF. `Meters.qml` carries the note and the place it goes |
| 5.5d | The power payload carries a **profile** control | **Not drawn** | `power-profiles-daemon` is not installed here, and `PowerProfiles.profile` still answers "Balanced" with no daemon running — so the control would state a profile that is not real. Page 03's own rule: a control that would do nothing is removed, never disabled |
| 5.5e | A meter's warning states are a ramp — `signal-warn` then `signal-error` | The band is a **word**; only critical takes colour | `SIGNAL_WARN` on `GROUND_BASE` is 2.05 (rose-pine-dawn), under the graphic floor in four of eight. Same finding that moved the battery's low band onto its glyph in 5.2 |

One thing page 06 asks for that is **not a design defect but a platform limit**: pointer-opened
popovers are specified to close on a click outside, with no keyboard grab. Under layer-shell
there is no mechanism that does both — `PopupWindow.grabFocus` fails outright on a layer parent
and `HyprlandFocusGrab` takes the keyboard. Pointer mode therefore closes on losing the pointer
instead. Measurements and the exact Qt errors are in `.claude/rules/quickshell-qml.md`.
