# Dunst - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/dunst/`
**Parent**: See `../CLAUDE.md` for desktop environment overview
**Theme system**: See `../themes/CLAUDE.md` for semantic variables reference

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **File**: `dunstrc.tmpl` (INI configuration)
- **Theme integration**: `!include ~/.config/themes/current/dunst.conf`
- **Format**: INI with direct hex values (no `@variable` support)
- **Variables used**: 4 semantic mappings (bg-primary, fg-primary, accent-primary, accent-error)
- **Urgency levels**: low, normal, critical

## Semantic Variable Usage

### 4 Variables Mapped to Hex

Dunst INI format doesn't support `@variable` syntax. Theme files provide direct hex values.

**Semantic mappings**:
| Semantic Variable | Dunst Setting | Usage |
|-------------------|---------------|-------|
| `@bg-primary` | `background` | All urgency levels |
| `@fg-primary` | `foreground` | All urgency levels |
| `@accent-primary` | `frame_color`, `highlight` | Normal/low urgency border |
| `@accent-error` | `frame_color` | Critical urgency border |

## Urgency Level Configuration

### Structure

Theme files (`themes/*/dunst.conf`) define colors per urgency:

```ini
[global]
frame_color = "#89b4fa"      # @accent-primary hex
separator_color = frame      # Matches frame_color
highlight = "#89b4fa"        # @accent-primary (progress bars)

[urgency_low]
background = "#1e1e2e"       # @bg-primary
foreground = "#cdd6f4"       # @fg-primary

[urgency_normal]
background = "#1e1e2e"       # @bg-primary
foreground = "#cdd6f4"       # @fg-primary

[urgency_critical]
background = "#1e1e2e"       # @bg-primary
foreground = "#cdd6f4"       # @fg-primary
frame_color = "#f38ba8"      # @accent-error
```

### Design Rationale

**Same background/foreground across urgencies**: Consistency, readability
**Different frame colors**: Visual distinction without jarring contrast
- Normal/low: Blue frame (`@accent-primary`) - calm, informational
- Critical: Red frame (`@accent-error`) - urgent, demands attention

## Theme Integration

### How It Works

1. Main config (`dunstrc.tmpl`) includes: `!include ~/.config/themes/current/dunst.conf`
2. Theme file provides urgency-specific colors
3. Dunst reads included file at startup
4. Theme switch → `killall dunst` → auto-restarts with new colors

### Theme File Locations

All themes provide dunst.conf:
```
~/.config/themes/
├── catppuccin-mocha/dunst.conf
├── catppuccin-latte/dunst.conf
├── gruvbox-dark/dunst.conf
├── gruvbox-light/dunst.conf
├── rose-pine-moon/dunst.conf
├── rose-pine-dawn/dunst.conf
├── solarized-dark/dunst.conf
└── solarized-light/dunst.conf
```

## Testing Procedures

After theme changes:

1. **Reload Dunst**: `killall dunst` (auto-restarts)
2. **Test notifications**:
   ```bash
   # Low urgency
   notify-send -u low "Low Priority" "This is a low urgency notification"

   # Normal urgency (default)
   notify-send "Normal Priority" "This is a normal notification"

   # Critical urgency
   notify-send -u critical "Critical Alert" "This is critical!"
   ```
3. **Verify**:
   - Low: Blue frame, readable text
   - Normal: Blue frame, readable text
   - Critical: Red frame, readable text
   - Background/text same across all (only frame differs)

## Common Patterns

### Adding New Urgency Level

Dunst supports custom urgency rules. Add to `dunstrc.tmpl`:

```ini
[custom_rule]
appname = "example-app"
urgency = critical
# Will use [urgency_critical] colors
```

### Progress Bar Colors

Dunst shows progress bars (e.g., volume, brightness). Color controlled by:
```ini
[global]
highlight = "#89b4fa"    # @accent-primary from theme
```

### Frame Consistency

Always use `separator_color = frame` to match separator with frame color.

## Theme System Integration

**Limitation**: INI format requires direct hex values, not variables.

**Solution**: Each theme provides pre-computed hex values in `dunst.conf`.

**See**: `../themes/CLAUDE.md` for:
- Semantic variable definitions
- Theme-to-hex mappings (all 8 themes)
- Example: Catppuccin Mocha `@bg-primary` = `#1e1e2e`

## File References

- **Main config**: `dunstrc.tmpl` (this directory)
- **Theme files**: `../themes/*/dunst.conf` (per-theme colors)
- **Active theme**: `../themes/current/dunst.conf` (symlink)
- **Semantic mappings**: `../themes/CLAUDE.md#theme-to-semantic-mappings`

## Configuration Details

Full dunst config in `dunstrc.tmpl` includes:
- Geometry (position, size, padding)
- Typography (font, alignment)
- Behavior (timeout, stacking, history)
- Icons (icon theme, size)
- Colors (via theme include)
