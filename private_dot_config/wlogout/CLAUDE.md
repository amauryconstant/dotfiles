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

⚠️ **Four different mappings exist for these six buttons.** This one (wlogout), the shipped
Quickshell `power/PowerMenu.qml` (only the destructive tile is coloured — every other tile is
neutral until selected, per the accent rule), and two more in the design canvas that disagree
with each other (`ses-a` gives suspend `@accent-subtle`; `f-d` gives it `@accent-border` and adds
a hibernate tile). Measured, three of the roles this table uses fail the 3:1 graphic floor on a
light ground — `@accent-tertiary` 2.60 (rose-pine-dawn), `@accent-alternative` 2.47 (latte),
`@accent-subtle` 2.34 (latte). Treat the table above as **wlogout's** mapping only; the
Quickshell power menu is not a port of it. Unresolved — see
`_research/QUICKSHELL_DESIGN_AUDIT.md` §1.13.

## Contrast rule

Buttons default to `@bg-secondary` (elevated) → labels **must** be `@fg-primary`, not `@fg-secondary`. Text on hover/focus accent fill uses `@fg-contrast`. See `themes/CLAUDE.md`.
