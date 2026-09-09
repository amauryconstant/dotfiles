# Wofi

**Status**: **fallback only.** Since 2026-09-09 nothing reaches for Wofi while the Quickshell
shell is running — the launcher is `quickshell/dotfiles/launcher/Launcher.qml`, every `--dmenu`
caller goes through `desktop/quickshell-menu`, and clipboard history is
`clipboard/ClipboardPicker.qml`. Wofi stays installed because `quickshell-menu` falls back to it
whenever the shell is unreachable, which is load-bearing: these menus run during first-boot setup
and while the shell is being restarted, and a picker that hung there would take `system-menu` and
every `menu-*` script with it. It is also what still renders when
`features.quickshell_shell.enabled` is false.

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

Wofi *was* the renderer for the whole menu system. It is now the second half of one function:
`show_menu()` in `user-interface/menu-helpers.sh` calls `desktop/quickshell-menu`, which uses this
stylesheet only when the shell does not answer. `keybinds.css.tmpl` is gone — the keybinding
cheatsheet renders through the picker like everything else, so its dedicated stylesheet had no
consumer left.
