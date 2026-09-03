# Design brief — round 5

**For**: Claude Design project `1d494341-deaa-47cb-ac39-32ccb9c23862`
**Evidence**: `_research/QUICKSHELL_DESIGN_AUDIT.md` — measurements and the full contradiction list.
**Date**: 2026-09-03

Rounds 1–4 are broad, and in places sharper than the implementation they describe. What they lack
is **internal consistency**, a **behaviour layer**, and **evidence that the colour rulings survive
the eight colorsets this shell ships**. Round 5 fixes those three and adds no new surfaces.

---

## 1. Decisions

### 1.1 Scope — this is a desktop shell, not a bar port

Quickshell replaces the desktop shell wholesale. The design should be **complete**: it owns every
surface a desktop shell owns. Prior declines made on *scope* grounds are withdrawn — clipboard
(`pan-b`) and system menu (`menu-a`/`menu-b`) are in scope, and `menu-a`'s own "EXPLORATORY ONLY
… out of scope" caveat should be removed.

A surface stays out only for a **technical or safety** reason, and must name what would change it:

| Surface | Status | Reason / condition |
|---|---|---|
| Polkit auth (`pf-d`) | **Deferred, weakly** | The API exists (below). The risk is exclusivity: one agent per session, so adopting it unregisters `polkit-gnome`, and a crash then leaves *no* agent — every privileged action fails until the shell restarts. Returns once the shell has a crash-recovery story. **Keep designing it** |
| Lock screen (`ses-b`) | **Deferred** | Same class: a crash in a lock surface is unrecoverable without a TTY. `WlSessionLock` + `PamContext` both exist |
| Control centre (`pan-c`) | **Superseded** | The seven popovers replace it — mark it so, rather than leaving it live |

🚨 **Correction.** An earlier note claimed a polkit agent would have to be hand-written over raw
D-Bus, and the deferral was taken partly on that basis. **It was wrong.**
`Quickshell.Services.Polkit` ships a `PolkitAgent` element and an `AuthFlow` object whose members
map onto `pf-d` almost exactly — `message`, `actionId`, `inputPrompt`, `supplementaryMessage` /
`supplementaryIsError` (the "2 attempts left" line), `isCompleted`/`isSuccessful`/`isCancelled`,
`submit()`, `cancelAuthenticationRequest()`. `Quickshell.Services.Pam` ships `PamContext`
likewise. Both verified in the installed 0.3.1. Details in `_research/QUICKSHELL_QML_API.md`.

**One real gap in `pf-d`**: `AuthFlow.identities` / `selectedIdentity` — polkit may offer a
**choice of user** to authenticate as. The artboard assumes a single implicit one.

### 1.2 Contrast — the design owns the law, the lint enforces it

The design keeps authorship: measuring before drawing is better practice than the repo's, and it
is how `pf-a` found the Solarized colorset bug the repo's lint had been *excusing*. In exchange:

- **Measure all eight colorsets, not two.** `pf-a`'s Latte and Solarized numbers reproduce
  exactly; its coverage does not. Gruvbox-light and rose-pine-dawn break rulings the two
  measured themes pass.
- **Every published number is a worst-of-eight, and names its theme.**
- `lint:theme-contrast` becomes the regression check on what the design ruled.

**Correction to carry**: `pf-a` invokes WCAG's large-text allowance (3:1) for "≥12.5px/600". The
threshold is **18.66px/700 or 24px**, so the 12.5px severity title at 4.46 and the accent-fill
text at 4.06 are not rescued by it. (The repo errs the other way, applying 4.5 to 28px OSD and
32px power-tile glyphs that are graphics at 3:1. Both get tightened.)

### 1.3 Feedback model — adopted whole, shell-wide

1. **A control that would do nothing is removed, never disabled.**
2. **The shell has no "action taken" affordance.** The surface changing *is* the confirmation; the
   shell never notifies about itself. (Notifications *from applications* are unaffected.)
3. **An operation in flight reports inside the row that started it**, siblings disabled. Never a
   toast, never a global spinner.

### 1.4 Degradation — per source, and hardware presence is not chassis

`st-e`'s law is adopted — **absent hardware hides, a failed service shows** — with two amendments:

- **Degrade per source, not per shell.** `st-e` drops the whole bar when the compositor socket is
  unreachable; the clock, launcher, battery and tray do not need Hyprland.
- **"No wireless adapter" ≠ "no network."** `st-e` hides the widget when the adapter is absent,
  but `f-d` defines a wired glyph (`U+F0E8`) that *takes priority over wireless*. The widget
  reports the active route and hides only when there is no networking at all.

---

## 2. Round 5 deliverables

### 2.1 Coherence — one normative reference

The design restates its own rules per artboard, and the restatements have drifted. Produce **one
normative reference** for tokens, glyphs, motion and geometry; every artboard cites it instead of
repeating it. Sixteen contradictions are catalogued in the audit's Part 1. Proposed rulings:

| Conflict | Ruling |
|---|---|
| `f-a`: `fg-muted` *is* the disabled colour; `f-b`: it cannot be | `f-b` — and further, **`fg-muted` is a non-text token**. It measures 2.48–3.49 on `bg-primary` in six of eight |
| `f-a` grounds popovers on `bg-tertiary`; `pop-a` on `bg-primary` | `pop-a` — see §2.3, the canvas's tier names do not map by label |
| `pf-a` bans `bg-tertiary` as a content ground; `st-b`/`st-c` use it for chips | `pf-a`. `st-b`'s "≥4.6:1 in all eight" is **1.67** at worst — the one place a false number justifies a choice |
| `U+F026` = volume-step-1 / muted / no-audio-server across artboards | **`f-d` is the single source of truth for codepoints.** It is the only file reasoning about 16px legibility |
| `U+F294` = "connected" (`f-d`) vs "off" (`pop-d`, `st-e`) | `f-d` |
| Tray overflow `U+F0D7` at >6 vs `U+F142` at >8 | Pick one; 8 matches the launcher's existing cap |
| Workspaces: dots (`f-d`) vs numbered pills (every drawn bar) | Pills — `f-d` abandons its own glyph mid-row |
| Motion tokens transposed in `st-a`, `st-d`, `pf-a` | `f-c` — its table is internally consistent |
| Accent tint has five values (13 / 16 / 18 / 16→28 / 24) | **One token**, computed — see §2.3 |
| `st-b` assumes a two-readout meter `pop-g` doesn't define; `bar-a` draws a pill `pop-g` declines | `pop-g` |
| `pop-a`: "two popovers never at once"; `pf-c`: per-output coordinator | `pf-c`; restate `pop-a` |
| `ses-a` suspend `@accent-subtle` vs `f-d` `@accent-border` + a hibernate tile | Reconcile; `accent-border` needs **one** job |
| `st-a`: "the one place `@fg-secondary` is legal" | It is legal on `bg-primary` generally — bar rest, popover footers, empty states |
| `f-a`'s type "scale" is 3 sizes; artboards draw 11 | Systematise, or state that type is chosen per surface |
| `pop-a`: "8 × 34 + gaps = 336, which is where `popMaxH` lands" (`popMaxH` = 420) | Neither number derives from the parts — fix or stop calling it derived |
| `pf-b`'s multipliers reproduce only the middle column | §2.4 |

Also retire: `launch-a`'s "the zero-match case is undrawn" (`st-c` draws it) and `launch-b`'s
"no frecency cache today" (shipped 2026-09-01, reading Wofi's `~/.cache/wofi-drun`). That cache is
**read-only** from the shell's side, which breaks `st-c`'s "self-deleting after three launches" —
nothing counts launches.

### 2.2 Behaviour — the layer that was started and never finished

`pf-c`'s one-word-per-surface table is the model. Extend it to: the **keyboard model per surface**
(who grabs, what Esc does, where focus lands on open); **focus order across the bar** (is the bar
Tab-reachable at all, and how does a popover's trap interact with it); **live theme switch** (what
happens to an open popover, a mid-flight animation, a running OSD hold when the palette changes);
**monitor hotplug** beyond `pf-c` (a popover mid-animation on a vanishing output); **shell
restart** for every surface, and whether "nothing persists" is desirable or merely current; and
**scroll, drag and swipe** — `st-a` mentions "swipe → dismiss" in a footer and nothing specifies
it, while bar widgets take the wheel today and the design never mentions it.

### 2.3 Theme adaptability — rules that hold by construction

The canvas is drawn in Mocha, so a rule that happens to work in Mocha reads as a rule that works.

**Four facts, each verified against `themes/*/colors.sh`:**

1. **Canvas colours map by HEX, never by label.** The canvas names three background tiers; the
   colorset has four, ordered differently. Canvas `#181825`, labelled "bg-tertiary", is our
   **`BG_OVERLAY`**. Our `BG_TERTIARY` (`#45475a` in Mocha) is a tier the canvas never draws.
   This one mismatch is why `bg-tertiary` reads as legal in `f-a`, banned in `pf-a`, and
   load-bearing in `st-b`/`st-c`.
2. **`BG_TERTIARY == BG_OVERLAY` in exactly one theme** (rose-pine-moon).
3. **No accent role clears 3:1 in all eight** against the grounds a ring or outline sits on:
   `ACCENT_BORDER` 1.81, `ACCENT_PRIMARY` 1.81, `ACCENT_INFO` 2.31, `ACCENT_ERROR` 2.81. Both
   foreground tokens do: `FG_PRIMARY` 3.64, `FG_SECONDARY` 4.02.
4. **A tint is never a UI component.** Against its own untinted ground an accent tint reaches
   **1.10–1.98 at every level in all eight**. It cannot carry a selection alone at any percentage.

**Three laws, proposed as the spine of the reference:**

> **L1 — Anything that must stay legible is foreground-class. Accent is never load-bearing.**
> `f-a` already says *"borders are foreground-class only"*; extend to rings, outlines, separators,
> hairlines. This dissolves the focus-ring search: `pf-a` moved the ring from `accent-border`
> (fails in three themes) to `accent-primary` (fails in one) — a relocation, not a fix.

> **L2 — Any colour whose job is defined against a ground is computed per theme, never fixed.**
> Already the established pattern: `fgOnAccent`, `scrim` and `fgOnScrim` are each computed,
> because no fixed token survived eight colorsets. The ring is the fourth case, the tint the
> fifth. Computed as the better of `ACCENT_PRIMARY` / `FG_PRIMARY` against the actual ground, the
> ring measures **3.64 worst, 8.69 median** — and keeps the accent in the six themes where it
> reads as brand.

> **L3 — Colour is never the sole carrier of state. Shape, number or position carries it;
> colour decorates.**
> The design already does this well locally — `f-d`'s *"every flagged glyph is paired"*, `pf-a`'s
> *"the battery glyph carries shape, not colour"*, `f-b`'s selected row pairing its tint with an
> accent glyph, `launch-a`'s `↵` on the selected row only. Promoting it to a law is what makes
> fact 4 survivable, and it reclassifies most accent contrast failures from defects into
> acceptable decoration.

**Then the four tiers, so `bg-tertiary` stops being ambiguous:**

| Tier | Job | Carries text? |
|---|---|---|
| `bg-primary` | every panel, bar, popover and OSD ground | yes — `fg-primary`, `fg-secondary` where ungrounded |
| `bg-secondary` | hover ground, hairlines, borders, slider tracks | yes — `fg-primary` only |
| `bg-tertiary` | **nothing that carries text** | no |
| `bg-overlay` | notification cards, tooltips | yes — `fg-primary` only |

Afterwards `bg-tertiary` has almost no legal use left. That is a finding: give it one job (the
hover tier, say) or collapse to three. The design should decide.

Two tokens need their role settled. **`accent-border`** currently means "whatever is left over" —
`pf-a` strips it of focus, `f-d` gives it a session tile, nothing else uses it. **`@scrim` /
`@scrim-fg`** are called tokens making the set "26, not 24", but both are theme-*invariant*: they
are computed values like `fgOnAccent`, not colorset entries. The implementation already treats
them so, at 86% where `pf-a` measures 72% as the floor.

### 2.4 Density, honestly

`pf-b`'s premise — everything a fixed multiple of `base-size`, so "one number to set" — does not
hold. The multipliers reproduce the `13` column and neither other: `barHeight` at base 12
computes to 37 where the table says 34, at 14 computes to 43 where it says 46. Nine of ten rows
disagree at both non-default columns, and the floor argument ("at base-size 11 the ramp yields
barHeight 31 and rowH 28") matches neither the multipliers nor the table.

Publish **three hand-tuned columns and drop the derivation claim** — that is what the artboards
draw, and a derivation that silently disagrees with the drawing at two of three densities is
worse than none.

---

## 3. What round 5 must not lose

The audit reads as a critique. These are right, and several are sharper than the implementation:

- **Measuring before drawing** — it found a real colorset bug (Solarized `FG_PRIMARY` at 4.13:1
  on its own ground) that the repo's lint excused because the tools being replaced render the
  same ratio. Parity with a tool you are replacing is a weak reason to ship failing text.
- **`f-b`: "pointer hover and keyboard cursor are one state"** — two visuals would mean a row
  could be both, which has no defined appearance.
- **`f-b`: "pressed exists only on live controls"** — for surfaces that open, the surface
  arriving *is* the feedback; a 60ms press only delays it.
- **`f-b`: "disabled is opacity, never a token swap"** — the *principle* is right (a token swap
  makes a disabled control look like a different role). Only the number is wrong: 55% measures
  1.90–2.66 and fails the artboard's own 3:1 floor in six of eight. Raise it, or state that
  disabled controls are exempt. Don't abandon the principle.
- **`pop-e`'s calendar argument** — *"a grid you scan needs a stable surface and a pointer that
  can leave the widget"*, neither of which a hover tooltip offers. The implementation puts a month
  grid in a tooltip today.
- **`pop-c` hosting the password field** — *"handing a password to a terminal is where the shell
  loses the user."* The implementation opens a terminal running `nmtui`.
- **`pop-b`: "a list of one offers a choice that does not exist."**
- **`pop-g`: "a widget that appears only in trouble teaches nobody where to look"** — and reflows
  the bar at the worst moment.
- **`f-d`'s codepoint discipline** — never a pasted character. This exact failure has shipped
  twice here, silently, with empty glyph strings and no error.
- **`f-d`'s ramps as inclusive lower bounds** — precision the implementation's battery bands lack.
- **`f-c`: "text replacing text is never animated"**, and the focus ring never.
- **`hitMin 32`** — the implementation has no hit-target rule at all.
- **`st-b`: "paths elide mid-string because the filename is the identifying half"**, and pixel
  eliding generally — the implementation truncates by character count, which does not bound pixels.

---

## 4. Upload manifest

`uploads/` was cleared 2026-09-03. **Preserve repo-relative paths** so artboard citations resolve.

**Tier 1 — required (17 files)**

`_research/QUICKSHELL_DESIGN_BRIEF_R5.md` · `_research/QUICKSHELL_DESIGN_AUDIT.md` ·
`_plans/QUICKSHELL_SHELL.md` (Amendments A–E: the decision history every §2.1 contradiction traces
back to) · `private_dot_config/themes/CLAUDE.md` (**the most important upload after this brief** —
semantic schema, contrast law, measured per-theme ratios) · `private_dot_config/themes/*/colors.sh`
(**8**) · `.mise/tasks/lint/theme-contrast.py` · `.claude/rules/quickshell-qml.md` (runtime traps —
stops the design specifying what cannot be built).

**Tier 2 — the scope expansion (7 files).** The design drew clipboard, system menu, lock screen and
polkit *speculatively*, without the documentation of what it replaces.

`_research/QUICKSHELL_COMPONENT_MAPPING.md` (the completeness checklist) ·
`private_dot_local/lib/scripts/user-interface/CLAUDE.md` (**the real `system-menu`; `menu-a`
invented one**) · `private_dot_local/lib/scripts/desktop/CLAUDE.md` (theme switcher, idle & lock,
session) · `private_dot_config/{wofi,wlogout,swaync,waybar}/CLAUDE.md` (the module→semantic tables
the design cites and has never had — note waybar's carries a "Quickshell deliberately diverges"
header).

**Tier 3 — capability and current state (4 files)**

`_research/QUICKSHELL_QML_API.md` (corrected 2026-09-03; carries the Polkit/PAM APIs and a Session
Lock section) · `private_dot_config/quickshell/CLAUDE.md` (what is built) ·
`.claude/rules/hyprland-lua.md` (the physical-vs-logical pixel trap `pf-b` needs) ·
`private_dot_config/hypr/CLAUDE.md`.

**Tier 4 — why the eight themes differ (9 files)**

`private_dot_config/themes/*/STYLE-GUIDE.md` (**8**) — each theme's colour-selection *methodology*,
which is what stops the eight being treated as interchangeable palettes, and where Solarized's
body-text choice is explained on its own terms · `themes/style-guide-generator.md`.

**Optional**: `_research/QUICKSHELL_DESKTOP_RESEARCH.md` (only its theming-philosophy section is
live; the rest is closed exploration). `_plans/QUICKSHELL_DESIGN_PROMPT.md` — useful as history,
**risky as input**: it contains round instructions the agent could re-execute. Mark superseded.

**Do not upload**: LLM / STT / DCLI / Omarchy / BTRFS research; `.claude/rules/chezmoi-*.md` and
the script-standards docs (repo mechanics); `_ai/` (vendored, huge — the API doc is the
distillation); **anything produced by `chezmoi cat`** — rendering `opencode.jsonc` emits a
decrypted API key.
