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

`#input` sits on `@bg-secondary` (elevated) → text **must** be `@fg-primary`, not `@fg-secondary` (which fails WCAG AA; `@fg-primary` gives 7:1+ across all themes). See `themes/CLAUDE.md`.

## Menu-system integration

Wofi is the renderer for the whole menu system, all sharing this stylesheet: app launcher (`Super+D`), and `~/.local/lib/scripts/user-interface/` menus via `menu-style.sh` / `theme-menu.sh`.
