# Waybar

**Location**: `private_dot_config/waybar/`
**Theme system**: See `../themes/CLAUDE.md` for the semantic variable schema.

- `style.css.tmpl` → GTK CSS, `@import "../themes/current/waybar.css"`.
- `config.tmpl` → JSON5 module definitions.
- Reload after edits: `killall -SIGUSR2 waybar`.

**`waybar.css` is the canonical theme color file**: it holds each variant's `@define-color` hex declarations, which `swaync` (`swaync.css.tmpl`) and `btop` (`btop.theme`) cross-reference. Edit a theme's colors there first.

## Module → semantic color assignments

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
| **Notification center** | `@fg-primary` | `@accent-error` bg (dnd), `@accent-warning` (unread) | Alert state |
| **Tray** | `@fg-primary` | `@accent-error` bg (needs-attention) | Neutral default |

### Background & Foreground Usage

| Element | Background | Foreground | Rationale |
|---------|-----------|------------|-----------|
| **Main bar** | `@bg-primary` | `@fg-primary` | Primary canvas |
| **Hover states** | `@bg-secondary` | - | Elevated surface |
| **Active workspace** | `@accent-primary` | `@fg-contrast` | High contrast on color |
| **Urgent workspace** | `@accent-error` | `@fg-contrast` | Critical visibility |

Convention for new modules: informational → `@accent-info`, success → `@accent-success`, warning → `@accent-warning`, critical → `@accent-error`, interactive → `@accent-highlight`, primary focus → `@accent-primary`; disabled → `@fg-muted`; hover bg → `@bg-secondary` (or the per-accent `*-hover` variant). Battery uses graded states incl. `@accent-urgent-secondary` for the 20–30% band.

## Modules (`config.tmpl`)

`hyprland/workspaces` (urgency hints), `hyprland/window`, `clock`, `network`, `pulseaudio`, `battery`, `bluetooth`, `backlight`, `disk`, `custom/swaync` (bell + unread badge), `tray`.
