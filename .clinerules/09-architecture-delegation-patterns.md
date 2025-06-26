---
description: Architecture delegation patterns for the new chezmoi script system with pure shell scripts and lightweight orchestrators
author: Repository Owner
version: 1.0
tags: ["architecture", "delegation", "pure-shell", "orchestration", "patterns"]
globs: [".chezmoiscripts/.lib/**/*", ".chezmoiscripts/*.tmpl"]
---

# Architecture Delegation Patterns

This rule documents the new architecture delegation patterns implemented in this chezmoi repository. The system separates concerns between chezmoi orchestration (lifecycle management, OS detection, environment setup) and pure shell script execution (actual task implementation).

## Core Architecture Principles

### **MUST** Follow Separation of Concerns

1. **Chezmoi Scripts (Orchestrators)**: Handle lifecycle, OS detection, and environment variable export
2. **Pure Shell Scripts (Workers)**: Handle actual task execution without OS conditionals
3. **Utility Libraries**: Provide shared functionality for logging, error handling, and validation

### **MUST** Use Standard Directory Structure

```
.chezmoiscripts/
├── .lib/                                   # Pure shell scripts (ignored by chezmoi)
│   ├── utils/                             # Shared utilities
│   │   ├── logging-lib.sh                 # Simplified logging
│   │   ├── error-handler.sh               # Structured error handling
│   │   └── environment-validator.sh       # Environment validation
│   ├── packages/                          # Package management
│   │   ├── install-packages-arch-work.sh
│   │   ├── install-packages-arch-leisure.sh
│   │   ├── install-packages-arch-test.sh
│   │   ├── update-packages-arch-work.sh
│   │   ├── update-packages-arch-leisure.sh
│   │   └── update-packages-arch-test.sh
│   ├── system/                           # System configuration
│   │   ├── setup-logging.sh
│   │   ├── create-directories.sh
│   │   ├── write-globals.sh
│   │   └── install-zsh.sh
│   ├── development/                      # Development tools
│   │   ├── install-extensions.sh
│   │   ├── configure-git.sh
│   │   └── setup-ai-models.sh
│   └── security/                         # Security operations
│       ├── instantiate-encryption-key.sh
│       └── setup-os-specifics.sh
├── run_once_before_*.sh.tmpl             # Lightweight orchestrators
├── run_once_after_*.sh.tmpl              # Lightweight orchestrators
└── run_onchange_*.sh.tmpl                # Lightweight orchestrators
```

## Chezmoi Orchestrator Pattern

### **MUST** Use This Template Structure

```bash
#!/bin/sh
# Chezmoi orchestrator script template

{{- template "chezmoi_logger_setup" . }}

{{ if eq .osId "linux-arch" }}
    {{- $destinationConfig := index .destinations .destination }}
    
    log_step "Preparing environment for {{ .destination }} destination"
    
    # Export all necessary environment variables
    export CHEZMOI_OS_ID="{{ .osId }}"
    export CHEZMOI_DESTINATION="{{ .destination }}"
    export CHEZMOI_SOURCE_DIR="{{ .chezmoi.sourceDir }}"
    export CHEZMOI_FIRSTNAME="{{ .firstname }}"
    export CHEZMOI_FULLNAME="{{ .fullname }}"
    export CHEZMOI_WORK_EMAIL="{{ .workEmail }}"
    export CHEZMOI_PERSONAL_EMAIL="{{ .personalEmail }}"
    export CHEZMOI_PRIVATE_SERVER="{{ .privateServer }}"
    export CHEZMOI_PACKAGES="{{ join "," $destinationConfig.packages }}"
    export CHEZMOI_LOG_LEVEL="{{ .logging.level }}"
    export CHEZMOI_DRY_RUN="${CHEZMOI_DRY_RUN:-false}"
    export CHEZMOI_VERBOSE="${CHEZMOI_VERBOSE:-false}"
    
    # Determine script path
    SCRIPT_PATH="${CHEZMOI_SOURCE_DIR}/.chezmoiscripts/.lib/category/action-{{ .osId }}-{{ .destination }}.sh"
    
    log_info "Executing: $(basename "$SCRIPT_PATH")"
    
    # Execute with error handling
    if [ -x "$SCRIPT_PATH" ]; then
        if ! "$SCRIPT_PATH"; then
            handle_error "Script execution failed: $(basename "$SCRIPT_PATH")" $?
        fi
    else
        log_error "Script not found or not executable: $SCRIPT_PATH"
        exit 1
    fi
    
    log_success "Script completed successfully"
    
{{ else }}
    log_error "Unsupported OS: {{ .osId }}"
    log_error "This script requires: linux-arch"
    exit 1
{{ end }}
```

### **MUST** Export Standard Environment Variables

```bash
# Core chezmoi context
export CHEZMOI_OS_ID="{{ .osId }}"                    # OS identifier
export CHEZMOI_DESTINATION="{{ .destination }}"       # Destination (work/leisure/test)
export CHEZMOI_SOURCE_DIR="{{ .chezmoi.sourceDir }}"  # Source directory

# User context
export CHEZMOI_FIRSTNAME="{{ .firstname }}"
export CHEZMOI_FULLNAME="{{ .fullname }}"
export CHEZMOI_WORK_EMAIL="{{ .workEmail }}"
export CHEZMOI_PERSONAL_EMAIL="{{ .personalEmail }}"
export CHEZMOI_PRIVATE_SERVER="{{ .privateServer }}"

# Task-specific configuration
export CHEZMOI_PACKAGES="{{ join "," $destinationConfig.packages }}"

# Logging and execution context
export CHEZMOI_LOG_LEVEL="{{ .logging.level }}"
export CHEZMOI_DRY_RUN="${CHEZMOI_DRY_RUN:-false}"
export CHEZMOI_VERBOSE="${CHEZMOI_VERBOSE:-false}"
```

## Pure Shell Script Pattern

### **MUST** Use This Template Structure

```bash
#!/bin/bash
# Pure shell script template
# Purpose: [Specific task description]
# Dependencies: [List of required commands/packages]
# Environment: [Required environment variables]

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="[Brief description]"
readonly REQUIRED_COMMANDS=("command1" "command2")
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID" "CHEZMOI_DESTINATION")

# Validation functions
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required commands
    require_commands "${REQUIRED_COMMANDS[@]}"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate OS/destination match
    require_os "linux-arch"
    require_destination "work"  # or leisure/test as appropriate
    
    log_debug "Environment validation passed"
}

# Task implementation functions
perform_task() {
    log_info "Performing specific task"
    
    # Implementation here
    
    log_success "Task completed successfully"
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: $CHEZMOI_OS_ID, Destination: $CHEZMOI_DESTINATION"
    
    validate_environment
    
    perform_task
    
    log_success "$SCRIPT_PURPOSE completed successfully"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
```

### **MUST** Include Standard Script Headers

```bash
#!/bin/bash
# script-name.sh
# Purpose: Brief description of what this script does
# Dependencies: List of required commands/packages
# Environment: Required environment variables
# OS Support: linux-arch (or specific OS requirements)
# Destination: work/leisure/test (or specific destination requirements)

set -euo pipefail
```

## Utility Library Integration

### **MUST** Source Required Utilities

```bash
# Source utilities (adjust path as needed)
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Optional: source environment validator for comprehensive validation
source "$SCRIPT_DIR/../utils/environment-validator.sh"
```

### **SHOULD** Use Utility Functions

#### Logging Functions
```bash
log_debug "Detailed debugging information"
log_info "General information"
log_warn "Warning messages"
log_error "Error messages"
log_success "Success messages"
log_step "Process step indicators"
log_dry_run "install" "package description"
log_progress 3 10 "Installing package group"
```

#### Error Handling Functions
```bash
error_exit "Error message" $EXIT_CODE $CATEGORY "Suggestion"
require_commands "pacman" "yay"
require_env_vars "CHEZMOI_OS_ID" "CHEZMOI_DESTINATION"
require_os "linux-arch"
require_destination "work"
check_package_manager "pacman"
```

#### Environment Validation Functions
```bash
validate_script_environment "linux-arch" "work"
validate_basic_environment "linux-arch" "work"
show_environment_info
```

## Package Management Script Pattern

### **MUST** Follow Package Script Structure

```bash
#!/bin/bash
# install-packages-arch-work.sh
# Purpose: Install packages for Arch Linux work destination

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Install packages for Arch Linux work destination"
readonly REQUIRED_COMMANDS=("pacman")
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID" "CHEZMOI_DESTINATION" "CHEZMOI_PACKAGES")

# Package installation functions
install_with_pacman() {
    local packages="$*"
    log_dry_run "install" "$packages via pacman"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if sudo pacman -S --noconfirm --needed "$@"; then
            return 0
        else
            return 1
        fi
    fi
}

install_with_yay() {
    local packages="$*"
    log_dry_run "install" "$packages via yay"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if yay -S --noconfirm --needed "$@"; then
            return 0
        else
            return 1
        fi
    fi
}

# Category installation functions
install_fonts() {
    log_info "Installing fonts for work environment"
    
    local packages="ttf-firacode-nerd otf-opendyslexic-nerd otf-geist-mono-nerd ttf-fira-sans"
    
    if ! install_with_pacman $packages; then
        error_exit "Failed to install fonts" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE
    fi
    
    log_success "Fonts installed successfully"
}

# Validation function
validate_environment() {
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    require_commands "${REQUIRED_COMMANDS[@]}"
    require_os "linux-arch"
    require_destination "work"
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    
    validate_environment
    
    # Parse enabled package categories
    IFS=',' read -ra CATEGORIES <<< "$CHEZMOI_PACKAGES"
    
    for category in "${CATEGORIES[@]}"; do
        case "$category" in
            "fonts") install_fonts ;;
            "terminal_essentials") install_terminal_essentials ;;
            "development_tools") install_development_tools ;;
            *) log_warn "Unknown package category: $category" ;;
        esac
    done
    
    log_success "$SCRIPT_PURPOSE completed successfully"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
```

## Error Handling Standards

### **MUST** Use Standardized Exit Codes

```bash
# Success
EXIT_SUCCESS=0

# General errors (1-10)
EXIT_GENERAL_FAILURE=1
EXIT_INVALID_ARGS=2
EXIT_MISSING_DEPENDENCY=3
EXIT_PERMISSION_DENIED=4
EXIT_NETWORK_ERROR=5
EXIT_FILESYSTEM_ERROR=6
EXIT_CONFIG_ERROR=7

# Package management errors (11-20)
EXIT_PACKAGE_NOT_FOUND=11
EXIT_PACKAGE_INSTALL_FAILED=12
EXIT_PACKAGE_CONFLICT=13
EXIT_REPOSITORY_ERROR=14
EXIT_PACKAGE_MANAGER_UNAVAILABLE=15

# System errors (21-30)
EXIT_SERVICE_START_FAILED=21
EXIT_SERVICE_CONFIG_ERROR=22
EXIT_SYSTEM_CONFIG_ERROR=23
EXIT_USER_GROUP_ERROR=24

# Security errors (31-40)
EXIT_ENCRYPTION_KEY_ERROR=31
EXIT_PERMISSION_SETUP_FAILED=32
EXIT_SECURITY_VALIDATION_FAILED=33
```

### **MUST** Use Structured Error Messages

Format: `ERROR_CODE:CATEGORY:MESSAGE:SUGGESTION`

```bash
error_exit "Package installation failed" \
           $EXIT_PACKAGE_INSTALL_FAILED \
           $CATEGORY_PACKAGE \
           "Try running: pacman -S package-name"
```

## Naming Conventions

### **MUST** Follow File Naming Patterns

#### Orchestrator Scripts (chezmoi templates)
```
run_once_before_NNN_description.sh.tmpl
run_once_after_NNN_description.sh.tmpl
run_onchange_before_description.sh.tmpl
run_onchange_after_description.sh.tmpl
```

#### Pure Shell Scripts
```
.lib/category/action-os-destination.sh
.lib/packages/install-packages-arch-work.sh
.lib/packages/update-packages-arch-leisure.sh
.lib/system/setup-logging.sh
.lib/development/install-extensions.sh
.lib/security/instantiate-encryption-key.sh
```

#### Utility Scripts
```
.lib/utils/logging-lib.sh
.lib/utils/error-handler.sh
.lib/utils/environment-validator.sh
```

## Testing and Validation

### **SHOULD** Test Pure Shell Scripts Independently

```bash
# Set up test environment
export CHEZMOI_OS_ID="linux-arch"
export CHEZMOI_DESTINATION="work"
export CHEZMOI_PACKAGES="fonts,terminal_essentials"
export CHEZMOI_DRY_RUN="true"
export CHEZMOI_LOG_LEVEL="DEBUG"

# Test script
./.lib/packages/install-packages-arch-work.sh
```

### **MUST** Validate Before Deployment

```bash
# Syntax validation
bash -n script.sh

# Environment validation
./script.sh --validate-only

# Dry-run testing
CHEZMOI_DRY_RUN=true ./script.sh
```

## Migration Guidelines

### **MUST** Follow Migration Process

1. **Create Pure Shell Script**: Extract logic from existing template
2. **Create Orchestrator**: Simplify template to environment export + delegation
3. **Test Independently**: Validate pure shell script works standalone
4. **Test Integration**: Validate orchestrator calls pure shell script correctly
5. **Replace Original**: Remove old template, deploy new architecture

### **SHOULD** Maintain Backward Compatibility

During migration, ensure:
- Same functionality is preserved
- Same error handling behavior
- Same logging output format
- Same environment variable usage

## Best Practices

### **MUST** Follow These Guidelines

1. ✅ **Keep orchestrators minimal** - Only OS detection and environment export
2. ✅ **Make pure scripts testable** - No OS conditionals, environment-driven
3. ✅ **Use structured error handling** - Standardized exit codes and messages
4. ✅ **Include comprehensive validation** - Environment, dependencies, permissions
5. ✅ **Document script purpose** - Clear headers and comments

### **SHOULD** Consider These Practices

1. ✅ **Use dry-run aware logging** - Respect CHEZMOI_DRY_RUN flag
2. ✅ **Implement progress indicators** - For long-running operations
3. ✅ **Include resource validation** - Disk space, network connectivity
4. ✅ **Use consistent naming** - Follow established patterns
5. ✅ **Source utilities properly** - Handle missing utility files gracefully

### **NEVER** Do These Things

1. ❌ **Never put OS conditionals in pure shell scripts**
2. ❌ **Never hardcode paths or user-specific values**
3. ❌ **Never skip environment validation**
4. ❌ **Never ignore error handling**
5. ❌ **Never bypass the delegation pattern**

## Verification Checklist

Before implementing new scripts:

<thinking>
1. Does this follow the delegation pattern correctly?
2. Are environment variables properly exported and used?
3. Is error handling comprehensive and structured?
4. Can the pure shell script be tested independently?
5. Does the orchestrator handle OS detection properly?
6. Are all utility libraries properly sourced?
7. Is the script purpose clearly documented?
</thinking>

### Critical Questions
1. 🔍 **Is the separation of concerns clear?**
2. 🔍 **Can this script be tested independently?**
3. 🔍 **Are error messages helpful and actionable?**
4. 🔍 **Does this follow the established patterns?**

---

**REMEMBER**: This architecture delegation pattern is designed to dramatically improve maintainability, testability, and development velocity. Always follow the established patterns to ensure consistency and reliability across the entire system.
