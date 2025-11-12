# Helper Scripts - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/.scripts/`
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Repository-level helper scripts
- **Key script**: template-merge-driver.sh
- **Setup**: `.chezmoiscripts/run_once_after_005_configure_git_tools.sh.tmpl`
- **Target**: Not applied to system (repo utilities only)

## Template Merge Driver

**File**: `template-merge-driver.sh`

**Purpose**: Preserve template syntax during Git merges

**Problem**: Git merges render template variables
- Before: `{{ .firstname }}`
- After: `John` (breaks template)

**Solution**: Custom merge driver prioritizes template syntax

### Algorithm

**Merge strategy**:
1. Check ancestor file for templates (`{{ }}`)
2. Check current file for templates
3. Check other file for templates
4. Prioritize version with templates
5. Fall back to standard merge if both have templates

**Exit codes**:
- 0: Success (no conflict)
- 1: Conflict (manual resolution needed)

**Template detection**:
```bash
grep -q '{{.*}}' "$file"
```

### Git Integration

**Git config** (`.config/git/config.tmpl`):
```ini
[merge "chezmoi-template"]
    name = Chezmoi template merge driver
    driver = ~/.scripts/template-merge-driver.sh %O %A %B %L
```

**Git attributes** (`.gitattributes`):
```
*.tmpl merge=chezmoi-template
```

**Parameters**:
- `%O` - Ancestor file (base)
- `%A` - Current file (ours)
- `%B` - Other file (theirs)
- `%L` - Conflict marker size

### Setup Script

**File**: `.chezmoiscripts/run_once_after_005_configure_git_tools.sh.tmpl`

**Actions**:
1. Copy merge driver to `~/.scripts/`
2. Make executable (`chmod +x`)
3. Configure git merge driver
4. Validate configuration

**Validation**:
```bash
# Check merge driver configured
git config merge.chezmoi-template.driver

# Check gitattributes
cat .gitattributes | grep "merge=chezmoi-template"
```

## Usage

**Automatic** (on merge):
```bash
git merge feature-branch
# Template protection automatic for *.tmpl files
```

**Manual resolution** (if conflicts):
```bash
chezmoi merge <file>        # Single file
chezmoi merge-all          # All conflicts
```

**Verification**:
```bash
chezmoi diff
chezmoi status
```

## Integration Points

- **Git config**: `.config/git/config.tmpl` (merge driver definition)
- **Git attributes**: `.gitattributes` (*.tmpl rule)
- **Setup script**: `.chezmoiscripts/run_once_after_005_configure_git_tools.sh.tmpl`
- **Target**: `~/.scripts/template-merge-driver.sh` (installed location)
