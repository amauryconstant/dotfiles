# Catppuccin Latte - Color Selection Methodology

**Philosophy**: "Colorfulness is better than colorless" - balanced contrast with harmonic color relationships and rich 14-accent variety.

**Variant**: Light variant, symmetric with Catppuccin Mocha. Same semantic relationships, re-calibrated for bright environments.

**Source**: [Catppuccin Official](https://github.com/catppuccin/catppuccin) | [Style Guide](https://github.com/catppuccin/catppuccin/blob/main/docs/style-guide.md)

---

## Design Principles

**Identical to Catppuccin Mocha** - see Mocha style guide for detailed principles.

Key symmetry:
- Same 5 design principles (colorfulness, balanced contrast, harmonic relationships, semantic-first, legibility flexibility)
- Same color selection framework
- Same decision rules
- **Only difference**: Accent colors darker/more saturated for light background visibility

---

## Color Selection Framework

**Use the exact same framework as Catppuccin Mocha** with these adaptations:

### State Indicators (Re-calibrated Accents)

| Semantic Purpose                    | Color      | Hex     | Change from Mocha                          |
| ----------------------------------- | ---------- | ------- | ------------------------------------------ |
| **Errors / Danger / Deletions**     | `red`      | #d20f39 | Darker, more saturated                     |
| **Success / Additions**             | `green`    | #40a02b | Darker, more saturated                     |
| **Warnings / Caution**              | `yellow`   | #df8e1d | Darker, more orange-yellow                 |
| **Information / Connectivity**      | `sapphire` | #209fb5 | Darker cyan                                |
| **Secondary Information**           | `sky`      | #04a5e5 | Darker blue                                |
| **Modifications / Highlights**      | `pink`     | #ea76cb | Darker pink                                |
| **Navigation / Primary Actions**    | `blue`     | #1e66f5 | Significantly darker for visibility        |

**Decision rule**: Same as Mocha - match functional purpose. All accents darker for light background contrast.

### Background Surfaces (Inverted Hierarchy)

| Surface Type             | Color      | Hex     | Change from Mocha                     |
| ------------------------ | ---------- | ------- | ------------------------------------- |
| **Primary / Base**       | `base`     | #eff1f5 | **Lightest** (was darkest)            |
| **Secondary / Elevated** | `surface0` | #ccd0da | **Mid-light** (was mid-dark)          |
| **Tertiary / Overlays**  | `surface1` | #bcc0cc | **Darker surfaces** (was lighter)     |

**Decision rule**: Same progressive hierarchy, inverted luminosity. Surfaces darker than base (opposite of Mocha).

### Text Hierarchy (Inverted Contrast)

| Content Type                   | Color      | Hex     | Change from Mocha             |
| ------------------------------ | ---------- | ------- | ----------------------------- |
| **Primary Content**            | `text`     | #4c4f69 | **Dark text** (was light)     |
| **Secondary / Metadata**       | `subtext1` | #5c5f77 | **Mid-dark** (was mid-light)  |
| **Disabled / Dimmed**          | `overlay2` | #7c7f93 | **Lighter disabled** (was darker) |
| **High Contrast (on accents)** | `crust`    | #dce0e8 | **Light contrast** (was dark) |

**Decision rule**: Same contrast hierarchy, inverted values. Use crust (light) on accent backgrounds.

### Interactive States

**Identical framework to Mocha** - use same color strategy with Latte's re-calibrated accents:

| State               | Color Strategy                         | Change from Mocha                |
| ------------------- | -------------------------------------- | -------------------------------- |
| **Active / Focused** | `blue` (#1e66f5) background           | Darker blue for visibility       |
| **Hover**           | `surface0` (#ccd0da) background        | Inverted from Mocha surface0     |
| **Inactive**        | `overlay2` (#7c7f93) foreground        | Lighter (inverted)               |
| **Selection**       | `overlay2` (#7c7f93) at 20-30% opacity | Same opacity strategy            |
| **Borders / Hints** | `lavender` (#7287fd)                   | Darker lavender                  |

---

## Context-Specific Selection

**Use identical tables from Catppuccin Mocha**:
- Syntax highlighting - same color assignments (all 14-accent utilization)
- Git operations - same color assignments

Only the accent hex values differ, not the semantic mappings.

**Key assignments** (see Mocha style guide for full rationale):
- Keywords: `mauve` (#8839ef darker)
- Functions: `blue` (#1e66f5 darker)
- Strings: `green` (#40a02b darker)
- Constants: `peach` (#fe640b darker)
- Types: `yellow` (#df8e1d darker)
- Variables: `text` or `flamingo` (#4c4f69 or #dd7878 darker)
- Parameters: `maroon` (#e64553 darker)
- Operators: `sky` or `teal` (#04a5e5 or #179299 darker)
- Git additions: `green` (#40a02b)
- Git modifications: `pink` (#ea76cb)
- Git deletions: `red` (#d20f39)

---

## OpenCode

**Base16 mapping**: [base16-catppuccin-latte](https://github.com/scaryrawr/base16-opencode) | [OPENCODE.md](./OPENCODE.md)
- `bg-primary` → `base00` (#eff1f5 - base)
- `bg-secondary` → `base01` (#e6e9ef - mantle)
- `bg-tertiary` → `base02` (#ccd0da - surface0)

**Diff backgrounds**: `bg-diff-added` #dfe7dd · `bg-diff-removed` #f4dde1 · `bg-diff-context` #ccd0da

---

## Extended Accent Utilization

**All 14 accents used** (same as Mocha):

| Color       | Hex     | Change from Mocha | Primary Use Cases               |
| ----------- | ------- | ----------------- | ------------------------------- |
| `rosewater` | #dc8a78 | Darker variant    | Cursors, subtle highlights      |
| `flamingo`  | #dd7878 | Darker variant    | Memory, soft pink               |
| `pink`      | #ea76cb | Darker variant    | Audio, modifications            |
| `mauve`     | #8839ef | Darker variant    | Keywords, special states        |
| `maroon`    | #e64553 | Darker variant    | CPU, darker error distinction   |
| `teal`      | #179299 | Darker variant    | Network connectivity            |

**Richness principle**: Same 14-accent utilization as Mocha - Latte's strength is also color variety.

---

## Variant Adaptation Notes

### Re-calibration Strategy

Catppuccin Latte uses **systematic accent darkening** while **preserving semantic relationships**:

**Accent darkening**:
- All accents 40-60% darker for visibility on light backgrounds
- Example: blue #89b4fa (Mocha) → #1e66f5 (Latte) - 46% darker
- Example: green #a6e3a1 (Mocha) → #40a02b (Latte) - 58% darker

**Background inversion**:
- Mocha: base (darkest) → surface0 → surface1
- Latte: base (lightest) → surface0 → surface1 (darker)

**Semantic preservation**:
- Sapphire still means information/connectivity
- Lavender still means borders/hints
- All 14 colors maintain identical semantic roles

---

## Complete Palette Reference

### Backgrounds (Inverted)
```
base:     #eff1f5  (lightest - primary background)
mantle:   #e6e9ef  (light - secondary pane)
crust:    #dce0e8  (lightest - high contrast on accents)
surface0: #ccd0da  (elevated surfaces)
surface1: #bcc0cc  (popovers)
surface2: #acb0be  (highest elevation)
```

### Foregrounds (Inverted)
```
overlay0: #9ca0b0  (subtle overlays)
overlay1: #8c8fa1  (moderate overlays)
overlay2: #7c7f93  (disabled/unfocused)
subtext0: #6c6f85  (sub-headlines alt)
subtext1: #5c5f77  (sub-headlines, labels)
text:     #4c4f69  (primary body text - dark)
```

### Accents (All 14, Re-calibrated)
```
rosewater: #dc8a78  (cursors - darker)
flamingo:  #dd7878  (memory - darker)
pink:      #ea76cb  (audio, modifications - darker)
mauve:     #8839ef  (keywords - darker)
red:       #d20f39  (errors - darker)
maroon:    #e64553  (CPU - darker)
peach:     #fe640b  (constants - darker)
yellow:    #df8e1d  (warnings, types - darker)
green:     #40a02b  (success, strings - darker)
teal:      #179299  (network - darker)
sky:       #04a5e5  (secondary info - darker)
sapphire:  #209fb5  (information - darker)
blue:      #1e66f5  (links, functions - darker)
lavender:  #7287fd  (borders, hints - darker)
```

---

## Terminal Colors (ANSI Mapping)

**Identical mapping to Mocha**, darker hex values:

| ANSI    | Catppuccin | Hex     | Notes                    |
| ------- | ---------- | ------- | ------------------------ |
| Red     | `red`      | #d20f39 | Darker for light bg      |
| Yellow  | `yellow`   | #df8e1d | Darker for light bg      |
| Green   | `green`    | #40a02b | Darker for light bg      |
| Cyan    | `teal`     | #179299 | Darker for light bg      |
| Blue    | `blue`     | #1e66f5 | Darker for light bg      |
| Magenta | `pink`     | #ea76cb | Darker for light bg      |

---

## Validation Checklist

**Color Assignment:**
- [ ] **Semantic consistency**: Color matches functional purpose (same as Mocha)
- [ ] **14-accent utilization**: Rich color variety leveraged (same as Mocha)
- [ ] **Contrast hierarchy**: Progressive tiers used correctly (inverted from Mocha)
- [ ] **Official alignment**: Sapphire for info, lavender for borders, rosewater for cursors (same as Mocha)
- [ ] **Legibility first**: Text on accents uses crust (light) for contrast
- [ ] **Variant symmetry**: Semantic mappings match Mocha exactly
- [ ] **Calibration**: Accents darkened 40-60% for light background visibility

**Accessibility (WCAG AA):**
- [ ] **Elevated surfaces**: All `@bg-secondary` surfaces use `@fg-primary` (NOT `@fg-secondary`)
- [ ] **Firefox compliance**: Icons on URL bar, selected tabs, sidebar all use primary text
- [ ] **Contrast ratios**:
  - FG_PRIMARY on BG_SECONDARY: 5.53:1 (✓ passes ≥4.5:1)
  - FG_SECONDARY on BG_SECONDARY: 4.05:1 (✗ fails, use PRIMARY only)

**Official palette alignment:**
- [ ] Colors match official Catppuccin Latte palette exactly
- [ ] No custom colors introduced

---

## References

### Official Specification
- [Catppuccin Official Site](https://github.com/catppuccin/catppuccin) - Philosophy, palette
- [Catppuccin Style Guide](https://github.com/catppuccin/catppuccin/blob/main/docs/style-guide.md) - Official color assignments

### Community Implementations
- [Catppuccin Ports](https://github.com/catppuccin/catppuccin/blob/main/docs/ports.md) - 180+ application examples
- [Catppuccin VSCode](https://github.com/catppuccin/vscode) - Syntax highlighting reference

### Related
- [Catppuccin Mocha Style Guide](../catppuccin-mocha/STYLE-GUIDE.md) - Dark variant reference

> **See also**: [OPENCODE.md](./OPENCODE.md) for OpenCode CLI integration details
