# Gruvbox Light - Color Selection Methodology

**Philosophy**: "Retro groove" - warm earthy tones with easily distinguishable colors and hard contrast comfort.

**Variant**: Light variant, symmetric with Gruvbox Dark. Same semantic relationships, re-calibrated for bright environments.

**Source**: [Gruvbox Official](https://github.com/morhetz/gruvbox) | [Gruvbox Material](https://github.com/sainnhe/gruvbox-material)

---

## Design Principles

**Identical to Gruvbox Dark** - see Dark style guide for detailed principles.

Key symmetry:
- Same 5 design principles (warm retro harmony, easily distinguishable colors, earthy palette, hard contrast, retro groove)
- Same color selection framework
- Same decision rules
- **Only difference**: Neutral colors darker/more muted for light background visibility

---

## Color Selection Framework

**Use the exact same framework as Gruvbox Dark** with these adaptations:

### State Indicators (Re-calibrated Accents)

| Semantic Purpose                       | Color          | Hex     | Change from Dark                           |
| -------------------------------------- | -------------- | ------- | ------------------------------------------ |
| **Errors / Danger / Deletions**        | `red`          | #cc241d | Darker, more saturated                     |
| **Success / Additions / Confirmation** | `green`        | #98971a | Darker, more saturated                     |
| **Warnings / Caution**                 | `yellow`       | #d79921 | Darker, warmer                             |
| **Information / Connectivity**         | `aqua`         | #689d6a | Darker, more muted                         |
| **Modifications / Changes**            | `orange`       | #d65d0e | Darker, warmer                             |
| **Navigation / Primary Actions**       | `blue`         | #458588 | Darker, more muted                         |

**Decision rule**: Same as Dark - warm colors preferred. All accents darker for light background contrast.

### Background Surfaces (Inverted Hierarchy)

| Surface Type             | Color    | Hex     | Change from Dark                      |
| ------------------------ | -------- | ------- | ------------------------------------- |
| **Primary / Base**       | `light0` | #fbf1c7 | **Lightest** (was dark0)              |
| **Secondary / Elevated** | `light1` | #ebdbb2 | **Mid-light** (was dark1)             |
| **Tertiary / Overlays**  | `light2` | #d5c4a1 | **Darker surfaces** (was dark2)       |

**Decision rule**: Same progressive hierarchy, inverted luminosity. Surfaces darker than base (opposite of Dark).

### Text Hierarchy (Inverted Contrast)

| Content Type                   | Color   | Hex     | Change from Dark              |
| ------------------------------ | ------- | ------- | ----------------------------- |
| **Primary Content**            | `dark1` | #3c3836 | **Dark text** (was light1)    |
| **Secondary / Metadata**       | `dark2` | #504945 | **Mid-dark** (was light2)     |
| **Disabled / Dimmed**          | `dark4` | #7c6f64 | **Lighter disabled** (was light4) |
| **High Contrast (on accents)** | `dark0` | #282828 | **Darkest contrast** (was light0) |

**Decision rule**: Same contrast hierarchy, inverted values. Use dark0 (darkest) on accent backgrounds.

### Interactive States

**Identical framework to Dark** - use same color strategy with Light's re-calibrated accents:

| State               | Color Strategy                    | Change from Dark                 |
| ------------------- | --------------------------------- | -------------------------------- |
| **Active / Focused** | `yellow` (#d79921) background     | Darker yellow for visibility     |
| **Hover**           | `light1` (#ebdbb2) background     | Inverted from dark1              |
| **Inactive**        | `dark4` (#7c6f64) foreground      | Inverted from light4             |
| **Selection**       | `light2` (#d5c4a1) at 30-40% opacity | Same opacity strategy            |
| **Borders / Hints** | `orange` (#d65d0e)                | Darker orange                    |

---

## Context-Specific Selection

**Use identical tables from Gruvbox Dark**:
- Syntax highlighting - same color assignments (warm-first approach)
- Git operations - same color assignments

Only the accent hex values differ, not the semantic mappings.

**Key assignments** (see Dark style guide for full rationale):
- Keywords: `red` (#cc241d darker)
- Functions: `green` (#98971a darker)
- Strings: `green` or `dark1` (#98971a or #3c3836 - configurable)
- Constants: `purple` (#b16286 darker)
- Types: `yellow` (#d79921 darker)
- Variables: `blue` (#458588 darker)
- Parameters: `aqua` (#689d6a darker - LSP/Tree-sitter)
- Operators: `orange` or `dark1` (#d65d0e or #3c3836 - stylistic)
- Git additions: `green` (#98971a)
- Git modifications: `orange` (#d65d0e)
- Git deletions: `red` (#cc241d)

---

## Variant Adaptation Notes

### Re-calibration Strategy

Gruvbox Light uses **systematic accent darkening** while **preserving semantic relationships**:

**Accent darkening**:
- All accents 15-25% darker for visibility on light backgrounds
- Example: yellow #fabd2f (Dark) → #d79921 (Light) - 18% darker
- Example: green #b8bb26 (Dark) → #98971a (Light) - 22% darker

**Background inversion**:
- Dark: dark0 (darkest) → dark1 → dark2
- Light: light0 (lightest) → light1 → light2 (darker)

**Semantic preservation**:
- Yellow still means warnings/primary focus
- Orange still means modifications/warm emphasis
- All colors maintain identical semantic roles

---

## Complete Palette Reference

### Backgrounds (Inverted)
```
light0_hard: #f9f5d7  (hardest contrast - lightest)
light0:      #fbf1c7  (primary background)
light1:      #ebdbb2  (elevated surfaces)
light2:      #d5c4a1  (popovers)
light3:      #bdae93  (highest elevation)
light4:      #a89984  (subtle overlays)
```

### Foregrounds (Inverted)
```
dark0_hard: #1d2021  (hardest contrast - darkest)
dark0:      #282828  (high contrast on accents)
dark1:      #3c3836  (primary body text - dark)
dark2:      #504945  (sub-headlines, labels)
dark3:      #665c54  (comments, metadata)
dark4:      #7c6f64  (disabled/unfocused)
```

### Accents (All 7, Re-calibrated Neutral)
```
red:    #cc241d  (errors, deletions - darker)
green:  #98971a  (success, additions - darker)
yellow: #d79921  (warnings, types - darker)
blue:   #458588  (functions, links - darker)
purple: #b16286  (special purpose - darker)
aqua:   #689d6a  (information - darker)
orange: #d65d0e  (modifications - darker)
gray:   #928374  (comments - unchanged)
```

---

## Terminal Colors (ANSI Mapping)

**Identical mapping to Dark**, darker hex values:

| ANSI    | Gruvbox | Hex     | Notes                    |
| ------- | ------- | ------- | ------------------------ |
| Red     | `red`   | #cc241d | Darker for light bg      |
| Yellow  | `yellow`| #d79921 | Darker for light bg      |
| Green   | `green` | #98971a | Darker for light bg      |
| Cyan    | `aqua`  | #689d6a | Darker for light bg      |
| Blue    | `blue`  | #458588 | Darker for light bg      |
| Magenta | `purple`| #b16286 | Darker for light bg      |

---

## Validation Checklist

**Color Assignment:**
- [ ] **Semantic consistency**: Color matches functional purpose (same as Dark)
- [ ] **Warm temperature**: Yellow/orange dominate (same as Dark)
- [ ] **Contrast hierarchy**: Progressive tiers used correctly (inverted from Dark)
- [ ] **Distinguishable colors**: High colorwheel separation (same as Dark)
- [ ] **Retro groove**: Earthy warmth throughout (same as Dark)
- [ ] **Variant symmetry**: Semantic mappings match Dark exactly
- [ ] **Calibration**: Accents darkened 15-25% for light background visibility
- [ ] **Neutral palette**: Using neutral variants (not bright) for light mode

**Accessibility (WCAG AA):**
- [ ] **Elevated surfaces**: All `@bg-secondary` surfaces use `@fg-primary` (NOT `@fg-secondary`)
- [ ] **Firefox compliance**: Icons on URL bar, selected tabs, sidebar all use primary text
- [ ] **Contrast ratios**:
  - FG_PRIMARY on BG_SECONDARY: 7.78:1 (✓ passes AAA ≥7.0:1)
  - FG_SECONDARY on BG_SECONDARY: 6.43:1 (✓ passes AA, but PRIMARY preferred)

**Official palette alignment:**
- [ ] Colors match official Gruvbox Light palette exactly
- [ ] No custom colors introduced

---

## References

### Official Specification
- [Gruvbox Official Repository](https://github.com/morhetz/gruvbox) - Original specification
- [Gruvbox Material](https://github.com/sainnhe/gruvbox-material) - Modern variant with refined palette

### Community Implementations
- [Gruvbox VSCode](https://github.com/jdinhify/vscode-theme-gruvbox) - Syntax highlighting reference
- [Gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) - Modern Neovim with Treesitter

### Related
- [Gruvbox Dark Style Guide](../gruvbox-dark/STYLE-GUIDE.md) - Dark variant reference
