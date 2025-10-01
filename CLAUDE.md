# CLAUDE.md

This file provides technical guidance to Claude Code (claude.ai/code) when developing code in this repository.

## Quick Reference

- **Project Type**: Chezmoi dotfiles repository
- **Target OS**: Arch Linux only (no cross-platform code)
- **Primary Languages**: Go templates (text/template + Sprig), Shell scripts (POSIX sh)
- **Key Constraint**: Security-first approach with manual encryption operations
- **Documentation**: See README.md for installation, usage, and system architecture

## 🚨 CRITICAL SAFETY PROTOCOLS

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

## Architecture Quick Reference

### File Naming Conventions

- **`private_dot_*`** → Private files (e.g., `private_dot_config/` → `~/.config/`)
- **`encrypted_*`** → Age-encrypted files
- **`executable_*`** → Executable scripts
- **`modify_*`** → chezmoi_modify_manager processed files
- **`run_once_*`** → Lifecycle scripts run once during setup
- **`run_onchange_*`** → Scripts run when content changes
- **`*.tmpl`** → Template files processed with Go text/template

### Repository Structure

```
.chezmoidata/           # Template data sources (YAML)
.chezmoiscripts/        # Setup and configuration scripts
.chezmoitemplates/      # Reusable template includes
private_dot_config/     # XDG config directory contents
private_dot_keys/       # Encrypted keys and secrets (🔐 NEVER access)
private_dot_ssh/        # SSH configuration and encrypted keys
```

### Data Files (.chezmoidata/)

```
.chezmoidata/
├── packages.yaml      # Package management with install strategies
├── ai.yaml           # AI models configuration
├── extensions.yaml   # VSCode extensions list
├── colors.yaml       # Color scheme definitions (oksolar)
└── globals.yaml      # Global environment variables (XDG paths)
```

## Template System Reference

### Quick Command Reference

| Task                   | Command                                | Purpose                     |
| ---------------------- | -------------------------------------- | --------------------------- |
| Test template syntax   | `chezmoi execute-template < file.tmpl` | Validate Go template syntax |
| View available data    | `chezmoi data`                         | See all template variables  |
| Preview file output    | `chezmoi cat path/to/file`             | See final rendered result   |
| Validate script syntax | `bash -n script.sh.tmpl`               | Check shell script syntax   |
| Test modify_manager    | `chezmoi cat path/to/target`           | Preview merged config       |
| Check modify syntax    | `chezmoi_modify_manager --help-syntax` | View directive reference    |

### Template Variables

**Built-in (chezmoi):**

- `.chezmoi.os` - Operating system (e.g., "linux")
- `.chezmoi.arch` - Architecture (e.g., "amd64")
- `.chezmoi.hostname` - System hostname
- `.chezmoi.username` - Current user
- `.chezmoi.sourceDir` - Chezmoi source directory
- `.chezmoi.homeDir` - Home directory path

**User-defined (.chezmoi.yaml.tmpl):**

- `.fullname` - Full name for git config
- `.firstname` - First name only
- `.workEmail` / `.personalEmail` - Email addresses
- `.privateServer` - Private server URL
- `.chassisType` - System type from hostnamectl (laptop/desktop)

**Data files (.chezmoidata/):**

- `.packages.install.arch` - Package lists from packages.yaml
- `.colors.oksolar.*` - Color definitions from colors.yaml
- `.extensions.code` - Extension arrays from extensions.yaml

**Usage examples:**

```go
{{ .chezmoi.os }}              # "linux"
{{ .firstname | lower }}       # String transformations
{{ .packages.install.arch }}   # Accessing nested data
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

### Template Includes (.chezmoitemplates/)

```
.chezmoitemplates/
├── log_start          # 🚀 Script start logging
├── log_step           # 📋 Major step logging
├── log_success        # ✅ Success logging
├── log_error          # ❌ Error logging
└── log_complete       # 🎉 Completion logging
```

## Script Standards (MANDATORY)

### **MUST** Follow This Exact Structure

```bash
#!/usr/bin/env sh

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

Trust that previous scripts succeeded (chezmoi stops if they fail). Don't add redundant checks.

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

#### **Alternative Implementation Patterns**

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

### Pre-Commit Script Checklist

Before committing any new or modified scripts, verify:

- [ ] Uses `#!/usr/bin/env sh` shebang
- [ ] Includes `{{ includeTemplate "log_start" "[description]" }}`
- [ ] Includes `{{ includeTemplate "log_complete" "[message]" }}`
- [ ] Has `set -euo pipefail` after log_start
- [ ] No `main()` function wrapper
- [ ] Uses template logging (not `echo`)
- [ ] Validated with `bash -n script.sh.tmpl`
- [ ] Tested with `chezmoi execute-template < script.sh.tmpl`

## chezmoi_modify_manager Reference

### Understanding the Problem

**chezmoi_modify_manager** handles configuration files with **mixed settings and state**. Many applications store both user preferences (settings) and runtime data (state like window positions, cache). Traditional dotfiles management treats these as single units, causing constant churn. chezmoi_modify_manager intelligently separates concerns.

### Quick Start

```bash
#!/usr/bin/env chezmoi_modify_manager
source auto  # Automatically finds corresponding .src.ini file

# Filter out runtime state
ignore section "Cache"
ignore section "DirSelect Dialog"

# Set user-specific values with templates
set "User" "Name" "{{ .fullname }}"
set "User" "Email" "{{ .personalEmail }}"

# Hide sensitive data when re-adding
add:hide "Auth" "token"
add:remove "User" "Name"
```

### Directive Reference

| Directive        | Purpose                           | Example                                            |
| ---------------- | --------------------------------- | -------------------------------------------------- |
| `source auto`    | Auto-find .src.ini file           | `source auto`                                      |
| `ignore`         | Filter state data (specific keys) | `ignore "General" "ColorSchemeHash"`               |
| `ignore section` | Filter entire sections            | `ignore section "Cache"`                           |
| `ignore regex`   | Pattern-based filtering           | `ignore regex "General" "clientVersion\|lastSync"` |
| `set`            | Force specific values             | `set "User" "Name" "{{ .fullname }}"`              |
| `add:remove`     | Remove from source when re-adding | `add:remove "User" "Name"`                         |
| `add:hide`       | Hide sensitive values             | `add:hide "Accounts" "0\\password"`                |
| `ignore_order`   | Ignore list sort order            | `ignore_order "Plugins" "LoadOrder"`               |
| `self_update`    | Enable auto-updates               | `self_update enable`                               |

### Complete Example

See working implementation: `private_dot_config/Nextcloud/modify_nextcloud.conf.tmpl`

**Key patterns used:**

- `ignore section "DirSelect Dialog"` - Filter runtime window state
- `set "User" "Name" "{{ .fullname }}"` - Template variables for user data
- `add:hide "Accounts" "0\\password"` - Protect sensitive tokens
- `add:remove` for dynamically-set values

**Template integration:**

```bash
# Conditional settings based on chassis type
{{ if eq .chassisType "laptop" }}
set "Power" "SuspendOnLidClose" "true"
{{ else }}
set "Power" "SuspendOnLidClose" "false"
{{ end }}

# Template transformations
{{ $nextcloudServer := .privateServer | replace "www" "nextcloud" }}
set "Server" "URL" "{{ $nextcloudServer }}"
```

### Common Mistakes

1. ❌ **Ignoring critical settings** - Only ignore state data, not user preferences
2. ❌ **Hardcoded values** - Use template variables for user-specific data
3. ❌ **Skipping testing** - Always validate with `chezmoi cat` before applying
4. ❌ **Committing sensitive data** - Use `add:hide` for passwords and tokens
5. ❌ **Assuming config structure** - Test with actual application config files

## Package Management for Development

### Installation Strategies

```yaml
# In .chezmoidata/packages.yaml

strategies:
  _install_binary: &_install_binary [pacman, yay_bin]
  _install_from_source: &_install_from_source [pacman, yay_bin, yay_source]

# Adding new packages
new_category:
  strategy: *_install_from_source # or *_install_binary
  list: [package-name, another-package]
```

**Strategy Execution:**

1. Try `pacman` (official repos)
2. Try `yay_bin` (AUR precompiled)
3. Try `yay_source` (AUR from source)

### Lifecycle Scripts Execution Order

1. **`run_once_before_*`** → Setup (package managers, directories, tools)
2. **File application** → chezmoi applies all configuration files
3. **`run_once_after_*`** → Configuration (services, final setup)
4. **`run_onchange_*`** → Content-driven (when data files change)

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

**Template Structure**:

```bash
#!/usr/bin/env sh

# Script: [filename]
# Purpose: [clear description]
# Requirements: Arch Linux, [dependencies]

{{ includeTemplate "log_start" "[description]" }}

set -euo pipefail

# Implementation here

{{ includeTemplate "log_complete" "[completion message]" }}
```

#### Validation

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

1. ✅ Validated all syntax (templates, scripts, YAML)?
2. ✅ Tested with `chezmoi diff` and `--dry-run`?
3. ✅ Followed established patterns and conventions?
4. ✅ Documented feature and integration points?
5. ✅ Respected security protocols and encryption boundaries?

## Merge Conflict Resolution

### Template Variable Protection

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

### Safe Merge Workflow

1. **Run checks** - `chezmoi diff` and `chezmoi status`
2. **Merge operations** - `chezmoi merge <file>` or `chezmoi merge-all` (safer with protection)
3. **Validation** - Template syntax automatically preserved by merge driver
4. **Emergency restore** - `git checkout HEAD -- <file>` if manual intervention needed

### Manual Resolution Steps

1. **Detect conflicts** - `chezmoi status` (look for "M" status)
2. **Resolve conflicts** - Use `chezmoi merge <file>` or `chezmoi merge-all` with confidence
3. **Validate results** - Protection system ensures `{{ .variable }}` syntax preserved
4. **Special cases** - Encrypted files (`.age`) still require manual workflow

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

## Documentation Maintenance Protocol

When adding features to this repository, update documentation following these patterns:

**Package additions:**

- Update `.chezmoidata/packages.yaml` only
- No additional documentation needed (self-documenting YAML)

**New script patterns:**

- Update "Script Standards" section if introducing new patterns
- Reference actual working scripts, don't create inline examples
- Example: "See `run_once_after_005_*.sh.tmpl` for service configuration pattern"

**New template techniques:**

- Add to "Template System Reference" section
- Reference working files: `See: private_dot_config/zsh/dot_zshrc.tmpl`
- Keep inline examples minimal, point to real implementations

**chezmoi_modify_manager directives:**

- Update "Directive Reference" table for new directives
- Add real-world example reference to "Complete Example" section

**General principles:**

- ✅ ALWAYS reference working files instead of creating inline examples
- ✅ Keep documentation close to code (single source of truth)
- ✅ Update README.md for user-facing changes, CLAUDE.md for development patterns
- ❌ NEVER duplicate information across multiple sections
- ❌ NEVER create extensive inline code examples (reference actual files)
