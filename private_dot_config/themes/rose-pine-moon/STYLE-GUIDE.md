# Rose Pine Moon - Color Selection Methodology

**Philosophy**: "Curated colours, endless creations" - intentional limitation over arbitrary choice.

**Source**: [Rose Pine Palette](https://rosepinetheme.com/palette/) | [Rose Pine Themes](https://rosepinetheme.com/themes/)

---

## Design Principles

### 1. Semantic Consistency

Colors have **unwavering semantic roles** across all contexts. A color's meaning doesn't change based on the application - it maintains the same purpose whether in code syntax, UI states, or terminal output.

### 2. Hierarchical Contrast

Use **progressive tiers** (low/medium/high) rather than arbitrary steps. Visual hierarchy emerges from relative contrast differences, not absolute brightness values.

### 3. Functional Temperature

- **Warm colors** signal attention/action (errors, warnings, modifications)
- **Cool colors** indicate information/structure (additions, keywords, navigation)

### 4. Layering Over Multiplication

Build complexity through **opacity and combinations** of existing colors rather than introducing new colors for edge cases.

### 5. Restrained Palette

Limited to **15 colors total** - forces consistency and creates cohesion across diverse applications.

---

## Color Selection Framework

### State Indicators

| Semantic Purpose                        | Color  | Hex     | Rationale                                                  |
| --------------------------------------- | ------ | ------- | ---------------------------------------------------------- |
| **Errors / Danger / Deletions**         | `love` | #eb6f92 | Warm red signals critical attention needed                 |
| **Warnings / Caution**                  | `gold` | #f6c177 | Yellow-gold balances visibility with less urgency          |
| **Success / Additions / Keywords**      | `pine` | #3e8fb0 | Cool teal conveys calm competence and structural stability |
| **Information / New Content**           | `foam` | #9ccfd8 | Soft cyan for non-critical information states              |
| **Modifications / Search / Highlights** | `rose` | #ea9a97 | Warm coral draws eye without alarming; change in progress  |
| **Navigation / Hints / Metadata**       | `iris` | #c4a7e7 | Purple for secondary guidance and references               |

**Decision rule**: Match functional purpose first, aesthetic second.

### Background Surfaces (Progressive Depth)

| Surface Type             | Color     | Hex     | Usage                              |
| ------------------------ | --------- | ------- | ---------------------------------- |
| **Primary / Base**       | `base`    | #232136 | Darkest layer; foundational canvas |
| **Secondary / Elevated** | `surface` | #2a273f | Panels and cards                   |
| **Tertiary / Overlays**  | `overlay` | #393552 | Popovers and dialogs               |

**Decision rule**: Each layer gets progressively lighter. Don't skip tiers.

### Text Hierarchy (Progressive Contrast)

| Content Type             | Color    | Hex     | Usage                                       |
| ------------------------ | -------- | ------- | ------------------------------------------- |
| **Primary Content**      | `text`   | #e0def4 | Highest contrast for readability            |
| **Secondary / Metadata** | `subtle` | #908caa | Medium contrast for supporting information  |
| **Disabled / Dimmed**    | `muted`  | #6e6a86 | Low contrast for unfocused/inactive content |

**Decision rule**: Contrast directly correlates with importance.

### Interactive States

| State                    | Color Strategy                                        | Application                                                |
| ------------------------ | ----------------------------------------------------- | ---------------------------------------------------------- |
| **Active / Focused**     | Semantic accent color                                 | Choose based on meaning (success → `pine`, error → `love`) |
| **Hover**                | `highlightMed` (#403d52) or accent at 60% opacity     | Non-semantic hover states                                  |
| **Inactive / Unfocused** | `muted` (#6e6a86)                                     | Disabled or unfocused elements                             |
| **Selection**            | `highlightLow/Med/High` ( #21202e / #403d52 / #524f67) | Based on intensity needed                                  |

**Decision rule**: Use accent colors for semantic meaning, highlight tiers for non-semantic interaction states.

---

## Context-Specific Selection

### Syntax Highlighting

| Element Type               | Color            | Rationale                               |
| -------------------------- | ---------------- | --------------------------------------- |
| **Keywords / Structure**   | `pine`           | Cool teal provides structural backbone  |
| **Functions / Calls**      | `love` or `rose` | Warm colors highlight actions           |
| **Strings / Literals**     | `gold`           | Content distinct from code              |
| **Variables**              | `rose` or `text` | Coral for mutable, `text` for constants |
| **Comments**               | `subtle`         | Supportive, not primary                 |
| **Constants / Booleans**   | `foam`           | Calm and stable                         |
| **Parameters / Arguments** | `iris`           | Metadata about functions                |

**Temperature rule**: Structure = cool; Actions = warm; Content = gold.

### Git Operations

| Operation            | Color  | Rationale                 |
| -------------------- | ------ | ------------------------- |
| **Additions**        | `foam` | New content being added   |
| **Modifications**    | `rose` | Change in progress        |
| **Deletions**        | `love` | Removal/danger            |
| **Renames**          | `pine` | Structural reorganization |
| **Staging / Merges** | `iris` | Meta-operations           |

---

## Variant Adaptation

Rose Pine provides **three brightness variants** (main, moon, dawn) that maintain **identical semantic relationships** while adapting absolute values for readability.

### Dark Variants (Main / Moon)

- Light text on dark backgrounds
- Moon slightly lighter than main
- Semantic roles unchanged

### Light Variant (Dawn)

- **Not inverted** - completely re-calibrated
- Accents **desaturated and darkened** for light backgrounds
- Semantic roles **preserved**
- Example: `pine` #3e8fb0 (moon) → #286983 (dawn)

**Adaptation rule**: Rebuild for new context, don't invert.

---

## Complete Palette Reference

### Backgrounds

```
base:    #232136  (darkest - primary background)
surface: #2a273f  (mid - elevated surfaces)
overlay: #393552  (lightest - popovers/dialogs)
```

### Foregrounds

```
muted:  #6e6a86  (low contrast - disabled/unfocused)
subtle: #908caa  (medium - secondary text)
text:   #e0def4  (high - primary text)
```

### Accents

```
love: #eb6f92  (errors, deletions, danger)
gold: #f6c177  (warnings, caution)
rose: #ea9a97  (modifications, search, highlights)
pine: #3e8fb0  (success, additions, keywords)
foam: #9ccfd8  (information, new content)
iris: #c4a7e7  (navigation, hints, metadata)
```

### Highlights

```
highlightLow:  #21202e  (subtle selection)
highlightMed:  #403d52  (moderate hover)
highlightHigh: #524f67  (strong emphasis)
```

---

## Terminal Colors (ANSI Mapping)

| ANSI    | Rose Pine | Hex     | Semantic        |
| ------- | --------- | ------- | --------------- |
| Red     | `love`    | #eb6f92 | Errors, danger  |
| Yellow  | `gold`    | #f6c177 | Warnings        |
| Green   | `pine`    | #3e8fb0 | Success         |
| Cyan    | `rose`    | #ea9a97 | Modifications   |
| Blue    | `foam`    | #9ccfd8 | Information     |
| Magenta | `iris`    | #c4a7e7 | Hints, metadata |

**Note**: Terminal cyan maps to `rose` (not `foam`) for semantic consistency with modification/highlight operations.

---

## Validation Checklist

**Color Assignment:**
- [ ] **Semantic consistency**: Color matches functional purpose
- [ ] **Contrast hierarchy**: Progressive tiers used correctly
- [ ] **Temperature logic**: Warm for attention, cool for information
- [ ] **Cross-application consistency**: Same meanings across contexts
- [ ] **Official alignment**: Success = `pine`, Info = `foam`
- [ ] **Variant adaptation**: Re-calibrated, not inverted

**Accessibility (WCAG AA):**
- [ ] **Elevated surfaces**: All `@bg-secondary` surfaces use `@fg-primary` (NOT `@fg-secondary`)
- [ ] **Firefox compliance**: Icons on URL bar, selected tabs, sidebar all use primary text
- [ ] **Contrast ratios**:
  - FG_PRIMARY on BG_SECONDARY: 5.18:1 (✓ passes ≥4.5:1)
  - FG_SECONDARY on BG_SECONDARY: 4.46:1 (✗ fails, use PRIMARY only)

**Official palette alignment:**
- [ ] Colors match official Rose Pine Moon palette exactly
- [ ] No custom colors introduced

---

## References

- [Rose Pine Palette Philosophy](https://rosepinetheme.com/palette/) - Official semantic definitions
- [Rose Pine Theme Implementations](https://rosepinetheme.com/themes/) - 205+ application examples
- [Rose Pine VSCode](https://github.com/rose-pine/vscode) - Syntax highlighting reference
- [Rose Pine Hyprland](https://github.com/rose-pine/hyprland) - Window manager patterns
