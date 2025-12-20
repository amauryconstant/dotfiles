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

---

## omarchy-changes.sh

**Purpose**: Track and analyze omarchy repository changes with AI-powered semantic classification

**Capabilities**:
- Incremental release tracking (default)
- Historical analysis (all 46 releases)
- Searchable metadata index
- Range-based analysis
- GitHub API integration

### State Management

**Location**: `~/.local/state/omarchy-tracker/` (outside chezmoi)

**Files**:
- `last-tag` - Current tracked version (e.g., v3.2.3)
- `processed-tags` - All analyzed tags (--all mode)
- `index.json` - Searchable release metadata
- `releases/` - Cached AI analyses (future)

### Command Interface

**Incremental** (default):
```bash
omarchy-changes
# Check for new releases since last tracked version
# Prompts to update state after showing releases
```

**Historical analysis**:
```bash
omarchy-changes --all
# Process all 46 releases sequentially
# Updates state to latest version
```

**Index building**:
```bash
omarchy-changes --index
# Build searchable JSON index from releases
```

**Search**:
```bash
omarchy-changes --search theme
omarchy-changes --search "hook system"
# Query indexed releases by keyword (requires jaq)
```

**Range analysis**:
```bash
omarchy-changes --range v3.0.0 v3.2.3
# Analyze specific version range
```

**Help**:
```bash
omarchy-changes --help
# Show usage and examples
```

### Release Processing

**Data sources** (priority order):
1. GitHub API (release notes via curl)
2. Commit summary (git log fallback)

**Output format** (for AI classification):
```
═══════════════════════════════════════════════════════════
RELEASE DATA FOR AI CLASSIFICATION
═══════════════════════════════════════════════════════════

Analyze this Omarchy release:

Version: v3.2.3
Previous Version: v3.2.2
Commits Included: 15

Release Notes:
[GitHub release notes or commit summary]

Provide semantic classification and integration recommendations.
```

### First Run Behavior

**Initialization sequence**:
1. Detects no state file
2. Fetches latest tag from repository
3. Creates `~/.local/state/omarchy-tracker/last-tag`
4. Exits with instruction to run again

**Output**:
```
First run - initializing tag-based tracking...
State initialized at version v3.2.3
Run this command again to see new releases.
```

### Migration from v1

**Legacy state** (`last-commit` → `last-tag`):
- Auto-migrates commit-based to tag-based
- Finds corresponding tag for last commit
- Backs up old state file
- Falls back to latest tag if migration fails

### Dependencies

**Required**:
- git (repository access)
- curl (GitHub API)
- jaq or jq (JSON processing)

**Optional**:
- GitHub API access (for release notes, fallback to commits)
- Omarchy repo at `~/Projects/omarchy`

### Integration

**Claude Code skill**: `/omarchy-changes` (managed skill)

**Workflow**:
1. Skill runs omarchy-changes script
2. Captures release data
3. AI analyzes for patterns
4. Recommends features for dotfiles

### Index Structure

**File**: `~/.local/state/omarchy-tracker/index.json`

**Schema**:
```json
{
  "last_indexed": "2025-12-20T10:00:00Z",
  "releases": {
    "v3.2.3": {
      "date": "2025-11-29",
      "features": 5,
      "bug_fixes": 2,
      "categories": ["theme", "keybindings"],
      "integrations": ["alacritty-fallback"],
      "priority": "medium",
      "cached_analysis": "releases/v3.2.3.md"
    }
  }
}
```

**Note**: Index population requires AI processing (future enhancement)
