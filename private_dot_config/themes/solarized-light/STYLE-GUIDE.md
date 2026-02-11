# Solarized Light - Color Selection Methodology

**Philosophy**: "Precision colors for machines and people" - scientifically calibrated using CIELAB color space with selective contrast.

**Variant**: Light variant, symmetric with Solarized Dark. Same semantic relationships, systematically inverted for bright environments.

**Source**: [Solarized Official](https://ethanschoonover.com/solarized/) | [GitHub Repository](https://github.com/altercation/solarized)

---

## Design Principles

**Identical to Solarized Dark** - see Dark style guide for detailed principles.

Key symmetry:
- Same 5 design principles (CIELAB calibration, selective contrast, symmetric design, hue over brightness, scalable structure)
- Same color selection framework
- Same decision rules
- **Only difference**: Monotone values systematically inverted; accent colors unchanged

---

## Color Selection Framework

**Use the exact same framework as Solarized Dark** with these adaptations:

### State Indicators (Community Conventions - Unchanged Accents)

**Note**: Same semantic conventions as Dark variant - see Dark style guide for detailed explanation.

| Semantic Purpose                       | Color    | Hex     | Confidence | Change from Dark |
| -------------------------------------- | -------- | ------- | ---------- | ---------------- |
| **Errors / Danger / Deletions**        | `red`    | #dc322f | High       | **Unchanged**    |
| **Success / Additions / Confirmation** | `green`  | #859900 | High       | **Unchanged**    |
| **Warnings / Caution**                 | `yellow` | #b58900 | High       | **Unchanged**    |
| **Information / Connectivity**         | `cyan`   | #2aa198 | Moderate   | **Unchanged**    |
| **Modifications / Changes**            | `orange` | #cb4b16 | Moderate   | **Unchanged**    |
| **Navigation / Primary Actions**       | `blue`   | #268bd2 | Moderate   | **Unchanged**    |

**Decision rule**: Same as Dark - use hue differentiation (colorwheel positions) not brightness.

### Background Surfaces (Inverted Monotones)

| Surface Type | Color | Hex | Change from Dark |
|--------------|-------|-----|------------------|
| **Primary / Base** | `base3` | #fdf6e3 | **Lightest** (was base03 darkest) |
| **Secondary / Elevated** | `base2` | #eee8d5 | **Mid-light** (was base02 mid-dark) |
| **Tertiary / Overlays** | `base1` | #93a1a1 | **Darker overlay** (was base01 lighter) |

**Decision rule**: Same CIELAB lightness progression, inverted absolute values. Don't skip tiers.

### Text Hierarchy (Inverted Contrast)

| Content Type | Color | Hex | Change from Dark |
|--------------|-------|-----|------------------|
| **Primary Content** | `base00` | #657b83 | **Dark text** (was base0 light) |
| **Secondary / Emphasized** | `base01` | #586e75 | **Darker emphasis** (was base1 lighter) |
| **Disabled / Dimmed** | `base1` | #93a1a1 | **Lighter disabled** (was base01 darker) |
| **High Contrast (on accents)** | `base03` | #002b36 | **Darkest contrast** (was base3 lightest) |

**Decision rule**: Same contrast hierarchy, inverted values. Normal text uses base3:base00 pairing. Emphasized uses base2:base01.

### Interactive States

**Identical framework to Dark** - use same color strategy with Light's inverted monotones:

| State | Color Strategy | Change from Dark |
|-------|---------------|------------------|
| **Active / Focused** | `blue` (#268bd2) background | **Unchanged accent** |
| **Hover** | `base2` (#eee8d5) background | Inverted from base02 |
| **Inactive** | `base1` (#93a1a1) foreground | Inverted from base01 |
| **Selection** | `base2` bg (#eee8d5) + `base01` fg (#586e75) | Inverted pairing |

---

## Context-Specific Selection

**Use identical tables from Solarized Dark**:
- Syntax highlighting - same color assignments (constants = yellow, types = orange)
- Git operations - same color assignments (modifications = orange)

Only the monotone hex values differ, not the semantic mappings or accent colors.

**Key assignments** (see Dark style guide for full table):
- Keywords: `green` (#859900)
- Functions: `blue` (#268bd2)
- Strings: `cyan` (#2aa198)
- Constants: `yellow` (#b58900)
- Types: `orange` (#cb4b16)
- Git additions: `green` (#859900)
- Git modifications: `orange` (#cb4b16)
- Git deletions: `red` (#dc322f)

---

## OpenCode

**Base16 mapping**: [base16-solarized-light](https://github.com/scaryrawr/base16-opencode) | [OPENCODE.md](./OPENCODE.md)
- `bg-primary` → `base00` (#fdf6e3 - Solarized base3)
- `bg-secondary` → `base01` (#eee8d5 - Solarized base2)
- `bg-tertiary` → `base02` (#93a1a1 - Solarized base1)

**Note**: Base16 base00-0F ≠ Solarized base00-3 naming; higher number = lighter in both, but different offsets.

---

## Variant Adaptation Notes

### Systematic Inversion

Solarized Light uses **precise monotone inversion** while **preserving accent colors**:

**Background inversion**:
- Dark: base03 (darkest) → base02 → base01
- Light: base3 (lightest) → base2 → base1

**Foreground inversion**:
- Dark: base0 (light text) / base1 (emphasized) / base01 (disabled)
- Light: base00 (dark text) / base01 (emphasized) / base1 (disabled)

**Accent preservation**:
- All eight accent colors **unchanged**: blue, cyan, green, yellow, orange, red, magenta, violet
- Same hex values work on both dark and light backgrounds due to CIELAB calibration

**CIELAB preservation**:
- Lightness differences between monotone tiers remain constant
- Only absolute RGB values change
- Perceived contrast identical to dark variant

---

## Complete Palette Reference

### Backgrounds (Inverted)
```
base3: #fdf6e3  (lightest - primary background)
base2: #eee8d5  (mid-light - elevated surfaces)
```

### Content Tones (Inverted)
```
base1:  #93a1a1  (light disabled text / tertiary surfaces)
base00: #657b83  (dark primary text)
base01: #586e75  (darker emphasized text / dimmed)
base0:  #839496  (optional - not typically used in light mode)
```

### Dark Backgrounds (Contrast Use)
```
base02: #073642  (dark alternate)
base03: #002b36  (darkest - text on accents)
```

### Accents (Unchanged from Dark)
```
yellow:  #b58900  (warnings, constants, numbers)
orange:  #cb4b16  (modifications, types/classes)
red:     #dc322f  (errors, deletions, danger)
magenta: #d33682  (special purpose)
violet:  #6c71c4  (secondary actions)
blue:    #268bd2  (functions, navigation, primary actions)
cyan:    #2aa198  (strings, information, connectivity)
green:   #859900  (success, additions, keywords)
```

---

## Terminal Colors (ANSI Mapping)

**Identical mapping to Dark**, same accent hex values:

| ANSI | Solarized | Hex | Notes |
|------|-----------|-----|-------|
| Red | `red` | #dc322f | Unchanged from dark |
| Yellow | `yellow` | #b58900 | Unchanged from dark |
| Green | `green` | #859900 | Unchanged from dark |
| Cyan | `cyan` | #2aa198 | Unchanged from dark |
| Blue | `blue` | #268bd2 | Unchanged from dark |
| Magenta | `magenta` | #d33682 | Unchanged from dark |

**Note**: Terminal palette includes monotones in bright variants. Background/foreground inverted from dark mode.

---

## Validation Checklist

**Color Assignment:**
- [ ] **Semantic consistency**: Color hue matches functional purpose (same as Dark)
- [ ] **Contrast hierarchy**: Progressive monotone tiers (base3 → base2 → base1) used correctly
- [ ] **CIELAB calibration**: Lightness differences maintained (same as Dark)
- [ ] **Cross-application consistency**: Same meanings across contexts (same as Dark)
- [ ] **Official alignment**: Selective contrast maintained (same as Dark)
- [ ] **Variant symmetry**: Semantic mappings match Dark exactly
- [ ] **Monotone inversion**: Background/foreground pairings follow base3:base00 or base2:base01
- [ ] **Accent preservation**: All eight accents use identical hex values to Dark

**Accessibility (WCAG AA):**
- [ ] **Elevated surfaces**: All `@bg-secondary` surfaces use `@fg-primary` (NOT `@fg-secondary`)
- [ ] **Firefox compliance**: Icons on URL bar, selected tabs, sidebar all use primary text
- [ ] **Contrast ratios**:
  - FG_PRIMARY on BG_SECONDARY: 4.99:1 (✓ passes ≥4.5:1)
  - FG_SECONDARY on BG_SECONDARY: 4.39:1 (✗ fails, use PRIMARY only)

**Official palette alignment:**
- [ ] Colors match official Solarized Light palette exactly
- [ ] No custom colors introduced

---

## References

### Official Specification
- [Solarized Official Site](https://ethanschoonover.com/solarized/) - Philosophy, CIELAB methodology
- [Official Repository](https://github.com/altercation/solarized) - Canonical palette values

### Community Implementations (Semantic Guidance)
- [VSCode Official Theme](https://github.com/microsoft/vscode/tree/main/extensions/theme-solarized-light) - Detailed semantic assignments
- [Vim Colors Solarized](https://github.com/altercation/vim-colors-solarized) - Original editor implementation
- [Solarized.nvim](https://github.com/maxmx03/solarized.nvim) - Modern Neovim with LSP/Treesitter

### Related
- [Solarized Dark Style Guide](../solarized-dark/STYLE-GUIDE.md) - Dark variant reference

> **See also**: [OPENCODE.md](./OPENCODE.md) for OpenCode CLI integration details
