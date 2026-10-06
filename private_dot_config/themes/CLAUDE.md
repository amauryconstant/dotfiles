# Themes - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/themes/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Theme system**: Semantic variable abstraction
- **Variants**: Catppuccin (latte/mocha), Rose Pine (dawn/moon), Gruvbox (light/dark), Solarized (light/dark)
- **Switching**: `theme switch <name>`, darkman (solar), Super+Shift+Y (toggle), Super+Shift+Ctrl+Space (menu)
- **Location**: `~/.config/themes/current` → symlink to active theme
- **Apps**: Desktop, CLI tools, Shell scripts (via gum-ui)
- **Style guides**: Each theme has `STYLE-GUIDE.md` with color selection methodology

---

## Architecture

**Symlink switching**: `~/.config/themes/current` → active theme directory

**Per-theme files** (each theme dir is a complete set):
- **Desktop**: `waybar.css`, `swaync.css.tmpl`, `ghostty.conf`, `hyprland.conf`, `hyprland.lua`, `hyprlock.conf`, `wlogout.css`, `wofi.css`, `firefox-userChrome.css`
- **CLI/TUI**: `bat.conf`, `broot.hjson`, `btop.theme`, `lazygit.yml`, `starship.toml`, `yazi.toml`, `opencode.json`
- **Shell**: `colors.sh` — **the role layer**, 18 keys, read by gum-ui *and* by Quickshell's `Theme.qml`. Named by role (`GROUND_*`, `FILL_INERT`, `INK_*`, `SIGNAL_*`, `IDENTITY_*`), not by the module that spends the value; see Shell Script Integration below
- **Docs**: `STYLE-GUIDE.md`
- **Brand mark**: `icon.png` — **optional**, 128×128, drawn by the theme picker (see below)

`swaync.css.tmpl` is the **only templated file** (injects `.globals.*` fonts); `hyprland.lua` is the Lua-config counterpart to `hyprland.conf` (see `.claude/rules/hyprland-lua.md`). All others are static — add the new file to every theme dir when introducing one.

**Integration**:
- **Desktop apps**: Import via `@import`, `!include`, or `source` directives
- **CLI tools**: Symlinks in `~/.config/{app}/` → `themes/current/{app-config}`

---

## 🚨 Two vocabularies, one palette

A theme carries its colours **twice**, in two naming systems that nothing translates between,
because nothing needs to. Confusing them is the standing defect in this directory.

| | `colors.sh` | `waybar.css` · `wofi.css` · `wlogout.css` · `swaync.css.tmpl` |
|---|---|---|
| Names | **roles** — `GROUND_*`, `FILL_INERT`, `INK_*`, `SIGNAL_*`, `IDENTITY_1..5` | **CSS module names** — `@bg-*`, `@fg-*`, `@accent-*` |
| Count | **18** `readonly` keys | 24 `@define-color` + 4 hover tints |
| Read by | `gum-ui.sh`, `organize-wallpapers-by-color`, Quickshell `Theme.qml` | GTK CSS only |
| Renamed | 2026-09-09, to roles | never |

**Rough mapping**, for reading an old note — not a translation layer, and not exact:

| CSS | Role |
|---|---|
| `@bg-primary` | `GROUND_BASE` |
| `@bg-secondary` | `GROUND_RAISED` |
| `@bg-overlay` | `GROUND_FLOAT` |
| `@bg-tertiary` | `FILL_INERT` — **the trap tier**, carries no text |
| `@fg-primary` / `@fg-secondary` / `@fg-muted` | `INK_PRIMARY` / `INK_SECONDARY` / `INK_MUTED` |
| `@fg-contrast` | `INK_CONTRAST_CANDIDATE` — measured against, never assigned |
| `@accent-primary` / `@accent-error` / `@accent-warning` / `@accent-success` / `@accent-info` | `SIGNAL_FOCUS` / `SIGNAL_ERROR` / `SIGNAL_WARN` / `SIGNAL_OK` / `SIGNAL_INFO` |
| `@accent-modification`, `@accent-special`, `@accent-subtle`, `@accent-tertiary`, `@accent-highlight` | **no fixed counterpart.** `IDENTITY_1..5` is an *indexed* slot set — assigned by position, never load-bearing, always redundant with a label — so it does not map name-for-name onto these |
| `@accent-border`, `@accent-performance`, `@accent-media`, `@accent-secondary`, `@accent-alternative`, `@accent-urgent-secondary` | **no role** — deleted from `colors.sh` on 2026-09-09 for having no consumer |

⚠️ **A section below written in `@`-names is about the CSS files only.** The measured contrast
tables use role names because they were regenerated from `colors.sh`.

---

## Semantic Variable Schema (CSS files only)

**Variables** organized into categories. **These live in `waybar.css` and its siblings, not in
`colors.sh`** — see the two-vocabulary note above.

### Background Hierarchy

| Variable | Role | Usage | **Required Text Color** |
|----------|------|-------|-------------------------|
| `@bg-primary` | Main background | Bars, windows, primary canvas | `@fg-primary` or `@fg-secondary` |
| `@bg-secondary` | Elevated surfaces | Hover states, cards, inputs | **ALWAYS @fg-primary** |
| `@bg-tertiary` | Tertiary elevation | ⚠️ **carries no text** — see the trap-tier note below | (none) |
| `@bg-overlay` | Cards, tooltips, modal overlays | Notification cards, popover content, dialogs | `@fg-primary` |

### Foreground/Text Hierarchy

| Variable | Role | Usage |
|----------|------|-------|
| `@fg-primary` | Primary text | Body content, main labels |
| `@fg-secondary` | Secondary text | Subtitles, window title |
| `@fg-muted` | Disabled/inactive | Unfocused, low contrast |
| `@fg-contrast` | High contrast | Text on colored backgrounds |

### Accent Colors (semantic roles, Phase 1+2+3)

**Core Accents**:

| Variable | Role | Usage |
|----------|------|-------|
| `@accent-primary` | Active states | Clock, active workspace — **the one active thing per surface** |
| `@accent-info` | Connectivity | Network, Bluetooth, battery charging |
| `@accent-success` | Success states | Battery normal, positive indicators |
| `@accent-warning` | Warnings | Battery low (<20%), backlight, caution |
| `@accent-error` | Errors/urgent | Battery critical (<10%), urgent workspace |
| `@accent-highlight` | Secondary actions | Audio/PulseAudio, special states |
| `@accent-secondary` | Tertiary actions | Alternative interactive elements |
| `@accent-tertiary` | Quaternary | Lock, logout buttons |

**Extended Accents**:

| Variable | Role | Usage |
|----------|------|-------|
| `@accent-modification` | File changes | Git diffs, search highlights, wofi search match |
| `@accent-border` | Focus indicators | Active borders (Hyprland), focus rings, input borders |
| `@accent-performance` | System metrics | Disk usage, CPU, memory modules |
| `@accent-media` | Media controls | Audio, video, media player modules |
| `@accent-subtle` | Low priority | Cursors, subtle hints, disabled secondary |
| `@accent-alternative` | Alternative | Tertiary navigation, wlogout extra buttons |
| `@accent-special` | Special states | Custom modules, rare indicators |
| `@accent-urgent-secondary` | Moderate urgency | Battery 20-30%, moderate warnings |

**Hover Variants** — ⚠️ **CSS-only, not part of the colorset**:

| Variable | Role | Usage |
|----------|------|-------|
| `@accent-info-hover` | Network hover | 10% opacity version of accent-info |
| `@accent-highlight-hover` | Audio hover | 10% opacity version of accent-highlight |
| `@accent-warning-hover` | Backlight hover | 10% opacity version of accent-warning |
| `@accent-success-hover` | Battery hover | 10% opacity version of accent-success |

These four are declared **only** in each theme's `waybar.css` and `swaync.css.tmpl`. They are
**not** in `colors.sh`, which holds exactly **18** `readonly` role keys — so they are invisible to
the shell scripts and to Quickshell's `Theme.qml`, both of which read `colors.sh` alone. A QML or
shell consumer needing a hover tint composites the base accent itself. Do not design against
these outside GTK CSS.

🚨 **Six `@accent-*` names above have no role counterpart** — `@accent-border`,
`@accent-performance`, `@accent-media`, `@accent-secondary`, `@accent-alternative` and
`@accent-urgent-secondary` were deleted from every `colors.sh` on 2026-09-09 for having no
consumer. They survive in the CSS files; do not reach for them from a shell script or from QML.

---

## Contrast Guidelines

### CRITICAL RULE: Text on Elevated Surfaces

Elevated surfaces (`@bg-secondary`, `@bg-tertiary`) MUST use `@fg-primary` for ALL text and icons.

**DO NOT** use `@fg-secondary` on elevated surfaces - this creates insufficient contrast (4.0-4.5:1) that fails WCAG AA standards (4.5:1 required).

Applies to QML as much as to CSS — see "QML Integration (Quickshell)" below. The QML side is
measured by `mise run lint:theme-contrast`, which reads all 8 colorsets rather than the one
currently symlinked; the CSS side is still by hand.

#### Correct Patterns

| Background Surface | Text Color | Measured range (all 8) | WCAG Status | Use Case |
|-------------------|------------|------------------------|-------------|----------|
| `@bg-primary` | `@fg-primary` | 4.13–11.86:1 | ✓ AA except solarized-light | Primary content |
| `@bg-primary` | `@fg-secondary` | 4.02–9.26:1 | ± AA (rose-pine-dawn 4.02) | Less critical text |
| **`@bg-secondary`** | **`@fg-primary`** | **3.64–10.90:1** | **✓ AA except solarized** | **Elevated surfaces** |
| `@bg-tertiary` | `@fg-primary` | 1.67–8.82:1 | ✗ fails in solarized + latte | Avoid — see below |

⚠️ **The "7.0:1+" and "6.0:1+" figures above were wrong.** Measured across all 8 colorsets
2026-09-01 (`mise run lint:theme-contrast`): `@fg-primary` on `@bg-secondary` is 4.11 in
solarized-dark and 3.64 in solarized-light — solarized puts body text at base0/base00 by
design, so no consumer clears AA there. `@fg-primary` on `@bg-tertiary` is worse still, 1.70
and 1.67 in the same two themes. **`@bg-tertiary` is the trap tier**: it is the only ground
whose distance from the foreground tokens varies enough between themes to vanish outright
(`INK_MUTED` *equals* `FILL_INERT` in both solarized themes, a ratio of exactly 1.00). Prefer
`@bg-secondary` for any ground that has to carry something on top of it.

#### Incorrect Patterns (DO NOT USE)

| Background Surface | Text Color | Typical Contrast | Problem |
|-------------------|------------|------------------|---------|
| ~~`@bg-secondary`~~ | ~~`@fg-secondary`~~ | ~~4.0-4.5:1~~ | Both "secondary" = low contrast |
| ~~`@bg-tertiary`~~ | ~~`@fg-muted`~~ | ~~3.0-4.0:1~~ | Barely readable |

### Application Examples

**Correct (Wofi, Wlogout):**
```css
#input {
  background-color: @bg-secondary;  /* Elevated surface */
  color: @fg-primary;                /* Primary text ✓ */
}
```

**Incorrect (Firefox prior to fix):**
```css
.tabbrowser-tab[selected] {
  background-color: var(--bg-secondary);  /* Elevated surface */
  /* Missing: color: var(--fg-primary); ✗ */
}
```

### Theme-Specific Contrast Ratios

Measured 2026-09-03 against every `colors.sh`. **Both columns, every row** — the INK_PRIMARY
column here was previously estimated rather than measured and was wrong in 6 of 8 rows (it
claimed 4.99 for solarized-light, which actually measures 3.64, and 5.18 for rose-pine-moon,
which measures 10.90). Regenerate with `mise run lint:theme-contrast` rather than by hand.

| Theme | INK_PRIMARY on GROUND_RAISED | INK_SECONDARY on GROUND_RAISED | INK_PRIMARY on FILL_INERT |
|-------|---------------------------|------------------------------|---------------------------|
| Catppuccin Latte | 5.17:1 | 4.05:1 ✗ | 4.39:1 ✗ |
| Catppuccin Mocha | 8.69:1 | 7.10:1 | 6.31:1 |
| Gruvbox Light | 8.45:1 | 6.43:1 | 6.76:1 |
| Gruvbox Dark | 8.45:1 | 6.76:1 | 6.43:1 |
| Rose Pine Dawn | 7.00:1 | 4.23:1 ✗ | 6.07:1 |
| Rose Pine Moon | 10.90:1 | 4.46:1 ✗ | 8.82:1 |
| Solarized Light | **3.64:1 ✗** | 4.39:1 ✗ | **1.67:1 ✗** |
| Solarized Dark | **4.11:1 ✗** | 4.86:1 | **1.70:1 ✗** |

**Key:** ✗ = below the 4.5:1 AA floor for text.

**Rationale:** combining a "secondary" background with "secondary" text is insufficient in five
of eight themes. Both variables are designed to be subtle; pairing them fails, most visibly in
Firefox (URL bar icons, selected tabs) on Rose Pine Dawn.

🚨 **Solarized inverts the rule.** In *both* solarized themes `INK_SECONDARY` measures **better**
than `INK_PRIMARY` on every ground (light: 4.39 vs 3.64; dark: 4.86 vs 4.11), because Solarized
assigns body text to base00/base0 by design. No consumer clears AA there — Waybar, wofi and
swaync render the same ratios today — so this is a **colorset** property, not a per-app one.

The shell now handles it **by measurement rather than by editing the palette**: `Theme.qml`
withdraws `INK_SECONDARY` wherever it fails 4.5:1 on `GROUND_BASE`, and that ground carries
`INK_PRIMARY` alone there. Design page 01 states the rule ("offered per ground, per theme, and
withdrawn where it fails"); `mise run lint:theme-contrast` prints which themes withdraw it. One
derivation covers every colorset, including any added later, which promoting two foregrounds by
hand would not. The other consumers still render the raw ratios.

---

## Semantic Mappings

**Reference**: See individual theme `STYLE-GUIDE.md` files for:
- Complete hex code mappings
- Design principles
- Color selection methodology
- Syntax highlighting patterns
- Variant adaptation strategies

**Quick lookup**: `colors.sh` is the **role layer** and the only file two different runtimes read
(gum-ui and Quickshell). `waybar.css` holds the fullest **CSS** set — 24 `@define-color` plus the
four hover tints — and is what a new theme is authored from today. The two are edited by hand and
independently; see the two-vocabulary note at the top.

---

## Theme Switching

**Manual**: `theme switch <name>`, `theme list`, `theme-menu`
**Solar auto**: darkman service (sunrise/sunset transitions)
**Keybindings**: Super+Shift+Y (toggle), Super+Shift+Ctrl+Space (menu)

**Process**: Updates symlink → reloads Waybar/Swaync/Hyprland → updates wallpaper

---

## Style Guides

Each theme has `STYLE-GUIDE.md` with methodology-focused documentation:

**Catppuccin**: 14-accent pastel, legibility-first, colorfulness philosophy
**Rose Pine**: Minimalist natural, dual-purpose colors, nature-inspired
**Gruvbox**: Warm retro groove, easily distinguishable, adjustable contrast
**Solarized**: CIELAB precision, symmetric design, selective contrast

**Format**: Design Principles → Color Selection Framework → Context-Specific → Variant Adaptation → Palette → Terminal → Validation → References

---

## Brand marks — `icon.png`

`user-interface/theme-menu` draws each row's `icon.png` in the picker's icon column and falls
back to a Nerd Font glyph when the file is absent. **Optional per theme**, 128×128 PNG (the
column paints at 20, so 128 covers HiDPI with headroom).

Upstream assets, all resized with `magick <src> -resize 128x128 <theme>/icon.png`:

| Theme dirs | Source | License |
|---|---|---|
| `catppuccin-mocha` | `catppuccin/catppuccin` `assets/logos/exports/1544x1544_circle.png` | MIT |
| `catppuccin-latte` | same repo, `latte_circle.png` | MIT |
| `rose-pine-{dawn,moon}` | `rose-pine/rose-pine-theme` `assets/icon.svg` | MIT |
| `solarized-{dark,light}` | `altercation/solarized` `img/solarized-yinyang.png` | MIT |
| `gruvbox-{dark,light}` | **none — no official mark exists**; falls back to `md-package_variant_closed` | — |

🚨 **PNG, not SVG, deliberately.** `IconImage` is a plain `QtQuick.Image`
(`_ai/quickshell/src/widgets/IconImage.qml`), so an SVG would render through qt6-svg's own
parser rather than the librsvg that produced these — one asset pipeline instead of two, and
nothing to debug when a filter or mask draws differently.

**A theme with no icon gets a tinted chip instead**: `theme-menu` reads that theme's own
`GROUND_BASE` and `INK_PRIMARY` out of `colors.sh` and sends them as `glyphBackground` /
`glyphColor`, so Gruvbox Dark and Gruvbox Light are told apart by their own grounds rather than
by two different box glyphs.

🚨 **The glyph is `INK_PRIMARY`, not `SIGNAL_FOCUS`.** The accent says more about a theme, but
measured on that theme's own `GROUND_BASE` it reaches **2.19** in gruvbox-light (3.41 and 3.47 in
solarized-light and rose-pine-dawn) — under the 3:1 a graphic owes. The ink clears 4.13 in all
eight, and the ground is what carries the dark/light distinction anyway.

Rosé Pine ships one mark for both variants, and Solarized's yin-yang *is* the dark/light pair —
so four of the eight rows share a file with their sibling. That is the upstream's decision, not
a shortcut here: the section header and the name already say which variant a row is.

Verify a candidate at the size it will actually be drawn before vendoring it — Solarized's
`solarized-palette.png` and `solarized-165.png` both dissolve into mush at 20px, which is why
the yin-yang won.

---

## Wallpapers

**System**: Theme-integrated collections, color-matched per theme via Delta E (LAB)
**Storage**: `~/.config/wallpapers/{theme}/` from chezmoi external
**Selection**: `random-wallpaper`, `set-wallpaper`
**Rotation**: Systemd timer (30 min)

**Organization**: One-time color matching using `organize-wallpapers-by-color`
**Note**: Wallust disabled (static theme colors, not dynamic extraction)

---

## CLI Tool Integration

**7 CLI tools** themed via symlink switching:

| Tool | Config File | Symlink Location | Purpose |
|------|-------------|------------------|---------|
| **bat** | `bat.conf` | `~/.config/bat/config` | Syntax highlighting theme selection |
| **broot** | `broot.hjson` | `~/.config/broot/skin.hjson` | File tree skin colors |
| **btop** | `btop.theme` | `~/.config/btop/themes/color_theme.theme` | System monitor color scheme |
| **lazygit** | `lazygit.yml` | `~/.config/lazygit/config.yml` | Git TUI theme colors |
| **opencode** | `opencode.json` | `~/.config/opencode/themes/current.json` | TUI theme via custom JSON |
| **starship** | `starship.toml` | `~/.config/starship.toml` | Shell prompt colors/symbols |
| **yazi** | `yazi.toml` | `~/.config/yazi/theme.toml` | File manager theme |

**Special handling**:
- **bat**: Requires cache rebuild via `run_onchange_after_rebuild_bat_cache.sh.tmpl`
- **bat themes**: Rose Pine variants use custom `.tmTheme` files (`~/.config/bat/themes/`)
- **starship**: Theme-specific prompt symbols and color schemes
- **broot**: Skin-based color system with syntax highlighting
- **btop**: Direct color code mappings (no semantic variables)
- **lazygit**: Theme colors integrated with git status highlighting
- **yazi**: File type icons and selection colors

**Switching**: Symlinks automatically update when `theme switch` runs

### Lazygit Semantic Mapping

All 12 lazygit theme fields and their semantic mappings:

| Field | Semantic | Notes |
|-------|----------|-------|
| `activeBorderColor` | `accent-border` + bold | Active panel border |
| `inactiveBorderColor` | `fg-muted` | **Must be foreground-class** |
| `searchingActiveBorderColor` | `accent-warning` + bold | Search mode border |
| `optionsTextColor` | `accent-info` | Help/options text |
| `selectedLineBgColor` | `bg-secondary` | Active panel row highlight |
| `inactiveViewSelectedLineBgColor` | `bg-tertiary` | Inactive panel row highlight |
| `cherryPickedCommitBgColor` | `accent-success` | Cherry-pick marker bg |
| `cherryPickedCommitFgColor` | `fg-contrast` | Cherry-pick marker fg |
| `markedBaseCommitBgColor` | `accent-warning` | Rebase base marker bg |
| `markedBaseCommitFgColor` | `fg-contrast` | Rebase base marker fg |
| `unstagedChangesColor` | `accent-modification` | Unstaged file indicator |
| `defaultFgColor` | `fg-primary` | Default text |

**Critical rule**: Border/outline colors MUST use foreground-hierarchy colors (`fg-muted`, `fg-secondary`, `accent-*`), NOT background-hierarchy colors (`bg-secondary`, `bg-tertiary`). Background colors are designed to be near-identical to bg-primary; they cannot provide border contrast.

**Calibration note**: For themes where bg-secondary ≈ bg-primary (Rose Pine), use the palette's dedicated highlight tier colors for `selectedLineBgColor` and `inactiveViewSelectedLineBgColor`. See Rose Pine STYLE-GUIDE.md files for details.

---

## Shell Script Integration (CLI Tools)

System CLI tools source `~/.config/themes/current/colors.sh` via the gum-ui library. The keys
are **roles**: `GROUND_BASE`, `INK_PRIMARY`, `SIGNAL_OK`, `IDENTITY_3`. They no longer mirror the
CSS variable names — `waybar.css` and the rest still carry their own module-named variables, and
nothing translates between the two, because nothing needs to.

⚠️ **`INK_MUTED` is terminal-only.** It survives in the colorset for `gum-ui.sh` and
`organize-wallpapers-by-color`, and is banned in the shell: it fails as text (2.48 worst) and
under 3:1 as an outline.

**Loading**: `gum-ui.sh` sources `colors.sh` automatically — scripts using `$UI_LIB` get theme colors.

**Direct sourcing**:
```bash
. ~/.config/themes/current/colors.sh
echo "${SIGNAL_FOCUS}Primary color${INK_PRIMARY}"
```

**Reload**: New shells only — running shells keep old colors (acceptable for CLI tools).

---

## QML Integration (Quickshell)

The Quickshell shell reads the **same** `colors.sh` at runtime. `Theme.qml`
(`private_dot_config/quickshell/dotfiles/`) parses it with a regex and exposes the 18 role keys
as QML `color` properties (`GROUND_BASE` → `Theme.groundBase`). Since the 2026-09-09 rename the
two speak one vocabulary, so that file is no longer a translation layer — what is left in it is
the **derived** tier, the materials no theme binds. There is no ninth per-theme file to
maintain, but three consequences follow:

- **The colorset must stay complete.** A key missing from a theme's `colors.sh` falls back to a
  hardcoded Catppuccin value inside `Theme.qml`. That renders the wrong colour with **no error**.
  🚨 The parser's character class is `[A-Z0-9_]+`, not `[A-Z_]+`: `IDENTITY_1`…`IDENTITY_5` carry
  a digit, and a class without one drops all five silently into that same fallback. The same bug
  was live in `theme-contrast.py`'s own parser.
- **Reload is an explicit IPC call, not a file watch.** `theme switch` swaps the `themes/current`
  *symlink*, and an inotify watch on the resolved path never fires. `theme-switcher` calls
  `quickshell -c dotfiles ipc call theme reload`.
- **Contrast is measured, not eyeballed.** `mise run lint:theme-contrast` reads all 8 colorsets.
  See below for what it does and does not cover.

### Contrast in QML

The ban applies unchanged, in role names: **`Theme.inkSecondary` on `groundRaised`,
`groundFloat` or `fillInert`**. The pattern that holds the rule is `bar/BarWidget.qml`'s
`grounded` property: rest colour is `inkSecondary` on the bar ground, and flips to `inkPrimary`
the moment the widget draws a ground of its own (hover, pill, tint). A widget that hardcodes
either one reintroduces the banned pair on half its states.

🚨 **`Theme.fgSecondary`, `Theme.bgSecondary` and the rest do not exist.** Every QML property was
renamed with the colorset on 2026-09-09 — `groundBase`, `groundRaised`, `groundFloat`,
`fillInert`, `inkPrimary`, `inkSecondary`, `signalFocus`, `identity1..5`, plus the derived tier
(`edge`, `hover`, `press`, `select`, `focusRing`, `action`, `inkOnAction`, `scrim`, `fgOnScrim`,
`disabledOpacity`). A grep written against the old names matches nothing and passes silently.

`mise run lint:theme-contrast` enforces this across all 8 colorsets — **manual-only**, because its
`PAIRS` table is harvested by hand from the QML and therefore goes stale silently when a widget
changes a colour. Run it after touching any colour in that tree, and re-harvest the table when
the tree grows a surface. It covers only the pairs listed in it: a pair the code renders but the
table omits is invisible (which is how `INK_PRIMARY` on `FILL_INERT` went unmeasured). Harvest by
reading the **parenting**, not by grepping colour lines — most `Theme.groundRaised` uses in that
tree are 1px hairlines (it is what `Theme.edge` resolves to), not grounds.

Five properties in `Theme.qml` are **computed per theme** rather than read from the colorset —
`action` (the accent solved for text on both grounds), `scrim`, `fgOnScrim`, `disabledOpacity` and
the `inkSecondary` withdrawal — each because no fixed
token clears its floor in all 8. That is the general pattern: **a colour whose job is defined
against a ground has to be computed.**

`theme-consistency-reviewer` reviews the QML tree as a second target, once rather than per
theme: three greps for a literal hex, a literal font name, and `fgSecondary` on a lit ground.

---

## Enhanced Theme Switching

`theme-switcher` (in `lib/scripts/desktop/`) drives the full switch:
1. Update `~/.config/themes/current` symlink
2. Reload core apps (Hyprland, Waybar, Swaync, terminal, wofi)
3. Call the `theme-apply-*` scripts for extended coverage: firefox, spotify, opencode, claude-code, gtk, qt, neovim (each silently skips if its app is absent)
4. Trigger the `theme-change` user hook: `hook-runner theme-change $theme_name`

Per-script behavior (e.g. Firefox needs `toolkit.legacyUserProfileCustomizations.stylesheets = true`) is documented in `lib/scripts/desktop/CLAUDE.md`.

**See**: `private_dot_local/lib/scripts/CLAUDE.md` for theme-apply script details
**See**: `dotfiles/CLAUDE.md` for hook system documentation

**See**: `swaync/CLAUDE.md` for SwayNC semantic variable mapping.
