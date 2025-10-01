# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a sophisticated chezmoi dotfiles repository that manages personal configuration files across systems. The repository implements comprehensive templating, encryption, and automated maintenance systems designed for Arch Linux development workstations.

**System Configuration**: This repository is configured as a comprehensive system with all packages, services, and extensions installed. The architecture has been simplified from destination-based profiles to a single comprehensive deployment.

### Repository Architecture

This is a comprehensive chezmoi dotfiles repository with:
- **Advanced templating**: Go text/template with custom functions
- **Age encryption**: Secure handling of sensitive files
- **chezmoi_modify_manager integration**: Smart configuration file management

## 🚨 CRITICAL SAFETY PROTOCOLS 🚨

### **NEVER** Attempt These Operations
❌ **NEVER** decrypt encrypted files programmatically  
❌ **NEVER** read contents of `.age` files  
❌ **NEVER** access encryption keys directly  
❌ **NEVER** modify encryption configuration without explicit user guidance  
❌ **NEVER** bypass security protocols for "convenience"  

### **ALWAYS** Guide Manual Encryption Operations
```bash
# Guide user to run manually:
chezmoi decrypt path/to/encrypted_file.age    # To view
chezmoi edit path/to/encrypted_file.age       # To edit
chezmoi add --encrypt path/to/sensitive_file  # To encrypt
```

## Architecture and Structure

### Chezmoi Template System
- **Template files**: `.tmpl` extension processed with Go text/template
- **Naming conventions**:
  - `private_dot_*` → private files (e.g., `private_dot_config/` → `~/.config/`)
  - `encrypted_*` → age-encrypted files
  - `modify_*` → chezmoi_modify_manager processed files
  - `run_once_*` → lifecycle scripts run once
  - `run_onchange_*` → scripts run when content changes

### Template Variables
```go
# Built-in chezmoi variables
{{ .chezmoi.os }}              # Operating system
{{ .chezmoi.arch }}            # Architecture
{{ .chezmoi.hostname }}        # System hostname
{{ .chezmoi.username }}        # Current user
{{ .chezmoi.sourceDir }}       # Source directory path
{{ .chezmoi.homeDir }}         # Home directory path

# User-defined variables (from .chezmoi.yaml.tmpl)
{{ .fullname }}                # Full name
{{ .firstname }}               # First name only  
{{ .workEmail }}              # Work email address
{{ .personalEmail }}          # Personal email address
{{ .privateServer }}          # Private server URL
{{ .chassisType }}            # Chassis type from hostnamectl (laptop/desktop)

# Data from .chezmoidata/ files (YAML becomes nested objects)
{{ .packages.install.arch }}  # Package data
{{ .colors.oksolar.base03 }}  # Color definitions
{{ .extensions.code }}        # Extension lists
```

### Standard Template Patterns
```go
# OS Detection
{{ includeTemplate "arch_linux_check" . }}

# Logging (MUST use these instead of echo)
{{ includeTemplate "log_start" "message" }}     # 🚀 Start
{{ includeTemplate "log_step" "message" }}      # 📋 Steps  
{{ includeTemplate "log_success" "message" }}   # ✅ Success
{{ includeTemplate "log_error" "message" }}     # ❌ Errors
{{ includeTemplate "log_complete" "message" }}  # 🎉 Complete

# Advanced Template Syntax (Go text/template + Sprig functions)
{{ if eq .chezmoi.os "linux" }}                 # Conditional logic
{{ if and (eq .chezmoi.os "linux") (ne .workEmail "") }}  # Chained operators
{{ .firstname | lower }}                        # String transformations
{{ .privateServer | replace "www" "nextcloud" }} # String replacement
{{ range .extensions.code }}                    # Iteration over arrays
{{ end }}
{{ $server := .privateServer | default "localhost" }}  # Variable assignment with defaults

# Whitespace control
{{- includeTemplate "log_step" "message" -}}

# Testing templates
# Use: chezmoi execute-template < template.tmpl
# View data: chezmoi data
```

## Core System Components

### Data Files Structure (.chezmoidata/)
```
.chezmoidata/
├── packages.yaml      # Package management with install strategies
├── ai.yaml           # AI models configuration
├── extensions.yaml   # VSCode extensions list
├── colors.yaml       # Color scheme definitions (oksolar)
└── globals.yaml      # Global environment variables (XDG paths)
```

**Key Concepts:**
- **Install Strategies**: `_install_binary`, `_install_from_source` with fallback chains
- **Package Categories**: fonts, terminal_essentials, development_tools, ai_tools, etc.
- **Strategy Chains**: `[pacman, yay_bin, yay_source]` for robust package installation
- **Complete Installation**: All package categories installed for comprehensive development setup

### Lifecycle Scripts (.chezmoiscripts/) - SETUP ONLY
```
.chezmoiscripts/
├── run_once_before_001_install_package_manager.sh.tmpl
├── run_once_before_002_write_globals.sh.tmpl
├── run_once_before_003_create_necessary_directories.sh.tmpl
├── run_once_before_004_install_distributions_and_os_specifics.sh.tmpl
├── run_once_before_005_instantiate_encryption_key.sh.tmpl
├── run_once_before_006_install_chezmoi_modify_manager.sh.tmpl
├── run_once_before_007_install_arch_packages.sh.tmpl
├── run_once_before_008_create_maintenance_user.sh.tmpl
├── run_once_after_001_generate_and_config_cli.sh.tmpl
├── run_once_after_002_enable_services.sh.tmpl
├── run_once_after_003_setup_network_printer.sh.tmpl
├── run_once_after_004_setup_topgrade_system.sh.tmpl
├── run_once_after_005_configure_template_merge_driver.sh.tmpl
├── run_once_after_006_configure_ollama.sh.tmpl
├── run_once_after_999_switch_to_ssh_remote.sh.tmpl
├── run_onchange_before_create_git_hooks.sh.tmpl
├── run_onchange_after_install_extensions.sh.tmpl
└── run_onchange_after_install_ai_models.sh.tmpl
```

**🚨 CRITICAL: Script Purpose Distinction**

**`.chezmoiscripts/` are for SETUP and CONFIGURATION ONLY:**
- `run_once_*` → **Initial system setup** (run only once during bootstrap)
- `run_onchange_*` → **Configuration updates** (when dotfiles content changes)
- **❌ NEVER for ongoing system maintenance** - that's handled by other tools

**System maintenance is handled by separate tools** (see System Maintenance Architecture below).

**Script Execution Order:**
1. `run_once_before_*` → Setup (package managers, directories, tools)
2. File application → chezmoi applies all configuration files
3. `run_once_after_*` → Configuration (services, final setup)
4. `run_onchange_*` → Content-driven (when data files change)

### Template System (.chezmoitemplates/)
```
.chezmoitemplates/
├── log_start          # 🚀 Script start logging
├── log_step           # 📋 Major step logging
├── log_success        # ✅ Success logging
├── log_error          # ❌ Error logging
└── log_complete       # 🎉 Completion logging
```

**Template Functions:**
- **Logging**: `{{ includeTemplate "log_start" "message" }}`
- **Error Handling**: Use standard shell error handling with `set -euo pipefail`

### Configuration Organization
- **`private_dot_config/`** - XDG config directory contents
- **`private_dot_keys/`** - Encrypted keys and secrets (🔐 NEVER access directly)
- **`private_dot_ssh/`** - SSH configuration and encrypted keys

## Shell Initialization Architecture

This repository implements a sophisticated multi-shell initialization system that provides consistent environment setup across sh, bash, and zsh in all execution modes (interactive, non-interactive, login).

### **Core Architecture Pattern**

#### **Layer 1: Common Shell Configuration (`private_dot_config/shell/`)**
- **`shell/env`** - Core environment setup, sets ENV/BASH_ENV variables, sources `env_functions`
- **`shell/env_functions`** - POSIX shell functions available to all shells (e.g., `system_health_simple()`, `system_maintenance_simple()`)
- **`shell/interactive`** - Common interactive shell configuration
- **`shell/login`** - Login shell environment variables (EDITOR, VISUAL, BROWSER, etc.)
- **`shell/logout`** - Logout cleanup (clears console for privacy)

#### **Layer 2: Shell-Specific Adapters (Complete Symmetry)**

Each shell follows the same delegation pattern where shell-specific files source common `shell/` files:

**Bash:**
- **`dot_bash_profile`** - Complex bash login setup with BASH_ENV management
- **`dot_bashrc`** - Sources `bash/env` + `bash/interactive`
- **`bash/env`** → sources `shell/env`
- **`bash/interactive`** → sources `shell/interactive`
- **`bash/login`** → sources `shell/login`
- **`bash/logout`** → sources `shell/logout`

**Zsh:**
- **`dot_zshenv`** - Sources `zsh/env`, sets ZDOTDIR
- **`zsh/env`** → sources `shell/env`
- **`zsh/dot_zlogin`** → sources `shell/login`
- **`zsh/dot_zlogout`** → sources `shell/logout`
- **`zsh/dot_zshrc`** - Zsh interactive setup with antidote plugins
- **`zsh/dot_zfunctions/`** - Zsh-specific interactive functions

**POSIX Shell:**
- **`dot_profile`** - Sources `sh/env` + `sh/login` (for sh-compatible login shells)
- **`sh/env`** → sources `shell/env`
- **`sh/interactive`** → sources `shell/interactive`
- **`sh/login`** → sources `shell/login`

### **Environment Variables Set by `shell/env`:**
```bash
ENV=$HOME/.config/sh/interactive      # For sh interactive shells
BASH_ENV=$HOME/.config/bash/env      # For bash non-interactive shells
```

These enable automatic loading of appropriate shell configurations in different execution contexts.

### **Function Architecture**

#### **POSIX Functions (`shell/env_functions`):**
- **Purpose**: Automation, scripts, systemd services, topgrade integration
- **Examples**: `system_health_simple()`, `system_maintenance_simple()`
- **Features**: Simple ANSI output, no dependencies, fast execution
- **Loaded by**: All shells via `shell/env`
- **Usage**: `system_health_simple --brief`, `system_maintenance_simple --cleanup`

#### **Interactive Functions (`zsh/dot_zfunctions/`):**
- **Purpose**: Rich terminal interaction
- **Examples**: `system-health`, `system-maintenance`
- **Features**: Gum-based UI, interactive menus, progress spinners, tables
- **Loaded by**: Zsh autoload mechanism
- **Usage**: Direct terminal commands with full interactive experience

### **Execution Flow by Context**

#### **Login Shells:**
- **Bash**: `.bash_profile` → `bash/env` → `shell/env` → `env_functions` ✅
- **POSIX**: `.profile` → `sh/env` + `sh/login` → `shell/env` + `shell/login` ✅
- **Zsh**: `.zshenv` → `zsh/env` → `shell/env` → `env_functions` ✅

#### **Non-Interactive Shells (systemd, topgrade, scripts):**
- **Bash**: `$BASH_ENV` → `bash/env` → `shell/env` → `env_functions` ✅
- **Zsh**: `.zshenv` → `zsh/env` → `shell/env` → `env_functions` ✅
- **POSIX**: Direct sourcing in scripts as needed

#### **Interactive Shells:**
- **Bash**: `.bashrc` → `bash/env` + `bash/interactive` → `shell/env` + `shell/interactive` ✅
- **Zsh**: `.zshenv` + `ZDOTDIR/.zshrc` → loads both POSIX and zsh functions ✅

### **Key Benefits**
- **Universal Consistency**: Same functions available across all shells
- **Separation of Concerns**: POSIX functions for automation, rich functions for interaction
- **Architecture Symmetry**: Each shell follows identical delegation patterns
- **Reliable Automation**: Non-interactive shells get consistent environment
- **Rich UX**: Interactive shells get enhanced functionality

### **Integration with Topgrade**
The system enables topgrade to use POSIX functions for system health monitoring:
```toml
"System health check" = "-i source ~/.config/zsh/env && system_health_simple --brief"
```

This architecture ensures that maintenance tools work reliably in all execution contexts while providing rich interactive experiences when used directly.

## System Maintenance Architecture

**🔧 System Maintenance (NOT chezmoi scripts):**

#### **CLI Functions** (`private_dot_config/zsh/dot_zfunctions/`)
```
dot_zfunctions/
├── system-health       # System status dashboard
├── check-packages      # Package health monitoring
├── backup-system       # Manual system backup
├── security-scan       # Security audit tools
├── db-init             # Database initialization
├── proj-switch         # Project management
└── service-check       # Service status tools
```

#### **Standalone Scripts** (`private_dot_config/scripts/`)
```
scripts/
├── maintenance/
│   ├── system-cleanup.sh
│   ├── package-health.sh
│   └── security-audit.sh
├── backup/
│   ├── create-backup.sh
│   └── restore-backup.sh
└── monitoring/
    ├── health-monitor.sh
    └── alert-system.sh
```

#### **Systemd Timers** (Setup by chezmoi, run independently)
```bash
# User timers: ~/.config/systemd/user/
backup.timer              # Automated backups
security-audit.timer      # Security scans
package-health.timer      # Package monitoring

# System timers: /etc/systemd/system/ (configured by chezmoi)
topgrade.timer           # System updates
```

#### **Topgrade Integration** (`private_dot_config/topgrade.toml.tmpl`)
```toml
[commands]
"System Health Check" = "system-health --brief"
"Package Health" = "check-packages --report"
"Security Status" = "security-scan --quick"
"Pre-backup" = "backup-system --pre-update"
```

**🎯 Key Principle: Separation of Concerns**
- **chezmoi**: Deploys and configures maintenance tools
- **topgrade**: Handles system updates and upgrades  
- **systemd**: Schedules automated maintenance tasks
- **CLI tools**: Provide manual maintenance capabilities
- **Scripts**: Execute complex maintenance workflows

### Development Environment
- **Languages**: Go, Python, Rust (managed via mise)
- **Tools**: Docker, VSCode, Git (delta, mergiraf)
- **Terminal**: Zsh + antidote, enhanced CLI tools (ripgrep, fd, fzf, etc.)
- **Theme**: Consistent Solarized (oksolar) color scheme

## Package Management System

### **MUST** Understand Installation Strategies
This repository uses sophisticated package management with fallback chains:

```yaml
strategies:
  _install_binary: &_install_binary [pacman, yay_bin]
  _install_from_source: &_install_from_source [pacman, yay_bin, yay_source]
```

**Strategy Execution:**
1. Try `pacman` (official repos)
2. Try `yay_bin` (AUR precompiled)  
3. Try `yay_source` (AUR from source)

### **System Configuration**
The system is configured as a comprehensive development environment with:

- **All package categories**: Complete development stack with tools and general applications
- **System-level services**: Docker, Snap, Bluetooth, and topgrade automation enabled
- **Extensions**: VSCode extensions automatically installed

### Package Categories
- **fonts**: Programming fonts (FiraCode, Geist Mono, etc.)
- **terminal_essentials**: Core CLI tools (ripgrep, fd, bat, fzf, etc.)
- **terminal_utils**: System monitoring (btop, nvitop, fastfetch, etc.)
- **languages**: Programming languages (Go, Python, Rust)
- **development_tools**: Development software (Docker, VSCode)
- **ai_tools**: AI/ML tools
- **general_software**: End-user apps (Firefox, Spotify, Nextcloud)
- **work_software**: Work-specific (Chromium, Slack)

### **CRITICAL** Package Installation Flow
1. **Setup Phase**: `run_once_before_*` installs package managers (yay, chaotic-aur)
2. **Package Phase**: `run_once_before_007_install_arch_packages.sh.tmpl` processes all package categories
3. **Services Phase**: `run_once_after_002_enable_services.sh.tmpl` enables Docker, Snap, and Bluetooth
4. **System Maintenance**: `run_once_after_004_setup_topgrade_system.sh.tmpl` configures sudoers and enables topgrade automation
5. **Extension Phase**: `run_onchange_after_install_extensions.sh.tmpl` installs VSCode extensions
6. **AI Models**: `run_onchange_after_install_ai_models.sh.tmpl` installs Ollama AI models

## Common Commands

### Chezmoi Management
```bash
# MANDATORY: Always run before changes
chezmoi diff                    # Preview changes
chezmoi apply --dry-run        # Test without applying

# Daily operations  
chezmoi apply -v               # Apply changes (verbose)
chezmoi status                 # Check status
chezmoi edit <file>            # Edit managed files
chezmoi add <file>             # Add new files

# Merge conflict resolution
chezmoi merge <file>           # Resolve specific file
chezmoi merge-all             # Resolve all conflicts
```

### System Maintenance - NOT Chezmoi's Responsibility
```bash
# Automated updates (configured via systemd at system level)
topgrade                       # Comprehensive system updates
sudo systemctl enable topgrade.timer

# Package management
yay -Syu                      # Update Arch packages + AUR
mise install                  # Install tool versions

# Manual maintenance tools (CLI functions)
system-health                 # Custom system health check
check-packages               # Package health monitoring
backup-system               # Manual system backup
security-scan               # Manual security audit
```

See **System Maintenance Architecture** section for complete maintenance tool organization.

## Script Standards (MANDATORY)

### **MUST** Follow This Exact Structure
```bash
#!/bin/sh

# Script: [filename]
# Purpose: [clear description]  
# Requirements: Arch Linux, [dependencies]

{{ includeTemplate "log_start" "[description]" }}

# Set strict error handling
set -euo pipefail

# Script implementation (NO main function)
# Use log templates for ALL output

{{ includeTemplate "log_complete" "[completion message]" }}
```

### **NEVER** Use These Anti-Patterns
❌ **NEVER** wrap scripts in main functions  
❌ **NEVER** use manual echo for logging  
❌ **NEVER** add unnecessary OS detection (system assumes Arch Linux)  
❌ **NEVER** add cross-platform compatibility (focused on Arch Linux only)  

### **ALWAYS** Trust Script Execution Order
Scripts execute in order: `run_once_before_*` → file application → `run_once_after_*` → `run_onchange_*`
Trust that previous scripts succeeded (chezmoi stops if they fail).

### **CRITICAL** Script Usage Guidelines

#### **DO Use .chezmoiscripts/ For:**
✅ **Initial system setup**: Installing package managers, creating directories  
✅ **Tool installation**: Installing packages, configuring services  
✅ **Configuration setup**: Setting up systemd timers, configuring tools  
✅ **Dotfiles-driven changes**: Updates when template data changes  

#### **DO NOT Use .chezmoiscripts/ For:**
❌ **System updates**: Use topgrade for package updates  
❌ **Ongoing maintenance**: Use systemd timers and CLI tools  
❌ **Regular monitoring**: Use scheduled scripts, not chezmoi  
❌ **User-initiated tasks**: Use CLI functions and standalone scripts  

#### **Alternative Implementation Patterns:**

**For System Monitoring:**
```bash
# WRONG: .chezmoiscripts/run_onchange_system_health.sh.tmpl
# RIGHT: private_dot_config/zsh/dot_zfunctions/system-health
# RIGHT: Add to topgrade.toml.tmpl custom commands
```

**For Backup Tasks:**
```bash
# WRONG: .chezmoiscripts/run_onchange_backup.sh.tmpl
# RIGHT: ~/.config/systemd/user/backup.timer (setup by chezmoi)
# RIGHT: private_dot_config/zsh/dot_zfunctions/backup-now
```

**For Package Maintenance:**
```bash
# WRONG: .chezmoiscripts/run_onchange_package_health.sh.tmpl
# RIGHT: topgrade.toml.tmpl custom commands
# RIGHT: private_dot_config/zsh/dot_zfunctions/check-packages
```

## chezmoi_modify_manager Integration

### Understanding the Problem
**chezmoi_modify_manager** is a specialized addon for handling configuration files that contain **mixed settings and state**. Many applications (KDE, Nextcloud, PrusaSlicer) store both:
- **Settings**: User preferences that should be managed in dotfiles
- **State**: Runtime data (window positions, cache, session info) that changes frequently

**The core issue**: Traditional dotfiles management treats these as single units, causing constant churn from state changes. chezmoi_modify_manager intelligently separates concerns.

### File Patterns
- **`modify_*.tmpl`** - Processing script files
- **`*.src.ini`** - Source files with only managed settings

### How chezmoi_modify_manager Works
1. **Reads current application config** (the file with mixed settings/state)
2. **Loads managed settings** from corresponding `.src.ini` file
3. **Applies modification directives** (ignore, set, transform)
4. **Merges intelligently** - keeps managed settings, preserves runtime state
5. **Writes processed config** back to application

### Core Directives

#### `source auto`
```bash
#!/usr/bin/env chezmoi_modify_manager
source auto  # Automatically finds corresponding .src.ini file
```

#### `ignore` - Filter Out State Data
```bash
# Ignore specific keys
ignore "General" "ColorSchemeHash"           # Single key
ignore "KFileDialog Settings" "Show hidden files"

# Ignore entire sections
ignore section "DirSelect Dialog"            # Runtime window state
ignore section "Cache"                       # Temporary data

# Ignore with regex patterns
ignore regex "General" "clientVersion|lastSync"
ignore regex "Accounts" ".*version|.*journalPath|.*server.*"
```

#### `set` - Force Specific Values (Template Integration)
```bash
# Set user-specific values using chezmoi templates
set "User" "Name" "{{ .fullname }}"
set "User" "Email" "{{ .personalEmail }}"
set "Paths" "Home" "/home/{{ .firstname | lower }}"

# Template transformations
{{ $nextcloudServer := .privateServer | replace "www" "nextcloud" }}
set "Server" "URL" "{{ $nextcloudServer }}"

# Conditional settings (based on hostnamectl chassis detection)
{{ if eq .chassisType "laptop" }}
set "Power" "SuspendOnLidClose" "true"
{{ else }}
set "Power" "SuspendOnLidClose" "false"
{{ end }}
```

#### `add:remove` and `add:hide` - Smart Re-add Control
```bash
# Remove from source when re-adding (since we set them dynamically)
add:remove "User" "Name"
add:remove "Paths" "Home"
add:remove "Server" "URL"

# Hide sensitive values when adding back to source
add:hide "Accounts" "0\\password"
add:hide "Auth" "token"
```

### Advanced Features

#### Value Transformations
```bash
# Keyring password lookup
set "Database" "Password" "{{ keyring "service" "username" }}"

# Ignore list sorting order (for lists that change order frequently)
ignore_order "Plugins" "LoadOrder"
```

#### Self-Updater Support
```bash
# Enable automatic updates of chezmoi_modify_manager
self_update enable

# Check for updates but don't auto-install
self_update check
```

### Best Practices for chezmoi_modify_manager

#### **MUST** Follow These Patterns
1. ✅ **Use `source auto`** - Automatically finds corresponding `.src.ini` files
2. ✅ **Ignore runtime state** - Filter out window positions, cache, temporary data
3. ✅ **Set user-specific values** - Use chezmoi templates for personalization
4. ✅ **Remove dynamic values from source** - Use `add:remove` for template-set values
5. ✅ **Hide sensitive data** - Use `add:hide` for passwords and tokens

#### **SHOULD** Consider These Practices
1. ✅ **Group related ignores** - Organize ignore statements by functionality
2. ✅ **Use regex for patterns** - Efficiently ignore multiple similar keys
3. ✅ **Document complex logic** - Add comments explaining why specific ignores are needed
4. ✅ **Test modifications** - Use `chezmoi cat` to preview results before applying
5. ✅ **Handle edge cases** - Consider what happens when applications update their config format

#### **NEVER** Do These Things
1. ❌ **Never ignore critical settings** - Only ignore state data, not user preferences
2. ❌ **Never set hardcoded values** - Use template variables for user-specific data
3. ❌ **Never modify without testing** - Always validate with `chezmoi cat` first
4. ❌ **Never commit sensitive data** - Use `add:hide` for passwords and tokens
5. ❌ **Never assume config structure** - Test with actual application config files

## Quality Standards (MANDATORY)

### **CRITICAL** Pre-Change Validation
```bash
# 1. MANDATORY: Check current state
chezmoi diff

# 2. MANDATORY: Check for merge conflicts  
chezmoi status

# 3. MANDATORY: Dry-run validation
chezmoi apply --dry-run

# 4. MANDATORY: Template syntax validation
chezmoi execute-template < template_file.tmpl

# 5. MANDATORY: Script syntax validation
bash -n script_file.sh.tmpl

# 6. MANDATORY: chezmoi_modify_manager validation (if applicable)
chezmoi_modify_manager --help-syntax                 # Check syntax reference
chezmoi execute-template < modify_script.tmpl        # Test template processing
chezmoi cat path/to/target/file                      # Preview merged result
```

### **NEVER** Skip These Steps
❌ **NEVER** run `chezmoi apply` without first running `chezmoi diff`  
❌ **NEVER** modify templates without syntax validation  
❌ **NEVER** change scripts without testing logic  
❌ **NEVER** modify chezmoi_modify_manager scripts without validating syntax first  
❌ **NEVER** assume chezmoi_modify_manager syntax without checking documentation  

### Error Handling Standards
```bash
# Script error handling
set -euo pipefail

# Template error handling
{{ if not .firstname }}
{{   fail "firstname variable is required" }}
{{ end }}

# Use safe defaults
{{ $server := .privateServer | default "localhost" }}
```

## Security and Encryption

### Encrypted File Recognition
- Files ending in `.age`
- Files in `private_dot_keys/` directory  
- Files with `encrypted_` prefix
- SSH private keys in `private_dot_ssh/`

### **ALWAYS** Guide Manual Operations
```
🔐 ENCRYPTED FILE DETECTED: [filename]

This file contains sensitive data encrypted with age encryption.

MANUAL ACTION REQUIRED:
1. To view: `chezmoi decrypt [filename]`
2. To edit: `chezmoi edit [filename]`  
3. To apply changes: `chezmoi apply`

I cannot access encrypted content for security reasons.
Please decrypt manually and provide the information needed.
```

## Feature Development Guide

### Development Workflow

#### Planning Phase
1. **Determine implementation type** ⚠️ **CRITICAL DECISION**:
   - **Setup/Installation**: Use `.chezmoiscripts/run_once_*` or `run_onchange_*`
   - **Ongoing maintenance**: Use CLI functions, systemd timers, or topgrade integration
   - **User tools**: Create CLI functions in `private_dot_config/zsh/dot_zfunctions/`
   - **Complex workflows**: Create standalone scripts in `private_dot_config/scripts/`

#### Implementation Patterns

##### Adding New Packages
```yaml
# In .chezmoidata/packages.yaml
new_category:
  strategy: *_install_from_source  # or *_install_binary
  list: [package-name, another-package]
```

##### Creating New Scripts
**Naming**: `run_[frequency]_[timing]_[order]_[description].sh.tmpl`

**Template Structure** (see Script Standards section for complete template):
```bash
#!/bin/sh
{{ includeTemplate "log_start" "Description..." }}
set -euo pipefail
# Implementation
{{ includeTemplate "log_complete" "Completion message" }}
```

#### Validation (see Quality Standards for complete procedures)
```bash
chezmoi execute-template < new_template.tmpl  # Template syntax
bash -n new_script.sh.tmpl                    # Script syntax
chezmoi diff && chezmoi apply --dry-run       # Preview changes
```

### Common Development Patterns

**New Package**: Add to `packages.yaml` → system auto-includes in installation
**New Config**: Use templates in `private_dot_config/` with template variables
**Mixed State/Settings**: Use `chezmoi_modify_manager` pattern (see section above)
**New Script**: Follow naming convention and Script Standards template

### Development Best Practices

**MUST Follow**:
- Start with smallest change, validate incrementally
- Use existing patterns and template variables
- Never skip syntax validation or bypass security protocols

**Key Principles**:
- Test individual components before integration
- Document decisions and consider security implications
- Use template variables, never hardcode user-specific values

### Development Checklist
1. Validated all syntax (templates, scripts, YAML)?
2. Tested with `chezmoi diff` and `--dry-run`?
3. Followed established patterns and conventions?
4. Documented feature and integration points?
5. Respected security protocols and encryption boundaries?

### Merge Conflict Resolution

#### **✅ Template Variable Protection (ACTIVE)**
**Automated protection system prevents template variable rendering during merge operations.**

**System Components:**
- **Git Attributes** - `.gitattributes` configures `*.tmpl merge=chezmoi-template`
- **Custom Merge Driver** - `.template-merge-driver.sh` intelligently preserves `{{ .variable }}` syntax
- **Auto-Configuration** - `run_once_after_005_configure_template_merge_driver.sh.tmpl` sets up git config

**How Protection Works:**
1. Git detects `.tmpl` files during merge operations
2. Custom merge driver prioritizes versions containing template syntax
3. Template variables remain as `{{ .variable }}` instead of being rendered
4. Only falls back to standard merge when both versions have templates

#### **Safe Merge Workflow**
1. **Run checks** - `chezmoi diff` and `chezmoi status`
2. **Merge operations** - `chezmoi merge <file>` or `chezmoi merge-all` (now safer with protection)
3. **Validation** - Template syntax automatically preserved by merge driver
4. **Emergency restore** - `git checkout HEAD -- <file>` if manual intervention needed

#### **Manual Resolution Steps**
1. **Detect conflicts** - `chezmoi status` (look for "M" status)
2. **Resolve conflicts** - Use `chezmoi merge <file>` or `chezmoi merge-all` with confidence
3. **Validate results** - Protection system ensures `{{ .variable }}` syntax preserved
4. **Special cases** - Encrypted files (`.age`) still require manual workflow

For complete validation procedures, see **Quality Standards** section above.


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

---

## Summary

This chezmoi dotfiles repository provides:
- **Comprehensive system management** for Arch Linux development workstations
- **Security-first approach** with age encryption and manual operation guidance  
- **Separation of concerns** between setup (chezmoi scripts) and maintenance (external tools)
- **Template-driven configuration** with robust validation procedures

**Key Principle**: Always validate before applying changes. When in doubt, guide users through manual processes rather than automated solutions.