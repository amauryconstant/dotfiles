# Local Executables and Libraries - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/`
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: User-level executables and libraries
- **Structure**: `bin/` (CLI wrappers) + `lib/scripts/` (implementations)
- **Pattern**: Lazy-loading architecture
- **Target**: `~/.local/` (XDG-compliant)

## CLI Architecture

**Problem**: Heavy script libraries at shell startup slow terminal launch

**Solution**: Lightweight executables in `bin/` lazy-load scripts from `lib/scripts/` on demand

### Directory Structure

```
~/.local/
├── bin/                    # 11 CLI wrappers (in PATH)
│   └── executable_*        # Lightweight shims
└── lib/scripts/            # 45 implementation scripts
    ├── core/               # Foundation libraries
    ├── desktop/            # Hyprland utilities
    ├── media/              # Wallpaper, screenshots
    ├── system/             # Maintenance, health, SSH
    ├── user-interface/     # Menu system
    └── [7 more categories]
```

## bin/ vs lib/ Separation

**bin/** - CLI wrappers:
- Lightweight executable shims
- No templates (static bash)
- In PATH (`~/.local/bin`)
- Fast invocation (no processing)

**lib/scripts/** - Implementations:
- Full script logic
- Can be templates (`.sh.tmpl`)
- Sourced on demand
- Category organization

### Benefits

- **Fast shell startup**: No library sourcing at login
- **Reduced memory**: Scripts loaded only when needed
- **Clean CLI**: Commands in PATH without long paths
- **Template safety**: Only lib/ templates (bin/ static)
- **Easy discovery**: `commands` function lists all

## Lazy-Loading Concept

**Wrapper pattern** (`bin/executable_*`):
```bash
#!/usr/bin/env bash
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
    echo "Error: Script not found" >&2
    exit 1
fi
```

**On invocation**:
1. User runs command (e.g., `system-health`)
2. Wrapper sources UI library (gum-ui.sh)
3. Wrapper executes implementation script
4. Script runs with full context

**Why not source at startup**:
- Shell startup: ~50ms faster
- Memory: ~5MB saved per shell
- Only load what's needed

## Environment Variables

**Set in** `.zstyles` (Zephyr plugin):
```zsh
zstyle ':zephyr:plugin:environment' 'SCRIPTS_DIR' "$HOME/.local/lib/scripts"
zstyle ':zephyr:plugin:environment' 'UI_LIB' "$HOME/.local/lib/scripts/core/gum-ui.sh"
```

**Used by**:
- All CLI wrappers in `bin/`
- Implementation scripts in `lib/scripts/`

## Available CLI Wrappers

| Command | Script | Purpose |
|---------|--------|---------|
| `package-manager` | `system/package-manager.sh` | Strategy-based pkg install |
| `system-health` | `system/system-health.sh` | Health monitoring |
| `system-maintenance` | `system/system-maintenance.sh` | System maintenance |
| `system-troubleshoot` | `system/troubleshoot.sh` | Diagnostic tool |
| `regen-ssh-key` | `system/regenerate-ssh-key.sh` | SSH key regeneration |
| `screenshot` | `media/screenshot.sh` | Screenshot with Satty |
| `random-wallpaper` | `media/random-wallpaper.sh` | Random wallpaper |
| `set-wallpaper` | `media/set-wallpaper.sh` | Set specific wallpaper |
| `launch-or-focus` | `desktop/launch-or-focus.sh` | Single-instance apps |
| `git-prune-branch` | `git/prune-branch.sh` | Branch cleanup |
| `ts` | `network/tailscale.sh` | Tailscale helper |

## Subdirectories with CLAUDE.md

**Detailed documentation**:
1. `lib/scripts/` - Script library overview
2. `lib/scripts/core/` - Gum UI library
3. `lib/scripts/desktop/` - Desktop utilities
4. `lib/scripts/system/` - System tools
5. `lib/scripts/user-interface/` - Menu system
6. `bin/` - CLI wrapper patterns

**See individual CLAUDE.md files for detailed references**

## Integration Points

- **Zephyr**: `~/.config/zsh/dot_zstyles` (environment vars)
- **Hyprland**: `~/.config/hypr/conf/bindings.conf.tmpl` (keybindings)
- **Menu system**: `lib/scripts/user-interface/` (calls other scripts)
- **PATH**: `~/.local/bin` in PATH via Zephyr
