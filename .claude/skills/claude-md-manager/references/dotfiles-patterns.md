# CLAUDE.md Patterns for Dotfiles Repositories

Specific patterns and considerations for CLAUDE.md files in dotfiles/configuration management repositories.

## Dotfiles-Specific Characteristics

### Common Structure
Dotfiles repositories typically use location-based CLAUDE.md hierarchy:
```
~/.local/share/chezmoi/
├── CLAUDE.md                           # Core standards, architecture
├── private_dot_config/
│   ├── CLAUDE.md                       # XDG config overview
│   ├── hypr/CLAUDE.md                  # Hyprland-specific
│   ├── shell/CLAUDE.md                 # Shell config
│   └── themes/CLAUDE.md                # Theme system
└── private_dot_local/
    ├── CLAUDE.md                       # CLI architecture
    └── lib/scripts/
        ├── CLAUDE.md                   # Script library
        └── core/CLAUDE.md              # Core utilities
```

### Key Differences from Code Projects

**Configuration vs Code**:
- Dotfiles are configurations, not software
- Changes affect system behavior immediately
- Testing is manual (apply and verify)
- Backup/rollback critical

**Domain-Specific Knowledge**:
- Desktop environment patterns
- Shell configuration layering
- Template processing (chezmoi, etc.)
- System integration points

**User-Centric**:
- Personal workflows and preferences
- Hardware-specific configurations
- Privacy and security considerations

## What to Include in Dotfiles CLAUDE.md

### ✅ Configuration Management Patterns
```markdown
# Chezmoi Template Patterns
- Use `{{ .variable }}` syntax for Go templates
- Validate with: `chezmoi execute-template < file.tmpl`
- Preview output: `chezmoi cat path/to/file`
```

### ✅ System-Specific Commands
```markdown
# Hyprland Reload
- Config syntax: `hyprctl keyword <setting> <value>`
- Reload all: `hyprctl reload` or `Super+Shift+R`
- Test changes: `hyprctl keyword general:gaps_in 5`
```

### ✅ Tool Integration Points
```markdown
# Desktop Integration
- Waybar: Status bar (killall -SIGUSR2 waybar to reload)
- Dunst: Notifications (dunstctl reload)
- Wofi: Launcher (Super+D)
```

### ✅ File Naming Conventions
```markdown
# Chezmoi Naming
- `private_dot_*` → `~/.{name}`
- `encrypted_*` → Age-encrypted
- `executable_*` → Executable (755)
- `modify_*` → chezmoi_modify_manager
- `*.tmpl` → Template (processed)
```

### ✅ Security Constraints
```markdown
# CRITICAL: Never attempt to:
- Decrypt encrypted files programmatically
- Read .age file contents
- Access encryption keys directly
- Modify encryption config without user guidance
```

### ✅ Validation Workflows
```markdown
# Pre-Apply Validation
1. `chezmoi diff` - See what will change
2. `chezmoi apply --dry-run` - Test without applying
3. Manual verification of critical configs
4. Backup before major changes
```

## What to Exclude from Dotfiles CLAUDE.md

### ❌ Standard Tool Documentation
```markdown
# BAD: Repeating official docs
Git supports these commands:
- git add <file>
- git commit -m "message"
- git push origin main
```

Link instead: "See git documentation for basic commands"

### ❌ Desktop Environment Basics
```markdown
# BAD: Self-evident Hyprland knowledge
Hyprland is a Wayland compositor. It manages windows and workspaces.
Keybindings are defined in hyprland.conf.
```

Claude knows this. Document your specific keybindings and customizations.

### ❌ Complete Config Walkthroughs
```markdown
# BAD: File-by-file descriptions
- waybar/config.json: Waybar configuration with modules
- waybar/style.css: Waybar styling with colors
- dunst/dunstrc: Dunst notification daemon config
```

Document the patterns, integration points, and gotchas instead.

## Location-Based Hierarchy Guidelines

### Root CLAUDE.md
**Purpose**: Core standards, architecture overview, global patterns

**Include**:
- Repository-wide conventions
- Template system reference
- Security protocols
- Quality standards
- Cross-cutting concerns

**Example structure**:
```markdown
# Quick Reference
- Project type, target OS, constraints
- Links to subdirectory docs

# Critical Safety Protocols
- Security rules (encryption, secrets)
- Never-do items

# Architecture Quick Reference
- File naming conventions
- Directory structure
- Integration points

# Standards (MANDATORY)
- Script standards
- Template standards
- Quality checklist
```

### Subdirectory CLAUDE.md
**Purpose**: Specific implementation details for that component

**Include**:
- Component-specific patterns
- Configuration syntax
- Integration points
- Testing/reload procedures
- Cross-references to parent/root

**Example structure**:
```markdown
# Component Name - Claude Code Reference

**Location**: `/path/to/directory`
**Parent**: See `../CLAUDE.md` for overview
**Root**: See `/path/to/root/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for token-efficiency.

## Quick Reference
- Purpose, structure, key files

## Configuration Details
- Specific syntax and patterns

## Integration Points
- How this connects to other components
```

### Conciseness Directive
Many dotfiles CLAUDE.md files start with:
```markdown
**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.
```

This sets the tone for the entire file. Use sentence fragments, bullet points, and telegraphic style.

## Common Dotfiles Patterns

### Template Validation Examples
```markdown
# Good: Specific command with context
Template syntax: `chezmoi execute-template < file.tmpl`
Script syntax: `bash -n script.sh.tmpl`
Preview output: `chezmoi cat path/to/target`

# Bad: Generic instruction
Validate templates before applying
```

### Security Pattern
```markdown
# Good: Clear constraint with reasoning
🔐 ENCRYPTED FILES: Never decrypt programmatically
Manual only: `chezmoi decrypt <file>`, `chezmoi edit <file>`
Reason: Age encryption security model

# Bad: Vague warning
Be careful with encrypted files
```

### Integration Pattern
```markdown
# Good: Specific connections with commands
**Waybar**: `killall -SIGUSR2 waybar` (reload)
**Dunst**: `dunstctl reload` (reload)
Sources: `~/.config/themes/current/*.css` (theme integration)

# Bad: General relationship
Waybar integrates with the theme system
```

## Token Efficiency Strategies

### Use Tables
```markdown
# Good: Scannable table format
| File | Purpose | Template? |
|------|---------|-----------|
| monitor.conf.tmpl | Display settings | ✅ Yes |
| environment.conf | Env vars | ❌ No |

# Bad: Verbose list
- monitor.conf.tmpl: This file handles display settings like
  resolution, scaling, and position. It's a template file.
- environment.conf: This file sets up environment variables for
  NVIDIA, Qt/GTK, and XDG. It's not a template.
```

### Use Quick Reference Sections
```markdown
# Good: Front-loaded essentials
## Quick Reference
- Purpose: Hyprland compositor config
- Reload: Super+Shift+R or hyprctl reload
- Files: 9 modular configs in conf/

# Bad: Scattered throughout file
```

### Use Cross-References Instead of Duplication
```markdown
# Good: Reference pattern
**UI Library**: See `core/CLAUDE.md` for gum-ui.sh reference
**Package Manager**: See root CLAUDE.md for package management

# Bad: Copy-paste from other files
(400 lines of duplicated content)
```

## Validation for Dotfiles

### Chezmoi-Specific Checks
- [ ] Template syntax documented (`{{ }}` patterns)
- [ ] Validation commands provided
- [ ] Encryption security constraints clear
- [ ] File naming conventions explained
- [ ] No decryption attempts in examples

### Desktop Environment Checks
- [ ] Reload procedures documented
- [ ] Keybindings referenced, not listed exhaustively
- [ ] Integration points clear
- [ ] No desktop env basics (Claude knows Wayland/X11)

### Location Hierarchy Checks
- [ ] Root file covers architecture
- [ ] Subdirectory files reference parent
- [ ] Cross-references accurate
- [ ] No duplication between levels
- [ ] Each file has clear scope

### Configuration-Specific Checks
- [ ] Syntax examples use real config
- [ ] Commands are copy-pasteable
- [ ] File paths are absolute or clear
- [ ] Dependencies documented
- [ ] Integration points explicit

## Anti-Patterns in Dotfiles CLAUDE.md

### Over-Documentation of Standard Tools
```markdown
# BAD
Git is a version control system created by Linus Torvalds.
It tracks changes to files over time. Basic commands include:
- git init: Initialize a repository
- git add: Stage files for commit
- git commit: Create a commit
[... 50 more lines of git tutorial ...]
```

**Fix**: Link to git docs, document only your specific git workflow patterns.

### Listing Every Config File
```markdown
# BAD
## File Structure
~/.config/hypr/
├── hyprland.conf (main config file)
├── conf/
│   ├── monitor.conf (monitor configuration)
│   ├── environment.conf (environment variables)
│   ├── input.conf (input device configuration)
│   [... 20 more files with obvious names ...]
```

**Fix**: Use a tree structure without verbose descriptions for obvious files.

### Template Syntax Documentation
```markdown
# BAD
Go templates use {{ }} syntax. Variables are accessed with a dot.
You can use if statements, range loops, and functions.
The template system supports Sprig functions like default, upper, lower.
[... 100 lines of Go template tutorial ...]
```

**Fix**: Link to Go template docs, document only your specific template patterns.

### Exhaustive Keybinding Lists
```markdown
# BAD
## Keybindings (Complete List)
Super+1: Switch to workspace 1
Super+2: Switch to workspace 2
[... 80 more keybindings ...]
```

**Fix**: Reference keybinding file, document patterns or access method (Super+? for help).

## Maintenance for Dotfiles

### Review Triggers
- New component added (new desktop app, new script category)
- Configuration pattern changes
- Tool updated with breaking changes
- Security policy changes
- Template system changes

### Pruning Opportunities
- Temporary workarounds for old tool versions
- Deprecated configurations
- Removed components
- Superseded patterns
- Historical decisions no longer relevant

### Update Checklist
- [ ] New patterns documented
- [ ] Removed patterns deleted
- [ ] Tool version updates reflected
- [ ] Commands tested and current
- [ ] Cross-references validated
- [ ] Integration points accurate
