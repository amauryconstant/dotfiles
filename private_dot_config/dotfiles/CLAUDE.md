# Dotfiles Hook System - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/dotfiles/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

---

## Quick Reference

- **Purpose**: User-extensible event-driven architecture for custom integrations
- **Location**: `~/.config/dotfiles/hooks/`
- **Pattern**: Silent hook execution without modifying core scripts
- **Hook Points**: theme-change, package-sync, wallpaper-change, dark-mode-change, pre/post-maintenance, menu-extend, idle-change, session-start
- **Discovery**: `dotfiles-hook-list` CLI
- **Creation**: `dotfiles-hook-create` CLI
- **Debug**: `HOOK_DEBUG=1 hook-runner <name> [args]` → logs to `~/.local/state/dotfiles/hook.log`

---

## Hook System Architecture

### Hook Runner

**File**: `~/.local/lib/scripts/core/hook-runner`

```bash
#!/usr/bin/env sh
HOOK_NAME="$1"
shift
HOOKS_DIR="$HOME/.config/dotfiles/hooks"
HOOK_PATH="$HOOKS_DIR/$HOOK_NAME"

# Silent execution - hooks are optional
if [ -x "$HOOK_PATH" ]; then
    "$HOOK_PATH" "$@" 2>/dev/null || true
fi
```

**Key features**:
- Silent execution (no errors if hook missing)
- Optional hooks (graceful degradation)
- Simple API (hook name + arguments)
- `HOOK_DEBUG=1` → logs timestamp, output, exit code to `~/.local/state/dotfiles/hook.log`

### Integration Pattern

**In core scripts**:

```bash
# Call hook after operation completes
if [ -f "$HOME/.local/lib/scripts/core/hook-runner" ]; then
    "$HOME/.local/lib/scripts/core/hook-runner" theme-change "$theme_name" 2>/dev/null || true
fi
```

**Why silent**:
- Core scripts don't depend on hooks
- User errors don't break core functionality
- Hooks are opt-in customization

---

## Available Hook Points

| Hook | Trigger Script | Arguments | Use Case |
|------|----------------|-----------|----------|
| `theme-change` | `theme-switcher.sh` | `$theme_name` | Custom app theming (Obsidian, web apps) |
| `package-sync` | `package-manager.sh sync` | `sync` | Post-install validation, custom setup |
| `wallpaper-change` | `set-wallpaper.sh` | `$wallpaper_path` | External sync (lockscreen, conky) |
| `dark-mode-change` | `darkman` scripts | `dark/light` | Web browser themes, external apps |
| `pre-maintenance` | `system-maintenance.sh` | none | Backup preparation, service stops |
| `post-maintenance` | `system-maintenance.sh` | `success/failure` | Validation, cleanup, notifications |
| `menu-extend` | `system-menu` | `options` / `handle <choice>` | Custom entries in Super+Space menu |
| `idle-change` | `hypridle` listener 1 | `timeout` / `resume` | Pause apps on lock, resume on unlock |
| `session-start` | `autostart.conf` (5s delay) | none | Launch personal services, restore state |

**`menu-extend` two-phase protocol** (differs from other hooks):
- Called with `options` → print pipe-separated entries to stdout
- Called with `handle <choice>` → route and execute the chosen entry

```sh
#!/usr/bin/env sh
# Hook: menu-extend
case "$1" in
    options)
        echo "󰀻 My Project"   # single entry, or "A|B|C" for multiple
        ;;
    handle)
        case "$2" in
            "󰀻 My Project") ghostty -e zsh -c "cd ~/Projects/my-project && exec zsh" ;;
        esac
        ;;
esac
```

---

## Authoring hooks

- Discover/scaffold with `dotfiles-hook-list` / `dotfiles-hook-create`; hooks land in `~/.config/dotfiles/hooks/<hook-name>` (chezmoi-tracked, synced across machines).
- A hook is an executable matching the hook name. Must `exit 0` even when skipping (a non-zero exit is swallowed by hook-runner but the convention keeps intent clear), guard on the target app being installed, and stay non-interactive (runs silently). Hooks run **synchronously** after the triggering operation.
- Example shape — a `theme-change` hook maps `$1` (theme name) to an app's theme and patches its config if that app is installed (`case "$1" in catppuccin-mocha) … esac`).

---

## Extra Bindings Extension Point

**File**: `~/.config/dotfiles/extra-bindings.conf`
**Chezmoi source**: `private_dot_config/dotfiles/extra-bindings.conf`

User-defined Hyprland keybindings sourced from `hyprland.conf` at the end of the config. Chezmoi-managed so the file always exists, preventing Hyprland parse errors on a missing `source` target.

**CLI**: `dotfiles-bindings-edit` — opens the file in `$EDITOR` and calls `hyprctl reload` on exit.

**Syntax**:
```conf
bindd = SUPER SHIFT, F1, My description, exec, my-script
```

**Key facts**:
- No chezmoi prefix (not `modify_`, not `private_`) — plain file, user-editable
- Lives in `~/.config/dotfiles/` alongside hooks
- Sourced last in `hyprland.conf` (overrides can follow core bindings)
- Auto-reloaded via `dotfiles-bindings-edit` or `Super+Shift+R`

---

## Integration Points

**Hook runner**: `~/.local/lib/scripts/core/hook-runner`
**CLI tools**: `dotfiles-hook-list`, `dotfiles-hook-create`, `dotfiles-bindings-edit`
**Core scripts**: See `private_dot_local/lib/scripts/CLAUDE.md`
**Theme system**: See `themes/CLAUDE.md`
**Package manager**: See `private_dot_local/lib/scripts/system/CLAUDE.md`
