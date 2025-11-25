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
**Dependencies**: hyprctl, notify-send, jaq (JSON)

**UI Pattern**:
- **All desktop utilities** use `notify-send` for user feedback (keybinding-triggered, minimal overhead)
- **No gum-ui library usage** in desktop scripts (background utilities pattern)

**Window Management**:
- `launch-or-focus.sh` - Single-instance apps (focus if exists, launch if not)
  - Integration: `Super+E` → dolphin
  - Pattern: `launch-or-focus.sh dolphin` or `launch-or-focus.sh btop "ghostty -e btop"`
  - Algorithm: Query clients → Match class/title → Focus or launch

- `keybindings.sh` - Keybinding reference (`Super+?`)

**Display & Monitors**:
- `monitor-switch.sh` - Switch display configs (uses `notify-send`)
- `monitor-mirror.sh` - Mirror displays (uses `notify-send`)
- Other monitor utilities - Display management (use `notify-send`)

**Appearance & Style**:
- `waybar-toggle.sh`, `waybar-style.sh` - Waybar controls (use `notify-send`)
- `nightlight-toggle.sh`, `nightlight-config.sh` - Blue light filter (use `notify-send`)
- `workspace-gaps-toggle.sh`, `workspace-gaps-reset.sh` - Gap controls (use `notify-send`)
- `idle-toggle.sh` - Idle management (uses `notify-send`)

**Other Utilities**:
- `audio-switch.sh` - Audio device switching (uses `notify-send`)
- `screenrecord.sh` - Screen recording (uses `notify-send`)
- `system-settings.sh` - Launch system settings (uses `notify-send`)
- `wlogout.sh` - Logout menu launcher
- `theme-switcher.sh` - Theme selection menu (uses `notify-send`)

### Media Scripts (3 scripts)
**Purpose**: Media capture and wallpaper management
**Tools**: grim, slurp, satty, swww, wallust
**Integration**: Hyprland bindings, systemd timer

**UI Pattern**: Templates use `{{ includeTemplate "log_*" }}`, `screenshot.sh` uses `notify-send`

**Scripts**:
- `screenshot.sh` - Smart screenshot with Satty annotation
  - Modes: smart (auto-snap window), region, window, fullscreen
  - Tools: grim (capture), slurp (selection), satty (annotation)
  - Smart mode: Auto-snap to window if <20px selection

- `random-wallpaper.sh.tmpl` - Random wallpaper from collection (uses log templates)
- `set-wallpaper.sh.tmpl` - Set specific wallpaper + color extraction (uses log templates)

### User Interface Menus (12 scripts)
**Purpose**: Omarchy-inspired hierarchical menu system
**Entry point**: `Super+Space` → `system-menu.sh`
**Integration**: Wofi (dmenu mode), menu-helpers.sh library
**Icons**: Material Design glyphs

**UI Pattern**: All menu scripts use `menu-helpers.sh` (wofi + notify-send)

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
- Provides `notify()` wrapper around `notify-send` for consistent notifications
- Provides `show_menu()` function for wofi integration
- All menu-*.sh scripts source this library

### System Scripts (7 scripts)
**Purpose**: System maintenance, health monitoring, SSH key management
**Tools**: pacman, paru, systemctl, ssh-keygen
**Integration**: CLI wrappers, scheduled tasks

**UI Pattern**: All system scripts use gum-ui library (`ui_*` functions) for consistent terminal UI

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
- `system-health-dashboard.sh` - Real-time system monitoring dashboard
- `pacman-lock-cleanup.sh` - Clean stale pacman locks

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

### UI Pattern Standards

**UI library usage by category**:

| Category | UI Pattern | Rationale |
|----------|------------|-----------|
| **System scripts** | gum-ui library (`ui_*` functions) | CLI tools, interactive, need rich terminal UI |
| **Desktop utilities** | notify-send | Keybinding-triggered, minimal overhead, native notifications |
| **Menu scripts** | menu-helpers.sh (wofi + notify-send) | Wofi integration, consistent menu interface |
| **Template scripts** | `{{ includeTemplate "log_*" }}` | Chezmoi lifecycle scripts, templated output |
| **Other utilities** | Varies by context | git-prune-branch uses gum-ui, others as needed |

### Pattern Examples

**System script (gum-ui library)**:
```bash
#!/usr/bin/env sh
# Script: system-health.sh
# Purpose: System health monitoring

if [ -n "$UI_LIB" ] && [ -f "$UI_LIB" ]; then
    . "$UI_LIB"
else
    echo "Error: UI library not found" >&2
    exit 1
fi

ui_title "System Status"
ui_info "Load: $(uptime | awk -F'load average:' '{print $2}')"
ui_success "All services running"
```

**Desktop utility (notify-send)**:
```bash
#!/usr/bin/env sh
# Script: monitor-switch.sh
# Purpose: Switch display configuration

if command -v wdisplays >/dev/null 2>&1; then
    wdisplays &
else
    notify-send "󰍹 Displays" "No display tool found"
fi
```

**Menu script (menu-helpers.sh)**:
```bash
#!/usr/bin/env sh
# Script: menu-update.sh
# Purpose: System update menu

. ~/.local/lib/scripts/user-interface/menu-helpers.sh

CHOICE=$(show_menu "Update" "System|Firmware|Mirrorlist")
case "$CHOICE" in
    "System") topgrade ;;
esac
notify "Update" "Complete"
```

**Anti-patterns**:
❌ Use gum-ui in desktop utilities (unnecessary overhead)
❌ Use notify-send in system CLI tools (use ui_* functions)
❌ Use undefined `notify()` function outside menu scripts
❌ Create templates in bin/

## Nerd Fonts Glyph Usage

**Resource**: `.resources/glyphnames.json` (10,799 glyphs from Nerd Fonts v3.4.0)
**Tool**: `jaq` (Rust-based jq alternative, aliased to jq)

### Finding Glyphs with jaq

**Search by name** (case-insensitive):
```bash
# Find monitor-related glyphs
jaq -r 'to_entries[] | select(.key | test("monitor"; "i")) | "\(.key): \(.value.char)"' \
  ~/.local/share/chezmoi/.resources/glyphnames.json

# Output: md-monitor: 󰍹
```

**Search by category** (prefix):
```bash
# Material Design icons only
jaq -r 'to_entries[] | select(.key | startswith("md-")) | "\(.key): \(.value.char)"' \
  ~/.local/share/chezmoi/.resources/glyphnames.json | head -20

# Codicons only
jaq -r 'to_entries[] | select(.key | startswith("cod-")) | "\(.key): \(.value.char)"' \
  ~/.local/share/chezmoi/.resources/glyphnames.json | head -20
```

**Search by keyword** (finds related concepts):
```bash
# Find all "power" related glyphs
jaq -r 'to_entries[] | select(.key | test("power|battery|energy"; "i")) | "\(.key): \(.value.char)"' \
  ~/.local/share/chezmoi/.resources/glyphnames.json
```

**Get specific glyph**:
```bash
# Get the actual character for a known name
jaq -r '."md-monitor".char' ~/.local/share/chezmoi/.resources/glyphnames.json
# Output: 󰍹
```

### Icon Selection Guidelines

**Prefer Material Design icons** (md-) for consistency:
- **md-** prefix: Material Design (primary choice)
- **cod-** prefix: Codicons (development tools)
- **fa-** prefix: Font Awesome (fallback)
- **oct-** prefix: Octicons (GitHub-related)
- **pom-** prefix: Pomicons (system/hardware)

**Common categories**:
```bash
# System icons
md-power, md-restart, md-shutdown, md-lock

# File operations
md-file, md-folder, md-document, md-archive

# Development
md-code-braces, md-git, md-github, md-terminal

# Media
md-image, md-camera, md-video, md-music

# UI controls
md-check, md-close, md-arrow-*, md-chevron-*
```

### Reference Documentation

**Menu icons**: See `.resources/MENU_ICONS.md` for complete menu system icon mapping

**Examples in codebase**:
- Desktop scripts: monitor-*.sh, waybar-*.sh (notification icons)
- Menu system: menu-*.sh (wofi menus)
- UI library: gum-ui.sh (status icons)

### Quick Reference Commands

```bash
# List all available icon prefixes
jaq -r 'keys[] | split("-")[0]' ~/.local/share/chezmoi/.resources/glyphnames.json | sort -u

# Count icons by prefix
jaq -r 'keys[] | split("-")[0]' ~/.local/share/chezmoi/.resources/glyphnames.json | sort | uniq -c | sort -rn

# Interactive search (requires fzf)
jaq -r 'to_entries[] | "\(.key)\t\(.value.char)"' \
  ~/.local/share/chezmoi/.resources/glyphnames.json | \
  fzf --preview 'echo {2}' --preview-window=up:1
```

## Adding New Scripts

**Process**:
1. Choose category (or create new)
2. Create script in `lib/scripts/{category}/`
3. Create wrapper in `bin/executable_{name}` (if CLI tool)
4. Source `$UI_LIB` in script
5. **Select appropriate glyphs** using jq queries above
6. Test with `chezmoi apply`

**Template decision**:
- Need template vars? → `script.sh.tmpl` in lib/
- Static script? → `script.sh` in lib/

**Icon selection**:
- Search `.resources/glyphnames.json` with jaq (aliased to jq)
- Prefer Material Design (md-) icons
- Reference `.resources/MENU_ICONS.md` for consistency
- Use jaq queries from "Nerd Fonts Glyph Usage" section above

## Integration Points

- **CLI wrappers**: `../../bin/` (10 executables)
- **Zephyr config**: `.zstyles` (SCRIPTS_DIR, UI_LIB)
- **Hyprland bindings**: `private_dot_config/hypr/conf/bindings.conf.tmpl`
- **Menu system**: `user-interface/` scripts
- **Core UI**: `core/gum-ui.sh` (572-line library)
