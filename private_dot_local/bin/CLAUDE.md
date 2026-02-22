# CLI Wrappers - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/bin/`
**Parent**: See `../CLAUDE.md` for CLI architecture overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## ⚠️ DEPRECATION NOTICE

**Most wrappers removed** — new architecture: scripts directly in PATH (no wrappers needed)
- Scripts named without .sh extension
- All script directories added to PATH
- Direct execution: `prune-branch`, `screenshot`, `system-health`, `hypr-session`

**Remaining wrappers** (3 total):
- `executable_package-manager` - Complex setup wrapper (module sourcing, state initialization)
- `executable_ts` - Tailscale helper with subcommand routing
- `executable_unzip` - Compatibility wrapper (unzip → unar)

**For new scripts**: Don't create wrappers — add directly to `lib/scripts/` without .sh extension

## Quick Reference

- **Purpose**: Special-case executable wrappers (3 files)
- **Pattern**: Complex setup, subcommand routing, or compatibility needs only
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

## Available Wrappers (3 total)

| Executable | Purpose | Reason for wrapper |
|------------|---------|-------------------|
| `executable_package-manager` | Package management CLI | Complex module sourcing + state initialization |
| `executable_ts` | Tailscale helper (`ts up`, `ts down`, `ts status`) | Subcommand routing to `network/tailscale` |
| `executable_unzip` | `unzip` → `unar` compatibility shim | Some tools expect `unzip`; maps args to `unar` equivalents |

**unzip mapping**: `-q` → `-q`, `-d DIR` → `-o DIR`, `-o` → `-f`

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

## When to Add a Wrapper

Only add to bin/ if the script needs **complex initialization before executing** (like `package-manager`) or must **override a system command** (like `unzip`). For everything else, add directly to `lib/scripts/{category}/` without .sh extension.

## Integration Points

- **lib/scripts/**: Implementation scripts (50+ files, directly in PATH)
- **Zephyr**: Environment variables (SCRIPTS_DIR, UI_LIB)
- **PATH**: `~/.local/bin` in PATH via Zephyr
