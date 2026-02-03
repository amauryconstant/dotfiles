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

**Design**: Scripts directly in PATH (no wrappers needed)

**Solution**: All script directories added to PATH → scripts callable without .sh extension

**Standards**: See root `CLAUDE.md` for:
- Error handling strategy (`set -euo pipefail` vs manual)
- UI library sourcing pattern (system scripts only)
- Shebang selection (bash vs sh guidelines)

### Directory Structure

```
~/.local/
├── bin/                    # 2 special wrappers (in PATH)
│   ├── executable_package-manager    # Complex setup wrapper
│   └── executable_unzip              # Compatibility wrapper (unzip → unar)
└── lib/scripts/            # 46+ scripts directly in PATH (10 categories)
    ├── core/               # Foundation libraries (gum-ui.sh, menu-helpers.sh)
    ├── desktop/            # Hyprland utilities (no .sh extension)
    ├── media/              # Wallpaper, screenshots (no .sh extension)
    ├── system/             # Maintenance, health, SSH (no .sh extension)
    ├── terminal/           # Terminal utilities (no .sh extension)
    ├── user-interface/     # Menu system, hooks (no .sh extension)
    ├── utils/              # Utilities (no .sh extension)
    └── [3 more categories]
```

## Direct Execution Architecture

**All script directories in PATH** (configured in `.zstyles`):
- `~/.local/bin` (special wrappers)
- `~/.local/lib/scripts/core` (libraries + utilities)
- `~/.local/lib/scripts/desktop` (desktop utilities)
- `~/.local/lib/scripts/git` (git utilities)
- `~/.local/lib/scripts/media` (media utilities)
- `~/.local/lib/scripts/network` (network utilities)
- `~/.local/lib/scripts/system` (system utilities)
- `~/.local/lib/scripts/system/package-manager` (package-manager executable)
- `~/.local/lib/scripts/terminal` (terminal utilities)
- `~/.local/lib/scripts/user-interface` (menu scripts)
- `~/.local/lib/scripts/utils` (utility scripts)

**Scripts named without .sh extension**:
- Call directly: `prune-branch`, `screenshot`, `system-health`
- No wrappers needed (scripts directly executable)
- Can be templates (`.tmpl` suffix for rendered scripts)

**Exceptions** (keep .sh extension):
- `gum-ui.sh` - UI library (sourced, not executed)
- `menu-helpers.sh` - Menu library (sourced, not executed)
- `state-manager.sh` - State library (sourced, not executed)

### Benefits

- **Fast shell startup**: No library sourcing at login
- **No wrapper maintenance**: Scripts directly callable
- **Clean naming**: No .sh extension (e.g., `prune-branch` not `prune-branch.sh`)
- **Category organization**: Scripts in logical subdirectories
- **Easy discovery**: All scripts in PATH directories

## Script Execution Pattern

**Scripts source UI library at top** (self-sufficient):
```bash
#!/usr/bin/env bash

# Source UI library (supports direct execution)
if [ -n "$UI_LIB" ] && [ -f "$UI_LIB" ]; then
    . "$UI_LIB"
elif [ -f "$HOME/.local/lib/scripts/core/gum-ui.sh" ]; then
    . "$HOME/.local/lib/scripts/core/gum-ui.sh"
else
    echo "Error: UI library not found" >&2
    exit 1
fi

# Script implementation
ui_title "System Health"
ui_info "Checking system status..."
```

**On invocation**:
1. User runs command (e.g., `system-health`)
2. Script sources UI library (lazy-loaded on demand)
3. Script executes with UI functions available
4. No wrapper overhead

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
- Scripts for UI library location
- Scripts for SCRIPTS_DIR references

## Special Wrappers (2 total)

**Kept for specific reasons**:

| Command | Wrapper | Reason |
|---------|---------|--------|
| `package-manager` | `bin/executable_package-manager` | Complex setup (module sourcing, state initialization) |
| `unzip` | `bin/executable_unzip` | Compatibility wrapper (unzip → unar) |

**All other commands**: Call scripts directly (no wrappers needed)

## Common Commands

**Directly callable** (via PATH):

| Command | Script Location | Purpose |
|---------|-----------------|---------|
| `system-health` | `system/system-health` | Health monitoring |
| `system-maintenance` | `system/system-maintenance` | System maintenance |
| `system-troubleshoot` | `system/troubleshoot` | Diagnostic tool |
| `dotfiles-debug` | `utils/dotfiles-debug` | System debug report |
| `dotfiles-hook-create` | `user-interface/hook-create` | Create hook template |
| `dotfiles-hook-list` | `user-interface/hook-list` | List hooks |
| `regen-zsh-plugins` | `terminal/regen-zsh-plugins` | Zsh plugin bundle |
| `regen-ssh-key` | `system/regenerate-ssh-key` | SSH key regeneration |
| `screenshot` | `media/screenshot` | Screenshot with Satty |
| `random-wallpaper` | `media/random-wallpaper` | Random wallpaper |
| `set-wallpaper` | `media/set-wallpaper` | Set specific wallpaper |
| `launch-or-focus` | `desktop/launch-or-focus` | Single-instance apps |
| `hypr-session` | `desktop/hypr-session` | Hyprland session management |
| `prune-branch` | `git/prune-branch` | Branch cleanup |
| `ts` | `network/tailscale` | Tailscale helper |

## Subdirectories with CLAUDE.md

**Detailed documentation**:
1. `lib/scripts/` - Script library overview, **UI pattern standards by category**
2. `lib/scripts/core/` - Gum UI library (system scripts only)
3. `lib/scripts/system/` - System tools (UI library adopters)
4. `bin/` - CLI wrapper patterns

**Key insight**: UI library primarily used by system CLI tools, not desktop utilities

**See individual CLAUDE.md files for detailed references**

## Integration Points

- **Zephyr**: `~/.config/zsh/dot_zstyles` (environment vars)
- **Hyprland**: `~/.config/hypr/conf/bindings.conf.tmpl` (keybindings)
- **Menu system**: `lib/scripts/user-interface/` (calls other scripts)
- **PATH**: `~/.local/bin` in PATH via Zephyr
