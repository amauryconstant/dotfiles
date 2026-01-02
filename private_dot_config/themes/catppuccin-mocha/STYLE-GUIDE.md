# Catppuccin Mocha - Color Selection Methodology

**Philosophy**: "Colorfulness is better than colorless" - balanced contrast with harmonic color relationships and rich 14-accent variety.

**Source**: [Catppuccin Official](https://github.com/catppuccin/catppuccin) | [Style Guide](https://github.com/catppuccin/catppuccin/blob/main/docs/style-guide.md)

---

## Design Principles

### 1. Colorfulness Over Neutrality

Rich color variety helps distinguish structural elements more easily. Cat

ppuccin embraces **14 distinct accent colors** (vs 6-8 in minimalist themes) to create visual interest and scannable interfaces.

### 2. Balanced Contrast

Middle ground between low and high contrast themes. Avoids dullness while preventing excessive brightness—works across various lighting conditions without harsh glare or insufficient distinction.

### 3. Harmonic Color Relationships

Vivid colors complement rather than clash. Pastel saturation ensures colors coexist harmoniously. Each accent carefully calibrated to maintain visual coherence across the full 14-color spectrum.

### 4. Semantic-First Selection

Choose colors based on meaning (error=red, success=green, links=blue) rather than aesthetic preference. Consistent semantic mapping across all 4 flavor variants enables seamless theme switching.

### 5. Legibility Flexibility

While maintaining readable contrast ratios, **legibility always comes first**. Text color guidelines are flexible—deviate when contrast demands it (e.g., text on colored backgrounds).

---

## Color Selection Framework

### State Indicators (Semantic Assignments)

| Semantic Purpose                       | Color        | Hex     | Rationale                                         |
| -------------------------------------- | ------------ | ------- | ------------------------------------------------- |
| **Errors / Danger / Deletions**        | `red`        | #f38ba8 | High attention critical states                    |
| **Success / Additions / Confirmation** | `green`      | #a6e3a1 | Positive outcomes and growth                      |
| **Warnings / Caution**                 | `yellow`     | #f9e2af | Alerts without urgency                            |
| **Information / Connectivity**         | `sapphire`   | #74c7ec | Primary info states (per official guide)          |
| **Secondary Information**              | `sky`        | #89dceb | Lighter alternative to sapphire                   |
| **Modifications / Highlights**         | `pink`       | #f5c2e7 | Change in progress, distinct from errors          |
| **Navigation / Primary Actions**       | `blue`       | #89b4fa | Links, tags, primary focus elements               |

**Decision rule**: Match functional purpose to semantic color. Sapphire for info (official), sky for secondary, pink for modifications.

### Background Surfaces (Progressive Depth)

| Surface Type             | Color     | Hex     | Usage                              |
| ------------------------ | --------- | ------- | ---------------------------------- |
| **Primary / Base**       | `base`    | #1e1e2e | Darkest layer; foundational canvas |
| **Secondary / Elevated** | `surface0` | #313244 | Panels, cards, elevated elements   |
| **Tertiary / Overlays**  | `surface1` | #45475a | Popovers, tooltips, dialogs        |

**Decision rule**: Progressive lightening (base → surface0 → surface1). Each tier distinctly elevated from previous.

### Text Hierarchy (Progressive Contrast)

| Content Type             | Color      | Hex     | Usage                                       |
| ------------------------ | ---------- | ------- | ------------------------------------------- |
| **Primary Content**      | `text`     | #cdd6f4 | Highest contrast for body text              |
| **Secondary / Metadata** | `subtext1` | #bac2de | Medium contrast for labels, sub-headlines   |
| **Disabled / Dimmed**    | `overlay2` | #9399b2 | Low contrast for unfocused/inactive content |
| **High Contrast (on accents)** | `crust` | #11111b | Text on colored backgrounds (darkest)       |

**Decision rule**: Contrast directly correlates with importance. Use crust on accent backgrounds for legibility (20:1+ ratios).

### Interactive States

| State                | Color Strategy                           | Application                                       |
| -------------------- | ---------------------------------------- | ------------------------------------------------- |
| **Active / Focused** | `blue` (#89b4fa) background              | Primary interactive elements, active workspaces   |
| **Hover**            | `surface0` (#313244) background          | Elevated surface indication                       |
| **Inactive**         | `overlay2` (#9399b2) foreground          | Disabled or unfocused elements                    |
| **Selection**        | `overlay2` (#9399b2) at 20-30% opacity   | Text selection (per official guide)               |
| **Borders / Hints**  | `lavender` (#b4befe)                     | Active borders, hints (per official guide)        |

**Decision rule**: Use blue for semantic active states. Lavender for borders/hints (official recommendation). Overlay opacity for selections.

---

## Context-Specific Selection

### Syntax Highlighting

| Element Type               | Color      | Hex     | Rationale                                  |
| -------------------------- | ---------- | ------- | ------------------------------------------ |
| **Keywords / Structure**   | `mauve`    | #cba6f7 | Structural language elements (purple)      |
| **Functions / Methods**    | `blue`     | #89b4fa | Callable actions                           |
| **Strings / Literals**     | `green`    | #a6e3a1 | Literal data distinct from logic           |
| **Comments / Docstrings**  | `overlay2` | #9399b2 | De-emphasized metadata                     |
| **Constants / Numbers**    | `peach`    | #fab387 | Fixed values (warm orange)                 |
| **Types / Classes**        | `yellow`   | #f9e2af | Type definitions                           |
| **Variables**              | `text` or `flamingo` | #cdd6f4 or #f2cdcd | Default text (minimal) or colored (nvim-style) |
| **Parameters**             | `maroon`   | #eba0ac | Function inputs (darker red variant)       |
| **Operators**              | `sky` or `teal` | #89dceb or #94e2d5 | Arithmetic/logic operators (varies by implementation) |

**Color variety rule**: Utilize full 14-accent palette for maximum visual distinction. Each element gets unique color for easy scanning.

### Git Operations

| Operation         | Color    | Hex     | Rationale                  |
| ----------------- | -------- | ------- | -------------------------- |
| **Additions**     | `green`  | #a6e3a1 | Positive growth            |
| **Modifications** | `pink`   | #f5c2e7 | Change in progress         |
| **Deletions**     | `red`    | #f38ba8 | Removal or danger          |
| **Renames**       | `blue`   | #89b4fa | Structural change          |
| **Staging**       | `sapphire` | #74c7ec | Informational state        |

---

## OpenCode Implementation Notes

### Official Base16 Alignment

**Reference**: This theme aligns with [base16-opencode](https://github.com/scaryrawr/base16-opencode) color mappings for OpenCode terminal UI.

**Background Hierarchy**:
- `bg-primary` → `base00` (#1e1e2e - crust)
- `bg-secondary` → `base01` (#181825 - mantle)
- `bg-tertiary` → `base02` (#313244 - surface0)

**Catppuccin Surface Naming**: Catppuccin uses semantic surface names (crust/mantle/surface0/surface1/surface2) rather than numeric `base00-0F`. The base16 mapping follows the luminance progression: crust (darkest) → mantle → surface0 → surface1 → surface2.

**Architecture**: We use separate theme directories (latte/mocha) for symlink-based switching integrated with desktop environment (Waybar, Dunst, Hyprland). Color values align with official base16-catppuccin-mocha implementation while maintaining our multi-app theme system.

**Diff Backgrounds**: This theme uses custom green/red tinted backgrounds for visual distinction:
- `bg-diff-added`: #2d353b (surface0 + green tint)
- `bg-diff-removed`: #3b2f32 (surface0 + red tint)
- `bg-diff-context`: #313244 (surface0 neutral)

### Validation Checklist

**Contrast Compliance**:
- [x] bg-tertiary ≠ fg-muted (no invisible text)
- [x] FG_PRIMARY on BG_SECONDARY ≥ 4.5:1 (WCAG AA: 10.2:1)

**Color Accuracy**:
- [x] Background tiers match official base00/01/02 (crust/mantle/surface0)
- [x] Foreground hierarchy uses official Catppuccin palette
- [x] Custom diff tinting documented above

**Official Reference**: [base16-catppuccin-mocha.json](https://github.com/scaryrawr/base16-opencode)

---

## Extended Accent Utilization

Catppuccin provides **14 accent colors**—use all of them to create rich visual hierarchy:

### When to Use Extended Colors

| Color        | Hex     | Primary Use Cases                                | Rationale                       |
| ------------ | ------- | ------------------------------------------------ | ------------------------------- |
| `rosewater`  | #f5e0dc | Cursors, subtle highlights                       | Official: cursor positioning    |
| `flamingo`   | #f2cdcd | Memory indicators, soft pink variants            | Gentle warm accent              |
| `pink`       | #f5c2e7 | Audio/media, modifications, terminal magenta     | Playful, distinct from red      |
| `mauve`      | #cba6f7 | Keywords, special states, emphasized items       | Purple for structural syntax    |
| `maroon`     | #eba0ac | CPU/performance, darker error distinction        | Darker red variant              |
| `teal`       | #94e2d5 | Network connectivity, terminal cyan alternative  | Distinct from sky/sapphire      |

**Richness principle**: Don't limit to 8 semantic colors. Catppuccin's strength is variety—leverage all 14 for visual interest.

---

## Variant Adaptation

Catppuccin Mocha → Latte transformation strategy:

### Background Inversion
- Mocha: `base` (#1e1e2e dark) → Latte: `base` (#eff1f5 light)
- Surface progression inverts but relationships preserved

### Accent Re-calibration
**Mocha (light pastels)** → **Latte (darker saturated)**:
- `blue`: #89b4fa → #1e66f5 (darker for visibility)
- `sapphire`: #74c7ec → #209fb5 (darker)
- `green`: #a6e3a1 → #40a02b (darker)
- `yellow`: #f9e2af → #df8e1d (darker, more orange)
- `red`: #f38ba8 → #d20f39 (darker)

**Adaptation rule**: All accents darken 40-60% for light backgrounds. Semantic relationships preserved exactly.

---

## Complete Palette Reference

### Backgrounds
```
base:    #1e1e2e  (darkest - primary background)
mantle:  #181825  (darker - secondary pane)
crust:   #11111b  (darkest - high contrast text on accents)
surface0: #313244  (elevated surfaces)
surface1: #45475a  (popovers)
surface2: #585b70  (highest elevation)
```

### Foregrounds
```
overlay0: #6c7086  (subtle overlays)
overlay1: #7f849c  (moderate overlays)
overlay2: #9399b2  (disabled/unfocused)
subtext0: #a6adc8  (sub-headlines alt)
subtext1: #bac2de  (sub-headlines, labels)
text:     #cdd6f4  (primary body text)
```

### Accents (All 14)
```
rosewater: #f5e0dc  (cursors, subtle highlights)
flamingo:  #f2cdcd  (memory, soft pink)
pink:      #f5c2e7  (audio, modifications, magenta)
mauve:     #cba6f7  (keywords, special states)
red:       #f38ba8  (errors, deletions, danger)
maroon:    #eba0ac  (CPU, darker red variant)
peach:     #fab387  (constants, numbers, warm orange)
yellow:    #f9e2af  (warnings, caution, types)
green:     #a6e3a1  (success, additions, strings)
teal:      #94e2d5  (network, cyan alternative)
sky:       #89dceb  (secondary info, lighter blue)
sapphire:  #74c7ec  (information, connectivity)
blue:      #89b4fa  (links, primary actions, functions)
lavender:  #b4befe  (borders, hints, active focus)
```

---

## Terminal Colors (ANSI Mapping)

| ANSI    | Catppuccin | Hex     | Semantic           |
| ------- | ---------- | ------- | ------------------ |
| Red     | `red`      | #f38ba8 | Errors, deletions  |
| Yellow  | `yellow`   | #f9e2af | Warnings           |
| Green   | `green`    | #a6e3a1 | Success, additions |
| Cyan    | `teal`     | #94e2d5 | Information        |
| Blue    | `blue`     | #89b4fa | Primary actions    |
| Magenta | `pink`     | #f5c2e7 | Special purpose    |

**Note**: Catppuccin uses `teal` for ANSI cyan (not `sky`/`sapphire`) to maintain distinct hue from blue family.

---

## Validation Checklist

**Color Assignment:**
- [ ] **Semantic consistency**: Color matches functional purpose across contexts
- [ ] **14-accent utilization**: Rich color variety leveraged (not limited to 8)
- [ ] **Contrast hierarchy**: Progressive surface/text tiers used correctly
- [ ] **Official alignment**: Sapphire for info, lavender for borders, rosewater for cursors
- [ ] **Legibility first**: Text on colored backgrounds uses crust for contrast
- [ ] **Harmonic relationships**: Accent combinations maintain pastel coherence

**Accessibility (WCAG AA):**
- [ ] **Elevated surfaces**: All `@bg-secondary` surfaces use `@fg-primary` (NOT `@fg-secondary`)
- [ ] **Firefox compliance**: Icons on URL bar, selected tabs, sidebar all use primary text
- [ ] **Contrast ratios**:
  - FG_PRIMARY on BG_SECONDARY: 9.26:1 (✓ passes AAA ≥7.0:1)
  - FG_SECONDARY on BG_SECONDARY: 7.10:1 (✓ passes AAA, but PRIMARY preferred)

**Official palette alignment:**
- [ ] Colors match official Catppuccin Mocha palette exactly
- [ ] No custom colors introduced

---

## References

### Official Specification
- [Catppuccin Official Site](https://github.com/catppuccin/catppuccin) - Philosophy, palette
- [Catppuccin Style Guide](https://github.com/catppuccin/catppuccin/blob/main/docs/style-guide.md) - Official color assignments

### Community Implementations (Semantic Guidance)
- [Catppuccin Ports](https://github.com/catppuccin/catppuccin/blob/main/docs/ports.md) - 180+ application examples
- [Catppuccin VSCode](https://github.com/catppuccin/vscode) - Syntax highlighting reference

### Related
- [Catppuccin Latte Style Guide](../catppuccin-latte/STYLE-GUIDE.md) - Light variant (re-calibrated accents)

> **See also**: [OPENCODE.md](./OPENCODE.md) for OpenCode CLI integration details
