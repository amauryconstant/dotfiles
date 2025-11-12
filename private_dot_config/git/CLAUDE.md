# Git Configuration - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/git/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Git configuration and merge protection
- **Files**: config.tmpl, attributes
- **Feature**: Template variable protection during merges
- **Setup**: `.chezmoiscripts/run_once_after_005_configure_git_tools.sh.tmpl`

## Template Variable Protection

**Problem**: Git merges render template variables

**Example**:
- Before merge: `{{ .firstname }}`
- After merge: `John` (rendered, breaks template)

**Solution**: Custom merge driver preserves `{{ .variable }}`

### Components

**Git Attributes** (`.gitattributes`):
```
*.tmpl merge=chezmoi-template
```

**Custom Merge Driver** (`.scripts/template-merge-driver.sh`):
- Prioritizes versions with template syntax
- Preserves `{{ .variable }}` format
- Falls back to standard merge when both have templates

**Auto-Configuration** (`run_once_after_005_configure_git_tools.sh.tmpl`):
- Installs merge driver
- Configures git config
- Sets up execution permissions

### How It Works

1. Git detects `.tmpl` files during merge
2. Custom merge driver invoked
3. Driver prioritizes versions with template syntax
4. Template variables preserved as `{{ .variable }}`
5. Falls back to standard merge if both have templates

## Git Configuration

**File**: `config.tmpl`

**Template variables**:
```ini
[user]
    name = {{ .fullname }}
    email = {{ .personalEmail }}

[core]
    editor = {{ .globals.applications.editor }}

[merge "chezmoi-template"]
    name = Chezmoi template merge driver
    driver = ~/.scripts/template-merge-driver.sh %O %A %B %L
```

**Sections**:
- User identity (name, email)
- Core settings (editor, pager)
- Merge driver (template protection)
- Aliases (shortcuts)
- UI colors (diff, status)

## Safe Merge Workflow

**Check status**:
```bash
chezmoi diff
chezmoi status
```

**Merge operations**:
```bash
chezmoi merge <file>        # Targeted
chezmoi merge-all          # All conflicts
```

**Validation**: Template syntax automatically preserved

**Emergency restore**:
```bash
git checkout HEAD -- <file>
```

## Manual Resolution

**Detect conflicts**:
```bash
chezmoi status  # Look for "M" status
```

**Resolve conflicts**:
```bash
chezmoi merge <file>        # Single file
chezmoi merge-all          # All files
```

**Validate results**:
```bash
chezmoi diff
chezmoi status
```

**Special cases**: Encrypted files (`.age`) require manual workflow

## Template Merge Driver

**Location**: `.scripts/template-merge-driver.sh`

**Purpose**: Preserve template syntax during merges

**Algorithm**:
1. Check if ancestor has templates
2. Check if current has templates
3. Check if other has templates
4. Prioritize version with templates
5. Fall back to standard merge

**Exit codes**:
- 0: Success (no conflict)
- 1: Conflict (manual resolution needed)

## Integration Points

- **Gitattributes**: `.gitattributes` (merge=chezmoi-template)
- **Setup script**: `.chezmoiscripts/run_once_after_005_configure_git_tools.sh.tmpl`
- **Template vars**: `.chezmoi.yaml.tmpl` (fullname, email)
- **Merge driver**: `.scripts/template-merge-driver.sh`
