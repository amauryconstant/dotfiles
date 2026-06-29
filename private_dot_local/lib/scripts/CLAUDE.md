# Script Library - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/`
**Parent**: See `../../CLAUDE.md` for CLI architecture
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Lazy-loaded script implementations for CLI wrappers
- **Target**: `~/.local/lib/scripts/`
- **Categories**: logical groupings by domain
- **Integration**: Sourced by `~/.local/bin/executable_*` wrappers
- **Template safety**: Only lib/ scripts can be templates (bin/ static)

## Directory Structure

```
~/.local/lib/scripts/
├── core/               # Foundation
│   ├── gum-ui.sh       # UI library
│   ├── hook-runner     # User hook execution engine
│   └── state-manager.sh # State management library
├── desktop/            # Hyprland utilities
├── media/              # Wallpaper, screenshots
├── system/             # Maintenance, health
├── terminal/           # CWD preservation
├── network/            # Tailscale
├── git/                # Branch cleanup
├── user-interface/     # Menu system
└── utils/              # JSON reorder
```

## Category Details

### Core Foundation
**Purpose**: Foundation libraries and hook system
**Dependencies**: None (self-contained)

**Hook System**:
- `hook-runner` - User-extensible hook execution engine
  - Pattern: Silent execution (`2>/dev/null || true`)
  - Location: `~/.config/dotfiles/hooks/`
  - Purpose: Execute user hooks without modifying core scripts
  - Usage: `hook-runner <hook-name> [args...]`

**Hook execution pattern**:
```bash
# In core scripts
if [ -f "$HOME/.local/lib/scripts/core/hook-runner" ]; then
    "$HOME/.local/lib/scripts/core/hook-runner" theme-change "$theme_name" 2>/dev/null || true
fi
```

**Available hook points**:
| Hook | Triggered By | Arguments | Use Case |
|------|--------------|-----------|----------|
| `theme-change` | theme-switcher.sh | `$theme_name` | Custom app theming |
| `package-sync` | package-manager sync | `sync` | Post-install validation |
| `wallpaper-change` | set-wallpaper.sh | `$wallpaper_path` | External sync (e.g., lockscreen) |
| `dark-mode-change` | darkman scripts | `dark/light` | Web app themes |
| `pre-maintenance` | system-maintenance.sh | none | Backup preparation |
| `post-maintenance` | system-maintenance.sh | `success/failure` | Validation, cleanup |
| `menu-extend` | system-menu | `options`/`handle <choice>` | Super+Space custom entries |
| `idle-change` | hypridle listener 1 | `timeout`/`resume` | Lock/unlock boundary events |
| `session-start` | autostart.conf | none | Hyprland session startup |

**Hook discovery**:
- CLI: `dotfiles-hook-list` (shows available + installed hooks)
- CLI: `dotfiles-hook-create` (interactive hook template generator)
- CLI: `hook-edit [name]` (edit installed hook in `$EDITOR`)
- CLI: `hook-test [name]` (run hook with default test args, shows output + exit code)
- Debug: `HOOK_DEBUG=1 hook-runner <name>` (logs to `~/.local/state/dotfiles/hook.log`)

**UI Library**: See `core/CLAUDE.md` for gum-ui.sh reference

### Desktop Utilities
**Purpose**: Hyprland desktop utilities
**Dependencies**: hyprctl, notify-send, jaq (JSON)

**Naming**: scripts are extensionless and directly executable (the `.sh` suffixes below are illustrative — actual files have none, e.g. `launch-or-focus`, not `launch-or-focus.sh`).

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
- `theme-switcher.tmpl` - Theme selection menu (uses `notify-send`)
  - Reloads terminal, waybar, swaync, wofi
  - Calls the `theme-apply-*` scripts (below) for extended app coverage
  - Triggers the `theme-change` hook for user customization

**theme-apply-\* scripts** (each silently skips if its app is absent): `theme-apply-firefox`, `theme-apply-spotify`, `theme-apply-opencode`, `theme-apply-claude-code`, `theme-apply-gtk`, `theme-apply-qt`, `theme-apply-neovim`, `theme-apply-zellij`. Details for a few:

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
  - Creates custom JSON theme files (one per theme)
  - Symlinks current theme to `~/.config/opencode/themes/current.json`
  - Updates opencode.jsonc via jaq: Sets `"theme": "current"`
  - Silent failure if opencode not installed
  - Mappings: semantic variables → opencode properties

- `theme-apply-claude-code.sh` - claude-code CLI theme integration
  - Maps light/dark themes to claude-code theme setting
  - Updates ~/.claude.json via jaq: Sets `"theme": "light"` or `"theme": "dark"`
  - Silent failure if claude-code not installed
  - Mappings: Light themes (latte, dawn, gruvbox-light, solarized-light) → "light", Dark themes → "dark"

**Session management**: `session-save`, `session-restore`, `session-prompt`, `recover-workspaces` — Hyprland window/workspace snapshotting (also driven by `session-autosave.timer`; see `systemd/user/CLAUDE.md`). `hypr-session` is the user-facing CLI over these.

**Input / keyboard**: `kanata-layer`, `kanata-layer-toggle` — query/switch Kanata layers (laptop, via the kanata daemon on port 5829).

**Other Utilities**:
- `audio-switch` - Audio device switching
- `battery-status` - Battery/power status (Waybar custom module / notify)
- `idle-indicator`, `idle-toggle` - idle/inhibit state
- `immediate-lock` - lock screen now
- `screenrecord` - Screen recording
- `system-settings` - Launch system settings
- `voice-meeting` - meeting voice helper
- `window-pop` - toggle a window to a floating "pop" state
- `zoom-cursor` - cursor magnifier
- `wlogout` - Logout menu launcher

### Media Scripts
**Purpose**: Media capture and wallpaper management
**Tools**: grim, slurp, satty, swww
**Integration**: Hyprland bindings, systemd timer

**UI Pattern**: Templates use `{{ includeTemplate "log_*" }}`, `screenshot.sh` uses `notify-send`

**Scripts**:
- `screenshot` - Smart screenshot with Satty annotation
  - Modes: smart (auto-snap window), region, window, fullscreen
  - Tools: grim (capture), slurp (selection), satty (annotation)
  - Smart mode: Auto-snap to window if <20px selection

- `random-wallpaper.tmpl` - Random wallpaper from collection (uses log templates)
- `set-wallpaper.tmpl` - Set specific wallpaper via swww (uses log templates)

### User Interface Menus
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

**Submenus** (not top-level): `menu-ai` (AI actions), `utilities-menu` (utility launcher), reached from the categories above.

**Hook tooling** (also in `user-interface/`): `hook-create`, `hook-edit`, `hook-list`, `hook-test` (exposed as `dotfiles-hook-*`), `dotfiles-bindings-edit` — see `dotfiles/CLAUDE.md`.

**Shared utilities**: `menu-helpers.sh` (common functions)
- Provides `notify()` wrapper around `notify-send` for consistent notifications
- Provides `show_menu()` function for wofi integration
- All menu-* scripts source this library

### System Scripts
**Purpose**: System maintenance, health monitoring, SSH key management
**Tools**: pacman, paru, systemctl, ssh-keygen
**Integration**: CLI wrappers, scheduled tasks

**UI Pattern**: All system scripts use gum-ui library (`ui_*` functions) for consistent terminal UI

**Scripts** (extensionless, directly executable; `package-manager` lives in `system/package-manager/` — see its CLAUDE.md):
- `package-manager` - Module-based package installation (pacman/paru)
- `system-health`, `system-health-dashboard` - health monitoring + live dashboard
- `system-maintenance` - automated maintenance tasks
- `troubleshoot` - troubleshooting wizard
- `pacman-lock-cleanup` - clean stale pacman locks
- `home-backup` - Restic home backup runner (driven by `home-backup.timer`)
- `rotate-ssh-key` - SSH key rotation + chezmoi reimport (ED25519, timestamped backup to `~/.ssh/backup-*`, re-encrypt via `chezmoi add --encrypt`). Usage: `rotate-ssh-key <keyname>`.
- `rotate-age-key` - rotate the age master encryption key

### Other Categories

| Category | Purpose | Scripts |
|----------|---------|---------|
| `core/` | Foundation libraries | `gum-ui.sh`, `hook-runner`, `state-manager.sh` |
| `terminal/` | Terminal utilities | `regen-zsh-plugins`, `terminal-cwd`, `zellij-sessionizer.tmpl` |
| `network/` | Network tools | `tailscale.sh`, `network-info`, `vpn-toggle`, `vpn-switch`, `wifi-switch` |
| `git/` | Git utilities | `prune-branch` |
| `utils/` | General utilities | `dotfiles-debug`, `firefox-debug-trace`, `reorder-json`, `unzip` |

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

**Tool**: `/nerdfonts-search` skill — fuzzy search across 10,764 glyphs from Nerd Fonts v3.4.0

**Prefer**: Material Design (`md-`) for system icons; Codicons (`cod-`) for dev tools; Font Awesome (`fa-`) as fallback.

## Adding New Scripts

**Process**:
1. Choose category (or create new)
2. Create script in `lib/scripts/{category}/` **WITHOUT .sh extension**
3. Name: `executable_scriptname` (no .sh suffix)
4. Source `$UI_LIB` at top of script (self-sufficient pattern)
5. **Select appropriate glyphs** using `/nerdfonts-search` skill
6. Test with `chezmoi apply`
7. Call directly: `scriptname` (in PATH automatically)

**Naming convention**:
- ✅ `executable_prune-branch` (no .sh) → callable as `prune-branch`
- ✅ `executable_screenshot` (no .sh) → callable as `screenshot`
- ❌ `executable_script.sh` (DON'T add .sh extension)

**Template decision**:
- Need template vars? → `executable_script.tmpl` (no .sh, just .tmpl)
- Static script? → `executable_script` (no extensions)

**Exceptions** (keep .sh extension):
- `gum-ui.sh` - Sourced library (not executed directly)
- `menu-helpers.sh` - Sourced library (not executed directly)
- `state-manager.sh` - Sourced library (not executed directly)

**Self-sufficient pattern**:
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
ui_title "My Script"
ui_info "Processing..."
```

**Icon selection**:
- Use `/nerdfonts-search` skill to find appropriate glyphs
- Prefer Material Design (md-) icons

**No wrappers needed**: Scripts directly in PATH via `.zstyles` configuration

## Integration Points

- **Direct execution**: All script directories in PATH (no wrappers)
- **Zephyr config**: `.zstyles` (PATH, SCRIPTS_DIR, UI_LIB)
- **Hyprland bindings**: `private_dot_config/hypr/conf/bindings/*.conf`
- **Menu system**: `user-interface/` scripts
- **Core UI**: `core/gum-ui.sh` (library)

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

1. **Editor validation**:
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

**For shellcheck-specific issues**: fix the code, or add `# shellcheck disable=SC####` inline, or add to `.shellcheckrc` for repo-wide suppression. Template false positives are expected — templates are excluded from editor validation and only validated at commit time after rendering.
