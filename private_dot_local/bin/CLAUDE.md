# CLI Wrappers - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/bin/`
**Parent**: See `../CLAUDE.md` for CLI architecture overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Lightweight executable wrappers (10 files)
- **Pattern**: Lazy-load scripts from `lib/scripts/`
- **Naming**: `executable_*` (chezmoi convention)
- **Templates**: NO templates in bin/ (static only)

## Lazy-Loading Pattern

**Standard wrapper structure**:
```bash
#!/usr/bin/env bash

# Description: [purpose]
# Target: ~/.local/bin/[name]

SCRIPT_PATH="$SCRIPTS_DIR/category/script.sh"

# Source UI library on demand
if [ -f "$UI_LIB" ]; then
    . "$UI_LIB"
else
    echo "Error: UI library not found at $UI_LIB" >&2
    exit 1
fi

# Execute actual script
if [ -f "$SCRIPT_PATH" ]; then
    "$SCRIPT_PATH" "$@"
else
    echo "Error: Script not found at $SCRIPT_PATH" >&2
    exit 1
fi
```

## Why No Templates

**Chezmoi naming**:
- `executable_*` → Becomes executable (chmod +x)
- `*.tmpl` → Template processed

**Problem**: `executable_name.tmpl`
- Would be processed as template
- Adds overhead to CLI invocation
- Defeats lazy-loading purpose

**Solution**: Static wrappers in bin/, templates in lib/

**Benefits**:
- Fast invocation (no template processing)
- Simple wrapper code
- All complexity in lib/ (where templates allowed)

## Available Wrappers

**Script Wrappers** (12 CLI commands):

| Executable | Script | Category |
|------------|--------|----------|
| `executable_package-manager` | `system/package-manager.sh` | System |
| `executable_system-health` | `system/system-health.sh` | System |
| `executable_system-maintenance` | `system/system-maintenance.sh` | System |
| `executable_system-troubleshoot` | `system/troubleshoot.sh` | System |
| `executable_screenshot` | `media/screenshot.sh` | Media |
| `executable_random-wallpaper` | `media/random-wallpaper.sh` | Media |
| `executable_set-wallpaper` | `media/set-wallpaper.sh` | Media |
| `executable_launch-or-focus` | `desktop/launch-or-focus.sh` | Desktop |
| `executable_git-prune-branch` | `git/prune-branch.sh` | Git |
| `executable_ts` | `network/tailscale.sh` | Network |

**Compatibility Wrappers** (1 command):

| Executable | Purpose | Wraps |
|------------|---------|-------|
| `executable_unzip` | unzip → unar compatibility wrapper | `unarchiver` (unar) |

**Why unzip wrapper**:
- System uses `unar` from `unarchiver` package (universal archive extractor)
- Some scripts expect `unzip` command (e.g., spicetify marketplace installer)
- Wrapper translates `unzip` arguments to `unar` equivalents
- Mapping: `-q` → `-q`, `-d DIR` → `-o DIR`, `-o` → `-f`

**User invokes**: `system-health` (not `executable_system-health`)

**Chezmoi applies**: `~/.local/bin/system-health` (executable, no prefix)

## Environment Variables

**Required** (set in `.zstyles`):
- `SCRIPTS_DIR` - Path to `~/.local/lib/scripts/`
- `UI_LIB` - Path to `~/.local/lib/scripts/core/gum-ui.sh`

**Why required**:
- Wrappers depend on these paths
- Zephyr sets them at shell startup
- Available to all processes

## Error Handling

**Wrapper validates**:
1. UI library exists (`$UI_LIB`)
2. Implementation script exists (`$SCRIPT_PATH`)

**Failure modes**:
- Missing UI library → Error message + exit 1
- Missing script → Error message + exit 1
- Script execution error → Propagates exit code

## Adding New Wrapper

**Process**:
1. Create implementation in `lib/scripts/{category}/script.sh`
2. Create wrapper in `bin/executable_{name}`
3. Set `SCRIPT_PATH` variable
4. Copy standard wrapper pattern
5. Test with `chezmoi apply`

**Example** (new command `foo`):
```bash
# File: bin/executable_foo
#!/usr/bin/env bash
SCRIPT_PATH="$SCRIPTS_DIR/category/foo.sh"

# [Standard wrapper code]
```

**Result**: User runs `foo` command

## Integration Points

- **lib/scripts/**: Implementation scripts (44 files)
- **Zephyr**: Environment variables (SCRIPTS_DIR, UI_LIB)
- **PATH**: `~/.local/bin` in PATH via Zephyr
- **Hyprland**: Bindings call wrapper commands
- **Menu system**: Menus call wrapper commands
