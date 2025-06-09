---
description: Guidelines for ensuring cross-distribution compatibility in configuration management scripts
author: Repository Owner
version: 1.0
tags: ["cross-distribution", "compatibility", "chezmoi", "configuration"]
globs: [".chezmoiscripts/**/*", ".chezmoidata/**/*"]
---

# Cross-Distribution Compatibility Guidelines

This rule establishes guidelines for ensuring that configuration management scripts and data files work across different Linux distributions, not just Arch-based systems.

## Core Principles

1. **Distribution-Agnostic Operations First**: Prefer operations that work the same way across all Linux distributions.
2. **Explicit Distribution Checks**: When distribution-specific code is necessary, use explicit checks and provide alternatives for other distributions.
3. **Modular Package Management**: Separate package management logic by distribution.
4. **Consistent Directory Structure**: Use standard Linux directory structures that work across distributions.
5. **Fallback Mechanisms**: Provide graceful fallbacks when distribution-specific features are unavailable.

## Script Structure Best Practices

### 1. OS and Distribution Detection

```bash
{{ if eq .chezmoi.os "linux" }}
    # Linux-generic code here
    
    {{ if eq .chezmoi.osRelease.id "arch" or eq .chezmoi.osRelease.id "endeavouros" }}
        # Arch-specific code
    {{ else if eq .chezmoi.osRelease.id "ubuntu" or eq .chezmoi.osRelease.id "debian" }}
        # Debian-based code
    {{ else if eq .chezmoi.osRelease.id "fedora" }}
        # Fedora-specific code
    {{ else }}
        # Fallback for other Linux distributions
        echo "Distribution-specific features not available for {{ .chezmoi.osRelease.id }}"
        # Attempt generic approach or graceful degradation
    {{ end }}
    
{{ else }}
    # Non-Linux OS handling
{{ end }}
```

### 2. Package Management Abstraction

Create distribution-specific package installation functions:

```bash
install_package() {
    local package="$1"
    
    {{ if eq .chezmoi.osRelease.id "arch" or eq .chezmoi.osRelease.id "endeavouros" }}
        sudo pacman -S --noconfirm "$package" || yay -S --noconfirm "$package"
    {{ else if eq .chezmoi.osRelease.id "ubuntu" or eq .chezmoi.osRelease.id "debian" }}
        sudo apt-get update && sudo apt-get install -y "$package"
    {{ else if eq .chezmoi.osRelease.id "fedora" }}
        sudo dnf install -y "$package"
    {{ else }}
        echo "Unsupported distribution for package installation: {{ .chezmoi.osRelease.id }}"
        return 1
    {{ end }}
}
```

### 3. Service Management

Use systemd where available, with fallbacks for non-systemd distributions:

```bash
enable_service() {
    local service="$1"
    
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl enable --now "$service"
    elif command -v service >/dev/null 2>&1; then
        sudo service "$service" start
        # Enable on boot using distribution-specific method
        {{ if eq .chezmoi.osRelease.id "ubuntu" or eq .chezmoi.osRelease.id "debian" }}
            sudo update-rc.d "$service" defaults
        {{ else }}
            echo "Unsupported distribution for service enablement: {{ .chezmoi.osRelease.id }}"
        {{ end }}
    else
        echo "No supported service manager found"
        return 1
    fi
}
```

## Data File Organization

### 1. Distribution-Specific Package Lists

Structure `.chezmoidata/packages.yaml` with distribution-specific sections:

```yaml
packages:
  install:
    arch:
      # Arch-specific packages and strategies
    
    debian:
      # Debian/Ubuntu packages and strategies
    
    fedora:
      # Fedora packages and strategies
    
    generic:
      # Packages with same names across distributions
```

### 2. Environment Variables

Use distribution-specific paths when necessary:

```yaml
paths:
  linux:
    # Generic Linux paths
    
    arch:
      # Arch-specific paths
    
    debian:
      # Debian-specific paths
```

## Testing and Validation

1. **Virtual Machine Testing**: Test scripts on different distributions using VMs
2. **Container Testing**: Use containers for quick validation
3. **Conditional Execution**: Add dry-run capabilities to test logic
4. **Logging**: Include detailed logs to identify distribution-specific issues

## Script Headers

All scripts should include standardized headers:

```bash
#!/bin/sh

# Script: script_name.sh.tmpl
# Purpose: Brief description of what this script does
# Requirements: Linux (or specific distributions if required)
# Supported Distributions: List of tested distributions
# Fallback Behavior: What happens on unsupported distributions
```

## Implementation Checklist

Before committing changes, verify:

- [ ] Script works on Arch-based distributions
- [ ] Script works on Debian-based distributions (or has appropriate fallbacks)
- [ ] Script works on Fedora (or has appropriate fallbacks)
- [ ] Distribution-specific code is properly isolated
- [ ] Fallback mechanisms are in place for unsupported distributions
- [ ] Error messages are clear and helpful

## Integration with Existing Rules

This rule complements the existing `04-arch-package-management-system.md` by extending its principles to other distributions. While the Arch-specific package management system remains valid for Arch-based systems, this rule provides guidance for ensuring scripts work across a wider range of Linux distributions.

### Relationship with Other Rules

- **01-chezmoi-core-principles.md**: Extends the cross-platform patterns section with more detailed distribution-specific guidance
- **04-arch-package-management-system.md**: Complements the Arch-specific package management with cross-distribution alternatives
- **06-repository-quality-standards.md**: Adds distribution compatibility as a quality criterion

## Verification Checklist

Before modifying scripts for cross-distribution compatibility:

<thinking>
1. Have I identified distribution-specific operations?
2. Have I provided alternatives for other distributions?
3. Have I tested on multiple distributions or provided fallbacks?
4. Are error messages clear and helpful?
5. Have I used distribution-agnostic approaches where possible?
</thinking>

### Critical Questions
1. 🔍 **Is this operation distribution-specific?**
2. 🔍 **What alternatives exist for other distributions?**
3. 🔍 **Have I provided graceful fallbacks?**
4. 🔍 **Are error messages clear and actionable?**

---

**REMEMBER**: Cross-distribution compatibility ensures that your configuration management system works reliably across different Linux distributions, making it more portable and flexible.
