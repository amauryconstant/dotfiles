# Script Library - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/`
**Parent**: See `../../CLAUDE.md` for CLI architecture
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Lazy-loaded script implementations for CLI wrappers
- **Target**: `~/.local/lib/scripts/` (48 total scripts)
- **Categories**: 11 logical groupings
- **Integration**: Sourced by `~/.local/bin/executable_*` wrappers
- **Template safety**: Only lib/ scripts can be templates (bin/ static)

## Directory Structure

```
~/.local/lib/scripts/   # 51 total scripts
├── core/               # 3 files - Foundation
│   ├── gum-ui.sh       # 572-line UI library
│   ├── colors.sh.tmpl  # Oksolar color definitions
│   └── hook-runner.sh  # User hook execution engine
├── desktop/            # 22 files - Hyprland utilities
├── media/              # 3 files - Wallpaper, screenshots
├── system/             # 6 files - Maintenance, health
├── terminal/           # 1 file - CWD preservation
├── network/            # 1 file - Tailscale
├── git/                # 1 file - Branch cleanup
├── user-interface/     # 13 files - Menu system
├── utils/              # 1 file - JSON reorder
└── development/        # [empty - future expansion]
```

## Category Details

### Core Foundation (3 scripts)
**Purpose**: Foundation libraries and hook system
**Dependencies**: None (self-contained)

**Hook System**:
- `hook-runner.sh` - User-extensible hook execution engine
  - Pattern: Silent execution (`2>/dev/null || true`)
  - Location: `~/.config/dotfiles/hooks/`
  - Purpose: Execute user hooks without modifying core scripts
  - Usage: `hook-runner.sh <hook-name> [args...]`

**Hook execution pattern**:
```bash
# In core scripts
if [ -f "$HOME/.local/lib/scripts/core/hook-runner.sh" ]; then
    "$HOME/.local/lib/scripts/core/hook-runner.sh" theme-change "$theme_name" 2>/dev/null || true
fi
```

**Available hook points** (6 total):
| Hook | Triggered By | Arguments | Use Case |
|------|--------------|-----------|----------|
| `theme-change` | theme-switcher.sh | `$theme_name` | Custom app theming |
| `package-sync` | package-manager sync | `sync` | Post-install validation |
| `wallpaper-change` | set-wallpaper.sh | `$wallpaper_path` | External sync (e.g., lockscreen) |
| `dark-mode-change` | darkman scripts | `dark/light` | Web app themes |
| `pre-maintenance` | system-maintenance.sh | none | Backup preparation |
| `post-maintenance` | system-maintenance.sh | `success/failure` | Validation, cleanup |

**Hook discovery**:
- CLI: `dotfiles-hook-list` (shows available + installed hooks)
- CLI: `dotfiles-hook-create` (interactive hook template generator)

**UI Library**: See `core/CLAUDE.md` for gum-ui.sh reference

### Desktop Utilities (20 scripts)
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

**Theme System**:
- `theme-switcher.sh` - Theme selection menu (uses `notify-send`)
  - Calls reload_applications() for terminal, waybar, dunst, wofi
  - Calls theme-apply scripts for extended app coverage
  - Triggers theme-change hook for user customization

- `theme-apply-vscode.sh` - VSCode theme synchronization
  - Maps dotfiles theme to VSCode theme extension
  - Updates settings.json via jaq (JSON processing)
  - Silent failure if VSCode not installed
  - Mappings: catppuccin-latte → "Catppuccin Latte", etc.

- `theme-apply-firefox.sh` - Firefox userChrome.css theming
  - Symlinks userChrome.css from `~/.config/themes/{variant}/`
  - Finds Firefox profile dynamically
  - Creates chrome/ directory if needed
  - Requires: `toolkit.legacyUserProfileCustomizations.stylesheets = true` in about:config

- `theme-apply-spotify.sh` - Spotify theme integration
  - Maps theme to spicetify color scheme
  - Applies via `spicetify config` + `spicetify apply`
  - Optional: Skips if spicetify-cli not installed
  - Mappings: catppuccin, rosepine, gruvbox, solarized

- `theme-apply-opencode.sh` - opencode TUI theme integration
  - Creates custom JSON theme files (8 variants)
  - Symlinks current theme to `~/.config/opencode/themes/current.json`
  - Updates opencode.jsonc via jaq: Sets `"theme": "current"`
  - Silent failure if opencode not installed
  - Mappings: 24 semantic variables → 62 opencode properties

- `theme-apply-claude-code.sh` - claude-code CLI theme integration
  - Maps light/dark themes to claude-code theme setting
  - Updates ~/.claude.json via jaq: Sets `"theme": "light"` or `"theme": "dark"`
  - Silent failure if claude-code not installed
  - Mappings: Light themes (latte, dawn, gruvbox-light, solarized-light) → "light", Dark themes → "dark"

**Other Utilities**:
- `audio-switch.sh` - Audio device switching (uses `notify-send`)
- `screenrecord.sh` - Screen recording (uses `notify-send`)
- `system-settings.sh` - Launch system settings (uses `notify-send`)
- `wlogout.sh` - Logout menu launcher

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

**Resource**: `resources/glyphnames.json` (10,799 glyphs from Nerd Fonts v3.4.0)
**Tool**: `jaq` (Rust-based jq alternative, aliased to jq)

### Finding Glyphs with jaq

**Search by name** (case-insensitive):
```bash
# Find monitor-related glyphs
jaq -r 'to_entries[] | select(.key | test("monitor"; "i")) | "\(.key): \(.value.char)"' \
  ~/.local/share/chezmoi/resources/glyphnames.json

# Output: md-monitor: 󰍹
```

**Search by category** (prefix):
```bash
# Material Design icons only
jaq -r 'to_entries[] | select(.key | startswith("md-")) | "\(.key): \(.value.char)"' \
  ~/.local/share/chezmoi/resources/glyphnames.json | head -20

# Codicons only
jaq -r 'to_entries[] | select(.key | startswith("cod-")) | "\(.key): \(.value.char)"' \
  ~/.local/share/chezmoi/resources/glyphnames.json | head -20
```

**Search by keyword** (finds related concepts):
```bash
# Find all "power" related glyphs
jaq -r 'to_entries[] | select(.key | test("power|battery|energy"; "i")) | "\(.key): \(.value.char)"' \
  ~/.local/share/chezmoi/resources/glyphnames.json
```

**Get specific glyph**:
```bash
# Get the actual character for a known name
jaq -r '."md-monitor".char' ~/.local/share/chezmoi/resources/glyphnames.json
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
jaq -r 'keys[] | split("-")[0]' ~/.local/share/chezmoi/resources/glyphnames.json | sort -u

# Count icons by prefix
jaq -r 'keys[] | split("-")[0]' ~/.local/share/chezmoi/resources/glyphnames.json | sort | uniq -c | sort -rn

# Interactive search (requires fzf)
jaq -r 'to_entries[] | "\(.key)\t\(.value.char)"' \
  ~/.local/share/chezmoi/resources/glyphnames.json | \
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
- Search `resources/glyphnames.json` with jaq (aliased to jq)
- Prefer Material Design (md-) icons
- Reference `.resources/MENU_ICONS.md` for consistency
- Use jaq queries from "Nerd Fonts Glyph Usage" section above

## Integration Points

- **CLI wrappers**: `../../bin/` (10 executables)
- **Zephyr config**: `.zstyles` (SCRIPTS_DIR, UI_LIB)
- **Hyprland bindings**: `private_dot_config/hypr/conf/bindings.conf.tmpl`
- **Menu system**: `user-interface/` scripts
- **Core UI**: `core/gum-ui.sh` (572-line library)

---

## Script Standards (MANDATORY)

**See**: Root `CLAUDE.md` for architecture overview
**See**: `.claude/rules/chezmoi-templates.md` for template syntax

### Error Handling Strategy

**Use `set -euo pipefail`** (strict mode):
- Multi-step scripts with dependencies between commands
- Template scripts (`.tmpl` files)
- Scripts where partial execution is dangerous
- Examples: wallpaper scripts, system setup scripts

**Use manual error checking**:
- Simple single-purpose utilities
- Scripts where graceful degradation needed
- Background utilities (avoid unexpected exits from keybindings)
- Examples: desktop utilities, simple launchers

### Shebang Selection

**Use `#!/usr/bin/env bash`** when:
- Need associative arrays
- Use bash-specific features (`[[`, `=~`, process substitution)
- Complex logic requiring bash extensions

**Use `#!/usr/bin/env sh`** when:
- Simple utilities using POSIX features only
- Background utilities (minimal dependencies)
- Scripts where portability matters

**Examples**: System scripts use bash, desktop utilities use sh

### Anti-Patterns

❌ Wrap scripts in main functions (chezmoi scripts execute directly)
❌ Use manual echo for logging in templates (use `{{ includeTemplate "log_*" }}`)
❌ Add unnecessary OS detection (Arch Linux only)
❌ Add cross-platform compatibility (target-specific)
❌ Partial execution without `set -euo pipefail` in multi-step scripts

### Trust Execution Order

Scripts execute: `run_once_before_*` → file application → `run_once_after_*` → `run_onchange_*`

Trust previous scripts succeeded (chezmoi stops if they fail). Don't add redundant checks.

---

## Pre-Commit Checklist

### For .chezmoiscripts/ templates

- [ ] `#!/usr/bin/env sh` shebang
- [ ] `{{ includeTemplate "log_start" }}` and `log_complete`
- [ ] `set -euo pipefail` after log_start
- [ ] No `main()` function
- [ ] Uses template logging (not echo)
- [ ] Validated: `bash -n script.sh.tmpl`
- [ ] Validated: `chezmoi execute-template < script.sh.tmpl | shellcheck -`
- [ ] Tested: `chezmoi execute-template < script.sh.tmpl`

### For lib/scripts/ files

- [ ] Correct shebang (bash or sh based on features needed)
- [ ] UI pattern matches category (system/desktop/menu)
- [ ] Error handling appropriate for script type
- [ ] Header with Script, Purpose, Requirements
- [ ] Validated: `shellcheck script.sh`

### Automated validation

- Pre-commit hook validates all staged scripts automatically
- Templates pre-rendered before shellcheck validation
- Use `git commit --no-verify` to skip (emergency only)

---

## Shellcheck Integration

**Automated validation** at commit time ensures script quality.

### How It Works

1. **Editor validation** (VSCode):
   - Real-time shellcheck on `.sh` files
   - Template files (`.tmpl`) excluded (validated at commit)
   - Quick-fix suggestions enabled

2. **Pre-commit validation** (git hook):
   - Validates all staged shell scripts via `mise run lint:staged`
   - Templates pre-rendered before validation
   - Blocking on errors/warnings only

3. **Centralized config** (`.shellcheckrc`):
   - 5 error codes disabled for template compatibility
   - Shell dialect auto-detection
   - Warning-level severity (excludes info/style)

### Manual Validation

```bash
# Check single file
shellcheck path/to/script.sh

# Check template (pre-render)
chezmoi execute-template < script.sh.tmpl | shellcheck -

# Check all scripts (via mise)
mise run lint

# Check staged scripts only (what pre-commit runs)
mise run lint:staged

# Skip pre-commit validation (emergency only)
git commit --no-verify
```

### Disabled Error Codes

| Code | Reason | Example |
|------|--------|---------|
| SC1083 | Go template literal braces | `{{ .variable }}` |
| SC1009 | Template delimiter parsing | `{{- if .condition }}` |
| SC1073 | Template control structures | `{{ range .list }}` |
| SC1072 | Template functions | `{{ .var \| default "x" }}` |
| SC2148 | Shebang in rendered output | Templates expand shebang |

### Common Issues & Fixes

**Unquoted variables** (SC2086):
```bash
# Bad
echo $var

# Good
echo "$var"
```

**Unused variables** (SC2034):
```bash
# Option 1: Use the variable
echo "Value: $unused_var"

# Option 2: Prefix with underscore
_unused_var="value"
```

**Exit code checking** (SC2181):
```bash
# Bad
command
if [ $? -eq 0 ]; then

# Good
if command; then
```

**Word splitting** (SC2046):
```bash
# Bad
for file in $(ls *.txt); do

# Good
for file in *.txt; do
```

**ls with grep** (SC2010):
```bash
# Bad
ls -1 | grep pattern

# Good
find . -name "pattern" -type f
```

---

## Shellcheck Troubleshooting

### Issue: Pre-commit hook fails on template

**Symptom**: `Template rendering failed: script.sh.tmpl`

**Cause**: Go template syntax errors or missing template variables

**Fix**:
```bash
# Test template rendering
chezmoi execute-template < script.sh.tmpl

# View rendered output
chezmoi cat path/to/target

# Check template data available
chezmoi data
```

### Issue: Shellcheck errors on valid code

**Symptom**: False positives from shellcheck

**Options**:
1. Fix the code (preferred)
2. Add inline directive: `# shellcheck disable=SC####`
3. Add to `.shellcheckrc` (if globally applicable)

### Issue: Pre-commit hook takes too long

**Symptom**: Commit waits >10 seconds

**Cause**: Too many scripts staged at once

**Fix**:
```bash
# Commit in smaller batches
git add file1.sh file2.sh
git commit

# Or skip validation (emergency)
git commit --no-verify
```

### Issue: VSCode not showing shellcheck errors

**Symptom**: No linting in editor

**Fix**:
1. Reload window: Ctrl+Shift+P → "Developer: Reload Window"
2. Check shellcheck installed: `mise install shellcheck`
3. Verify `.shellcheckrc` exists in workspace root
4. Check VSCode extension installed: "shellcheck"

### Issue: Template validated in pre-commit but not editor

**Symptom**: Pre-commit catches issues VSCode doesn't

**Expected**: Templates (`.tmpl`) excluded from editor validation

**Reason**: Go template syntax causes false positives

**Workflow**: Templates validated only at commit time (after rendering)

### Issue: Need to commit with known shellcheck issues

**Symptom**: Urgent fix needed, shellcheck blocking

**Solution**:
```bash
# Skip pre-commit validation (use sparingly)
git commit --no-verify -m "emergency fix"

# Create follow-up issue to fix shellcheck warnings
# Fix in next commit
```

### Issue: Different errors in VSCode vs pre-commit

**Symptom**: VSCode shows errors pre-commit doesn't (or vice versa)

**Cause**: Version mismatch or config desync

**Fix**:
```bash
# Check versions match
mise current shellcheck
code --version

# Ensure .shellcheckrc exists
ls -la .shellcheckrc

# Reload VSCode
# Ctrl+Shift+P → "Developer: Reload Window"
```
