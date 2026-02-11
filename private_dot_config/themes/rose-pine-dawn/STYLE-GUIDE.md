# Rose Pine Dawn - Color Selection Methodology

**Philosophy**: "Curated colours, endless creations" - intentional limitation over arbitrary choice.

**Variant**: Light variant, symmetric with Rose Pine Moon. Same semantic relationships, re-calibrated for bright environments.

**Source**: [Rose Pine Palette](https://rosepinetheme.com/palette/) | [Rose Pine Themes](https://rosepinetheme.com/themes/)

---

## Design Principles

**Identical to Rose Pine Moon** - see Moon style guide for detailed principles.

Key symmetry:
- Same 5 design principles (semantic consistency, hierarchical contrast, functional temperature, layering over multiplication, restrained palette)
- Same color selection framework
- Same decision rules
- **Only difference**: Absolute color values re-calibrated for light backgrounds

---

## Color Selection Framework

**Use the exact same framework as Rose Pine Moon** with these adaptations:

### State Indicators (Re-calibrated)

| Semantic Purpose | Color | Hex | Change from Moon |
|------------------|-------|-----|------------------|
| **Errors / Danger / Deletions** | `love` | #b4637a | Darker, more saturated |
| **Warnings / Caution** | `gold` | #ea9d34 | Darker, more saturated |
| **Success / Additions / Keywords** | `pine` | #286983 | Darker, more saturated |
| **Information / New Content** | `foam` | #56949f | Darker, more saturated |
| **Modifications / Search / Highlights** | `rose` | #d7827e | Darker, less saturated |
| **Navigation / Hints / Metadata** | `iris` | #907aa9 | Darker, less saturated |

**Decision rule**: Same as Moon - match functional purpose first.

### Background Surfaces (Inverted Depth)

| Surface Type | Color | Hex | Change from Moon |
|--------------|-------|-----|------------------|
| **Primary / Base** | `base` | #faf4ed | **Lightest** (was darkest) |
| **Secondary / Elevated** | `surface` | #fffaf3 | **Mid-light** (was mid-dark) |
| **Tertiary / Overlays** | `overlay` | #f2e9e1 | **Darkest background** (was lightest) |

**Decision rule**: Same progressive layering, inverted direction - overlays are darker than base (not lighter).

### Text Hierarchy (Inverted Contrast)

| Content Type | Color | Hex | Change from Moon |
|--------------|-------|-----|------------------|
| **Primary Content** | `text` | #575279 | **Dark** (was light) |
| **Secondary / Metadata** | `subtle` | #797593 | **Mid-dark** (was mid-light) |
| **Disabled / Dimmed** | `muted` | #9893a5 | **Lightest text** (was darkest) |

**Decision rule**: Same contrast hierarchy, inverted values - muted is lighter than text (opposite of Moon).

### Interactive States

**Identical framework to Moon** - use same color strategy table with Dawn's re-calibrated accent colors.

---

## Context-Specific Selection

**Use identical tables from Rose Pine Moon**:
- Syntax highlighting - same color assignments
- Git operations - same color assignments

Only the absolute hex values differ, not the semantic mappings.

---

## OpenCode

**Base16 mapping**: [base16-rose-pine-dawn](https://github.com/scaryrawr/base16-opencode) | [OPENCODE.md](./OPENCODE.md)
- `bg-primary` → `base00` (#faf4ed - base)
- `bg-secondary` → `base01` (#fffaf3 - surface)
- `bg-tertiary` → `base02` (#f2e9e1 - overlay)

---

## Variant Adaptation Notes

### Calibration Strategy

Rose Pine Dawn is **not an inversion** of Moon - it's a complete re-calibration:

**Background progression reversal**:
- Moon: base (darkest) → surface → overlay (lightest)
- Dawn: base (lightest) → surface → overlay (darkest)

**Accent darkening**:
- All accents are darker and more/less saturated for visibility on light backgrounds
- Example: pine #3e8fb0 (moon) → #286983 (dawn) - significantly darker

**Foreground inversion**:
- Text goes from light (#e0def4) to dark (#575279)
- Muted goes from dark (#6e6a86) to light (#9893a5)

**Semantic preservation**:
- `pine` still means success/additions/keywords
- `foam` still means information/new content
- All semantic relationships unchanged

---

## Complete Palette Reference

### Backgrounds (Inverted)
```
base:    #faf4ed  (lightest - primary background)
surface: #fffaf3  (mid-light - elevated surfaces)
overlay: #f2e9e1  (darkest bg - popovers/dialogs)
```

### Foregrounds (Inverted)
```
muted:  #9893a5  (lightest - disabled/unfocused)
subtle: #797593  (mid-dark - secondary text)
text:   #575279  (darkest - primary text)
```

### Accents (Re-calibrated)
```
love: #b4637a  (errors, deletions, danger - darker)
gold: #ea9d34  (warnings, caution - darker)
rose: #d7827e  (modifications, search, highlights - darker)
pine: #286983  (success, additions, keywords - darker)
foam: #56949f  (information, new content - darker)
iris: #907aa9  (navigation, hints, metadata - darker)
```

### Highlights (Re-calibrated)
```
highlightLow:  #dfdad9  (subtle selection - lighter)
highlightMed:  #cecacd  (moderate hover - lighter)
highlightHigh: #6e6a86  (strong emphasis - darker)
```

**Note**: Highlight colors not explicitly defined in official Rose Pine Dawn palette - these are inferred from the pattern.

### Lazygit Calibration Override

Rose Pine Dawn's surface tier (base → surface → overlay) produces only ~1.05:1 contrast ratio, making standard `bg-secondary`/`bg-tertiary` row highlights invisible in lazygit.

**Override**:
- `selectedLineBgColor` → `highlightMed` (#cecacd) instead of `surface` (#fffaf3)
- `inactiveViewSelectedLineBgColor` → `highlightLow` (#dfdad9) instead of `overlay` (#f2e9e1)

This uses Rose Pine's dedicated highlight tier (designed for selection states) rather than the surface elevation tier (designed for panel depth).

---

## Terminal Colors (ANSI Mapping)

**Identical mapping to Moon**, different hex values:

| ANSI | Rose Pine | Hex | Notes |
|------|-----------|-----|-------|
| Red | `love` | #b4637a | Darker for light bg |
| Yellow | `gold` | #ea9d34 | Darker for light bg |
| Green | `pine` | #286983 | Darker for light bg |
| Cyan | `rose` | #d7827e | Darker for light bg |
| Blue | `foam` | #56949f | Darker for light bg |
| Magenta | `iris` | #907aa9 | Darker for light bg |

---

## Validation Checklist

**Color Assignment:**
- [ ] **Semantic consistency**: Color matches functional purpose (same as Moon)
- [ ] **Contrast hierarchy**: Progressive tiers used correctly (inverted from Moon)
- [ ] **Temperature logic**: Warm for attention, cool for information (same as Moon)
- [ ] **Cross-application consistency**: Same meanings across contexts (same as Moon)
- [ ] **Official alignment**: Success = `pine`, Info = `foam` (same as Moon)
- [ ] **Variant symmetry**: Semantic mappings match Moon exactly
- [ ] **Calibration**: Accents darkened appropriately for light backgrounds
- [ ] **Background inversion**: Overlays darker than base (opposite of Moon)

**Accessibility (WCAG AA):**
- [ ] **Elevated surfaces**: All `@bg-secondary` surfaces use `@fg-primary` (NOT `@fg-secondary`)
- [ ] **Firefox compliance**: Icons on URL bar, selected tabs, sidebar all use primary text
- [ ] **Contrast ratios**:
  - FG_PRIMARY on BG_SECONDARY: 7.00:1 (✓ passes ≥4.5:1)
  - FG_PRIMARY on BG_PRIMARY: 8.59:1 (✓ passes AAA)
  - FG_SECONDARY on BG_PRIMARY: 4.02:1 (⚠ borderline, use sparingly)

**Official palette alignment:**
- [ ] Colors match official Rose Pine Dawn palette exactly
- [ ] No custom colors introduced

## Known Contrast Limitations

Rose Pine Dawn's official palette prioritizes aesthetic minimalism over maximum contrast. The `subtle` color (#797593) provides only 4.02:1 contrast on `base` (#faf4ed), slightly below WCAG AA requirements (4.5:1).

**Solution**: Use `text` color (#575279) for all elevated surfaces (`surface` backgrounds) instead of `subtle`. This achieves 7.00:1 contrast while staying within the official palette.

**Implementation**: Firefox userChrome.css explicitly uses `text` for all icons and buttons on `surface` backgrounds (URL bar, selected tabs, sidebar).

---

## References

- [Rose Pine Palette Philosophy](https://rosepinetheme.com/palette/) - Official semantic definitions
- [Rose Pine Theme Implementations](https://rosepinetheme.com/themes/) - 205+ application examples
- [Rose Pine Moon Style Guide](../rose-pine-moon/STYLE-GUIDE.md) - Dark variant reference

> **See also**: [OPENCODE.md](./OPENCODE.md) for OpenCode CLI integration details
