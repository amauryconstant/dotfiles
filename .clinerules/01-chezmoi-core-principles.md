---
description: Comprehensive guide to chezmoi dotfiles management principles, file naming conventions, and template syntax for this repository
author: Repository Owner
version: 1.0
tags: ["chezmoi", "core-knowledge", "dotfiles", "templates"]
globs: ["**/*.tmpl", ".chezmoi*", ".chezmoiscripts/**/*"]
---

# Chezmoi Core Principles

This repository uses chezmoi for sophisticated dotfiles management with templates, encryption, and cross-platform support. Understanding these core principles is ESSENTIAL for working effectively with this codebase.

## File Naming Conventions

### **MUST** Follow These Naming Patterns

- **`private_dot_`**: Private files that should not be world-readable
  - Example: `private_dot_config/` → `~/.config/`
  - Example: `private_dot_ssh/` → `~/.ssh/`

- **`encrypted_`**: Files encrypted with age encryption
  - Example: `encrypted_private_github.age` → decrypted SSH key
  - **🚨 CRITICAL**: NEVER attempt to decrypt these files - see encryption protocol

- **`.tmpl`**: Template files processed with Go template syntax
  - Example: `config.tmpl` → `config` (after template processing)
  - Contains variables like `{{ .firstname }}`, `{{ .osId }}`

- **`modify_`**: Files managed by chezmoi_modify_manager
  - Example: `modify_nextcloud.cfg.tmpl` → processed by chezmoi_modify_manager
  - Used for INI files with mixed settings/state

### Directory Structure Understanding

```
.chezmoidata/          # YAML data files for templates
├── packages.yaml      # Package management configuration
├── ai.yaml           # AI models configuration
├── extensions.yaml   # VSCode extensions
├── colors.yaml       # Color scheme definitions
└── globals.yaml      # Global environment variables

.chezmoiscripts/       # Lifecycle scripts
├── run_once_*        # Run only once per machine
├── run_onchange_*    # Run when content changes (hash-based)
├── run_before_*      # Run before applying changes
└── run_after_*       # Run after applying changes

private_dot_config/    # Private configuration files
private_dot_keys/      # Encrypted keys and secrets
private_dot_ssh/       # SSH configuration and keys
```

## Template Syntax Mastery

### Variables Available
From `.chezmoi.yaml.tmpl`:
- `{{ .fullname }}` - Full name
- `{{ .firstname }}` - First name only
- `{{ .workEmail }}` - Work email address
- `{{ .personalEmail }}` - Personal email address
- `{{ .privateServer }}` - Private server URL
- `{{ .osId }}` - OS identifier (e.g., "linux-arch")
- `{{ .chassisType }}` - "desktop" or "laptop"

### Common Template Patterns

#### OS Detection
```go
{{ if eq .osId "linux-arch" }}
    # Arch Linux specific code
{{ else }}
    echo "ERROR: This script is only supported on Arch Linux systems"
    exit 1
{{ end }}
```

#### Variable Transformation
```go
{{ .firstname | lower }}           # Convert to lowercase
{{ .privateServer | replace "www" "nextcloud" }}  # String replacement
```

#### Including Data Files
```go
# Hash: {{ include ".chezmoidata/packages.yaml" | sha256sum }}
```

#### Iterating Over Data
```go
{{ range .ai.models -}}
    echo "Installing {{.}}"
    ollama pull {{.}}
{{ end -}}
```

## Script Lifecycle Understanding

### **MUST** Use Correct Script Types

1. **`run_once_before_*`**: Setup scripts that run once before applying
   - Package manager installation
   - Directory creation
   - System prerequisites

2. **`run_once_after_*`**: Configuration scripts that run once after applying
   - Service enablement
   - Final configuration steps

3. **`run_onchange_*`**: Scripts that run when content changes
   - Package updates (hash-based detection)
   - Extension installation
   - Model updates

### Script Naming Convention
```
run_[frequency]_[timing]_[order]_[description].sh.tmpl
```
- `frequency`: `once` or `onchange`
- `timing`: `before` or `after`
- `order`: 3-digit number (001, 002, etc.)
- `description`: Clear description of purpose

## Cross-Platform Patterns

### OS-Specific Logic
```bash
{{ if eq .osId "linux-arch" }}
    # Arch Linux implementation
{{ else if eq .osId "linux-ubuntu" }}
    # Ubuntu implementation
{{ else }}
    echo "Unsupported OS: {{ .osId }}"
    exit 1
{{ end }}
```

### Chassis Type Detection
```bash
{{ if eq .chassisType "laptop" }}
    # Laptop-specific configuration
{{ else }}
    # Desktop configuration
{{ end }}
```

## Data File Integration

### **MUST** Understand Data Structure
- All data files in `.chezmoidata/` are available as template variables
- YAML structure becomes nested objects in templates
- Arrays can be iterated with `range`

### Example Data Usage
```yaml
# .chezmoidata/packages.yaml
packages:
  install:
    arch:
      packages:
        fonts:
          list:
            - ttf-firacode-nerd
```

```go
# In template
{{ range .packages.install.arch.packages.fonts.list }}
    pacman -S {{ . }}
{{ end }}
```

## Error Handling Patterns

### **MUST** Include OS Validation
```bash
{{ if eq .osId "linux-arch" }}
    # Implementation
{{ else }}
    echo "ERROR: This script is only supported on Arch Linux systems"
    echo "Required: osId 'linux-arch'"
    echo "Detected: '{{ .osId }}'"
    echo "Script: $(basename "$0")"
    exit 1
{{ end }}
```

### **SHOULD** Include Function Definitions
```bash
# Define utility functions
is_package_installed() {
    local package="$1"
    pacman -Qi "$package" >/dev/null 2>&1 || yay -Qi "$package" >/dev/null 2>&1
}
```

## Chezmoi Commands Reference

### **MUST** Use These Commands Safely

- `chezmoi diff` - **ALWAYS** run before applying changes
- `chezmoi apply --dry-run` - Preview changes without applying
- `chezmoi apply` - Apply changes to system
- `chezmoi update` - Pull and apply changes from source
- `chezmoi edit <file>` - Edit source file
- `chezmoi add <file>` - Add file to chezmoi management

### **NEVER** Run These Without Understanding
- `chezmoi apply` without first running `chezmoi diff`
- Template modifications without testing syntax
- Script changes without understanding lifecycle

## Integration with External Tools

### Age Encryption
- Files with `.age` extension are encrypted
- Managed through separate key infrastructure
- **NEVER** attempt programmatic decryption

### chezmoi_modify_manager
- Handles INI files with mixed settings/state
- Uses `modify_*.tmpl` naming pattern
- Integrates with chezmoi templates

### Git Integration
- Uses delta for diff viewing
- Uses mergiraf for merge conflicts
- Hooks managed through scripts

## **CRITICAL VERIFICATION STEPS**

Before making ANY changes to this repository:

1. ✅ **Verify OS compatibility** - Check `{{ .osId }}` requirements
2. ✅ **Validate template syntax** - Ensure proper Go template format
3. ✅ **Check data dependencies** - Verify required data files exist
4. ✅ **Test script logic** - Understand script lifecycle and dependencies
5. ✅ **Review encryption impact** - Never modify encrypted file handling
6. ✅ **Validate file naming** - Follow exact naming conventions

## Common Mistakes to Avoid

❌ **NEVER** modify encrypted files directly
❌ **NEVER** change file naming conventions
❌ **NEVER** skip OS validation in scripts
❌ **NEVER** apply changes without running `chezmoi diff` first
❌ **NEVER** assume cross-platform compatibility without testing

✅ **ALWAYS** follow template syntax exactly
✅ **ALWAYS** include proper error handling
✅ **ALWAYS** test changes in dry-run mode first
✅ **ALWAYS** understand the script lifecycle
✅ **ALWAYS** respect the data file structure
