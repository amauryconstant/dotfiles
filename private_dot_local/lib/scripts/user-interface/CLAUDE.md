# User Interface Scripts - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/user-interface/`
**Parent**: See `../CLAUDE.md` for script library overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Entry point**: `launcher-actions` (`Super+Space`, the launcher's `>` mode)
- **Library**: `menu-helpers.sh` (sourced by `desktop/display-menu`)
- **Hook tools**: `hook-create`, `hook-edit`, `hook-list`, `hook-test`
- **Extra bindings**: `dotfiles-bindings-edit`
- **UI pattern**: `menu-helpers.sh` (show_menu + notify) — NOT gum-ui
- **Renderer**: `desktop/quickshell-menu` (the shell); no fallback — unreachable means cancelled plus a `hyprctl notify`

## Actions (Super+Space) — `launcher-actions`

`Super+Space` → `quickshell-toggle launcher actions` → the SUPER+D launcher opened on its `>` mode
(`Launcher.qml`). It replaced the ten-category `system-menu` tree (Apps, Learn, Trigger, Style,
Setup, Install, Update, AI, About, System) on 2026-10-23: that tree was 2–3 levels deep, its filter
saw only the current level, and most rows duplicated a dedicated surface or key.

- **`launcher-actions --print-items`** emits the rows as item JSON (`desktop/quickshell-menu --json`
  shape; `{header: true, title}` for sections). The launcher runs it on every open. Content lives
  here, not in QML, so a menu change never means editing the shell.
- **`launcher-actions run <payload>`** dispatches one row. Capture payloads are `capture:<mode>` and
  go to `media/capture-menu --run <mode>` after a 0.15s sleep (the launcher closes in the same tick;
  a Quickshell surface cannot exclude itself from a grim capture). Maintenance rows open a terminal
  and wait for Enter.
- **Capture rows are not copied**: they come from `media/capture-menu --print-items`.
- **Only actions with no other home are listed** (Capture, Maintenance). Apps, power, clipboard,
  audio/network/bluetooth, nightlight, themes and the keybindings sheet each have a key; do not add
  a second route to them here.
- 🚨 **Dotfile rows show `chezmoi diff` and ask before `chezmoi apply`** — never a blind apply.
- **No `menu-extend` hook** — retired with the old menu. Add rows to `launcher-actions`.
- Unrouted since the retirement: `desktop/display-menu` (display profiles), random/set wallpaper,
  `home-backup`. Scripts kept; give them a key or a row if wanted.

🚨 **The picker is `desktop/quickshell-menu`; Wofi was retired 2026-10-19.** `show_menu()` and
`confirm()` write the list to the shell over a UNIX socket
(`$XDG_RUNTIME_DIR/quickshell-menu.sock`) and block on the reply, which is why a dmenu call could
not be an `ipc call`: an IPC handler returns immediately. There is no fallback and the
contract is unchanged — items on stdin, the choice on stdout, exit 1 and no output on cancel.

## Icon Reference

**Criteria**: Material Design (`md-`) primary, outlined variants preferred (small-size legibility), emoji fallback only if no MD icon fits. Select via `/nerdfonts-search` skill (glyph data: `.claude/skills/nerdfonts-search/references/glyphnames.json`).

### Universal

| Entry | Icon | Glyph Name |
|-------|------|------------|
| ← Back | 󰁍 | md-arrow-left |

**Test icon rendering**: `echo "󰀻 Apps|󰗚 Learn|󰈿 Trigger" | tr '|' '\n' | quickshell-menu`

## menu-helpers.sh Library

Menu scripts source this library (today: `desktop/display-menu`). Three functions:

```bash
show_menu "Prompt" "option1|option2|option3"  # → quickshell-menu, returns selection
confirm "Question?"                             # → Yes/No via quickshell-menu, 0 if Yes
notify "Title" "Message" [timeout_ms]          # → notify-send wrapper (default 3000ms)
```

**Why not gum-ui**: Menu scripts are keypress-triggered background processes with no terminal to
draw in; a graphical picker + notify-send is the correct pattern.

## Hook Management CLI

Four tools that use gum-ui (not menu-helpers.sh — these are interactive terminal tools):

| Command | Purpose | Output |
|---------|---------|--------|
| `hook-create` | Interactive generator → creates executable hook file | `~/.config/dotfiles/hooks/{name}` |
| `hook-list` | Show all hook points + installed hooks | Terminal (gum table) |
| `hook-edit` | Open installed hook in `$EDITOR` | Editor launch |
| `hook-test` | Run hook with default test args | Shows output + exit code |

**Hook locations**: `~/.config/dotfiles/hooks/` (chezmoi-managed, always present)

## dotfiles-bindings-edit

Opens `~/.config/dotfiles/extra-bindings.conf` in `$EDITOR` and calls `hyprctl reload` on exit.

**Keybinding**: `Super+Ctrl+Shift+B`
**File managed by**: chezmoi (always present, prevents Hyprland parse error on missing source)

## theme-menu

Interactive theme selector. **The one caller that does not use `show_menu()`**: it sends JSON
objects through `quickshell-menu --json`, so each theme's own brand mark
(`themes/<name>/icon.png`, with a glyph fallback where upstream has none) lands in the icon column,
the active theme carries a `badge` instead of a `✓ ` prefix that shifted every other title, and
the slug travels as `payload` — invisible, and out of the fuzzy-match haystack. Rows are grouped
under `DARK` / `LIGHT` section headers.

**`show_menu()` stays plain-string.** A caller that wants a glyph column calls `quickshell-menu`
directly, as this one does; the pipe-delimited option list has no room for a second field.

🚨 **The dark/light arm lives in `desktop/theme-switcher` (`variant <theme>`)**, not here — it
was copied in four places. `theme-menu` owns the glyph map, which is presentation.

**Usage**: `theme-menu [--print-items]` (`Super+Shift+Ctrl+Space`). `--print-items` writes the item JSON
and exits, which is how the grouping, ordering and badge are checked without a display.

## Non-Obvious Patterns

**menu-helpers.sh keeps .sh extension**: It's a sourced library, not an executed script. Don't rename it.

🚨 **Nothing else keeps a `.sh` extension.** chezmoi strips `executable_` and `.tmpl` but adds
nothing, so the deployed scripts are `launcher-actions`, `audio-switch`, `random-wallpaper` — never
`*.sh`. (18 call sites once said otherwise, and **Back did nothing at all**: the path failed, the
script exited, and the menu simply closed.) A leaf that exits looks exactly like a leaf that ran,
so check the deployed name (`ls ~/.local/lib/scripts/<category>/`), not the source name.

**Template scripts** (`.tmpl` suffix): launcher-actions.tmpl, theme-menu.tmpl — chezmoi processes these at `chezmoi apply` time, not at runtime. Template vars are build-time substitutions.

**hook-create/edit/list/test use gum-ui**: Unlike menu scripts (graphical picker), hook tools are interactive terminal utilities — use gum for rich UI.

## Integration Points

- **Hyprland**: `~/.config/hypr/conf/bindings/system-control.conf` (`Super+Space` → `quickshell-toggle launcher actions`)
- **Picker**: menu scripts pipe lines to `desktop/quickshell-menu` (dmenu contract — lines in,
  one line out, empty means cancelled). there is no fallback picker
- **Hook system**: See `dotfiles/CLAUDE.md` for hook architecture
- **Extra bindings**: See `dotfiles/CLAUDE.md` for extra-bindings.conf
