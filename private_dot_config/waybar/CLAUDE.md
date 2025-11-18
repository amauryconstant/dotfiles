# Waybar - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/waybar/`
**Parent**: See `../CLAUDE.md` for desktop environment overview
**Theme system**: See `../themes/CLAUDE.md` for semantic variables reference

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **File**: `style.css.tmpl` (GTK CSS with semantic variables)
- **Config**: `config.tmpl` (JSON with module definitions)
- **Theme integration**: `@import "../themes/current/waybar.css"`
- **Variables used**: All 16 semantic variables
- **Format**: GTK CSS with `@variable` references

## Semantic Variable Usage

### All 16 Variables Used

Waybar uses complete semantic schema. Variables imported from `themes/current/waybar.css`.

**Quick lookup**:
```css
/* Imported from theme file */
@import "../themes/current/waybar.css";

/* Then used throughout */
window#waybar {
    background-color: @bg-primary;
    color: @fg-primary;
}
```

### Module Color Assignments

| Module | Default State | Alternative States | Rationale |
|--------|---------------|-------------------|-----------|
| **Clock** | `@accent-primary` | - | Primary focal point |
| **Workspaces (inactive)** | `@fg-muted` | - | Subtle when not active |
| **Workspaces (hover)** | `@accent-primary` bg, `@fg-contrast` text | - | Clear hover feedback |
| **Workspaces (active)** | `@accent-primary` bg, `@fg-contrast` text | - | Active indication |
| **Workspaces (urgent)** | `@accent-error` bg, `@fg-contrast` text | - | Demands attention |
| **Window title** | `@fg-secondary` | - | Less prominent |
| **Network** | `@accent-info` | `@fg-muted` (disconnected) | Connectivity status |
| **Battery (normal)** | `@accent-success` | - | Good state (>20%) |
| **Battery (warning)** | `@accent-warning` | - | Low (~20%) |
| **Battery (critical)** | `@accent-error` | Blink animation | Urgent (<10%) |
| **Battery (charging)** | `@accent-info` | - | Informational |
| **Battery (plugged)** | `@accent-primary` | - | Primary power |
| **Audio** | `@accent-highlight` | `@fg-muted` (muted) | Special interactive |
| **Bluetooth** | `@accent-info` | `@accent-highlight` (connected), `@fg-muted` (disabled) | Connectivity |
| **Backlight** | `@accent-warning` | - | Visual indicator |
| **Tray** | `@fg-primary` | `@accent-error` bg (needs-attention) | Neutral default |

### Background & Foreground Usage

| Element | Background | Foreground | Rationale |
|---------|-----------|------------|-----------|
| **Main bar** | `@bg-primary` | `@fg-primary` | Primary canvas |
| **Hover states** | `@bg-secondary` | - | Elevated surface |
| **Active workspace** | `@accent-primary` | `@fg-contrast` | High contrast on color |
| **Urgent workspace** | `@accent-error` | `@fg-contrast` | Critical visibility |

## Implementation Patterns

### Standard Module Styling

```css
/* Example: Network module */
#network {
    color: @accent-info;          /* Connected state */
}

#network.disconnected {
    color: @fg-muted;             /* Disabled/inactive state */
}
```

### State-Based Colors

```css
/* Example: Battery with multiple states */
#battery {
    color: @accent-success;       /* Normal (>20%) */
}

#battery.warning:not(.charging) {
    color: @accent-warning;       /* Warning (10-20%) */
}

#battery.critical:not(.charging) {
    color: @accent-error;         /* Critical (<10%) */
    animation: critical-blink 1s ease infinite;
}

#battery.charging {
    color: @accent-info;          /* Charging state */
}

#battery.plugged {
    color: @accent-primary;       /* Plugged/full */
}
```

### Animation with Semantic Colors

```css
@keyframes critical-blink {
    0% {
        background: transparent;
        color: @accent-error;
    }
    50% {
        background: @accent-error;
        color: @fg-contrast;      /* High contrast text on colored bg */
    }
    100% {
        background: transparent;
        color: @accent-error;
    }
}
```

## Module Configuration Reference

See `config.tmpl` for module definitions. Key modules:

- `hyprland/workspaces`: Workspace switcher (uses urgency hints)
- `hyprland/window`: Window title display
- `clock`: Date/time display
- `network`: Network connectivity
- `pulseaudio`: Audio control
- `battery`: Battery status (4 states)
- `bluetooth`: Bluetooth status (3 states)
- `backlight`: Screen brightness
- `tray`: System tray icons

## Testing Procedures

After theme changes:

1. **Reload Waybar**: `killall waybar && waybar &`
2. **Test all states**:
   - Connect/disconnect network
   - Toggle audio mute
   - Drain battery to test warning/critical (or simulate)
   - Hover over workspaces
   - Create urgent window (`hyprctl dispatch togglespecialworkspace`)
3. **Verify contrast**: Text readable on all backgrounds
4. **Check animations**: Battery critical blink visible

## Common Patterns

### Adding New Module

1. Define module in `config.tmpl`
2. Style in `style.css.tmpl` using semantic variables
3. Choose semantic color based on module purpose:
   - Informational → `@accent-info`
   - Success/positive → `@accent-success`
   - Warning/caution → `@accent-warning`
   - Error/critical → `@accent-error`
   - Interactive/special → `@accent-highlight`
   - Primary focus → `@accent-primary`

### Disabled/Inactive States

Always use `@fg-muted` for disabled:
```css
#module.disabled {
    color: @fg-muted;
}
```

### Hover Effects

Use `@bg-secondary` for hover backgrounds:
```css
#module:hover {
    background-color: @bg-secondary;
}
```

## Theme System Integration

**How it works**:
1. Theme file (`themes/current/waybar.css`) defines semantic variables with hex values
2. Waybar template (`style.css.tmpl`) imports theme and uses semantic names
3. Theme switch updates symlink → Waybar reloads → new colors applied

**See**: `../themes/CLAUDE.md` for:
- Complete semantic variable definitions
- Theme-to-semantic mappings (all 8 themes)
- Theme switching methods
- Style guide philosophy

## File References

- **Style implementation**: `style.css.tmpl` (this directory)
- **Module config**: `config.tmpl` (this directory)
- **Theme definitions**: `../themes/current/waybar.css` (symlink)
- **Theme mappings**: `../themes/CLAUDE.md#theme-to-semantic-mappings`
