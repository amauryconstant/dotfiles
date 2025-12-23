# Solarized Dark - Color Selection Methodology

**Philosophy**: "Precision colors for machines and people" - scientifically calibrated using CIELAB color space with selective contrast.

**Source**: [Solarized Official](https://ethanschoonover.com/solarized/) | [GitHub Repository](https://github.com/altercation/solarized)

---

## Design Principles

### 1. Scientific Calibration (CIELAB)

Monotones use **symmetric CIELAB lightness differences** ensuring perceived contrast remains constant across dark/light modes. Accent colors translated to CIELAB for perceptual uniformity rather than arbitrary RGB values.

### 2. Selective Contrast

Reduces **brightness contrast** while retaining **hue-based differentiation** via fixed colorwheel relationships. Like reading in shade vs direct sunlight - lower measurable contrast reduces eye strain while maintaining clarity through color distinction.

### 3. Symmetric Design

**Identical contrast relationships** when switching between dark/light backgrounds. CIELAB lightness differences preserved through systematic monotone inversion - only absolute values change, relationships stay constant.

### 4. Hue Over Brightness

Visual hierarchy achieved through **contrasting hues** (colorwheel positions) rather than maximum brightness differences. Enables readable syntax highlighting without harsh contrast.

### 5. Scalable Structure

Sixteen colors (eight monotones + eight accents) scale down to minimal five-color palettes (four monotones + one accent) while retaining personality and function.

---

## Color Selection Framework

### State Indicators (Community Conventions)

**Note**: Solarized's official documentation doesn't prescribe UI state semantics. The assignments below reflect **common community conventions** observed across popular implementations (VSCode, git tools, terminal emulators), not official specifications.

| Semantic Purpose                       | Color    | Hex     | Confidence | Rationale                                  |
| -------------------------------------- | -------- | ------- | ---------- | ------------------------------------------ |
| **Errors / Danger / Deletions**        | `red`    | #dc322f | High       | Universal across implementations           |
| **Success / Additions / Confirmation** | `green`  | #859900 | High       | Universal across implementations           |
| **Warnings / Caution**                 | `yellow` | #b58900 | High       | Widely adopted (some use orange)           |
| **Information / Connectivity**         | `cyan`   | #2aa198 | Moderate   | Common but not universal                   |
| **Modifications / Changes**            | `orange` | #cb4b16 | Moderate   | VSCode and git patterns                    |
| **Navigation / Primary Actions**       | `blue`   | #268bd2 | Moderate   | Common for focus states                    |

**Decision rule**: Use hue differentiation (colorwheel positions) not brightness to distinguish semantic states.

### Background Surfaces (Progressive Depth)

| Surface Type             | Color    | Hex     | Usage                              |
| ------------------------ | -------- | ------- | ---------------------------------- |
| **Primary / Base**       | `base03` | #002b36 | Darkest layer; foundational canvas |
| **Secondary / Elevated** | `base02` | #073642 | Cards, hover states, panels        |
| **Tertiary / Overlays**  | `base01` | #586e75 | Popovers, tooltips, dialogs        |

**Decision rule**: Monotone progression (base03 → base02 → base01) uses calibrated CIELAB lightness steps. Don't skip tiers.

### Text Hierarchy (Progressive Contrast)

| Content Type                      | Color    | Hex     | Usage                                      |
| --------------------------------- | -------- | ------- | ------------------------------------------ |
| **Primary Content**               | `base0`  | #839496 | Body text, main readable content           |
| **Secondary / Emphasized**        | `base1`  | #93a1a1 | Headings, metadata, emphasized information |
| **Disabled / Dimmed**             | `base01` | #586e75 | Inactive text, low priority elements       |
| **High Contrast (on accents)**    | `base3`  | #fdf6e3 | Text on colored backgrounds                |

**Decision rule**: Normal text uses base03:base0 pairing. Emphasized content uses base02:base1. Body text is NOT base00 (intentional distinction).

### Interactive States

| State                | Color Strategy                             | Application                                       |
| -------------------- | ------------------------------------------ | ------------------------------------------------- |
| **Active / Focused** | `blue` (#268bd2) background                | Primary interactive elements, active workspaces   |
| **Hover**            | `base02` (#073642) background              | Elevated surface indication                       |
| **Inactive**         | `base01` (#586e75) foreground              | Disabled or unfocused elements                    |
| **Selection**        | `base02` bg (#073642) + `base1` fg (#93a1a1) | Text selection, highlighted items                 |

**Decision rule**: Use monotone background progression for hover states. Use blue accent for semantic focus. Maintain CIELAB lightness relationships.

---

## Context-Specific Selection

### Syntax Highlighting (VSCode Official Implementation)

| Element Type               | Color         | Hex     | Confidence | Rationale                              |
| -------------------------- | ------------- | ------- | ---------- | -------------------------------------- |
| **Keywords / Control**     | `green`       | #859900 | High       | Structural language elements           |
| **Functions / Methods**    | `blue`        | #268bd2 | High       | Callable actions and procedures        |
| **Strings / Literals**     | `cyan`        | #2aa198 | High       | Literal data distinct from logic       |
| **Comments / Docstrings**  | `base01`      | #586e75 | High       | De-emphasized metadata                 |
| **Constants / Numbers**    | `yellow`      | #b58900 | High       | Fixed unchanging values                |
| **Types / Classes**        | `orange`      | #cb4b16 | Moderate   | Type definitions and class names       |
| **Variables**              | `blue` or `base0` | varies | Low    | Context-dependent (often inherits)     |
| **Operators**              | `base0`       | #839496 | Low        | Often inherits default text color      |

**Hue differentiation rule**: Prioritize **colorwheel spacing** (green keywords, blue functions, cyan strings, yellow constants) over temperature-based patterns. CIELAB perceptual uniformity maintained across accent colors.

**Source**: [VSCode Official Solarized Dark](https://github.com/microsoft/vscode/blob/main/extensions/theme-solarized-dark/themes/solarized-dark-color-theme.json)

### Git Operations

| Operation         | Color    | Hex     | Rationale           |
| ----------------- | -------- | ------- | ------------------- |
| **Additions**     | `green`  | #859900 | Positive growth     |
| **Modifications** | `orange` | #cb4b16 | Alterations/changes |
| **Deletions**     | `red`    | #dc322f | Removal or danger   |

**Source**: [VSCode Git Decorations](https://github.com/microsoft/vscode/blob/main/extensions/theme-solarized-dark/themes/solarized-dark-color-theme.json)

---

## Variant Adaptation

Solarized uses **systematic monotone inversion** between dark and light variants while **preserving accent colors**.

### Dark → Light Transformations

| Dark Mode | Light Mode | Role |
| --------- | ---------- | ---- |
| `base03` #002b36 → | `base3` #fdf6e3 | Background |
| `base02` #073642 → | `base2` #eee8d5 | Elevated surfaces |
| `base0` #839496 → | `base00` #657b83 | Primary text |
| `base1` #93a1a1 → | `base01` #586e75 | Secondary text |
| `base01` #586e75 → | `base1` #93a1a1 | Disabled |
| `base3` #fdf6e3 → | `base03` #002b36 | High contrast |

**Accent colors unchanged**: blue, cyan, green, yellow, orange, red, magenta, violet remain identical.

**Adaptation rule**: CIELAB lightness differences constant. Only absolute RGB values invert. Semantic relationships preserved exactly.

---

## Complete Palette Reference

### Backgrounds

```
base03: #002b36  (darkest - primary background)
base02: #073642  (mid - elevated surfaces)
```

### Content Tones

```
base01: #586e75  (tertiary surfaces / disabled text)
base00: #657b83  (optional body text)
base0:  #839496  (primary body text)
base1:  #93a1a1  (emphasized text)
```

### Light Backgrounds (Contrast Use)

```
base2:  #eee8d5  (light alternate)
base3:  #fdf6e3  (lightest - text on accents)
```

### Accents

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

| ANSI    | Solarized | Hex     | Semantic              |
| ------- | --------- | ------- | --------------------- |
| Red     | `red`     | #dc322f | Errors, deletions     |
| Yellow  | `yellow`  | #b58900 | Warnings              |
| Green   | `green`   | #859900 | Success, additions    |
| Cyan    | `cyan`    | #2aa198 | Information           |
| Blue    | `blue`    | #268bd2 | Primary actions       |
| Magenta | `magenta` | #d33682 | Special purpose       |

**Note**: Terminal palette includes monotones in bright variants (base00, base01, base02) for flexible text hierarchy.

---

## Validation Checklist

**Color Assignment:**
- [ ] **Semantic consistency**: Color hue matches functional purpose (error=red, success=green)
- [ ] **Contrast hierarchy**: Progressive monotone tiers (base03 → base02 → base01) used correctly
- [ ] **CIELAB calibration**: Lightness differences maintained, not arbitrary brightness
- [ ] **Cross-application consistency**: Same semantic meanings across terminal, editor, UI
- [ ] **Official alignment**: Selective contrast (hue differentiation over brightness maximization)
- [ ] **Symmetric design**: Background/foreground pairings follow base03:base0 or base02:base1

**Accessibility (WCAG AA):**
- [ ] **Elevated surfaces**: All `@bg-secondary` surfaces use `@fg-primary` (NOT `@fg-secondary`)
- [ ] **Firefox compliance**: Icons on URL bar, selected tabs, sidebar all use primary text
- [ ] **Contrast ratios**:
  - FG_PRIMARY on BG_SECONDARY: 5.61:1 (✓ passes ≥4.5:1)
  - FG_SECONDARY on BG_SECONDARY: 4.86:1 (✓ passes, but PRIMARY preferred)

**Official palette alignment:**
- [ ] Colors match official Solarized Dark palette exactly
- [ ] No custom colors introduced

---

## References

### Official Specification
- [Solarized Official Site](https://ethanschoonover.com/solarized/) - Philosophy, CIELAB methodology
- [Official Repository](https://github.com/altercation/solarized) - Canonical palette values

### Community Implementations (Semantic Guidance)
- [VSCode Official Theme](https://github.com/microsoft/vscode/tree/main/extensions/theme-solarized-dark) - Detailed semantic assignments
- [Vim Colors Solarized](https://github.com/altercation/vim-colors-solarized) - Original editor implementation
- [Solarized.nvim](https://github.com/maxmx03/solarized.nvim) - Modern Neovim with LSP/Treesitter

### Related
- [Solarized Light Style Guide](../solarized-light/STYLE-GUIDE.md) - Light variant (symmetric adaptation)
