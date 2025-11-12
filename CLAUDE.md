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
│   └── themes/CLAUDE.md                                         # Theme files
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
├── .chezmoitemplates/          # Reusable includes (log_*, arch_linux_check)
├── private_dot_config/         # XDG config (hypr, waybar, wofi, zsh, etc.)
├── private_dot_keys/           # 🔐 Encrypted secrets
├── private_dot_ssh/            # SSH + encrypted keys
└── private_dot_local/
    ├── bin/                    # CLI wrappers (10 executables)
    └── lib/scripts/            # Script library (44 scripts in 8 categories)
```

**See**: Chezmoi Data Files Reference for data file structure
**See**: Chezmoi Scripts Reference for lifecycle script execution
**See**: `private_dot_local/CLAUDE.md` for CLI wrapper architecture
**See**: `private_dot_local/lib/scripts/CLAUDE.md` for script library organization

## Script Library Overview

| Category | Location | Scripts | CLI Wrappers | Purpose |
|----------|----------|---------|--------------|---------|
| Core | `lib/scripts/core/` | 2 | 0 | Foundation libraries (UI, colors) |
| Desktop | `lib/scripts/desktop/` | 16 | 1 | Hyprland utilities |
| System | `lib/scripts/system/` | 6 | 4 | Maintenance & monitoring |
| Media | `lib/scripts/media/` | 3 | 3 | Wallpaper & screenshots |
| UI | `lib/scripts/user-interface/` | 12 | 0 | Menu system |

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

### Gum UI Library Usage

```bash
# Source UI library
. "$UI_LIB"

# Use UI functions (24 functions: status, interactive, layout, data display)
ui_step "Processing task"
ui_success "Task complete"
if ui_confirm "Continue?"; then
    choice=$(ui_choose "Select" "Opt1" "Opt2")
fi
```

**Environment variables** (defined in `.zstyles` via Zephyr):
- `SCRIPTS_DIR="$HOME/.local/lib/scripts"`
- `UI_LIB="$HOME/.local/lib/scripts/core/gum-ui.sh"`

### Anti-Patterns

❌ Wrap scripts in main functions
❌ Use manual echo for logging
❌ Add unnecessary OS detection (Arch Linux only)
❌ Add cross-platform compatibility
❌ Skip gum-ui library (use it for consistency)

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
❌ System updates (use topgrade)
❌ Ongoing maintenance (use systemd timers, CLI tools)
❌ Regular monitoring (use scheduled scripts)
❌ User-initiated tasks (use CLI functions)

### Pre-Commit Checklist

- [ ] `#!/usr/bin/env sh` shebang
- [ ] `{{ includeTemplate "log_start" }}` and `log_complete`
- [ ] `set -euo pipefail` after log_start
- [ ] No `main()` function
- [ ] Uses template logging (not echo)
- [ ] Uses gum-ui library (source `$UI_LIB`)
- [ ] Validated: `bash -n script.sh.tmpl`
- [ ] Tested: `chezmoi execute-template < script.sh.tmpl`

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
{{ includeTemplate "arch_linux_check" . }}

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

**Native Arch** (pacman/yay): CLI tools, system services, dev tools, deep integration
**Flatpak**: Proprietary apps, cross-platform GUI apps, sandboxing

### Strategy Execution (Arch only)
1. Try `pacman` (official repos)
2. Try `yay_bin` (AUR precompiled)
3. Try `yay_source` (AUR from source)

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

1. **`run_once_before_*`** → Setup (package managers, dirs, tools)
2. **`run_onchange_before_install_arch_packages.sh.tmpl`** → Arch packages (hash-triggered, cascade removal)
3. **File application** → chezmoi applies configs
4. **`run_once_after_*`** → Configuration (services, setup)
5. **`run_onchange_*`** → Content-driven (data file changes)
6. **`run_onchange_after_install_flatpak_packages.sh.tmpl`** → Flatpak apps (hash-triggered)

**Hash-based change detection**: Each `run_onchange` script has unique hash based on specific data section. Arch/Flatpak/Extensions changes trigger only relevant scripts.

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

1. `run_once_before_*` (001-007)
2. File application (configs, templates)
3. `run_once_after_*` (001-007, 999)
4. `run_onchange_*` (hash-based, any order)

### Current Scripts (21 total)

**run_once_before_* (7)**:
- 001: Package manager setup
- 002: Directory creation
- 003: OS-specific packages
- 004: Encryption key setup
- 005: chezmoi_modify_manager install
- 006: Maintenance user creation
- 007: Locale configuration

**run_once_after_* (8)**:
- 001: CLI generation
- 002: System services
- 003: Network printer
- 004: Topgrade system
- 005: Git tools
- 006: Wallpaper timer
- 007: Boot system
- 999: SSH remote switch

**run_onchange_* (6)**:
- before_install_arch_packages: Arch package installation
- after_install_flatpak_packages: Flatpak app installation
- after_install_extensions: VSCode extensions
- after_install_ai_models: Ollama models
- after_update_plymouth_theme: Plymouth theme
- after_update_topgrade_config: Topgrade config

### Hash Triggers

Changes to `.chezmoidata/` files trigger specific scripts:
- `packages.install.arch` → `run_onchange_before_install_arch_packages.sh.tmpl`
- `packages.flatpak` → `run_onchange_after_install_flatpak_packages.sh.tmpl`
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
- `arch_linux_check`: OS validation

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
**Ongoing maintenance**: CLI functions, systemd timers, topgrade integration
**User tools**: CLI functions in `~/.local/bin/` or `~/.local/lib/scripts/`

### Pattern References

**Package management**: Package Management for Development
**Script standards**: Script Standards (MANDATORY)
**CLI tools**: `private_dot_local/CLAUDE.md#cli-architecture`
**Desktop configs**: `private_dot_config/CLAUDE.md` (see subdirectories)
**Shell environment**: `private_dot_config/zsh/CLAUDE.md`

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
| `colors.yaml` | Oksolar color scheme | `{{ .colors.* }}` |
| `globals.yaml` | Global env vars (XDG, apps, boot) | `{{ .globals.* }}` |

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
