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
├── bin/                    # overrides + CLI shims only (in PATH)
│   ├── executable_mmdc               # Mermaid CLI shim (mmdc flags → mmdr)
│   ├── executable_firefox            # NVIDIA egl-wayland2 workaround (shadows /usr/bin/firefox)
│   ├── symlink_firefox-esr           # → firefox (load-bearing: dispatches on $0)
│   └── symlink_ts                    # → ../lib/scripts/network/tailscale.sh
└── lib/scripts/            # scripts directly in PATH, by category
    ├── core/               # gum-ui.sh, hook-runner, state-manager.sh
    ├── ai/                 # llama-models
    ├── desktop/            # Hyprland utilities, theme-apply-*
    ├── media/              # screenshot, wallpaper, clipboard-store
    ├── network/            # tailscale, vpn-toggle, wifi-switch
    ├── system/             # maintenance, health, backup, rotate-age-key, rotate-ssh-key
    ├── terminal/           # regen-zsh-plugins, terminal-cwd, zellij-sessionizer, ghostty-sessionizer
    ├── user-interface/     # system-menu, menu-*, hook tools
    ├── utils/              # dotfiles-debug, firefox-debug-trace, reorder-json, unzip
    └── git/                # prune-branch
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

**Why not source at startup**: keeps shell init free of library loading — each script pulls `gum-ui.sh` only when run.

## Environment Variables

**Exported in** `private_dot_config/shell/env` (POSIX, so every shell gets them — not zsh-only):
```sh
export SCRIPTS_DIR="$HOME/.local/lib/scripts"
export UI_LIB="$SCRIPTS_DIR/core/gum-ui.sh"
```

PATH order is separate: the `prepath` zstyle in `private_dot_config/zsh/dot_zstyles`.

**Used by**:
- Scripts for UI library location
- Scripts for SCRIPTS_DIR references

## Special Wrappers

**Kept for specific reasons**:

| Command | File | Reason |
|---------|------|--------|
| `firefox` | `bin/executable_firefox` | Overrides `/usr/bin/firefox` — NVIDIA egl-wayland2 workaround |
| `firefox-esr` | `bin/symlink_firefox-esr` | Same wrapper, dispatched via `${0##*/}` |
| `mmdc` | `bin/executable_mmdc` | Mermaid CLI shim (translates `mmdc` flags to `mmdr`) |
| `ts` | `bin/symlink_ts` | Short name for `network/tailscale.sh` — a symlink, not a wrapper |

🚨 **A wrapper that only re-execs a script already in PATH is not a reason.** `ts`, `unzip` and
`package-manager` were such wrappers and were removed 2026-09-14; `unzip` and `package-manager`
now resolve straight to `lib/scripts/utils/` and `lib/scripts/system/package-manager/`. See
`bin/CLAUDE.md`.

**All other commands**: Call scripts directly (no wrappers needed)

## Common Commands

**Directly callable** (via PATH):

| Command | Script Location | Purpose |
|---------|-----------------|---------|
| `system-health` | `system/system-health` | Health monitoring |
| `system-maintenance` | `system/system-maintenance` | System maintenance |
| `troubleshoot` | `system/troubleshoot` | Diagnostic tool |
| `dotfiles-debug` | `utils/dotfiles-debug` | System debug report |
| `hook-create` | `user-interface/hook-create` | Create hook template |
| `hook-list` | `user-interface/hook-list` | List hooks |
| `regen-zsh-plugins` | `terminal/regen-zsh-plugins` | Zsh plugin bundle |
| `rotate-ssh-key` | `system/rotate-ssh-key` | SSH key pair rotation |
| `rotate-age-key` | `system/rotate-age-key` | age master encryption key rotation |
| `screenshot` | `media/screenshot` | Screenshot with Satty |
| `random-wallpaper` | `media/random-wallpaper` | Random wallpaper |
| `set-wallpaper` | `media/set-wallpaper` | Set specific wallpaper |
| `launch-or-focus` | `desktop/launch-or-focus` | Single-instance apps |
| `hypr-session` | `desktop/hypr-session` | Hyprland session management |
| `prune-branch` | `git/prune-branch` | Branch cleanup |
| `ts` | `bin/symlink_ts` → `network/tailscale.sh` | Tailscale helper (short name via symlink) |

## Subdirectories with CLAUDE.md

**Detailed documentation**:
1. `lib/scripts/` - Script library overview, **UI pattern standards by category**
2. `lib/scripts/core/` - Gum UI library (system scripts only)
3. `lib/scripts/system/` - System tools (UI library adopters)
4. `lib/scripts/system/package-manager/` - Package manager module internals
5. `lib/scripts/desktop/` - Hyprland utilities
6. `lib/scripts/user-interface/` - Menu system + hook tools
7. `lib/scripts/media/` - Screenshots, wallpaper
8. `lib/scripts/network/` - Tailscale, VPN, wifi
9. `lib/scripts/ai/` - Local LLM model management
10. `bin/` - CLI wrapper patterns

**No CLAUDE.md** (small, self-evident): `git/`, `terminal/`, `utils/`

**Key insight**: UI library primarily used by system CLI tools, not desktop utilities

**See individual CLAUDE.md files for detailed references**

## Integration Points

- **Zephyr**: `~/.config/zsh/dot_zstyles` (environment vars)
- **Hyprland**: `~/.config/hypr/conf/bindings/*.conf` (keybindings invoke these scripts)
- **Menu system**: `lib/scripts/user-interface/` (calls other scripts)
- **PATH**: `~/.local/bin` in PATH via Zephyr
