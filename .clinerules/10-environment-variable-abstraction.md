---
description: Environment variable abstraction system for chezmoi scripts with centralized export management
author: Repository Owner
version: 1.0
tags: ["environment", "abstraction", "templates", "variables", "orchestration"]
globs: [".chezmoitemplates/chezmoi_environment*", ".chezmoiscripts/*.tmpl"]
---

# Environment Variable Abstraction System

This rule documents the environment variable abstraction system that eliminates repetitive variable exports across chezmoi orchestrator scripts. The system provides centralized environment variable management similar to the logging system.

## Core Architecture

### **MUST** Understand the Template Hierarchy

```
chezmoi_environment_setup (base)
├── Core chezmoi context variables
├── User context variables  
├── Execution context variables
├── Destination-specific configuration
└── XDG Base Directory variables

chezmoi_environment_enhanced (extended)
├── Includes all from chezmoi_environment_setup
├── Service-specific boolean flags
└── Package category boolean flags

chezmoi_logger_setup (integrated)
├── Includes chezmoi_environment_setup
├── Logging configuration variables
└── Logging system initialization
```

## Template Usage Patterns

### **MUST** Use Appropriate Template for Script Type

#### Standard Orchestrator Scripts
```bash
#!/bin/sh
# Chezmoi orchestrator script

{{- template "chezmoi_logger_setup" . }}

{{ if eq .osId "linux-arch" }}
    # All standard environment variables are automatically available
    # CHEZMOI_OS_ID, CHEZMOI_DESTINATION, CHEZMOI_SOURCE_DIR, etc.
    
    # Only export script-specific variables if needed
    export SCRIPT_SPECIFIC_VAR="value"
    
    # Execute delegated script
    SCRIPT_PATH="${CHEZMOI_SOURCE_DIR}/.chezmoiscripts/.lib/category/action.sh"
    "$SCRIPT_PATH"
{{ end }}
```

#### Enhanced Environment Scripts
```bash
#!/bin/sh
# Script needing service/package flags

{{- template "chezmoi_environment_enhanced" . }}

{{ if eq .osId "linux-arch" }}
    # All standard variables plus service/package flags available
    # CHEZMOI_DOCKER_ENABLED, CHEZMOI_FONTS_ENABLED, etc.
    
    if [ "$CHEZMOI_DOCKER_ENABLED" = "true" ]; then
        # Docker-specific logic
    fi
{{ end }}
```

#### Logging-Only Scripts
```bash
#!/bin/sh
# Script that only needs logging

{{- template "chezmoi_logger_setup" . }}

{{ if eq .osId "linux-arch" }}
    # Standard environment + logging available
    log_info "Processing with destination: $CHEZMOI_DESTINATION"
{{ end }}
```

## Available Environment Variables

### **Core Variables** (from `chezmoi_environment_setup`)

#### chezmoi Context
```bash
CHEZMOI_OS_ID="{{ .osId }}"                    # OS identifier (e.g., "linux-arch")
CHEZMOI_DESTINATION="{{ .destination }}"       # Destination (work/leisure/test)
CHEZMOI_SOURCE_DIR="{{ .chezmoi.sourceDir }}"  # Source directory path
CHEZMOI_DEST_DIR="{{ .chezmoi.homeDir }}"      # Destination directory path
CHEZMOI_CACHE_DIR="{{ .chezmoi.homeDir }}/.cache/chezmoi"
CHEZMOI_CONFIG_DIR="{{ .chezmoi.homeDir }}/.config/chezmoi"
```

#### User Context
```bash
CHEZMOI_FIRSTNAME="{{ .firstname }}"           # First name
CHEZMOI_FULLNAME="{{ .fullname }}"             # Full name
CHEZMOI_WORK_EMAIL="{{ .workEmail }}"          # Work email
CHEZMOI_PERSONAL_EMAIL="{{ .personalEmail }}"  # Personal email
CHEZMOI_PRIVATE_SERVER="{{ .privateServer }}"  # Private server URL
CHEZMOI_CHASSIS_TYPE="{{ .chassisType }}"      # "desktop" or "laptop"
```

#### Execution Context
```bash
CHEZMOI_LOG_LEVEL="{{ .logging.level }}"       # Log level
CHEZMOI_DRY_RUN="${CHEZMOI_DRY_RUN:-false}"    # Dry-run mode
CHEZMOI_VERBOSE="${CHEZMOI_VERBOSE:-false}"    # Verbose mode
CHEZMOI_INTERACTIVE="${CHEZMOI_INTERACTIVE:-false}"
CHEZMOI_KEEP_GOING="${CHEZMOI_KEEP_GOING:-false}"
CHEZMOI_PROGRESS="${CHEZMOI_PROGRESS:-auto}"
```

#### Destination Configuration
```bash
CHEZMOI_PACKAGES="fonts,terminal_essentials,..."  # Comma-separated package list
CHEZMOI_SERVICES="docker,ollama,..."              # Comma-separated service list
```

#### XDG Base Directory
```bash
XDG_CACHE_HOME="$HOME/.cache"
XDG_CONFIG_HOME="$HOME/.config"
XDG_DATA_HOME="$HOME/.local/share"
XDG_STATE_HOME="$HOME/.local/state"
```

### **Enhanced Variables** (from `chezmoi_environment_enhanced`)

#### Service Flags
```bash
CHEZMOI_DOCKER_ENABLED="true|false"           # Docker service enabled
CHEZMOI_OLLAMA_ENABLED="true|false"           # Ollama service enabled
CHEZMOI_BLUETOOTH_ENABLED="true|false"        # Bluetooth service enabled
CHEZMOI_SNAPD_ENABLED="true|false"            # Snapd service enabled
```

#### Package Category Flags
```bash
CHEZMOI_FONTS_ENABLED="true|false"                    # Fonts package category
CHEZMOI_TERMINAL_ESSENTIALS_ENABLED="true|false"      # Terminal essentials
CHEZMOI_TERMINAL_UTILS_ENABLED="true|false"           # Terminal utilities
CHEZMOI_DEVELOPMENT_TOOLS_ENABLED="true|false"        # Development tools
CHEZMOI_DEVELOPMENT_CLIS_ENABLED="true|false"         # Development CLIs
CHEZMOI_LANGUAGES_ENABLED="true|false"                # Programming languages
CHEZMOI_PACKAGE_MANAGERS_ENABLED="true|false"         # Package managers
CHEZMOI_SYSTEM_SOFTWARE_ENABLED="true|false"          # System software
CHEZMOI_GENERAL_SOFTWARE_ENABLED="true|false"         # General software
CHEZMOI_AI_TOOLS_ENABLED="true|false"                 # AI tools
CHEZMOI_TERMINAL_PRESENTATION_ENABLED="true|false"    # Presentation tools
```

## Migration Guidelines

### **MUST** Follow Migration Process

#### Before (Repetitive Exports)
```bash
#!/bin/sh
{{- template "chezmoi_logger_setup" . }}

{{ if eq .osId "linux-arch" }}
    # Repetitive exports in every script
    export CHEZMOI_OS_ID="{{ .osId }}"
    export CHEZMOI_DESTINATION="{{ .destination }}"
    export CHEZMOI_SOURCE_DIR="{{ .chezmoi.sourceDir }}"
    export CHEZMOI_FIRSTNAME="{{ .firstname }}"
    export CHEZMOI_FULLNAME="{{ .fullname }}"
    export CHEZMOI_WORK_EMAIL="{{ .workEmail }}"
    export CHEZMOI_PERSONAL_EMAIL="{{ .personalEmail }}"
    export CHEZMOI_PRIVATE_SERVER="{{ .privateServer }}"
    export CHEZMOI_LOG_LEVEL="{{ .logging.level }}"
    export CHEZMOI_DRY_RUN="${CHEZMOI_DRY_RUN:-false}"
    export CHEZMOI_VERBOSE="${CHEZMOI_VERBOSE:-false}"
    
    # Script logic...
{{ end }}
```

#### After (Abstracted Environment)
```bash
#!/bin/sh
{{- template "chezmoi_logger_setup" . }}

{{ if eq .osId "linux-arch" }}
    # All standard variables automatically available
    # Only export script-specific variables if needed
    export SCRIPT_SPECIFIC_VAR="value"
    
    # Script logic...
{{ end }}
```

### **SHOULD** Update Scripts Incrementally

1. **Identify repetitive exports** in existing scripts
2. **Replace with template inclusion** (`chezmoi_logger_setup` or `chezmoi_environment_enhanced`)
3. **Remove redundant export statements**
4. **Test script functionality** to ensure variables are available
5. **Update documentation** to reflect changes

## Template Selection Guidelines

### **MUST** Choose Appropriate Template

#### Use `chezmoi_logger_setup` When:
- ✅ Script needs logging functionality
- ✅ Script needs standard environment variables
- ✅ Script doesn't need service/package flags
- ✅ Most common use case for orchestrator scripts

#### Use `chezmoi_environment_enhanced` When:
- ✅ Script needs service-specific boolean flags
- ✅ Script needs package category boolean flags
- ✅ Script doesn't need logging functionality
- ✅ Pure environment setup without logging overhead

#### Use `chezmoi_environment_setup` When:
- ✅ Script needs only basic environment variables
- ✅ Script doesn't need logging or enhanced flags
- ✅ Building custom environment templates
- ✅ Minimal overhead required

## Best Practices

### **MUST** Follow These Guidelines

1. ✅ **Use template inclusion** instead of manual exports
2. ✅ **Choose minimal template** that meets script needs
3. ✅ **Document script-specific exports** when needed
4. ✅ **Test variable availability** after migration
5. ✅ **Maintain backward compatibility** during migration

### **SHOULD** Consider These Practices

1. ✅ **Group related exports** when script-specific variables are needed
2. ✅ **Use descriptive variable names** for script-specific exports
3. ✅ **Document variable purposes** in script comments
4. ✅ **Validate required variables** in pure shell scripts
5. ✅ **Use consistent naming patterns** for new variables

### **NEVER** Do These Things

1. ❌ **Never duplicate standard exports** already in templates
2. ❌ **Never hardcode user-specific values** in exports
3. ❌ **Never export sensitive information** without encryption
4. ❌ **Never skip template inclusion** for new scripts
5. ❌ **Never assume variables exist** without template inclusion

## Integration with Pure Shell Scripts

### **MUST** Validate Environment in Pure Scripts

```bash
#!/bin/bash
# Pure shell script template

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Validate required environment variables
require_env_vars "CHEZMOI_OS_ID" "CHEZMOI_DESTINATION" "CHEZMOI_SOURCE_DIR"

# Use environment variables
log_info "Processing for OS: $CHEZMOI_OS_ID, Destination: $CHEZMOI_DESTINATION"

# Script logic using available variables
main() {
    if [ "$CHEZMOI_DOCKER_ENABLED" = "true" ]; then
        setup_docker_configuration
    fi
    
    if [ "$CHEZMOI_FONTS_ENABLED" = "true" ]; then
        install_font_packages
    fi
}
```

## Error Handling

### **MUST** Handle Missing Variables Gracefully

```bash
# Check for required variables with defaults
CHEZMOI_OS_ID="${CHEZMOI_OS_ID:-unknown}"
CHEZMOI_DESTINATION="${CHEZMOI_DESTINATION:-default}"

# Validate critical variables
if [ "$CHEZMOI_OS_ID" = "unknown" ]; then
    log_error "CHEZMOI_OS_ID not set - ensure chezmoi template is included"
    exit 1
fi

# Use variables safely
log_info "Operating on $CHEZMOI_OS_ID for $CHEZMOI_DESTINATION destination"
```

## Template Maintenance

### **SHOULD** Keep Templates Updated

#### Adding New Variables
1. **Add to appropriate template** (`setup`, `enhanced`, or new template)
2. **Update documentation** to reflect new variables
3. **Test with existing scripts** to ensure compatibility
4. **Update migration guidelines** if needed

#### Modifying Existing Variables
1. **Maintain backward compatibility** when possible
2. **Document breaking changes** clearly
3. **Provide migration path** for affected scripts
4. **Test thoroughly** across all script types

## Verification Checklist

Before modifying environment templates:

<thinking>
1. Does this change affect existing scripts?
2. Are all required variables properly exported?
3. Is the template hierarchy maintained correctly?
4. Have I tested with different destinations?
5. Are variable names consistent with existing patterns?
6. Does this maintain backward compatibility?
</thinking>

### Critical Questions
1. 🔍 **Will existing scripts continue to work?**
2. 🔍 **Are new variables properly documented?**
3. 🔍 **Is the template selection guidance clear?**
4. 🔍 **Have I tested the changes thoroughly?**

---

**REMEMBER**: This environment variable abstraction system eliminates repetitive exports and provides a centralized, maintainable approach to environment management. Always use the appropriate template for your script's needs and maintain consistency across the repository.
