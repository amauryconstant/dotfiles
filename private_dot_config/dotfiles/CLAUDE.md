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
- **Hook Points**: 7 total (theme-change, package-sync, wallpaper-change, dark-mode-change, pre/post-maintenance, menu-extend)
- **Discovery**: `dotfiles-hook-list` CLI
- **Creation**: `dotfiles-hook-create` CLI

---

## Hook System Architecture

### Hook Runner

**File**: `~/.local/lib/scripts/core/hook-runner.sh`

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

### Integration Pattern

**In core scripts**:

```bash
# Call hook after operation completes
if [ -f "$HOME/.local/lib/scripts/core/hook-runner.sh" ]; then
    "$HOME/.local/lib/scripts/core/hook-runner.sh" theme-change "$theme_name" 2>/dev/null || true
fi
```

**Why silent**:
- Core scripts don't depend on hooks
- User errors don't break core functionality
- Hooks are opt-in customization

---

## Available Hook Points (6)

| Hook | Trigger Script | Arguments | Use Case |
|------|----------------|-----------|----------|
| `theme-change` | `theme-switcher.sh` | `$theme_name` | Custom app theming (Obsidian, web apps) |
| `package-sync` | `package-manager.sh sync` | `sync` | Post-install validation, custom setup |
| `wallpaper-change` | `set-wallpaper.sh` | `$wallpaper_path` | External sync (lockscreen, conky) |
| `dark-mode-change` | `darkman` scripts | `dark/light` | Web browser themes, external apps |
| `pre-maintenance` | `system-maintenance.sh` | none | Backup preparation, service stops |
| `post-maintenance` | `system-maintenance.sh` | `success/failure` | Validation, cleanup, notifications |
| `menu-extend` | `system-menu` | `options` / `handle <choice>` | Custom entries in Super+Space menu |

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

## User Workflow

### 1. Discovery

```bash
dotfiles-hook-list
```

**Output**:
- Available hook points (6 total)
- Installed hooks (with ✓)
- Descriptions and arguments

### 2. Creation

```bash
dotfiles-hook-create
```

**Interactive prompts**:
1. Select hook point
2. Enter description
3. Choose template (basic, conditional, api-call)
4. Generates executable hook in `~/.config/dotfiles/hooks/`

### 3. Testing

**Trigger events**:
```bash
theme switch catppuccin-latte     # Triggers theme-change hook
package-manager sync              # Triggers package-sync hook
set-wallpaper path/to/image.jpg   # Triggers wallpaper-change hook
```

### 4. Version Control

**Location**: `~/.config/dotfiles/hooks/` tracked by chezmoi
- Hooks are part of dotfiles
- Synced across machines
- Version controlled

---

## Example Hook

**File**: `~/.config/dotfiles/hooks/theme-change`

```bash
#!/usr/bin/env sh
# Custom theme integration for Obsidian

THEME_NAME="$1"

# Map dotfiles theme to Obsidian theme
case "$THEME_NAME" in
    catppuccin-latte)
        OBSIDIAN_THEME="Catppuccin Latte"
        ;;
    catppuccin-mocha)
        OBSIDIAN_THEME="Catppuccin Mocha"
        ;;
    rose-pine-dawn)
        OBSIDIAN_THEME="Rosé Pine Dawn"
        ;;
    rose-pine-moon)
        OBSIDIAN_THEME="Rosé Pine Moon"
        ;;
    *)
        # Unknown theme, skip
        exit 0
        ;;
esac

# Update Obsidian config (if installed)
OBSIDIAN_CONFIG="$HOME/.config/obsidian/config.json"
if [ -f "$OBSIDIAN_CONFIG" ]; then
    jaq --arg theme "$OBSIDIAN_THEME" \
        '.cssTheme = $theme' \
        "$OBSIDIAN_CONFIG" > "$OBSIDIAN_CONFIG.tmp"
    mv "$OBSIDIAN_CONFIG.tmp" "$OBSIDIAN_CONFIG"
fi
```

**Features**:
- Theme mapping (dotfiles → Obsidian)
- Safe operation (checks if app installed)
- Exit 0 for unknown themes (silent)
- Uses jaq for JSON manipulation

---

## Hook Development Guidelines

### DO

- ✅ Check if target app installed before running
- ✅ Exit 0 for graceful degradation
- ✅ Use conditional logic for multiple cases
- ✅ Make hooks idempotent (safe to re-run)
- ✅ Test hooks independently

### DON'T

- ❌ Assume apps are installed
- ❌ Exit with error codes (breaks core scripts)
- ❌ Perform destructive operations without checks
- ❌ Depend on specific argument formats (they may change)
- ❌ Use interactive prompts (hooks run silently)

---

## Hook Templates

### Basic Template

```bash
#!/usr/bin/env sh
# Hook: [name]
# Purpose: [description]

ARG1="$1"

# Your implementation here
```

### Conditional Template

```bash
#!/usr/bin/env sh
# Hook: theme-change
# Purpose: Custom theme integration

THEME_NAME="$1"

case "$THEME_NAME" in
    theme1)
        # Action for theme1
        ;;
    theme2)
        # Action for theme2
        ;;
    *)
        # Unknown, skip
        exit 0
        ;;
esac
```

### API Call Template

```bash
#!/usr/bin/env sh
# Hook: package-sync
# Purpose: Notify external service

# Check network connectivity
if ! ping -c 1 -W 1 api.example.com > /dev/null 2>&1; then
    exit 0
fi

# Make API call (silent failure)
curl -X POST https://api.example.com/webhook \
    -H "Content-Type: application/json" \
    -d '{"event": "package-sync"}' \
    > /dev/null 2>&1 || true
```

---

## Debugging Hooks

### Test Hook Execution

```bash
# Run hook manually
~/.config/dotfiles/hooks/theme-change catppuccin-latte

# Check exit code
echo $?  # Should be 0
```

### Common Issues

**Hook not executing**:
- Check executable permission: `chmod +x ~/.config/dotfiles/hooks/hook-name`
- Verify hook name matches (case-sensitive)

**Hook causing errors**:
- Check shebang: `#!/usr/bin/env sh`
- Test script independently
- Ensure exits with 0 (never error codes)

**Hook not seeing changes**:
- Hooks run synchronously (after operation completes)
- Check argument passing
- Verify timing (some hooks run before, some after)

---

## Integration Points

**Hook runner**: `~/.local/lib/scripts/core/hook-runner.sh`
**CLI tools**: `dotfiles-hook-list`, `dotfiles-hook-create`
**Core scripts**: See `private_dot_local/lib/scripts/CLAUDE.md`
**Theme system**: See `themes/CLAUDE.md`
**Package manager**: See `private_dot_local/lib/scripts/system/CLAUDE.md`
