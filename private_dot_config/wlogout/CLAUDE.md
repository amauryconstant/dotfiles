# Wlogout

**Location**: `private_dot_config/wlogout/`
**Theme system**: See `../themes/CLAUDE.md` for the semantic variable schema + contrast rules.

- `style.css.tmpl` → GTK CSS, `@import "../themes/current/wlogout.css"` (themed via symlink).
- `layout` → button definitions (label, icon, action, position). Trigger: `Super+Shift+E`.

## Button → accent mapping (the point of this config)

Each power action gets a distinct semantic accent so it's recognizable at a glance, ordered least→most severe:

| Button | Semantic | Action |
|--------|----------|--------|
| `#lock` | `@accent-tertiary` | `hyprlock` |
| `#logout` | `@accent-warning` | `hyprctl dispatch exit` |
| `#suspend` | `@accent-primary` | `systemctl suspend` (comfortable default) |
| `#hibernate` | `@accent-highlight` | `systemctl hibernate` |
| `#reboot` | `@accent-info` | `systemctl reboot` |
| `#shutdown` | `@accent-error` | `systemctl poweroff` (most prominent) |

Optional 7th button (`#suspend-then-hibernate`, commented in `style.css.tmpl`) uses `@accent-alternative` to stay distinct from the six.

## Contrast rule

Buttons default to `@bg-secondary` (elevated) → labels **must** be `@fg-primary`, not `@fg-secondary`. Text on hover/focus accent fill uses `@fg-contrast`. See `themes/CLAUDE.md`.
