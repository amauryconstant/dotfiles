# Wlogout - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/wlogout/`
**Parent**: See `../CLAUDE.md` for desktop environment overview
**Theme system**: See `../themes/CLAUDE.md` for semantic variables reference

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **File**: `style.css.tmpl` (GTK CSS with semantic variables)
- **Layout**: `layout` (button positions)
- **Theme integration**: `@import "../themes/current/wlogout.css"`
- **Format**: GTK CSS with `@variable` references
- **Variables used**: ~10 (backgrounds, foregrounds, all 8 accents)
- **Purpose**: Power menu (lock, logout, suspend, hibernate, reboot, shutdown)

## Semantic Variable Usage

### 10 Variables Used

| Semantic Variable | Wlogout Element | Usage |
|-------------------|-----------------|-------|
| `@bg-primary` | Window background | Main canvas (semi-transparent) |
| `@bg-secondary` | Button default state | Elevated button surface |
| `@bg-tertiary` | Button borders | Visual separation |
| `@fg-primary` | Button labels | Default text |
| `@fg-contrast` | Text on colored buttons | High contrast on hover/focus |
| `@accent-tertiary` | Lock button | Orange/peach |
| `@accent-warning` | Logout button | Yellow |
| `@accent-primary` | Suspend button | Blue |
| `@accent-highlight` | Hibernate button | Violet/purple |
| `@accent-info` | Reboot button | Cyan/teal |
| `@accent-error` | Shutdown button | Red |

## Button-to-Accent Mappings

### 6 Buttons, 6 Different Colors

Each button gets distinct semantic accent for instant recognition:

| Button ID | Semantic Color | Typical Hue | Action Type | Rationale |
|-----------|---------------|-------------|-------------|-----------|
| `#lock` | `@accent-tertiary` | Orange/peach | Non-destructive | Alternative action |
| `#logout` | `@accent-warning` | Yellow | Caution | Ends session, warns user |
| `#suspend` | `@accent-primary` | Blue | Primary sleep | Most common sleep action |
| `#hibernate` | `@accent-highlight` | Violet/purple | Alternative sleep | Less common sleep |
| `#reboot` | `@accent-info` | Cyan/teal | System restart | Informational/system |
| `#shutdown` | `@accent-error` | Red | Destructive | Powers off, most severe |

### Design Rationale

**Color progression** (left to right, top to bottom):
1. Lock (orange) - least severe
2. Logout (yellow) - session ends
3. Suspend (blue) - reversible sleep
4. Hibernate (purple) - deep sleep
5. Reboot (cyan) - restarts system
6. Shutdown (red) - most severe

**Visual hierarchy**: Red shutdown most prominent, blue suspend comfortable default.

## Implementation Pattern

### Button Styling

```css
/* Default button state */
button {
    background-color: @bg-secondary;     /* Elevated */
    color: @fg-primary;                  /* Readable */
    border: 2px solid @bg-tertiary;      /* Defined edge */
    margin: 10px;
}

/* Hover state - button gets accent color */
button:hover {
    color: @fg-contrast;                 /* High contrast text */
}

/* Individual button hover colors */
button#lock:hover {
    background-color: @accent-tertiary;  /* Orange */
    color: @fg-contrast;
}

button#logout:hover {
    background-color: @accent-warning;   /* Yellow */
    color: @fg-contrast;
}

button#suspend:hover {
    background-color: @accent-primary;   /* Blue */
    color: @fg-contrast;
}

button#hibernate:hover {
    background-color: @accent-highlight; /* Violet */
    color: @fg-contrast;
}

button#reboot:hover {
    background-color: @accent-info;      /* Cyan */
    color: @fg-contrast;
}

button#shutdown:hover {
    background-color: @accent-error;     /* Red */
    color: @fg-contrast;
}

/* Focus state (keyboard navigation) */
button:focus {
    background-color: @accent-highlight; /* Or per-button accent */
    color: @fg-contrast;
    border-color: @accent-primary;       /* Visible focus ring */
}
```

### Alternative: Colored by Default

Some themes show colors without hover:
```css
button#lock {
    background-color: @accent-tertiary;
    color: @fg-contrast;
}

button#lock:hover {
    /* Brighten or add border */
    filter: brightness(1.2);
}
```

## Theme Integration

### How It Works

1. Wlogout template (`style.css.tmpl`) imports: `@import "../themes/current/wlogout.css"`
2. Theme file defines all semantic variables
3. Template applies accents to buttons
4. Theme switch updates symlink → Next wlogout launch uses new colors

### Theme File Locations

All themes provide wlogout.css:
```
~/.config/themes/
├── catppuccin-mocha/wlogout.css
├── catppuccin-latte/wlogout.css
├── gruvbox-dark/wlogout.css
├── gruvbox-light/wlogout.css
├── rose-pine-moon/wlogout.css
├── rose-pine-dawn/wlogout.css
├── solarized-dark/wlogout.css
└── solarized-light/wlogout.css
```

## Testing Procedures

After theme changes:

1. **Launch wlogout**: `Super+Shift+E` (power menu keybinding)
2. **Test elements**:
   - Window: Semi-transparent `@bg-primary` overlay
   - Buttons default: `@bg-secondary` surface
   - Hover each button: Should show distinct accent color
   - Button text on color: `@fg-contrast` high visibility
3. **Verify distinctions**:
   - All 6 buttons visually distinct
   - Shutdown (red) most obvious
   - Suspend (blue) comfortable default
4. **Test keyboard nav**: Focus visible, can tab between buttons

## Layout Configuration

**File**: `layout` (button positions)

Standard 2x3 grid:
```
[Lock]     [Logout]
[Suspend]  [Hibernate]
[Reboot]   [Shutdown]
```

Each entry defines:
- Button label
- Icon (optional)
- Action command
- Grid position

## Common Patterns

### Border-Based Alternative

Some prefer borders over backgrounds:
```css
button {
    background-color: @bg-secondary;
    border: 2px solid @bg-tertiary;
}

button#shutdown:hover {
    background-color: @bg-secondary;     /* Same bg */
    border-color: @accent-error;         /* Accent border */
    color: @accent-error;                /* Accent text */
}
```

### Icon Styling

If using icons (requires icon theme):
```css
button {
    /* Icon + label */
}

button image {
    /* Icon-specific styling */
    margin-bottom: 5px;
}
```

## Integration with Power Menu

**Trigger**: `Super+Shift+E` (Hyprland binding)
**Command**: `wlogout` (uses configs in this directory)
**Actions**: Defined in `layout` file
- Lock: `hyprlock`
- Logout: `hyprctl dispatch exit`
- Suspend: `systemctl suspend`
- Hibernate: `systemctl hibernate`
- Reboot: `systemctl reboot`
- Shutdown: `systemctl poweroff`

## Theme System Integration

**Key principle**: Wlogout uses ALL 8 semantic accents (one per button + extras).

**See**: `../themes/CLAUDE.md` for:
- Complete semantic variable definitions
- Theme-to-semantic mappings (all 8 themes)
- Accent color philosophy per theme

## File References

- **Style implementation**: `style.css.tmpl` (this directory)
- **Layout config**: `layout` (this directory)
- **Theme files**: `../themes/*/wlogout.css` (per-theme colors)
- **Active theme**: `../themes/current/wlogout.css` (symlink)
- **Semantic mappings**: `../themes/CLAUDE.md#theme-to-semantic-mappings`
- **Power actions**: Hyprland bindings in `~/.config/hypr/conf/bindings.conf.tmpl`
