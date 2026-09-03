# Wofi

**Location**: `private_dot_config/wofi/`
**Theme system**: See `../themes/CLAUDE.md` for the semantic variable schema + contrast rules.

- `style.css.tmpl` → GTK CSS, `@import "../themes/current/wofi.css"` (themed via symlink; new colors on next launch).
- `config` → behavior (modes: drun/run/dmenu, geometry, insensitive search, icons).

## Semantic variables used

| Variable | Wofi element |
|----------|--------------|
| `@bg-primary` | window / inner-box / outer-box |
| `@bg-secondary` | input field, scrollbar, hover |
| `@fg-primary` | text + input text |
| `@fg-muted` | placeholder |
| `@accent-primary` | selected item background |
| `@fg-contrast` | text on selected item |
| `@accent-modification` | search-match highlight (`#text match` — bold/underline) |

`@accent-modification` is the "highlight/changes" role, reused here for matched search chars.

## Contrast rule

`#input` sits on `@bg-secondary` (elevated) → text **must** be `@fg-primary`, not `@fg-secondary`. Measured range for `@fg-primary` on `@bg-secondary` is **3.64–10.90:1** across the 8 colorsets (not "7:1+", which this file claimed until 2026-09-03) — it clears AA in six, and fails in both solarized themes, where the colorset itself is the problem. See `themes/CLAUDE.md` → Theme-Specific Contrast Ratios.

## Menu-system integration

Wofi is the renderer for the whole menu system, all sharing this stylesheet: app launcher (`Super+D`), and `~/.local/lib/scripts/user-interface/` menus via `menu-style.sh` / `theme-menu.sh`.
