# Gruvbox Dark - Color Selection Methodology

**Philosophy**: "Retro groove" - warm earthy tones with easily distinguishable colors and hard contrast comfort.

**Source**: [Gruvbox Official](https://github.com/morhetz/gruvbox) | [Gruvbox Material](https://github.com/sainnhe/gruvbox-material)

---

## Design Principles

### 1. Warm Retro Harmony

Earthy, warm-toned palette inspired by vintage aesthetics. Yellows and oranges dominate over cool blues. Creates cozy, nostalgic atmosphere reminiscent of old terminal emulators and retro computing.

### 2. Easily Distinguishable Colors

High differentiation between accent colors ensures visual clarity. Each color occupies distinct colorwheel position with sufficient perceptual distance. Reduces cognitive load when scanning syntax or UI elements.

### 3. Earthy Palette Philosophy

Natural warm tones (browns, oranges, yellows) form foundation. Analogous to autumn leaves, weathered wood, warm earth. Cool colors (blues, aquas) used sparingly for contrast, not dominance.

### 4. Hard Contrast with Comfort

"Hard" contrast variant provides strong differentiation without harshness. Higher contrast than "soft" variant while maintaining warmth. Balances readability with visual comfort across lighting conditions.

### 5. Retro Groove Aesthetic

Deliberately warm color temperature throughout. Avoids clinical whites and pure blacks. Embraces "character" over sterile precision—personality as design feature.

---

## Color Selection Framework

### State Indicators (Community Conventions)

| Semantic Purpose                       | Color          | Hex     | Rationale                                  |
| -------------------------------------- | -------------- | ------- | ------------------------------------------ |
| **Errors / Danger / Deletions**        | `red`          | #fb4934 | High attention critical states             |
| **Success / Additions / Confirmation** | `green`        | #b8bb26 | Positive outcomes and growth               |
| **Warnings / Caution**                 | `yellow`       | #fabd2f | Warm attention without urgency             |
| **Information / Connectivity**         | `aqua`         | #8ec07c | Cool accent for informational states       |
| **Modifications / Changes**            | `orange`       | #fe8019 | Warm distinct change indicator             |
| **Navigation / Primary Actions**       | `blue`         | #83a598 | Minimal cool accent for primary focus      |

**Decision rule**: Warm colors (yellow, orange) preferred over cool (blue). Use aqua/blue sparingly to maintain warm aesthetic.

### Background Surfaces (Progressive Depth)

| Surface Type             | Color   | Hex     | Usage                              |
| ------------------------ | ------- | ------- | ---------------------------------- |
| **Primary / Base**       | `dark0` | #282828 | Darkest layer; foundational canvas |
| **Secondary / Elevated** | `dark1` | #3c3836 | Panels, cards, elevated elements   |
| **Tertiary / Overlays**  | `dark2` | #504945 | Popovers, tooltips, dialogs        |

**Decision rule**: Progressive lightening (dark0 → dark1 → dark2) using warm brown tones. Each tier distinctly elevated.

### Text Hierarchy (Progressive Contrast)

| Content Type                   | Color    | Hex     | Usage                                      |
| ------------------------------ | -------- | ------- | ------------------------------------------ |
| **Primary Content**            | `light1` | #ebdbb2 | Highest contrast for body text             |
| **Secondary / Metadata**       | `light2` | #d5c4a1 | Medium contrast for labels, sub-headlines  |
| **Disabled / Dimmed**          | `light4` | #a89984 | Low contrast for unfocused/inactive        |
| **High Contrast (on accents)** | `dark0`  | #282828 | Text on colored backgrounds (darkest base) |

**Decision rule**: Warm beige/tan text colors (not cool grays). Contrast through lightness, warmth preserved.

### Interactive States

| State                | Color Strategy                    | Application                                     |
| -------------------- | --------------------------------- | ----------------------------------------------- |
| **Active / Focused** | `yellow` (#fabd2f) background     | Warm-first approach; yellow for active states   |
| **Hover**            | `dark1` (#3c3836) background      | Elevated surface indication                     |
| **Inactive**         | `light4` (#a89984) foreground     | Disabled or unfocused elements                  |
| **Selection**        | `dark2` (#504945) at 30-40% opacity | Text selection with warm undertone              |
| **Borders / Hints**  | `orange` (#fe8019)                | Warm accent for active borders                  |

**Decision rule**: Yellow for active (not blue). Warm accents (orange, yellow) preferred for interactive feedback.

---

## Context-Specific Selection

### Syntax Highlighting

| Element Type               | Color    | Hex     | Rationale                              |
| -------------------------- | -------- | ------- | -------------------------------------- |
| **Keywords / Structure**   | `red`    | #fb4934 | Structural language elements           |
| **Functions / Methods**    | `green`  | #b8bb26 | Callable actions                       |
| **Strings / Literals**     | `green` or `light1` | #b8bb26 or #ebdbb2 | Literal data (green with improved_strings, foreground default) |
| **Comments / Docstrings**  | `gray`   | #928374 | De-emphasized metadata                 |
| **Constants / Numbers**    | `purple` | #d3869b | Fixed values (warm purple)             |
| **Types / Classes**        | `yellow` | #fabd2f | Type definitions (warm emphasis)       |
| **Variables**              | `blue`   | #83a598 | Minimal cool accent                    |
| **Parameters**             | `aqua`   | #8ec07c | Function inputs (LSP/Tree-sitter, not base Vim) |
| **Operators**              | `orange` or `light1` | #fe8019 or #ebdbb2 | Arithmetic/logic (stylistic preference, Vim default uses foreground) |

**Warm-first rule**: Red keywords, yellow types. Blue/aqua used sparingly for contrast.

### Git Operations

| Operation         | Color    | Hex     | Rationale           |
| ----------------- | -------- | ------- | ------------------- |
| **Additions**     | `green`  | #b8bb26 | Positive growth     |
| **Modifications** | `orange` | #fe8019 | Alterations/changes |
| **Deletions**     | `red`    | #fb4934 | Removal or danger   |
| **Renames**       | `blue`   | #83a598 | Structural change   |
| **Staging**       | `yellow` | #fabd2f | Informational state |

---

## OpenCode Implementation Notes

### Official Base16 Alignment

**Reference**: This theme aligns with [base16-opencode](https://github.com/scaryrawr/base16-opencode) color mappings for OpenCode terminal UI.

**Background Hierarchy**:
- `bg-primary` → `base00` (#282828 - bg)
- `bg-secondary` → `base01` (#3c3836 - bg1)
- `bg-tertiary` → `base02` (#504945 - bg2)

**Gruvbox Progressive Backgrounds**: Gruvbox uses numbered background progression (bg/bg1/bg2/bg3/bg4) representing increasing luminance. The base16 mapping uses the first three tiers for primary/panel/element backgrounds.

**Architecture**: We use separate theme directories (dark/light) for symlink-based switching integrated with desktop environment (Waybar, Dunst, Hyprland). Color values align with official base16-gruvbox-dark-hard implementation while maintaining our multi-app theme system.

**Status**: ✅ **Already aligned** - No color changes needed. All values match official base16-gruvbox-dark-hard implementation.

### Validation Checklist

**Contrast Compliance**:
- [x] bg-tertiary ≠ fg-muted (no invisible text)
- [x] FG_PRIMARY on BG_SECONDARY ≥ 4.5:1 (WCAG AA: 8.59:1)

**Color Accuracy**:
- [x] Background tiers match official base00/01/02 (bg/bg1/bg2)
- [x] Foreground hierarchy uses official Gruvbox palette
- [x] No custom colors introduced

**Official Reference**: [base16-gruvbox-dark-hard.json](https://github.com/scaryrawr/base16-opencode)

---

## Variant Adaptation

Gruvbox uses **neutral color darkening** for light variant while **preserving warm temperature**.

### Dark → Light Transformations

| Dark Mode | Light Mode | Role |
| --------- | ---------- | ---- |
| `dark0` #282828 → | `light0` #fbf1c7 | Background (warm cream) |
| `dark1` #3c3836 → | `light1` #ebdbb2 | Elevated surfaces |
| `light1` #ebdbb2 → | `dark1` #3c3836 | Primary text (warm brown) |
| Bright accents → | Neutral accents | Darker/muted for visibility |

**Bright vs Neutral palettes**:
- **Dark uses bright**: #fb4934 (red), #b8bb26 (green), #fabd2f (yellow)
- **Light uses neutral**: #cc241d (red), #98971a (green), #d79921 (yellow)

**Adaptation rule**: Accents darken 15-25% for light backgrounds. Warm temperature preserved. Semantic relationships identical.

---

## Complete Palette Reference

### Backgrounds (Warm Browns)
```
dark0_hard: #1d2021  (hardest contrast variant)
dark0:      #282828  (primary background)
dark1:      #3c3836  (elevated surfaces)
dark2:      #504945  (popovers)
dark3:      #665c54  (highest elevation)
dark4:      #7c6f64  (subtle overlays)
```

### Foregrounds (Warm Beiges)
```
light0_hard: #f9f5d7  (hardest contrast variant)
light0:      #fbf1c7  (optional emphasized)
light1:      #ebdbb2  (primary body text)
light2:      #d5c4a1  (sub-headlines, labels)
light3:      #bdae93  (comments, metadata)
light4:      #a89984  (disabled/unfocused)
```

### Accents (Bright Palette)
```
red:    #fb4934  (errors, deletions, keywords)
green:  #b8bb26  (success, additions, strings)
yellow: #fabd2f  (warnings, types, constants)
blue:   #83a598  (functions, links, minimal cool accent)
purple: #d3869b  (special purpose, constants)
aqua:   #8ec07c  (information, parameters)
orange: #fe8019  (modifications, operators, warm emphasis)
gray:   #928374  (comments, dimmed)
```

---

## Terminal Colors (ANSI Mapping)

| ANSI    | Gruvbox | Hex     | Semantic              |
| ------- | ------- | ------- | --------------------- |
| Red     | `red`   | #fb4934 | Errors, deletions     |
| Yellow  | `yellow`| #fabd2f | Warnings              |
| Green   | `green` | #b8bb26 | Success, additions    |
| Cyan    | `aqua`  | #8ec07c | Information           |
| Blue    | `blue`  | #83a598 | Primary actions       |
| Magenta | `purple`| #d3869b | Special purpose       |

**Note**: Terminal palette includes neutral variants for ANSI 0-7 (darker) and bright variants for ANSI 8-15.

---

## Validation Checklist

**Color Assignment:**
- [ ] **Semantic consistency**: Color matches functional purpose (warm-first approach)
- [ ] **Warm temperature**: Yellow/orange dominate over blue/aqua
- [ ] **Contrast hierarchy**: Progressive surface/text tiers (dark0 → dark1 → dark2)
- [ ] **Distinguishable colors**: High colorwheel separation between accents
- [ ] **Retro groove**: Earthy warmth throughout, no clinical neutrals
- [ ] **Bright palette**: Using bright variants (not neutral) for dark mode

**Accessibility (WCAG AA):**
- [ ] **Elevated surfaces**: All `@bg-secondary` surfaces use `@fg-primary` (NOT `@fg-secondary`)
- [ ] **Firefox compliance**: Icons on URL bar, selected tabs, sidebar all use primary text
- [ ] **Contrast ratios**:
  - FG_PRIMARY on BG_SECONDARY: 8.59:1 (✓ passes AAA ≥7.0:1)
  - FG_SECONDARY on BG_SECONDARY: 6.76:1 (✓ passes AA, but PRIMARY preferred)

**Official palette alignment:**
- [ ] Colors match official Gruvbox Dark palette exactly
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
- [Gruvbox Light Style Guide](../gruvbox-light/STYLE-GUIDE.md) - Light variant (neutral palette)

> **See also**: [OPENCODE.md](./OPENCODE.md) for OpenCode CLI integration details
