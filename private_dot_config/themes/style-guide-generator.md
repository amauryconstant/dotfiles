# Theme Style Guide Generator

**Purpose**: Generate concise, methodology-focused style guides for theme variants that explain color selection principles rather than enumerate specific assignments.

---

## Input Requirements

Before generating a style guide, gather:

1. **Theme name and variant** (e.g., "Catppuccin Mocha", "Gruvbox Dark")
2. **Official documentation URLs** (palette page, style guide, GitHub repo)
3. **Design philosophy** from official sources
4. **Complete color palette** with native color names and hex values
5. **Existing theme implementations** (VSCode, terminal emulators, other apps)
6. **Related variants** (light/dark pairs, family members)

---

## Generation Prompt Template

```
You are creating a color selection methodology guide for [THEME_NAME] [VARIANT].

## Research Phase

1. **Fetch official documentation**:
   - [THEME_PALETTE_URL] - Color definitions and philosophy
   - [THEME_STYLE_GUIDE_URL] - Official design guidelines (if exists)
   - [THEME_IMPLEMENTATIONS_URL] - Real-world examples

2. **Analyze the following**:
   - What is the core design philosophy?
   - What principles guide color selection? (contrast, temperature, semantic meaning)
   - How are colors organized? (by hue, by purpose, by intensity)
   - What patterns exist across implementations?
   - How does this theme differ from others in its family?
   - What makes this theme distinctive?

3. **Extract decision-making frameworks**:
   - When do you choose color A vs color B?
   - How are semantic meanings assigned? (error, warning, info, success)
   - What temperature logic applies? (warm vs cool colors)
   - How is hierarchy expressed? (backgrounds, text, accents)
   - How are interactive states handled? (hover, active, disabled)

## Document Structure

Create a style guide with these sections:

### Header
```markdown
# [Theme Name] [Variant] - Color Selection Methodology

**Philosophy**: [One-sentence core philosophy from official docs]

**[Variant Info]**: [If light variant] Light variant, symmetric with [Dark Variant]. Same semantic relationships, re-calibrated for bright environments.

**Source**: [Official URLs]
```

### 1. Design Principles (3-5 principles)

Extract and document the theme's core principles. Examples:
- Semantic consistency (colors have unwavering roles)
- Hierarchical contrast (progressive tiers, not arbitrary steps)
- Functional temperature (warm = attention, cool = information)
- Restrained palette (limited colors force consistency)
- Scientific calibration (CIELAB color space, measured contrast)

**Format**:
```markdown
## Design Principles

### 1. [Principle Name]
[1-2 sentence explanation of the principle]

### 2. [Principle Name]
[Explanation with examples if needed]
```

**For light variants of existing dark themes**:
```markdown
## Design Principles

**Identical to [Dark Variant]** - see [Dark Variant] style guide for detailed principles.

Key symmetry:
- [List what stays the same]
- **Only difference**: [What changes]
```

### 2. Color Selection Framework

Create decision trees and tables for choosing colors. Include:

#### State Indicators
Table with columns: Semantic Purpose | Color | Hex | Rationale

Cover: Errors, Warnings, Success, Information, Modifications, Navigation/Hints

**Decision rule**: [One sentence rule for this category]

#### Background Surfaces (Progressive Depth)
Table with columns: Surface Type | Color | Hex | Usage

Cover: Primary/Base, Secondary/Elevated, Tertiary/Overlays

**Decision rule**: [One sentence rule]

#### Text Hierarchy (Progressive Contrast)
Table with columns: Content Type | Color | Hex | Usage

Cover: Primary, Secondary/Metadata, Disabled/Dimmed

**Decision rule**: [One sentence rule]

#### Interactive States
Table with columns: State | Color Strategy | Application

Cover: Active/Focused, Hover, Inactive, Selection

**Decision rule**: [One sentence rule]

**For light variants**: Add "Change from [Dark]" column showing calibration

### 3. Context-Specific Selection

Only include if theme has specific guidance for these contexts:

#### Syntax Highlighting (if applicable)
Table: Element Type | Color | Rationale

Cover: Keywords, Functions, Strings, Variables, Comments, Constants, Parameters

**Temperature rule**: [Pattern, e.g., "Structure = cool; Actions = warm"]

#### Git Operations (if applicable)
Table: Operation | Color | Rationale

Cover: Additions, Modifications, Deletions, Renames, Staging/Merges

#### Domain-Specific (if theme has specific context)
Examples: Gruvbox's "warm-first" philosophy, Solarized's "content-type" approach

### 4. Variant Adaptation (if applicable)

**For theme families with light/dark variants**:

Explain the adaptation strategy:
- How are dark → light conversions done?
- Are colors inverted or re-calibrated?
- What stays constant (semantic roles)?
- What changes (absolute values)?
- Provide examples (e.g., "pine #3e8fb0 → #286983")

**For standalone themes**: Omit this section.

### 5. Complete Palette Reference

List all colors in organized groups:

```markdown
## Complete Palette Reference

### Backgrounds
\`\`\`
[name]: #[hex]  ([description])
\`\`\`

### Foregrounds
\`\`\`
[name]: #[hex]  ([description])
\`\`\`

### Accents
\`\`\`
[name]: #[hex]  ([semantic meaning])
\`\`\`

### [Additional Categories]
\`\`\`
[name]: #[hex]  ([purpose])
\`\`\`
```

### 6. Terminal Colors (ANSI Mapping)

Table: ANSI | Theme Color | Hex | Semantic/Notes

Cover: Red, Yellow, Green, Cyan, Blue, Magenta

Include notes if mappings are non-standard (e.g., Rose Pine cyan → rose)

### 7. Validation Checklist

List of checkboxes for applying the theme correctly:

```markdown
## Validation Checklist

- [ ] **Semantic consistency**: Color matches functional purpose
- [ ] **Contrast hierarchy**: Progressive tiers used correctly
- [ ] **Temperature logic**: [Theme-specific rule]
- [ ] **Cross-application consistency**: Same meanings across contexts
- [ ] **Official alignment**: [Key principle from official docs]
- [ ] **[Theme-specific validation]**: [Unique requirement]
```

**For light variants**: Add variant-specific items:
- [ ] **Variant symmetry**: Semantic mappings match [dark variant] exactly
- [ ] **Calibration**: Accents adjusted appropriately for light backgrounds

### 8. References

```markdown
## References

- [Official Palette/Philosophy] - [Description]
- [Official Style Guide] - [Description]
- [Implementation Examples] - [Description]
- [Related Variant Guide] - [If applicable]
```

---

## Content Guidelines

### DO:
- ✅ Focus on **methodology** (how to choose) not **assignments** (what was chosen)
- ✅ Extract principles from official documentation
- ✅ Use decision trees and rules ("If X, use Y because Z")
- ✅ Include rationale for every color choice
- ✅ Keep language concise and direct
- ✅ Use tables for organized information
- ✅ Reference official sources with URLs
- ✅ Make light variants reference dark variants to avoid duplication

### DON'T:
- ❌ Include application-specific sections (Waybar, Wofi, Dunst, etc.)
- ❌ Provide usage examples or scenarios
- ❌ List specific UI element assignments (battery module, clock, etc.)
- ❌ Create lengthy explanations (1-2 sentences maximum)
- ❌ Duplicate information between dark/light variant guides
- ❌ Invent principles not found in official documentation
- ❌ Use subjective language ("beautiful", "elegant", "nice")

### Length Target:
- **Primary variant** (dark theme or standalone): 150-200 lines
- **Secondary variant** (light theme referencing dark): 100-150 lines

### Tone:
- Technical and precise
- Neutral and objective
- Imperative ("Use X for Y") not suggestive ("Consider using...")
- Fact-based with citations

---

## Theme-Specific Adaptations

### For Warm-First Themes (Gruvbox)
- Emphasize temperature hierarchy in Design Principles
- Add "Warm-First Philosophy" column to State Indicators table
- Document why warm colors are primary (not supporting)

### For Scientific Themes (Solarized)
- Highlight CIELAB/contrast-based principles
- Document symmetric design (light/dark have identical relationships)
- Include contrast ratio validation if part of official spec

### For Semantic Themes (Rose Pine)
- Emphasize semantic consistency principle
- Document git conventions if applicable
- Note intentional dual-purpose colors (not duplication)

### For Extensive Palettes (Catppuccin 14+ colors)
- Group accents by category (core, extended, special-purpose)
- Document official color role assignments
- Note which colors are optional vs required

### For Minimalist Themes (Base16-style)
- Document the 16-color constraint
- Explain how limitation creates consistency
- Show how colors are reused contextually

---

## Example Generation Command

**Input**:
```
Theme: Catppuccin Mocha
Official Palette: https://catppuccin.com/palette
Style Guide: https://github.com/catppuccin/catppuccin/blob/main/docs/style-guide.md
Implementations: https://github.com/catppuccin/catppuccin
```

**Output**: Generate a style guide following the template above, with:
1. Design principles emphasizing pastel aesthetics and semantic clarity
2. Decision framework for choosing among 14+ accent colors
3. Tables showing when to use sapphire vs blue vs sky
4. Official recommendations (sapphire for info, lavender for borders, etc.)
5. Validation checklist ensuring official patterns followed
6. References to Catppuccin official documentation

---

## Quality Checklist

Before finalizing a style guide, verify:

- [ ] All official documentation URLs included and accessible
- [ ] Design principles extracted from official sources (not invented)
- [ ] Every color has a clear semantic purpose documented
- [ ] Decision rules provided for each category
- [ ] Rationale column filled for every color table
- [ ] No application-specific sections (Waybar, Wofi, etc.)
- [ ] No usage examples or scenarios
- [ ] Concise language (1-2 sentences per explanation)
- [ ] Tables formatted consistently
- [ ] Validation checklist includes theme-specific items
- [ ] Light variant references dark variant (if applicable)
- [ ] Length appropriate (150-200 lines for primary, 100-150 for secondary)
- [ ] Tone is technical, neutral, objective

---

## Usage

To generate a new style guide:

1. **Gather inputs**: Theme name, official URLs, design philosophy
2. **Research**: Use sub-agents to fetch and analyze official documentation
3. **Extract**: Identify design principles and decision-making patterns
4. **Generate**: Follow the template structure above
5. **Validate**: Check against quality checklist
6. **Review**: Ensure conciseness and methodology focus

The result should be a **concise, methodology-focused guide** that teaches someone how to make color decisions consistent with the theme's official philosophy, not a comprehensive list of every possible color assignment.
```
