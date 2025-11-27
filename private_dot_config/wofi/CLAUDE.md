# Wofi - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/wofi/`
**Parent**: See `../CLAUDE.md` for desktop environment overview
**Theme system**: See `../themes/CLAUDE.md` for semantic variables reference

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **File**: `style.css.tmpl` (GTK CSS with semantic variables)
- **Config**: `config` (launcher behavior)
- **Theme integration**: `@import "../themes/current/wofi.css"`
- **Format**: GTK CSS with `@variable` references
- **Variables used**: 9 semantic variables (8 core + 1 extended Phase 3)
- **Purpose**: Application launcher and menu system

## Semantic Variable Usage

### 9 Variables Used (Phase 3)

| Semantic Variable | Wofi Element | Usage |
|-------------------|--------------|-------|
| `@bg-primary` | Window background, inner-box, outer-box | Main canvas |
| `@bg-secondary` | Input field, scroll bar, hover states | Elevated surfaces |
| `@fg-primary` | Text content, input text | Main text |
| `@fg-muted` | Placeholder text (if used) | Subtle hints |
| `@accent-primary` | Selected item background | Active selection |
| `@fg-contrast` | Text on selected item | High contrast on accent bg |
| `@bg-tertiary` | (Optional) borders, separators | Visual separation |
| `@accent-highlight` | (Optional) alternative highlight | Special emphasis |
| `@accent-modification` | **Search match highlight (Phase 3)** | **Matched search terms** |

## Element Mappings

### Core Elements

```css
/* Main window */
window {
    background-color: @bg-primary;
    color: @fg-primary;
    border: 1px solid @bg-secondary;    /* Subtle border */
}

/* Search input */
#input {
    background-color: @bg-secondary;    /* Elevated */
    color: @fg-primary;
    border: 1px solid @bg-tertiary;     /* Defined border */
}

/* Results containers */
#inner-box, #outer-box {
    background-color: @bg-primary;      /* Match window */
    color: @fg-primary;
}

/* Scrollbar */
#scroll {
    background-color: @bg-secondary;    /* Elevated track */
}

/* Individual result text */
#text {
    color: @fg-primary;
}

/* Selected result */
#entry:selected {
    background-color: @accent-primary;  /* Prominent selection */
    color: @fg-contrast;                /* High contrast text */
}
```

### State Handling

Wofi supports CSS states for interactive elements:

```css
/* Hover state (optional) */
#entry:hover {
    background-color: @bg-secondary;    /* Subtle hover */
}

/* Selected + hover (if different from selected) */
#entry:selected:hover {
    background-color: @accent-primary;  /* Keep selection prominent */
    color: @fg-contrast;
}
```

## Theme Integration

### How It Works

1. Wofi template (`style.css.tmpl`) imports: `@import "../themes/current/wofi.css"`
2. Theme file defines semantic variables with hex values
3. Template uses semantic names throughout
4. Theme switch updates symlink → Wofi inherits new colors on next launch

### Theme File Locations

All themes provide wofi.css:
```
~/.config/themes/
├── catppuccin-mocha/wofi.css
├── catppuccin-latte/wofi.css
├── gruvbox-dark/wofi.css
├── gruvbox-light/wofi.css
├── rose-pine-moon/wofi.css
├── rose-pine-dawn/wofi.css
├── solarized-dark/wofi.css
└── solarized-light/wofi.css
```

## Testing Procedures

After theme changes:

1. **Launch Wofi**: `Super+D` (app launcher) or `wofi --show drun`
2. **Test elements**:
   - Window background: Should match `@bg-primary`
   - Input field: Elevated `@bg-secondary`
   - Type query: Text visible `@fg-primary`
   - Navigate results: Selection visible `@accent-primary` bg
   - Selected text: High contrast `@fg-contrast`
3. **Verify contrast**: All text readable, selection obvious

## Common Patterns

### Minimal Launcher Style

Wofi focuses on simplicity. Key principles:
- Single accent color for selection (no multi-color accents)
- Consistent backgrounds (primary + secondary only)
- High contrast selection for keyboard navigation

### Search Highlight (Phase 3 - Active)

Search term highlighting enabled with modification semantic:
```css
#text match {
    color: @accent-modification;        /* Highlight matched chars - Phase 3 */
    font-weight: bold;
    text-decoration: underline;
}
```

**Rationale**: `@accent-modification` semantically represents "changes/highlights" - perfect for search matching.

### Alternative Selection Style

Some themes use border instead of background:
```css
#entry:selected {
    background-color: @bg-secondary;    /* Subtle bg */
    border-left: 3px solid @accent-primary;  /* Accent indicator */
    color: @fg-primary;
}
```

## Configuration Details

**Behavior config** (`config`):
- Mode: drun (apps), run (commands), dmenu (input)
- Width, height, position
- Columns, rows
- Allow images (app icons)
- Insensitive search

**Style** (`style.css.tmpl`):
- Colors (via theme import)
- Typography (font family, size)
- Spacing (padding, margins)
- Borders, corners

## Theme System Integration

**See**: `../themes/CLAUDE.md` for:
- Complete semantic variable definitions
- Theme-to-semantic mappings (all 8 themes)
- Wofi-specific color assignments

**Key principle**: Wofi uses subset of semantic schema (8/16 variables). Focus on backgrounds, foregrounds, primary accent only.

## File References

- **Style implementation**: `style.css.tmpl` (this directory)
- **Behavior config**: `config` (this directory)
- **Theme files**: `../themes/*/wofi.css` (per-theme colors)
- **Active theme**: `../themes/current/wofi.css` (symlink)
- **Semantic mappings**: `../themes/CLAUDE.md#theme-to-semantic-mappings`

## Integration with Menu System

Wofi used for multiple purposes:
- Application launcher: `Super+D` (hyprland binding)
- Power menu: Via `menu-style.sh` wrapper
- Theme menu: `theme-menu.sh` uses wofi for theme selection
- Custom menus: Scripts in `~/.local/lib/scripts/user-interface/`

Each uses same styling, ensuring visual consistency.
