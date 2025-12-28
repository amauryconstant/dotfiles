# CLAUDE.md

Technical guidance for Claude Code when developing in this repository.

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Table of Contents & Location Hierarchy

This repository uses **location-based CLAUDE.md files**. Claude Code automatically loads relevant files when working in subdirectories.

### Documentation Hierarchy

**Root (this file)**: Core standards, security protocols, architecture overview
**Location-specific**: Detailed implementation docs in relevant directories

```
~/.local/share/chezmoi/
├── CLAUDE.md                                                    # Core (this file)
├── .chezmoidata/                                                 # Template data (YAML)
├── .chezmoiscripts/                                             # Lifecycle scripts
├── .chezmoitemplates/                                           # Template includes
├── private_dot_config/
│   ├── CLAUDE.md                                                # Desktop environment (consolidated)
│   ├── hypr/CLAUDE.md                                           # Hyprland compositor
│   ├── systemd/user/CLAUDE.md                                   # User services
│   ├── shell/CLAUDE.md                                          # Shell + Zsh config (consolidated)
│   ├── Nextcloud/CLAUDE.md                                      # Nextcloud sync (modify_manager example)
│   ├── git/CLAUDE.md                                            # Git config
│   ├── themes/CLAUDE.md                                         # Theme system (semantic variables, switching)
│   ├── waybar/CLAUDE.md                                         # Waybar status bar
│   ├── dunst/CLAUDE.md                                          # Dunst notifications
│   ├── wofi/CLAUDE.md                                           # Wofi launcher
│   └── wlogout/CLAUDE.md                                        # Wlogout power menu
└── private_dot_local/
    ├── CLAUDE.md                                                # CLI wrappers overview
    ├── bin/CLAUDE.md                                            # CLI wrappers
    └── lib/scripts/
        ├── CLAUDE.md                                            # Script library (consolidated)
        ├── core/CLAUDE.md                                       # Gum UI & colors
        └── system/CLAUDE.md                                     # Maintenance & health
```

### Core Documentation (This File)

1. Quick Reference
2. Critical Safety Protocols
3. Architecture Quick Reference
4. Script Standards (MANDATORY)
5. Template System Reference
6. chezmoi_modify_manager Reference
7. Package Management for Development
8. Chezmoi Data Files Reference
9. Quality Standards (MANDATORY)
10. Security and Encryption
11. Feature Development Guide
12. Merge Conflict Resolution
13. Emergency Procedures
14. Documentation Maintenance Protocol
15. Shellcheck Troubleshooting

---

## Quick Reference

- **Project**: Chezmoi dotfiles repository
- **Target OS**: Arch Linux (archinstall + Hyprland profile)
- **Desktop**: Hyprland + Waybar + Wofi
- **Terminal**: Ghostty (primary), Kitty (baseline)
- **Languages**: Go templates (text/template + Sprig), Shell (POSIX sh)
- **Constraint**: Security-first, manual encryption only
- **Docs**: README.md for user-facing, CLAUDE.md for dev patterns

## 🚨 CRITICAL SAFETY PROTOCOLS

### **NEVER** Attempt These

❌ Decrypt encrypted files programmatically
❌ Read `.age` file contents
❌ Access encryption keys directly
❌ Modify encryption config without explicit user guidance
❌ Bypass security protocols for convenience

### **ALWAYS** Guide Manual Encryption

```bash
# Guide user to run manually:
chezmoi decrypt path/to/file.age        # View
chezmoi edit path/to/file.age           # Edit
chezmoi add --encrypt path/to/file      # Encrypt
```

## Architecture Quick Reference

### File Naming Conventions

| Prefix | Target | Example |
|--------|--------|---------|
| `private_dot_*` | `~/.{name}` | `private_dot_config/` → `~/.config/` |
| `encrypted_*` | Age-encrypted | `encrypted_key.txt.age` → `key.txt` |
| `executable_*` | Executable | `executable_script` → `script` (755) |
| `modify_*` | chezmoi_modify_manager | `modify_app.conf.tmpl` → managed |
| `run_once_*` | Run once | Setup scripts |
| `run_onchange_*` | Hash-triggered | Content-driven scripts |
| `*.tmpl` | Template | `config.tmpl` → `config` (processed) |

### Repository Structure

```
~/.local/share/chezmoi/
├── .chezmoidata/               # Template data (packages, colors, globals)
├── .chezmoiscripts/            # Lifecycle scripts (run_once_*, run_onchange_*)
├── .chezmoitemplates/          # Reusable includes (log_*)
├── .scripts/                   # Repository utilities (omarchy-changes, merge-driver)
├── private_dot_config/         # XDG config (hypr, waybar, wofi, zsh, etc.)
│   ├── dotfiles/hooks/         # User-extensible hooks (6 hook points)
│   └── themes/                 # Theme system (8 variants with Firefox CSS)
├── private_dot_keys/           # 🔐 Encrypted secrets
├── private_dot_ssh/            # SSH + encrypted keys
└── private_dot_local/
    ├── bin/                    # CLI wrappers (14 executables)
    └── lib/scripts/            # Script library (49 scripts in 10 categories)
```

**See**: Chezmoi Data Files Reference for data file structure
**See**: Chezmoi Scripts Reference for lifecycle script execution
**See**: `private_dot_local/CLAUDE.md` for CLI wrapper architecture
**See**: `private_dot_local/lib/scripts/CLAUDE.md` for script library organization

## Script Library Overview

| Category | Location | Scripts | CLI Wrappers | Purpose |
|----------|----------|---------|--------------|---------|
| Core | `lib/scripts/core/` | 3 | 0 | Foundation library (gum-ui, hook system) |
| Desktop | `lib/scripts/desktop/` | 20 | 1 | Hyprland utilities, theme switching |
| Development | `lib/scripts/development/` | 0 | 0 | Development tools (reserved) |
| Git | `lib/scripts/git/` | 1 | 1 | Git utilities (prune-branch) |
| Media | `lib/scripts/media/` | 4 | 3 | Wallpaper, screenshots, color sorting |
| Network | `lib/scripts/network/` | 1 | 1 | Network tools (tailscale) |
| System | `lib/scripts/system/` | 7 | 4 | Maintenance & monitoring |
| Terminal | `lib/scripts/terminal/` | 1 | 0 | Terminal utilities (CWD) |
| User-interface | `lib/scripts/user-interface/` | 13 | 1 | Menu system, theme menu |
| Utils | `lib/scripts/utils/` | 1 | 0 | Utilities (JSON reordering) |

**Details**: See `private_dot_local/lib/scripts/CLAUDE.md`
**Standards**: See `#script-standards-mandatory` in this file

**Note**: Changes to `.chezmoidata/` automatically trigger `run_onchange_*` scripts via hash detection.

**See**: Chezmoi Scripts Reference for lifecycle script details
**See**: `private_dot_local/lib/scripts/CLAUDE.md` for script library patterns
**See**: `private_dot_local/lib/scripts/core/CLAUDE.md` for Gum UI library

### Structure

```bash
#!/usr/bin/env sh

# Script: [filename]
# Purpose: [clear description]
# Requirements: Arch Linux, [dependencies]

{{ includeTemplate "log_start" "[description]" }}

set -euo pipefail

# Implementation (NO main function)
# Use log templates for ALL output

{{ includeTemplate "log_complete" "[message]" }}
```

### UI Library Sourcing Pattern

**Standard pattern** (for system CLI scripts):
```bash
# Source UI library with fallback
if [ -n "$UI_LIB" ] && [ -f "$UI_LIB" ]; then
    . "$UI_LIB"
elif [ -f "$HOME/.local/lib/scripts/core/gum-ui.sh" ]; then
    . "$HOME/.local/lib/scripts/core/gum-ui.sh"
else
    echo "Error: UI library not found" >&2
    exit 1
fi

# Use UI functions (35 functions: status, interactive, layout, data display)
ui_step "Processing task"
ui_success "Task complete"
if ui_confirm "Continue?"; then
    choice=$(ui_choose "Select" "Opt1" "Opt2")
fi
```

**Environment variables** (defined in `.zstyles` via Zephyr):
- `SCRIPTS_DIR="$HOME/.local/lib/scripts"`
- `UI_LIB="$HOME/.local/lib/scripts/core/gum-ui.sh"`

**Note**: See `private_dot_local/lib/scripts/CLAUDE.md` for UI pattern by category (system vs desktop vs menu)

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

### Anti-Patterns

❌ Wrap scripts in main functions (chezmoi scripts execute directly)
❌ Use manual echo for logging in templates (use `{{ includeTemplate "log_*" }}`)
❌ Add unnecessary OS detection (Arch Linux only)
❌ Add cross-platform compatibility (target-specific)
❌ Partial execution without `set -euo pipefail` in multi-step scripts

### Trust Execution Order

Scripts execute: `run_once_before_*` → file application → `run_once_after_*` → `run_onchange_*`

Trust previous scripts succeeded (chezmoi stops if they fail). Don't add redundant checks.

### Script Usage Guidelines

**DO use .chezmoiscripts/ for**:
✅ Initial system setup
✅ Tool installation
✅ Configuration setup
✅ Dotfiles-driven changes

**DO NOT use .chezmoiscripts/ for**:
❌ System updates (use manual tools like topgrade)
❌ Ongoing maintenance (use CLI tools)
❌ Regular monitoring (use CLI tools)
❌ User-initiated tasks (use CLI functions)

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

### Pre-Commit Checklist

**For .chezmoiscripts/ templates**:
- [ ] `#!/usr/bin/env sh` shebang
- [ ] `{{ includeTemplate "log_start" }}` and `log_complete`
- [ ] `set -euo pipefail` after log_start
- [ ] No `main()` function
- [ ] Uses template logging (not echo)
- [ ] Validated: `bash -n script.sh.tmpl`
- [ ] Validated: `chezmoi execute-template < script.sh.tmpl | shellcheck -`
- [ ] Tested: `chezmoi execute-template < script.sh.tmpl`

**For lib/scripts/ files**:
- [ ] Correct shebang (bash or sh based on features needed)
- [ ] UI pattern matches category (system/desktop/menu)
- [ ] Error handling appropriate for script type
- [ ] Header with Script, Purpose, Requirements
- [ ] Validated: `shellcheck script.sh`

**Automated validation**:
- Pre-commit hook validates all staged scripts automatically
- Templates pre-rendered before shellcheck validation
- Use `git commit --no-verify` to skip (emergency only)

### Shellcheck Integration

**Automated validation** at commit time ensures script quality.

#### How It Works

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

#### Manual Validation

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

#### Disabled Error Codes

| Code | Reason | Example |
|------|--------|---------|
| SC1083 | Go template literal braces | `{{ .variable }}` |
| SC1009 | Template delimiter parsing | `{{- if .condition }}` |
| SC1073 | Template control structures | `{{ range .list }}` |
| SC1072 | Template functions | `{{ .var \| default "x" }}` |
| SC2148 | Shebang in rendered output | Templates expand shebang |

#### Common Issues & Fixes

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

## Template System Reference

### Quick Commands

| Task | Command | Purpose |
|------|---------|---------|
| Test template syntax | `chezmoi execute-template < file.tmpl` | Validate Go template |
| View data | `chezmoi data` | All template vars |
| Preview output | `chezmoi cat path/to/file` | Final rendered |
| Validate script | `bash -n script.sh.tmpl` | Shell syntax |
| Test modify_manager | `chezmoi cat path/to/target` | Preview merge |
| Check modify syntax | `chezmoi_modify_manager --help-syntax` | Directive reference |

### Template Variable Patterns

#### Built-in (chezmoi)
```go
.chezmoi.os, .chezmoi.arch, .chezmoi.hostname, .chezmoi.username
.chezmoi.sourceDir, .chezmoi.homeDir
```

#### User-defined (`.chezmoi.yaml.tmpl`)
```go
.fullname, .firstname, .workEmail, .personalEmail
.privateServer, .chassisType  # laptop/desktop
```

#### Data files (`.chezmoidata/`)
```go
.packages.install.arch     # Package lists with strategies
.colors.oksolar.*         # Oksolar color definitions
.extensions.code          # VSCode extension arrays
.globals.applications.*   # Default apps (EDITOR, VISUAL, BROWSER)
.globals.xdg.*           # XDG Base Directory paths
```

#### Standard Patterns
```go
# OS Detection


# Logging (MUST use these, not echo)
{{ includeTemplate "log_start" "message" }}
{{ includeTemplate "log_step" "message" }}
{{ includeTemplate "log_success" "message" }}

# Advanced syntax
{{ if eq .chezmoi.os "linux" }}
{{ .firstname | lower }}
{{ .privateServer | replace "www" "nextcloud" }}
{{ range .extensions.code }}{{ end }}
{{ $var := .value | default "fallback" }}

# Whitespace control
{{- includeTemplate "log_step" "message" -}}
```

## chezmoi_modify_manager Reference

**See**: `private_dot_config/Nextcloud/CLAUDE.md#chezmoi_modify_manager-reference` for complete directive reference and examples

**Purpose**: Intelligently separates settings from state in application config files

## Package Management for Development

### Dual System Architecture

**Native Arch** (paru): CLI tools, system services, dev tools, deep integration
**Flatpak**: Proprietary apps, cross-platform GUI apps, sandboxing

### Package Manager

**Tool**: `package-manager.sh` (v3.0.0, modularized architecture)
**Features**: NixOS-style version pinning, module system, hybrid update mode, performance optimizations
**Details**: See `private_dot_local/lib/scripts/system/CLAUDE.md#package-manager.sh-v3.0`

**Key capabilities**:
- Module-based package organization with conflict detection
- Version constraints (exact, >=, <) for reproducible builds
- Unmanaged package discovery with `merge` command
- Lockfile generation (like NixOS flake.lock)
- **Hybrid update mode**: sync to packages.yaml + update all installed packages
- Interactive downgrade selection with numbered menus
- Rolling package detection (-git packages)
- Comprehensive validation and status checks
- Backup integration (Timeshift or Snapper)
- Performance-optimized sync operations (batch installs, lockfile fast-path)

**System Update Integration**:
- **Topgrade**: Calls `package-manager update` as pre-command for unified update workflow
- **Update command**: `package-manager update` syncs packages.yaml, then updates all Arch/AUR and Flatpak packages
- **Flags**: `--no-sync` (skip sync), `--no-flatpak` (skip Flatpak updates)
- **Workflow**: Packages → Firmware (topgrade) → Git repos (topgrade) → Cleanup (topgrade)

### Decision Matrix

**Use Flatpak for**:
✅ Proprietary apps (Spotify, Slack, VS Code)
✅ Cross-platform GUI apps (Xournalpp, qBittorrent)
✅ Sandboxing/isolation needed

**Use Native Arch for**:
✅ CLI tools and utilities
✅ System services and daemons
✅ Development tools and languages
✅ Linux-first applications
✅ Deep system integration (browsers with extensions, sync clients)
✅ Desktop environment components (Thunar, Hyprland polkit agent)

### Lifecycle Scripts Execution

1. **`run_once_before_*`** → Setup (package managers, dirs, tools, dependencies)
2. **`run_onchange_before_*`** → Package installation (first install AND updates)
3. **File application** → chezmoi applies configs
4. **`run_once_after_*`** → Configuration (services, setup)
5. **`run_onchange_after_*`** → Content-driven updates (extensions, themes, AI models)

**Package installation strategy**:
- **Single script**: `run_onchange_before_sync_packages.sh.tmpl` handles both initial install and updates
- **First install**: Script runs because chezmoi has no prior hash record (installs all packages)
- **Updates**: Script re-runs when `packages.yaml` changes (hash-triggered sync)
- **Timing**: Runs BEFORE file application (ensures Docker, systemd services exist for config scripts)

**Hash-based change detection**: `run_onchange` scripts track content hash. The `{{ .packages | toJson | sha256sum }}` comment triggers re-execution when packages.yaml changes.

### GPU Driver Selection

**Auto-detection**: NVIDIA driver selection based on GPU generation

**Architecture support**:
- **Modern** (nvidia-open-dkms): Turing+ (GTX 16xx, RTX 20xx/30xx/40xx)
- **Legacy** (nvidia-580xx-dkms): Pascal/Maxwell (GTX 9xx/10xx)

**Detection logic** (`.chezmoi.yaml.tmpl`):
1. Check `NVIDIA_DRIVER_OVERRIDE` env var
2. Parse lspci for GPU model
3. Pattern match: GTX 9xx/10xx → legacy, else → modern
4. Default: modern (safe for new systems)

**Package modules** (`packages.yaml`):
- `graphics_drivers_modern`: nvidia-open-dkms, nvidia-utils (enabled by default)
- `graphics_drivers_legacy`: nvidia-580xx-dkms, nvidia-580xx-utils (disabled by default)
- **Dynamic selection**: Sync script enables correct module based on `.nvidiaDriverType`

**Manual override**:
```bash
# Force legacy drivers (Pascal/Maxwell GPUs)
export NVIDIA_DRIVER_OVERRIDE=legacy
chezmoi apply

# Force modern drivers (Turing+ GPUs)
export NVIDIA_DRIVER_OVERRIDE=modern
chezmoi apply

# Clear override (restore auto-detection)
unset NVIDIA_DRIVER_OVERRIDE
chezmoi data | jaq -r '.nvidiaDriverType'  # Verify detection
```

**Migration safety**:
- Interactive prompt before driver changes (integrated in validation script)
- Automatic cleanup of conflicting drivers
- Validation script checks correct driver installed
- Requires reboot after driver change

**Troubleshooting**:
```bash
# Check detection
chezmoi data | jaq -r '.nvidiaDriverType'

# View detected GPU
chezmoi data | jaq -r '.nvidiaGpuDetected'

# Preview which packages will be installed
chezmoi execute-template < .chezmoiscripts/run_onchange_before_sync_packages.sh.tmpl | grep -A5 "NVIDIA"

# Manual fallback
export NVIDIA_DRIVER_OVERRIDE=legacy  # or modern
chezmoi apply
```

**Package manager integration**: Calls `package-manager sync --prune` which handles Arch and Flatpak packages, respects version constraints, handles conflicts, and validates packages.

**Script Numbering**:
- **run_onchange**: No numbering (hash-tracked, order independent)
- **run_once**: Use next available number
- **999**: Reserved for finalization (SSH remote switch)

## Chezmoi Scripts Reference

### Script Types

| Type | Prefix | Purpose | Execution |
|------|--------|---------|-----------|
| Setup | `run_once_before_*` | System preparation | Before file application |
| Configuration | `run_once_after_*` | Service setup | After file application |
| Content-driven | `run_onchange_*` | Data file changes | Hash-triggered |

### Execution Order

1. `run_once_before_*` (000-006)
   - 000: System prerequisites
   - 001: **Hyprland session validation** (prevents crashes)
   - 002-006: Setup tasks
2. `run_onchange_before_*` (sync_packages) - runs on first install AND package changes
3. File application (configs, templates)
4. `run_once_after_*` (001-009, 999)
   - 001-008: Configuration tasks
   - 009: **Hyprland config validation** (post-install safety check)
   - 999: SSH remote switch
5. `run_onchange_after_*` (hash-based, any order)

### Current Scripts (21 total)

**run_once_before_* (7)**:
- 000: Preflight checks (sudo, git, network, pacman)
- 001: Hyprland session validation + NVIDIA driver migration check
- 002: Package manager setup + dependencies (paru, yq, gum)
- 003: Locale configuration
- 004: Directory creation
- 005: Encryption key setup
- 006: chezmoi_modify_manager install

**run_onchange_before_* (1)**:
- sync_packages: Package sync (Arch + Flatpak) - runs on first install AND when packages.yaml changes

**run_once_after_* (10)**:
- 001: CLI generation
- 002: System services
- 003: Network printer
- 004: Git tools
- 005: Wallpaper timer
- 006: Boot system
- 007: Default theme setup
- 008: Darkman service
- 009: Hyprland config validation (syntax, theme, autostart, terminal)
- 999: SSH remote switch

**run_onchange_after_* (4)**:
- install_extensions: VSCode extensions
- install_ai_models: Ollama models
- rebuild_bat_cache: Bat syntax highlighting cache
- update_plymouth_theme: Plymouth theme

### Hash Triggers

Changes to `.chezmoidata/` files trigger specific scripts:
- `packages` → `run_onchange_before_sync_packages.sh.tmpl` (Arch + Flatpak, runs BEFORE file application)
- `extensions.code` → `run_onchange_after_install_extensions.sh.tmpl`
- `ai.models` → `run_onchange_after_install_ai_models.sh.tmpl`

## Chezmoi Templates Reference

### Available Includes

**Log Templates (11)**:
- `log_start`: "🚀 message"
- `log_step`: "→ message"
- `log_success`: "✅ message"
- `log_error`: "❌ message"
- `log_warning`: "⚠️ message"
- `log_info`: "ℹ️ message"
- `log_progress`: "⏳ message"
- `log_debug`: "🐛 message"
- `log_skip`: "⏭️ message"
- `log_complete`: "🎉 message"

**Utility Templates**:


### Usage Patterns

```go
# Basic logging
{{ includeTemplate "log_start" "Installing packages..." }}
{{ includeTemplate "log_step" "Updating pacman cache..." }}
{{ includeTemplate "log_success" "Package installation complete" }}

# Conditional logging
{{ if .condition }}
  {{ includeTemplate "log_step" "Processing..." }}
{{ else }}
  {{ includeTemplate "log_skip" "Skipping..." }}
{{ end }}

# Whitespace control
{{- includeTemplate "log_step" "Processing..." -}}
```

### Template Standards

- **MUST use template logging** (not echo)
- **Control whitespace** with `{{-` and `-}}`
- **Validate syntax**: `chezmoi execute-template < file.tmpl`
- **Test output**: `chezmoi cat path/to/target`

## Quality Standards (MANDATORY)

### Pre-Change Validation

```bash
# 1. Check current state
chezmoi diff

# 2. Check for merge conflicts
chezmoi status

# 3. Dry-run validation
chezmoi apply --dry-run

# 4. Template syntax validation
chezmoi execute-template < template.tmpl

# 5. Script syntax validation
bash -n script.sh.tmpl

# 6. chezmoi_modify_manager validation
chezmoi_modify_manager --help-syntax
chezmoi execute-template < modify_script.tmpl
chezmoi cat path/to/target/file
```

### Never Skip

❌ Run `chezmoi apply` without `chezmoi diff`
❌ Modify templates without syntax validation
❌ Change scripts without testing
❌ Modify chezmoi_modify_manager without validating syntax
❌ Assume chezmoi_modify_manager syntax

### Error Handling

```bash
# Script error handling
set -euo pipefail

# Template error handling
{{ if not .firstname }}
{{   fail "firstname variable is required" }}
{{ end }}

# Safe defaults
{{ $server := .privateServer | default "localhost" }}
```

## Security and Encryption

### Encrypted File Recognition

- Files ending in `.age`
- Files in `private_dot_keys/`
- Files with `encrypted_` prefix
- SSH private keys in `private_dot_ssh/`

### Always Guide Manual Operations

```
🔐 ENCRYPTED FILE DETECTED: [filename]

Sensitive data encrypted with age encryption.

MANUAL ACTION REQUIRED:
1. View: `chezmoi decrypt [filename]`
2. Edit: `chezmoi edit [filename]`
3. Apply: `chezmoi apply`

Cannot access encrypted content for security.
Decrypt manually and provide needed info.
```

## Feature Development Guide

### Implementation Planning

**Setup/Installation**: `.chezmoiscripts/run_once_*` or `run_onchange_*`
**Ongoing maintenance**: CLI functions, manual tools (topgrade, system-maintenance)
**User tools**: CLI functions in `~/.local/bin/` or `~/.local/lib/scripts/`

### Pattern References

**Package management**: Package Management for Development
**Script standards**: Script Standards (MANDATORY)
**CLI tools**: `private_dot_local/CLAUDE.md#cli-architecture`
**Desktop configs**: `private_dot_config/CLAUDE.md` (see subdirectories)
**Shell environment**: `private_dot_config/zsh/CLAUDE.md`

### Hook System (User Extensibility)

**Purpose**: User-extensible event-driven architecture for custom integrations

**Pattern**: Silent hook execution without modifying core scripts

**Hook runner** (`~/.local/lib/scripts/core/hook-runner.sh`):
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

**Integration pattern** (in core scripts):
```bash
# Call hook after operation completes
if [ -f "$HOME/.local/lib/scripts/core/hook-runner.sh" ]; then
    "$HOME/.local/lib/scripts/core/hook-runner.sh" theme-change "$theme_name" 2>/dev/null || true
fi
```

**Available hook points** (6 total):
| Hook | Trigger | Arguments | Use Case |
|------|---------|-----------|----------|
| `theme-change` | theme-switcher.sh | `$theme_name` | Custom app theming (Obsidian, web apps) |
| `package-sync` | package-manager sync | `sync` | Post-install validation, custom setup |
| `wallpaper-change` | set-wallpaper.sh | `$wallpaper_path` | External sync (lockscreen, conky) |
| `dark-mode-change` | darkman scripts | `dark/light` | Web browser themes, external apps |
| `pre-maintenance` | system-maintenance.sh | none | Backup preparation, service stops |
| `post-maintenance` | system-maintenance.sh | `success/failure` | Validation, cleanup, notifications |

**User workflow**:
1. Discovery: `dotfiles-hook-list` (shows available + installed hooks)
2. Creation: `dotfiles-hook-create` (interactive template generator)
3. Testing: Trigger event (e.g., `theme switch <name>`)
4. Version control: `~/.config/dotfiles/hooks/` tracked by chezmoi

**Example hook** (`~/.config/dotfiles/hooks/theme-change`):
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
    *)
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

**See**: `private_dot_local/lib/scripts/CLAUDE.md` for complete hook documentation

### Enhanced Theme Switching

**Extended app coverage** beyond core apps (terminal, waybar, dunst, wofi):

**VSCode** (`theme-apply-vscode.sh`):
- Maps dotfiles theme to VSCode theme extension
- Updates settings.json via jaq
- Silent failure if VSCode not installed

**Firefox** (`theme-apply-firefox.sh`):
- Symlinks userChrome.css from `~/.config/themes/{variant}/`
- Creates chrome/ directory if needed
- Requires `toolkit.legacyUserProfileCustomizations.stylesheets = true`

**Spotify** (`theme-apply-spotify.sh`):
- Maps to spicetify color schemes
- Optional (skips if spicetify-cli not installed)

**Integration**: All theme-apply scripts called by `theme-switcher.sh` after reload_applications()

**Firefox themes**: 8 userChrome.css files in `~/.config/themes/{variant}/` (catppuccin-latte, catppuccin-mocha, rose-pine-dawn, rose-pine-moon, gruvbox-light, gruvbox-dark, solarized-light, solarized-dark)

**See**: `private_dot_config/themes/CLAUDE.md` for theme system architecture
**See**: `private_dot_local/lib/scripts/CLAUDE.md` for theme-apply script details

### Validation Checklist

```bash
chezmoi execute-template < new_template.tmpl
bash -n new_script.sh.tmpl
chezmoi diff && chezmoi apply --dry-run
```

**Requirements**: Syntax valid, patterns followed, security respected

## Merge Conflict Resolution

### Template Variable Protection

**Automated protection prevents template variable rendering during merges.**

**Components**:
- **Git Attributes**: `.gitattributes` configures `*.tmpl merge=chezmoi-template`
- **Custom Merge Driver**: `.template-merge-driver.sh` preserves `{{ .variable }}`
- **Auto-Configuration**: `run_once_after_005_configure_git_tools.sh.tmpl` sets up git config

**How it works**:
1. Git detects `.tmpl` files during merge
2. Custom merge driver prioritizes versions with template syntax
3. Template variables remain as `{{ .variable }}` instead of rendered
4. Falls back to standard merge when both versions have templates

### Safe Merge Workflow

1. **Run checks**: `chezmoi diff` and `chezmoi status`
2. **Merge operations**: `chezmoi merge <file>` or `chezmoi merge-all`
3. **Validation**: Template syntax automatically preserved
4. **Emergency restore**: `git checkout HEAD -- <file>`

### Manual Resolution

1. **Detect conflicts**: `chezmoi status` (look for "M" status)
2. **Resolve conflicts**: `chezmoi merge <file>` or `chezmoi merge-all`
3. **Validate results**: Protection ensures `{{ .variable }}` preserved
4. **Special cases**: Encrypted files (`.age`) require manual workflow

## Emergency Procedures

### If Something Goes Wrong

```bash
# Immediate response
git checkout HEAD~1
chezmoi apply

# Assessment
chezmoi diff
chezmoi status

# Recovery
chezmoi apply specific/file
chezmoi verify
```

### If Merge Conflicts Occur

```bash
# Detection
chezmoi status

# Resolution
chezmoi merge <file>        # Targeted
chezmoi merge-all          # All conflicts

# Validation
chezmoi diff
chezmoi status
```

## Chezmoi Data Files Reference

**Location**: `.chezmoidata/`
**Purpose**: Template data (YAML) for Go templates
**Access**: `{{ .key.subkey }}` in templates
**Trigger**: Changes trigger `run_onchange_*` scripts via hash

### Data Files

| File | Purpose | Template Access |
|------|---------|-----------------|
| `packages.yaml` | Package management (Arch + Flatpak) | `{{ .packages.* }}` |
| `ai.yaml` | AI model configuration | `{{ .ai.* }}` |
| `extensions.yaml` | VSCode extensions | `{{ .extensions.* }}` |
| `globals.yaml` | Global env vars (XDG, apps, boot) | `{{ .globals.* }}` |

**Note**: All color theming now uses the theme system from `~/.config/themes/current/`

### Template Variable Access

**View all data**: `chezmoi data`

**Common patterns**:
```go
# Direct access
{{ .packages.install.arch }}

# Range iteration
{{ range .extensions.code }}
  {{ . }}
{{ end }}

# Nested access
{{ .globals.applications.terminal }}
```

### Hash-Triggered Scripts

Changes to data files trigger specific `run_onchange_*` scripts:
- `packages.install.arch` → `run_onchange_before_install_arch_packages.sh.tmpl`
- `packages.flatpak` → `run_onchange_after_install_flatpak_packages.sh.tmpl`
- `extensions.code` → `run_onchange_after_install_vscode_extensions.sh.tmpl`

**Complete data file documentation**: See sections above

## Documentation Maintenance Protocol

### Update Patterns

**Package additions**:
- Update `.chezmoidata/packages.yaml` only
- No additional documentation needed (self-documenting)

**New script patterns**:
- Update "Script Standards" if introducing new patterns
- Reference actual scripts, don't create inline examples
- Example: "See `run_once_after_005_*.sh.tmpl`"

**New template techniques**:
- Add to "Template System Reference"
- Reference working files: `See: private_dot_config/zsh/dot_zshrc.tmpl`
- Keep inline examples minimal

**chezmoi_modify_manager directives**:
- Update "Directive Reference" table
- Add real-world example reference

**Location-specific docs**:
- Update relevant subdirectory CLAUDE.md files
- Keep root CLAUDE.md for core standards only
- Cross-reference between files

**General principles**:
- ✅ ALWAYS reference working files (not inline examples)
- ✅ Keep docs close to code (single source of truth)
- ✅ Update README.md for user-facing, CLAUDE.md for dev patterns
- ✅ Use location-specific CLAUDE.md for detailed implementation docs
- ❌ NEVER duplicate information
- ❌ NEVER create extensive inline examples

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
