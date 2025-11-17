# Script Library - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/`
**Parent**: See `../../CLAUDE.md` for CLI architecture
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Lazy-loaded script implementations for CLI wrappers
- **Target**: `~/.local/lib/scripts/` (44 total scripts)
- **Categories**: 11 logical groupings
- **Integration**: Sourced by `~/.local/bin/executable_*` wrappers
- **Template safety**: Only lib/ scripts can be templates (bin/ static)

## Directory Structure

```
~/.local/lib/scripts/   # 44 total scripts
├── core/               # 2 files - Foundation
│   ├── gum-ui.sh       # 572-line UI library
│   └── colors.sh.tmpl  # Oksolar color definitions
├── desktop/            # 16 files - Hyprland utilities
├── media/              # 3 files - Wallpaper, screenshots
├── system/             # 6 files - Maintenance, health
├── terminal/           # 1 file - CWD preservation
├── network/            # 1 file - Tailscale
├── git/                # 1 file - Branch cleanup
├── user-interface/     # 12 files - Menu system
├── utils/              # 1 file - JSON reorder
└── development/        # [empty - future expansion]
```

## Category Details

### Desktop Utilities (16 scripts)
**Purpose**: Hyprland desktop utilities
**Dependencies**: hyprctl, gum-ui, jaq (JSON)

**Window Management**:
- `launch-or-focus.sh` - Single-instance apps (focus if exists, launch if not)
  - Integration: `Super+E` → dolphin
  - Pattern: `launch-or-focus.sh dolphin` or `launch-or-focus.sh btop "ghostty -e btop"`
  - Algorithm: Query clients → Match class/title → Focus or launch

- `keybindings.sh` - Keybinding reference (`Super+?`)

**Display & Monitors**:
- `monitor-switch.sh` - Switch display configs
- `monitor-*` scripts - Display management utilities

### Media Scripts (3 scripts)
**Purpose**: Media capture and wallpaper management
**Tools**: grim, slurp, satty, swww, wallust
**Integration**: Hyprland bindings, systemd timer

**Scripts**:
- `screenshot.sh` - Smart screenshot with Satty annotation
  - Modes: smart (auto-snap window), region, window, fullscreen
  - Tools: grim (capture), slurp (selection), satty (annotation)
  - Smart mode: Auto-snap to window if <20px selection

- `random-wallpaper.sh` - Random wallpaper from collection
- `set-wallpaper.sh` - Set specific wallpaper + color extraction

### User Interface Menus (12 scripts)
**Purpose**: Omarchy-inspired hierarchical menu system
**Entry point**: `Super+Space` → `system-menu.sh`
**Integration**: Wofi (dmenu mode), gum-ui library
**Icons**: Material Design glyphs

**Main menu categories**:
| Icon | Category | Script | Purpose |
|------|----------|--------|---------|
| 󰀻 | Apps | wofi drun | Application launcher |
| 󰗚 | Learn | `menu-learn.sh` | Help/documentation |
| 󰈿 | Trigger | `menu-trigger.sh` | Quick actions (Capture, Share, Toggle) |
| 󰏘 | Style | `menu-style.sh` | Theme/appearance |
| 󰒓 | Setup | `menu-setup.sh` | System configuration |
| 󰏓 | Install | `menu-install.sh` | Package installation |
| 󰩺 | Remove | `menu-remove.sh` | Package removal |
| 󰚰 | Update | `menu-update.sh` | System updates |
| 󰋼 | About | `menu-about.sh` | System information |
| 󰐥 | System | `menu-system.sh` | Power management |

**Shared utilities**: `menu-helpers.sh` (common functions)

### System Scripts (7 scripts)
**Purpose**: System maintenance, health monitoring, SSH key management
**Tools**: pacman, paru, systemctl, ssh-keygen
**Integration**: CLI wrappers, scheduled tasks

**Scripts**:
- `package-manager.sh` - Module-based package installation (pacman/paru)
- `system-health.sh` - System health monitoring and diagnostics
- `system-maintenance.sh` - Automated maintenance tasks
- `troubleshoot.sh` - System troubleshooting wizard
- `regenerate-ssh-key.sh` - SSH key regeneration + chezmoi reimport
  - Features: ED25519 keys, automatic backup, encryption, chezmoi integration
  - Usage: `regen-ssh-key <keyname>` (e.g., github, gitlab, ovh-server)
  - Backup: Timestamped to `~/.ssh/backup-{YYYY-MM-DD-HHMMSS}/`
  - Encryption: Automatic via `chezmoi add --encrypt`
- Additional system utilities

### Other Categories

| Category | Purpose | Script Count | Key Scripts |
|----------|---------|--------------|-------------|
| `core/` | Foundation libraries | 2 | gum-ui.sh, colors.sh.tmpl |
| `terminal/` | Terminal utilities | 1 | terminal-cwd.sh |
| `network/` | Network tools | 1 | tailscale.sh |
| `git/` | Git utilities | 1 | prune-branch.sh |
| `utils/` | General utilities | 1 | reorder-json.sh |

## Organization Rationale

**XDG compliance**: `~/.local/lib/` follows Linux standards

**Separation**: CLI wrappers (bin/) vs logic (lib/)
- `bin/`: Lightweight executable shims (no templates)
- `lib/`: Full implementation scripts (can be templates)

**Template isolation**: Only lib/ scripts can be templates
- Prevents template processing overhead at CLI invocation
- Keeps bin/ fast and simple

**Category grouping**: Logical functionality clusters

**Shared foundation**: `core/` provides UI and color libraries

## Naming Conventions

**Executables** (in `bin/`):
- Pattern: `executable_*`
- No templates (static bash wrappers)
- Example: `executable_package-manager`

**Implementation** (in `lib/`):
- Pattern: `*.sh` (static) or `*.sh.tmpl` (template)
- Category subdirectories
- Example: `system/package-manager.sh`

**Templates**:
- Only in lib/ subdirectories
- Use Go template syntax
- Example: `core/colors.sh.tmpl`

## Gum UI Library Sourcing

**Standard pattern**:
```bash
# In implementation scripts
. "$UI_LIB"  # or: . ~/.local/lib/scripts/core/gum-ui.sh

# Use UI functions
ui_step "Processing task"
ui_success "Task complete"
if ui_confirm "Continue?"; then
    choice=$(ui_choose "Select" "Opt1" "Opt2")
fi
```

**Environment variable** (set in `.zstyles`):
```zsh
zstyle ':zephyr:plugin:environment' 'UI_LIB' "$HOME/.local/lib/scripts/core/gum-ui.sh"
```

**See**: `core/CLAUDE.md` for full UI library reference

## CLI Wrapper Integration

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

**Benefits**:
- Fast shell startup (no library sourcing)
- Reduced memory footprint
- Clean CLI interface
- Easy discovery via `commands` function

## Script Standards

**Structure**:
```bash
#!/usr/bin/env sh

# Script: [filename]
# Purpose: [clear description]
# Requirements: [dependencies]

# Source UI library
. "$UI_LIB"

# Implementation
ui_step "Task description"
# ... logic ...
ui_success "Task complete"
```

**Anti-patterns**:
❌ Duplicate UI library code
❌ Skip gum-ui library
❌ Use raw echo instead of UI functions
❌ Create templates in bin/

## Adding New Scripts

**Process**:
1. Choose category (or create new)
2. Create script in `lib/scripts/{category}/`
3. Create wrapper in `bin/executable_{name}` (if CLI tool)
4. Source `$UI_LIB` in script
5. Test with `chezmoi apply`

**Template decision**:
- Need template vars? → `script.sh.tmpl` in lib/
- Static script? → `script.sh` in lib/

## Integration Points

- **CLI wrappers**: `../../bin/` (10 executables)
- **Zephyr config**: `.zstyles` (SCRIPTS_DIR, UI_LIB)
- **Hyprland bindings**: `private_dot_config/hypr/conf/bindings.conf.tmpl`
- **Menu system**: `user-interface/` scripts
- **Core UI**: `core/gum-ui.sh` (572-line library)
