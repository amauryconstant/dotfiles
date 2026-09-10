# User Interface Scripts - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/user-interface/`
**Parent**: See `../CLAUDE.md` for script library overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Entry point**: `system-menu` (keybinding: `Super+Space`)
- **Library**: `menu-helpers.sh` (sourced by all menu scripts)
- **Hook tools**: `hook-create`, `hook-edit`, `hook-list`, `hook-test`
- **Extra bindings**: `dotfiles-bindings-edit`
- **UI pattern**: `menu-helpers.sh` (show_menu + notify) — NOT gum-ui
- **Renderer**: `desktop/quickshell-menu` (the shell), falling back to Wofi when it is unreachable

## Main Menu (system-menu)

Routes `Super+Space` → the picker → category script.

🚨 **The picker is `desktop/quickshell-menu`, not Wofi.** Since 2026-09-09 `show_menu()` and
`confirm()` write the list to the shell over a UNIX socket
(`$XDG_RUNTIME_DIR/quickshell-menu.sock`) and block on the reply, which is why a dmenu call could
not be an `ipc call`: an IPC handler returns immediately. Wofi remains the fallback and the
contract is unchanged — items on stdin, the choice on stdout, exit 1 and no output on cancel —
so sixteen `menu-*` scripts converted without an edit of their own.

| Icon | Category | Script | Purpose |
|------|----------|--------|---------|
| 󰀻 | Apps | `quickshell-toggle launcher` | Application launcher |
| 󰗚 | Learn | menu-learn | Help/documentation |
| 󰈿 | Trigger | menu-trigger | Quick actions (capture, share, toggle) |
| 󰏘 | Style | menu-style | Theme switching, appearance |
| 󰒓 | Setup | menu-setup | System configuration |
| 󰏓 | Install | menu-install | Package installation |
| 󰚰 | Update | menu-update | System updates |
| 󱚣 | AI | menu-ai | AI integration |
| 󰋼 | About | menu-about | System information |
| 󰐥 | System | menu-system | Power management |

**Note**: Remove category (`menu-remove`) is commented out in system-menu. `utilities-menu` is a secondary launcher (reached from the Trigger/Setup categories, not a top-level entry).

**menu-extend hook**: Unknown choices from system-menu are delegated to `~/.config/dotfiles/hooks/menu-extend` (see `dotfiles/CLAUDE.md`).

## Icon Reference

**Criteria**: Material Design (`md-`) primary, outlined variants preferred (Wofi visibility), emoji fallback only if no MD icon fits. Select via `/nerdfonts-search` skill (glyph data: `.claude/skills/nerdfonts-search/references/glyphnames.json`).

### Trigger Menu (menu-trigger)

| Entry | Icon | Glyph Name |
|-------|------|------------|
| Capture | 󰄀 | md-camera |
| Share | 󰒖 | md-share |
| Toggle | 󰔡 | md-toggle-switch |

**Capture submenu**: 󰹑 md-selection (Smart) · 󰩭 md-selection-drag (Region) · 󰖲 md-window-maximize (Window) · 󰍹 md-monitor (Fullscreen) · 󰨸 md-clipboard-arrow-down (→ Clipboard) · 󰻂 md-record-circle (Screen Record) · 󰕾 md-microphone (+ Audio) · 󰴱 md-eyedropper (Color Picker)

**Share submenu**: 󰈔 md-file-send (File) · 󰨸 md-clipboard-arrow-up (Clipboard)

**Toggle submenu**: 󰛨 md-weather-night (Nightlight) · 󰌾 md-lock (Idle Lock) · 󰘯 md-monitor-dashboard (Waybar) · 󰝘 md-grid-large (Workspace Gaps)

### Style Menu (menu-style)

| Entry | Icon | Glyph Name |
|-------|------|------------|
| Switch Theme | 󰔎 | md-theme-light-dark |
| Wallpaper (Random) | 󰸉 | md-image-multiple |
| Wallpaper (Set) | 󰋩 | md-image |
| Edit Hyprland Config | 󰒓 | md-cog |

**Config submenu**: 󰍹 md-monitor (Monitor) · 󱃾 md-application-variable (Environment) · 󰌌 md-keyboard (Input) · 󰒓 md-cog (General) · 󰐮 md-palette-swatch (Decoration) · 󰫢 md-animation (Animations) · 󰌑 md-keyboard-settings (Bindings) · 󰖲 md-window-maximize (Window Rules) · 󰐊 md-application-cog (Autostart)

### Learn Menu (menu-learn)

| Entry | Icon | Glyph Name |
|-------|------|------------|
| Keybindings | 󰌌 | md-keyboard |
| Hyprland Wiki | 󰗚 | md-book-open |
| Arch Wiki | 󰣇 | md-arch |
| Chezmoi Docs | 󰈙 | md-file-document |
| GitHub (Dotfiles) | 󰊤 | md-github |

### Setup Menu (menu-setup)

| Entry | Icon | Glyph Name |
|-------|------|------------|
| Audio (PulseAudio) | 󰕾 | md-volume-high |
| Audio Output Switch | 󰓃 | md-swap-horizontal |
| Network (WiFi) | 󰖩 | md-wifi |
| Bluetooth | 󰂯 | md-bluetooth |
| Power Profile | 󰁹 | md-battery-charging |
| Displays | 󰍹 | md-monitor |
| Edit Keybindings | 󰌑 | md-keyboard-settings |
| Input Devices | 󰖳 | md-mouse |

**Power Profile submenu**: 󰓅 md-speedometer (Performance) · 󰗑 md-scale-balance (Balanced) · 󰁼 md-battery-plus (Power Saver)

### Install Menu (menu-install)

| Entry | Icon | Glyph Name |
|-------|------|------------|
| Install Package | 󰏗 | md-package-variant-closed |
| AI Models (Ollama) | 󰚩 | md-robot |
| Development Tools | 󰙵 | md-code-braces |
| Code Editors | 󰘐 | md-application-edit |

**Ollama submenu**: 󰇚 md-download (Pull) · 󰉖 md-format-list-bulleted (List) · 󰆴 md-delete (Remove)
**Dev Tools submenu**: 󰡨 md-docker · 󱘗 md-language-rust · 󰌠 md-language-python (mise) · 󰎙 md-nodejs (mise) · 󰟓 md-language-go (mise)
**Code Editors submenu**: 󰨞 md-microsoft-visual-studio-code (VSCode/VSCodium) · 󰕷 md-vim (Neovim Config) · 󱓥 md-dna (Helix)

### Remove Menu (menu-remove)

| Entry | Icon | Glyph Name |
|-------|------|------------|
| Remove Package | 󰏖 | md-package-down |
| Clean Package Cache | 󰃬 | md-broom |
| Remove Orphans | 󰩺 | md-trash-can |
| Clean Home Cache | 󰃨 | md-folder-remove |

### Update Menu (menu-update)

| Entry | Icon | Glyph Name |
|-------|------|------------|
| System Update (topgrade) | 󰚰 | md-update |
| Config Refresh (chezmoi) | 󰑓 | md-refresh |
| Firmware Update | 󰣐 | md-chip |
| Sync Time | 󰅐 | md-clock-outline |
| Update Mirrorlist | 󰒋 | md-mirror |

**Firmware submenu**: 󰋗 md-help-circle (Check) · 󰇚 md-download (Download) · 󰁯 md-arrow-up-bold-circle (Install) · 󰾰 md-devices (Show Devices)

### System Menu (menu-system)

| Entry | Icon | Glyph Name |
|-------|------|------------|
| Lock | 󰌾 | md-lock |
| Suspend | 󰤄 | md-power-sleep |
| Restart | 󰜉 | md-restart |
| Shutdown | 󰐥 | md-power-off |

### Universal

| Entry | Icon | Glyph Name |
|-------|------|------------|
| ← Back | 󰁍 | md-arrow-left |

**Test icon rendering**: `echo "󰀻 Apps|󰗚 Learn|󰈿 Trigger" | tr '|' '\n' | wofi --dmenu`

## menu-helpers.sh Library

All menu-\* scripts source this library. Three functions:

```bash
show_menu "Prompt" "option1|option2|option3"  # → Wofi dmenu, returns selection
confirm "Question?"                             # → Yes/No wofi, returns 0 if Yes
notify "Title" "Message" [timeout_ms]          # → notify-send wrapper (default 3000ms)
```

**Why not gum-ui**: Menu scripts are keypress-triggered background processes; wofi + notify-send is the correct pattern.

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

**Keybinding**: `Super+Ctrl+Shift+B` (or via menu-setup)
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

**Usage**: `theme-menu [--print-items]` or via Style menu. `--print-items` writes the item JSON
and exits, which is how the grouping, ordering and badge are checked without a display.

## Non-Obvious Patterns

**menu-helpers.sh keeps .sh extension**: It's a sourced library, not an executed script. Don't rename it.

**Template scripts** (`.tmpl` suffix): menu-about.tmpl, menu-ai.tmpl, menu-install.tmpl, menu-setup.tmpl, menu-style.tmpl, menu-update.tmpl, theme-menu.tmpl — chezmoi processes these at `chezmoi apply` time, not at runtime. Template vars are build-time substitutions.

**hook-create/edit/list/test use gum-ui**: Unlike menu scripts (wofi), hook tools are interactive terminal utilities — use gum for rich UI.

## Integration Points

- **Hyprland**: `~/.config/hypr/conf/bindings/system-control.conf` (`Super+Space` → `system-menu`)
- **Wofi**: menu scripts use wofi dmenu mode (not drun)
- **Hook system**: See `dotfiles/CLAUDE.md` for hook architecture
- **Extra bindings**: See `dotfiles/CLAUDE.md` for extra-bindings.conf
