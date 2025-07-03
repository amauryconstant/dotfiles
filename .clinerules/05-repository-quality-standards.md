---
description: Quality standards, testing protocols, and maintenance procedures for this chezmoi repository
author: Repository Owner
version: 1.0
tags: ["quality", "testing", "maintenance", "best-practices", "validation"]
globs: ["**/*"]
---

# Repository Quality Standards

This rule establishes quality standards, testing protocols, and maintenance procedures for this sophisticated chezmoi dotfiles repository. Following these standards ensures reliability, consistency, and maintainability across all configurations.

## Core Quality Principles

### **MUST** Follow These Fundamental Standards

1. **🚨 Safety First**: Never compromise security or data integrity
2. **🔍 Validation Required**: Always validate before applying changes
3. **📝 Documentation Mandatory**: Document all decisions and patterns
4. **🧪 Testing Essential**: Test changes before deployment
5. **🔄 Consistency Critical**: Maintain patterns across the repository
6. **⚡ Simplicity First**: Always choose the simplest solution (see Rule 01)

## Pre-Change Validation Protocol

### **CRITICAL** - Always Run Before Changes

```bash
# 1. MANDATORY: Check current state
chezmoi diff

# 2. MANDATORY: Check for merge conflicts
chezmoi status
# If files show "M" status, resolve with merge commands
# chezmoi merge <file> or chezmoi merge-all

# 3. MANDATORY: Dry-run validation
chezmoi apply --dry-run

# 4. MANDATORY: Template syntax validation
chezmoi execute-template < template_file.tmpl

# 5. MANDATORY: Script syntax validation
bash -n script_file.sh.tmpl
```

### **NEVER** Skip These Validation Steps

❌ **NEVER** run `chezmoi apply` without first running `chezmoi diff`
❌ **NEVER** modify templates without syntax validation
❌ **NEVER** change scripts without testing the logic
❌ **NEVER** ignore OS compatibility requirements
❌ **NEVER** bypass encryption safety protocols

## Template Quality Standards

### **MUST** Follow Template Best Practices

#### Variable Validation
```go
# ✅ CORRECT: Always validate required variables
{{ if not .firstname }}
{{   fail "firstname variable is required" }}
{{ end }}

# ✅ CORRECT: Use safe defaults
{{ $server := .privateServer | default "localhost" }}
```

#### Error Handling
```go
# ✅ CORRECT: Include comprehensive error handling
{{ if eq .osId "linux-arch" }}
    # Implementation for Arch Linux
{{ else }}
    echo "ERROR: This configuration is only supported on Arch Linux"
    echo "Required: osId 'linux-arch'"
    echo "Detected: '{{ .osId }}'"
    exit 1
{{ end }}
```

#### Template Documentation
```go
{{/*
Template: config.tmpl
Purpose: Generate user-specific configuration
Variables Required: .firstname, .personalEmail
Variables Optional: .workEmail
OS Support: linux-arch
*/}}
```

## Script Quality Standards

### **MUST** Include Standard Script Headers

```bash
#!/bin/sh

# Script: script_name.sh.tmpl
# Purpose: Brief description of what this script does
# Requirements: List of prerequisites
# OS Support: Specific OS requirements

{{ if eq .osId "linux-arch" }}
    # Script implementation
{{ else }}
    echo "ERROR: This script is only supported on Arch Linux systems"
    echo "Required: osId 'linux-arch'"
    echo "Detected: '{{ .osId }}'"
    echo "Script: $(basename "$0")"
    exit 1
{{ end }}
```

### **MUST** Include Function Definitions

```bash
# Define utility functions at the top
is_package_installed() {
    local package="$1"
    pacman -Qi "$package" >/dev/null 2>&1 || yay -Qi "$package" >/dev/null 2>&1
}

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}
```

### **SHOULD** Include Progress Indicators

```bash
echo "Starting package installation process..."
echo "Step 1/3: Checking system requirements..."
echo "Step 2/3: Installing packages..."
echo "Step 3/3: Verifying installation..."
echo "✓ Package installation completed successfully"
```

## Data File Quality Standards

### **MUST** Maintain YAML Structure

```yaml
# ✅ CORRECT: Well-structured, documented YAML
packages:
  install:
    arch:
      strategies:
        # Strategy definitions with clear purposes
        default_strategy: [pacman, yay_bin, yay_source]
        _install_binary: &_install_binary [pacman, yay_bin]
        _install_from_source: &_install_from_source [pacman, yay_bin, yay_source]
      
      packages:
        # Categorized packages with clear purposes
        fonts:
          list:
            - ttf-firacode-nerd  # Programming font with icons
            - otf-opendyslexic-nerd  # Accessibility font
```

### **SHOULD** Include Comments for Complex Configurations

```yaml
# Color scheme: Oksolar - optimized solarized variant
colors:
  oksolar:
    # Base colors (dark to light)
    - base03: "002d38"  # Background
    - base02: "093946"  # Background highlights
    # ... rest of color definitions
```

## Testing Protocols

### **MUST** Test Changes in This Order

1. **Syntax Validation**
   ```bash
   # Test template syntax
   chezmoi execute-template < file.tmpl
   
   # Test script syntax
   bash -n script.sh.tmpl
   
   # Test YAML syntax
   yamllint data.yaml
   ```

2. **Dry-Run Testing**
   ```bash
   # Preview all changes
   chezmoi diff
   
   # Test application without changes
   chezmoi apply --dry-run
   ```

3. **Incremental Application**
   ```bash
   # Apply specific files first
   chezmoi apply path/to/specific/file
   
   # Verify each change
   chezmoi status
   ```

4. **Full System Validation**
   ```bash
   # Apply all changes
   chezmoi apply
   
   # Verify system state
   chezmoi verify
   ```

## Error Handling Standards

### **MUST** Implement Comprehensive Error Handling

#### Script Error Handling
```bash
# Set strict error handling
set -euo pipefail

# Function-level error handling
install_package() {
    local package="$1"
    
    if ! pacman -S --noconfirm "$package"; then
        log_error "Failed to install $package via pacman"
        if ! yay -S --noconfirm "$package"; then
            log_error "Failed to install $package via yay"
            return 1
        fi
    fi
    
    log_info "Successfully installed $package"
    return 0
}
```

#### Template Error Handling
```go
# Graceful error handling in templates
{{ $email := .personalEmail | default "" }}
{{ if eq $email "" }}
{{   fail "personalEmail is required but not set" }}
{{ end }}
```

## Documentation Standards

### **MUST** Document All Decisions

#### Inline Documentation
```bash
# Why we use this specific approach
# Alternative: Could use X, but Y is better because Z
install_with_strategy() {
    # Implementation with explanation
}
```

#### Change Documentation
```yaml
# Document why packages are in specific categories
terminal_essentials:
  # These tools are installed from source to get latest features
  # that improve development workflow significantly
  strategy: *_install_from_source
  list:
    - ripgrep  # Faster than grep, essential for code search
```

## Maintenance Protocols

### **SHOULD** Perform Regular Maintenance

#### Weekly Checks
```bash
# Check for system updates
chezmoi update

# Verify repository state
chezmoi status

# Check for broken links or outdated configurations
chezmoi verify
```

#### Monthly Reviews
- Review package lists for outdated or unused packages
- Update extension lists based on development needs
- Review and update color schemes and themes
- Check for new chezmoi features or best practices

#### Quarterly Audits
- Full security review of encrypted files
- Performance review of scripts and templates
- Documentation updates and improvements
- Backup and recovery testing

## Performance Standards

### **SHOULD** Optimize for Performance

#### Script Performance
```bash
# ✅ CORRECT: Efficient package checking
if ! is_package_installed "$package"; then
    install_package "$package"
fi

# ❌ WRONG: Inefficient repeated checks
install_package "$package"  # Always tries to install
```

#### Template Performance
```go
# ✅ CORRECT: Cache expensive operations
{{ $packages := .packages.install.arch.packages }}
{{ range $name, $config := $packages }}
    # Use cached $packages
{{ end }}
```

## Security Standards

### **CRITICAL** Security Requirements

1. **🔐 Encryption Mandatory**: All sensitive data MUST be encrypted
2. **🚫 No Hardcoded Secrets**: Use templates and external sources
3. **🔍 Regular Audits**: Review access patterns and permissions
4. **📝 Change Tracking**: Document all security-related changes

#### Security Checklist
```bash
# Before committing changes
grep -r "password\|secret\|key" . --exclude-dir=.git
find . -name "*.age" -exec echo "Encrypted: {}" \;
chezmoi verify
```

## Verification Checklist

Before ANY repository changes:

<thinking>
1. Have I run chezmoi diff to see what will change?
2. Have I validated all template syntax?
3. Have I tested scripts for syntax errors?
4. Are all OS compatibility checks in place?
5. Have I documented the reasoning for changes?
6. Are encryption protocols being followed?
7. Will this work across different machines?
8. Have I considered the impact on existing configurations?
</thinking>

### Critical Quality Gates

1. ✅ **Syntax Validation**: All templates and scripts are syntactically correct
2. ✅ **OS Compatibility**: Changes work on target operating systems
3. ✅ **Security Compliance**: No sensitive data exposed, encryption used properly
4. ✅ **Documentation**: Changes are documented and reasoning is clear
5. ✅ **Testing**: Changes have been tested in dry-run mode
6. ✅ **Consistency**: Changes follow established patterns and conventions

## Emergency Procedures


### If Something Goes Wrong

1. **Immediate Response**
   ```bash
   # Stop any running processes
   # Revert to last known good state
   git checkout HEAD~1
   chezmoi apply
   ```
   
2. **Assessment**
   ```bash
   # Check what changed
   chezmoi diff
   
   # Verify system state
   chezmoi status
   ```
   
3. **Recovery**
   ```bash
   # Apply fixes incrementally
   chezmoi apply specific/file
   
   # Verify each step
   chezmoi verify
   ```


# [No Replacement Content]

### If Merge Conflicts Occur

1. **Conflict Detection**
   ```bash
   # Check for merge conflicts
   chezmoi status
   
   # Look for files with "M" status
   # M  private_dot_config/git/config
   # M  .chezmoiscripts/run_onchange_packages.sh.tmpl
   ```

2. **Targeted Resolution**
   ```bash
   # Resolve conflicts one file at a time
   chezmoi merge private_dot_config/git/config
   
   # Or resolve all conflicts at once
   chezmoi merge-all
   ```

3. **Post-Merge Validation**
   ```bash
   # Verify merge results
   chezmoi diff
   
   # Check status is clean
   chezmoi status
   
   # Validate template syntax if templates were merged
   chezmoi execute-template < merged_template.tmpl
   
   # Test script syntax if scripts were merged
   bash -n merged_script.sh.tmpl
   ```

4. **Special Case: Encrypted Files**
   ```bash
   # For encrypted files, follow the manual workflow in Rule 02
   # NEVER attempt to merge encrypted files directly
   ```

---

**REMEMBER**: Quality is not optional. These standards exist to ensure the reliability and maintainability of this sophisticated dotfiles system. When in doubt, err on the side of caution and thorough testing.
