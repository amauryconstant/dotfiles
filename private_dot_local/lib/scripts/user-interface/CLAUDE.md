# User Interface Scripts - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/user-interface/`
**Parent**: See `../CLAUDE.md` for script library overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Entry point**: `system-menu` (keybinding: `Super+Space`)
- **Library**: `menu-helpers.sh` (sourced by all menu scripts)
- **Hook tools**: `dotfiles-hook-create`, `dotfiles-hook-edit`, `dotfiles-hook-list`, `dotfiles-hook-test`
- **Extra bindings**: `dotfiles-bindings-edit`
- **UI pattern**: `menu-helpers.sh` (show_menu + notify) — NOT gum-ui

## Main Menu (system-menu)

Routes `Super+Space` → Wofi dmenu → category script.

| Icon | Category | Script | Purpose |
|------|----------|--------|---------|
| 󰀻 | Apps | wofi --show drun | Application launcher |
| 󰗚 | Learn | menu-learn | Help/documentation |
| 󰈿 | Trigger | menu-trigger | Quick actions (capture, share, toggle) |
| 󰏘 | Style | menu-style | Theme switching, appearance |
| 󰒓 | Setup | menu-setup | System configuration |
| 󰏓 | Install | menu-install | Package installation |
| 󰚰 | Update | menu-update | System updates |
| 󱚣 | AI | menu-ai | AI integration |
| 󰋼 | About | menu-about | System information |
| 󰐥 | System | menu-system | Power management |

**Note**: Remove category (`menu-remove`) is commented out in system-menu.

**menu-extend hook**: Unknown choices from system-menu are delegated to `~/.config/dotfiles/hooks/menu-extend` (see `dotfiles/CLAUDE.md`).

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
| `dotfiles-hook-create` | Interactive generator → creates executable hook file | `~/.config/dotfiles/hooks/{name}` |
| `dotfiles-hook-list` | Show all hook points + installed hooks | Terminal (gum table) |
| `dotfiles-hook-edit` | Open installed hook in `$EDITOR` | Editor launch |
| `dotfiles-hook-test` | Run hook with default test args | Shows output + exit code |

**Hook locations**: `~/.config/dotfiles/hooks/` (chezmoi-managed, always present)

## dotfiles-bindings-edit

Opens `~/.config/dotfiles/extra-bindings.conf` in `$EDITOR` and calls `hyprctl reload` on exit.

**Keybinding**: `Super+Ctrl+Shift+B` (or via menu-setup)
**File managed by**: chezmoi (always present, prevents Hyprland parse error on missing source)

## theme-menu

Interactive Wofi-based theme selector. Template script (`.tmpl`) — uses chezmoi template var for current theme indicator.

**Usage**: `theme-menu` or via Style menu

## Non-Obvious Patterns

**menu-helpers.sh keeps .sh extension**: It's a sourced library, not an executed script. Don't rename it.

**Template scripts** (`.tmpl` suffix): menu-about.tmpl, menu-ai.tmpl, menu-install.tmpl, menu-setup.tmpl, menu-style.tmpl, menu-update.tmpl, theme-menu.tmpl — chezmoi processes these at `chezmoi apply` time, not at runtime. Template vars are build-time substitutions.

**hook-create/edit/list/test use gum-ui**: Unlike menu scripts (wofi), hook tools are interactive terminal utilities — use gum for rich UI.

## Integration Points

- **Hyprland**: `~/.config/hypr/conf/bindings/system-control.conf` (`Super+Space` → `system-menu`)
- **Wofi**: menu scripts use wofi dmenu mode (not drun)
- **Hook system**: See `dotfiles/CLAUDE.md` for hook architecture
- **Extra bindings**: See `dotfiles/CLAUDE.md` for extra-bindings.conf
