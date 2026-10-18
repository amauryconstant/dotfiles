---
paths:
  - "private_dot_config/quickshell/**/bar/**"
  - "private_dot_config/quickshell/**/dock/**"
  - "private_dot_config/quickshell/**/notifications/**"
  - "private_dot_config/quickshell/**/launcher/**"
  - "private_dot_config/quickshell/**/menu/**"
  - "private_dot_config/quickshell/**/clipboard/**"
  - "private_dot_config/quickshell/**/osd/**"
  - "private_dot_config/quickshell/**/power/**"
  - "private_dot_config/quickshell/**/polkit/**"
  - "private_dot_config/quickshell/**/lock/**"
  - "private_dot_config/quickshell/**/keybindings/**"
  - "private_dot_config/quickshell/**/overview/**"
  - "private_dot_config/quickshell/**/Theme.qml"
  - "private_dot_config/quickshell/**/Config.qml.tmpl"
---

# Quickshell Design Rules: Geometry, Accent, Contrast, Theming

What a surface may draw. Loads for files that draw something; the QML syntax, tooling and runtime
traps are in `.claude/rules/quickshell-qml.md`, and the measurements behind these rules are in
`_research/archive/QUICKSHELL_RULE_EVIDENCE.md`.

**See**: Root `CLAUDE.md` for core standards · `private_dot_config/themes/CLAUDE.md` for the theme system

---

🚨 **A modal scrim cannot be built from a background token.** `GROUND_FLOAT` measures 0.71–0.96
luminance in all four light themes, so an 86% scrim over it renders near-white — and
`INK_CONTRAST_CANDIDATE` inverts per theme (0.006 in mocha, 0.88 in gruvbox-dark). A scrim is a *shade*,
not a theme colour: `Theme.scrim` is a deliberate literal, under the same exemption as
`Theme.qml`'s fallbacks.

🚨 **Then everything drawn on it needs `Theme.fgOnScrim`.** The scrim is dark in every theme,
so a light theme's own foregrounds land on it at **1.81** (gruvbox-light) and 2.63 (latte) and
are simply not there. A computed pick, better of `INK_PRIMARY` / `GROUND_BASE`;
worst case across all 8 becomes 6.64. `mise run lint:theme-contrast` checks both, in their own
section — the scrim is not a colorset token, so the `PAIRS` table cannot express it.

---

## Geometry and the accent rule

Both originate in Amendment A of the frozen `_plans/archive/QUICKSHELL_SHELL.md` (which cites a
design set that no longer exists), and both live in exactly one place here.

**Geometry** is the scale in `Config.qml.tmpl`, and a widget never writes a radius, a
spacing, a font size or an animation duration of its own.

🚨 **There are exactly THREE radii, and radii are NOT on the density ramp**: `radiusChip` 8
for chips and rows, `radiusPanel` 12 for surfaces, `radiusPill` 999. The four-step ramp this
tree used to carry (plus a fifth at 14 on the power tiles and a sixth at 6 on tooltips) was
inventing distinctions no surface needs — a tooltip and a chip are the same kind of thing.
Spacing is `gap` 8 and `padTight`/`pad`/`padLoose` 12/16/24; `rowH` 34 is a list row and
`launcherRowHeight` 48 is a two-line one. `barHeight` 40, `barInset` 4, `chipSize` 26,
`pillHeight` 24.

🚨 **`hitMin` 32 does not scale with anything.** It is a pointer fact, not a density
preference: a widget whose paint is 26 still claims 32 of pointer space. `BarWidget`'s
`MouseArea` floors at it, which costs no layout because chips sit `gap` apart and two 32px
areas on adjacent 26px chips are 34 apart.

**Type is six steps and four glyph sizes, and nothing outside them is drawn**: `fontMeta` 11,
`fontBody` 12, `fontTitle` 14, `fontDisplay` 20 (the OSD readout and the lock's date), with glyphs
at `glyphRow` 13, `glyphBar` 16, `glyphOsd` 28, `glyphTile` 32. QML's `font.pixelSize` is an
**integer**, so the design's half-pixel steps round here — meta 10.5 → 11, title 13.5 → 14.
That is a QML constraint, not a reading of the design.

🚨 **The scale is calibrated for a 40px bar and 340px panels, and the LOCK is the one
full-screen surface.** Page 12's 220x34 field is correct against the scale and wrong against
the surface — at 1920x1080 it reads as a popover control dropped onto a wall. So the lock
carries panel measurements of its own in `Config.qml.tmpl`, beside `polkitDialogWidth` and for
the same reason (the scale does not supply how wide a panel is): `lockFieldWidth` 360,
`lockFieldHeight` 56, and `lockClockSize` 72 — the one type size outside the six steps, taken
because there is no other display-sized thing on that screen to be consistent with. Everything
else the lock draws still comes from the scale. This is the exception, not a licence: a surface
that is not full-screen has no claim to one.

**Motion is three durations**: `motionFast` 120 (hover and press tints, meter fills),
`motionSlow` 180 (reflow, pill travel, OSD fade-out), `motionEnter` 220 (arrival). Never
animated: text replacing text, the focus ring, and anything whose only change is a colour role
— which is why a live theme switch repaints with no transition at all.

🚨 **A control's boundary owes 3:1 against its ground, and a ground-tier step never supplies
it.** The notification primary was `groundRaised` on the card's `groundFloat`: **1.00** in five
of eight colorsets, 1.27 at best. It had no edge, stood beside 3:1 outlines, and read as the
*disabled* button — and since `groundRaised` is also `Theme.hover`, it looked hovered at rest.
The centre's Clear chip was the same defect one tier down (`groundRaised` on `groundBase`, 1.05
in rose-pine-dawn). Tier steps are hover and elevation, never a boundary. Both tier pairs are
`BANNED` rows in `lint:theme-contrast`.

🚨 **Every push button is `bar/ActionButton.qml`, and colour is what ranks it.** `primary` is a
`Theme.action` fill with an `inkOnAction` label — the one thing the surface asks for. `secondary`
is a `Theme.action` outline and label — anything else the sender offers. `neutral` is an
`inkSecondary` outline with an `inkPrimary` label — *ours*, not the sender's: Dismiss, Cancel,
Clear. Colour means "does something", grey means "go away". A first pass (2026-10-06) made the
primary an `inkPrimary` fill to keep the accent for focus; it read as one more grey button and was
reversed the same day — an action that does not look like one blends into the card.

**Truncation is by PIXELS, never by character count.** `titleMaxLength` and
`mediaMaxLength` are gone: `WWWW…` is about three times the width of `iiii…`, so a character
cap does not bound the bar. Set `labelMaxWidth` on `BarWidget` and let `Text.elide` do it —
`labelElideMode: Text.ElideMiddle` for a path, whose identifying half is its tail.

**The design publishes three density columns** (compact 12 / default 13 / roomy 14). Only the
default is implemented: the one thing that could select a column is the system menu, which is
not built, and two unreachable columns are dead configuration.

**The accent rule** — *the accent marks focus and action, everything else neutral, semantic
colours only for state* — is enforced by `BarWidget.iconColor` on the bar and by `ActionButton`
everywhere a control is drawn. Focus is what you are on; action is what you can do (a button, a
link). Information is never accented. A widget overrides it only
for a genuine state (muted, disconnected, inhibited, low battery); at rest every widget is
the same colour. Set `icon`/`label` on `BarWidget` rather than declaring your own `Text`, and
the rule applies for free.

🚨 **`iconColor`/`labelColor` are not one fixed rest colour — they default to `restColor`,
which follows `grounded`.** A widget colouring for a state ends its ternary on `root.restColor`;
ending it on a flat `Theme.inkSecondary` pins the ungrounded colour onto a lit ground. That was
six widgets' worth of defect, found by the reviewer below and fixed 2026-09-01.
`themes/CLAUDE.md` bans the second ink on an elevated ground outright, and a hovered chip, a
pill and the launcher tint are all elevated surfaces. So the default is `inkSecondary` at rest
and `inkPrimary` the moment a ground appears. Anything that hardcodes one of the two
reintroduces the banned pair on half the widget's states.

🚨 **`signalError` is the ONLY semantic colour a bar widget may take.** Across all eight colorsets
`SIGNAL_WARN` is 2.05 (rose-pine-dawn) / 2.19 (gruvbox-light) and `SIGNAL_INFO` 2.80–3.31 in the
light sets — under the 3:1 a graphic owes — while `SIGNAL_ERROR` clears it everywhere (worst 3.25).
Warn and info states ride on their own **glyph** (battery low band, idle inhibitor, unread bell,
dictation states). `signalInfo` and `signalOk` are bound in `Theme.qml` and drawn nowhere.
`signalWarn` has one site, and it is a **ground**: `MetersWidget` tints its pill with it at 18%.
`lint:theme-contrast` measures that tint and the battery's 14% one as **composites** (a `Qt.alpha`
ground is not a token, so no `PAIRS` row can express it).

🚨 **The tinted pill's number is 3.19 at worst (solarized-light, critical) and that is ACCEPTED,
not a defect to fix** (measured 2026-09-13). The untinted pill is already 3.64 there, no alpha
recovers it (limit as alpha → 0 is 4.13), and swapping Solarized's two inks still misses (4.39 /
4.49) while demoting its body value. Six of eight themes clear 4.5 (worst 5.21, latte). The tint is
load-bearing: a `signalError` glyph on a pill is 2.81 on `groundRaised` in solarized-dark, which is
why `PowerMenu` moved its tiles off that tier.

`signalInfo` and `signalOk` stay **bound and undrawn**. Deleting them would save two lines
and break the rule `themes/*/colors.sh` states in its own header — the five SIGNAL roles stay
mutually separable in every theme — so a role model with three roles is a worse thing to own
than two unspent ones.

`labelColor` is split from `iconColor` so the glyph can carry a state while the number it
annotates stays readable — the battery pill is the case that needs it. `monoLabel: true`
puts a number in `terminalFont`: digits only line up fixed-pitch, and a proportional face
reflows the bar every time the value changes width.

`pill: true` gives a widget its own permanent ground. **Exactly two widgets have it** — the
battery and the meter — because charge and load are the two numbers that have to be readable
without a hover. The design draws both grounded; what it forbids is a *second meter* beside
the first, not a second ground.
`tinted: true` is the same idea without the pill radius, and **only the launcher chip has
it**: an accent ground at rest is the single fixed anchor the bar is allowed.
Everything else is icon-only, with its number in the tooltip.

`BarSeparator` binds to the group that **follows** it (`group: gPower`), so a group that
collapses to zero width on a desktop takes its leading hairline with it instead of leaving a
stray rule in the bar. **The hairline is `Theme.edge`** — bar border, separators, the gap dot
and every panel border alike. `edge` resolves to `groundRaised`; use the role name, because a
`border.color` and a ground are different jobs even where the value coincides.

🚨 **The hairline is `Theme.edge` = `groundRaised`, never `fillInert`.** An earlier mis-mapping read
the canvas's `#313244` as `FILL_INERT` and moved it one tier the wrong way in all 8 themes. Never
map a canvas colour by its LABEL (see "Map canvas colours by HEX").

### Contrast is measured, not eyeballed — `mise run lint:theme-contrast`

`themes/CLAUDE.md` states the rules and says outright that QML gets no automatic
enforcement. `.mise/tasks/lint/theme-contrast.py` is that enforcement: it reads all **8**
colorsets (not just the one symlinked at `themes/current`) and measures the pairs this tree
actually renders. Part of `mise run lint`, silent on success (`-- --report` prints the tables). Its pair table is
harvested by hand, so it goes stale silently when a widget changes a colour: re-harvest after touching any colour here.

🚨 **There is no `INHERENT` escape hatch.** Parity with an older tool (Waybar) is not a reason to
ship failing text, so accent-as-text pairs are no longer drawn rather than excused. A `BANNED` list
is measured and reported but asserted absent from the tree: a rule keeps its evidence.

🚨 **Harvest by parenting, never by grepping colour lines.** Most `Theme.groundRaised` uses here are
1px hairlines and borders, not grounds; reading `color: Theme.groundRaised` two lines above an ink
token invents failures that are not on screen (all five suspects in the 2026-09-01 pass were
hairlines).

Two thresholds, per WCAG 2.1: **4.5:1 for text, 3:1 for UI components and graphics** — an
outline, a progress fill. Getting this wrong in the strict direction is how a legitimate
outline gets "fixed" into a `fgPrimary` that competes with the button beside it.

The first run found four defects invisible on the one applied theme (OSD fill 1.38, OSD dimmed fill
1.00, PowerMenu avatar 1.46, NotificationCard outlines 2.18) and one pattern: **`fillInert` is the
trap tier** — a *material* that carries no text. Prefer `groundRaised` for any ground that has to
carry something. The 2026-09-08 pass added the occupied workspace pill (1.67, solarized-light).

### `Theme.action` — buttons, links, and accent fills that carry text

🚨 **Raw `signalFocus` cannot be an action colour in all 8 themes.** As a fill on a card it is
**1.81** in gruvbox-light (the shape vanishes); with the best computed label on it, the old
`inkOnSignal`, text reached only **3.47** in rose-pine-dawn and 4.08 in both Solarized sets.

So `Theme.action` is `signalFocus` pushed **away from the ground** — toward white on a dark
`groundBase`, black on a light one — in 5% steps, stopping at the first that clears 4.5 against
`groundBase` *and* `groundFloat` and 3.0 against `groundRaised`. It is then legal as text on both
grounds a control sits on, and `inkOnAction` (= `groundBase`) clears 4.5 on it by construction.
Measured 2026-10-06: mocha, gruvbox-dark and rose-pine-moon keep the raw accent; the largest
shift is gruvbox-light's (0.45 toward black, a darker amber `#765412`). The hue survives in all
eight, and the same derivation covers any colorset added later.

Use `action` + `inkOnAction` for: every `ActionButton`, a launchable popover footer hatch, the
focused workspace pill, the unread badge, the calendar's today, every text selection
(`selectionColor`/`selectedTextColor`). Graphics that carry no text — carets, the slider and OSD
fills, `PopoverRow`'s selected glyph, PowerMenu's current border, the launcher prefix glyph —
stay on raw `signalFocus` at their own 3:1. Raw `signalFocus` as a control fill on a card is a
`BANNED` row. `mise run lint:theme-contrast` reproduces the derivation per theme and fails if any
floor is missed.

### Reading the design source, not the transcription

The canvas lives in a Claude Design project (`1d494341-deaa-47cb-ac39-32ccb9c23862`), read through
the `DesignSync` MCP tool (`list_files`, then `get_file`; it needs its own authorization —
`/design-login`). Since the 2026-09-08 rewrite it has **fourteen pages** and every earlier artboard
id is dead. Pages **01** colour/type/motion, **02** geometry and **03** behaviour state the rules; a
surface page states only its own departures, so a number on a surface page that contradicts a
foundation page is a **defect in the design**, not a local override.

🚨 **Read `_research/archive/QUICKSHELL_DESIGN_AUDIT.md` Part 5 before implementing anything from a
page** — where the set contradicts itself, where its numbers are wrong, and which departures here
are deliberate.

The dock and the workspace overview have no page; both are dormant (`Config.dockEnabled` /
`overviewEnabled` false) and were declined in daily use — not deleted, not updated.

### 🚨 Map canvas colours by HEX, never by name

The canvas names three background tiers Catppuccin-style; our colorset has four, ordered
differently, and matching on the name caused the hairline defect. Map by hex against
`themes/<theme>/colors.sh` (mocha: `#313244` is `GROUND_RAISED`, `#181825` `GROUND_FLOAT`, `#45475a`
`FILL_INERT`). Copy a `Theme.qml` fallback from `colors.sh`, never a mockup. The canvas's fourth
background tier has no single equivalent here — collapsing a tier beats inventing a colour. The
"empty" workspace pill stays transparent on purpose: a ground would make it an elevated surface and
force `fg-primary` on the one state that has to recede.

---

## Theming

`Theme.qml` parses `~/.config/themes/current/colors.sh` at runtime — the same format-neutral
colorset every other app reads, so there is no ninth per-theme file. A missing key falls back to
hardcoded Catppuccin, which renders wrong colours **with no error**, so the property set must
stay complete, and every fallback is a verbatim copy from `themes/catppuccin-mocha/colors.sh` —
never from a mockup.

🚨 **The names are SEMANTIC ROLES, in the colorset too.** A token names a meaning or the module
that spends it, and only the first kind can be reasoned about (a module-named scheme cannot express
that a CPU readout and a failed service stay tellable apart). `Theme.qml` reads **the key of the
same name**; the 2026-09-09 rename deleted six zero-consumer keys (24 → 18).

| Tier | Roles | Colorset keys |
|---|---|---|
| Ground | `groundBase` `groundRaised` `groundFloat` | `GROUND_BASE` `GROUND_RAISED` `GROUND_FLOAT` |
| Material | `fillInert` | `FILL_INERT` — **never accepts text**, 1.67 at worst |
| Ink | `inkPrimary` `inkSecondary` | `INK_PRIMARY` `INK_SECONDARY` |
| Signal | `signalFocus` `signalError` `signalWarn` `signalOk` `signalInfo` | `SIGNAL_FOCUS` `SIGNAL_ERROR` `SIGNAL_WARN` `SIGNAL_OK` `SIGNAL_INFO` |
| Identity | `identity1`…`identity5` | `IDENTITY_1`…`IDENTITY_5` |

🚨 **The colorset parser's character class is `[A-Z0-9_]+`, not `[A-Z_]+`.** `IDENTITY_1`…`_5`
carry a digit, and a class without one drops all five silently into the hardcoded fallback —
wrong colours, no error. The same bug was live in `theme-contrast.py`'s own parser and was
fixed with it.

🚨 **`inkSecondary` is OFFERED, not guaranteed.** Design page 01: the quiet ink is "offered per
ground, per theme, and withdrawn where it fails". `Theme.qml` measures `inkSecondaryOffered`
against `groundBase` and falls back to `inkPrimary` below 4.5:1 — rose-pine-dawn (4.02) and both
Solarized sets, where the palette assigns body text to base0/base00. Withdrawing by measurement
fixes every colorset including any added later; hand-editing two palettes fixes two. Never
assign `inkSecondaryOffered` to a `color:` — it exists only to be measured.

**Six values are derived, not read**: `edge` (every hairline), `hover` (one opaque step up the
ground stack), `press` (`inkPrimary` at 8%), `select` (`signalFocus` at 13%, **always** paired
with a glyph or a weight change — the tint alone reaches 1.10–1.98), `focusRing` and
`disabledOpacity`. Plus `action`/`inkOnAction`, `scrim` and `fgOnScrim`, each because no token in the set
works across all 8 themes. `disabledOpacity` is measured against the **live** theme rather than
fixed — the lowest 5% step of `inkSecondary` over `groundBase` still clearing 3:1, which lands
between 0.60 and 0.85 depending on the colorset.

🚨 **`INK_MUTED` is not bound here at all.** It is banned as text (2.48 worst) and fails 3:1 as
an outline, so every former site is `inkSecondary` or the `disabled` derivation. It survives in
the colorset only because `core/gum-ui.sh` and `media/organize-wallpapers-by-color` spend it,
and a terminal is not a lit surface. `INK_CONTRAST_CANDIDATE` is not bound either since `action`
replaced the `inkOnSignal` pick it was a candidate for.

Deleted keys and why: see the evidence file.

Contrast rules from `themes/CLAUDE.md` are measured by `mise run lint:theme-contrast` across all 8
colorsets; what its hand-harvested pair table does not cover is by-hand discipline. The
`theme-consistency-reviewer` subagent takes this tree as a second target: literal hex (only
`Theme.qml`'s fallbacks), literal font name (only `Config.qml.tmpl`, via `globals.yaml`), and
`Theme.inkSecondary` on a lit ground — judged against `BarWidget`'s `grounded` ternary.
