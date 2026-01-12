# Jujutsu Configuration - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/jj/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Jujutsu (jj-vcs) configuration
- **File**: config.toml.tmpl (TOML format)
- **Delta**: Inherits settings from git config
- **Pattern**: Mirrors git config (templated, NOT themed)

## Delta Integration Strategy

**Design Decision**: Delta settings NOT duplicated in jj config

**Rationale**:
- Delta reads `~/.config/git/config` automatically
- Single source of truth: git config `[delta]` section
- Navigate and side-by-side inherited seamlessly

**How It Works**:
1. JJ sets `ui.pager = "delta"`
2. Delta reads git config on startup
3. Settings applied: navigate, side-by-side, colors
4. Consistent behavior between git and jj

**Architecture**:
```
Git Config (~/.config/git/config)
│ [delta]
│   navigate = true
│   side-by-side = true
└─> Delta (reads automatically)
    └─> Used by both git and jj

JJ Config (~/.config/jj/config.toml)
│ [ui]
│   pager = "delta"
│   diff-formatter = ":git"
```

## Template Variables

```toml
[user]
name = "{{ .fullname }}"      # From .chezmoi.yaml.tmpl
email = "{{ .workEmail }}"    # From .chezmoi.yaml.tmpl
```

**Source**: `.chezmoi.yaml.tmpl` (fullname, workEmail)

## Configuration Sections

### User Identity

```toml
[user]
name = "{{ .fullname }}"
email = "{{ .workEmail }}"
```

**Purpose**: User identity for commits (mirrors git config)

### UI Settings

```toml
[ui]
pager = "delta"
diff-formatter = ":git"
```

**Purpose**:
- Fixes 'less' pager warning
- Integrates delta for beautiful diffs
- Git-style diff format for delta compatibility

### Aliases

**Git-like shortcuts** (muscle memory):
- `st`: status
- `l`: log -r "ancestors(@)" (daily workflow)

**Workflow helpers**:
- `sync`: git fetch --all-remotes (multi-remote)

**Community-validated**: From jj-vcs/jj discussions

## TOML Format Notes

**Jujutsu uses TOML** (not INI like git):
- Requires quotes for strings: `name = "value"`
- No indentation (unlike git)
- Arrays use brackets: `["status"]`

**Comparison**:
```ini
# Git (INI)
[user]
    name = value
```

```toml
# JJ (TOML)
[user]
name = "value"
```

## Validation

### Template Validation

```bash
# Test Go template rendering
chezmoi execute-template < config.toml.tmpl

# Preview rendered config
chezmoi cat ~/.config/jj/config.toml
```

### JJ Config Validation

```bash
# List all user config
jj config list --user

# Get specific values
jj config get user.name
jj config get user.email
jj config get ui.pager
```

### Delta Integration Test

```bash
# Create test repo
cd /tmp && jj init test-jj-delta && cd test-jj-delta

# Make changes
echo "line 1" > test.txt && jj commit -m "initial"
echo "line 2" >> test.txt && jj commit -m "second"

# Test delta rendering (should show colors, side-by-side)
jj log
jj diff -r @-

# Verify navigation works (press 'n' and 'N')
```

### Verify Delta Settings Inheritance

```bash
# Confirm delta reads git config
delta --show-config | grep -E "(navigate|side-by-side)"

# Expected output:
# navigate = true
# side-by-side = true

# Verify git config location
git config --list --show-origin | grep delta
# Should show: file:/home/amaury/.config/git/config
```

## Design Rationale

### Why NOT Duplicate Delta Settings?

**Rejected approach**:
```toml
[ui]
pager = ["sh", "-c", "delta --navigate --side-by-side"]
```

**Problems**:
- Violates DRY principle
- Two places to maintain
- Inconsistency risk
- Shell wrapper overhead

**Chosen approach**:
```toml
[ui]
pager = "delta"
```

**Benefits**:
- Single source of truth (git config)
- Automatic consistency
- Simpler maintenance
- Standard delta behavior

### Why These Aliases?

**Community validated** (jj-vcs/jj discussions):
- `st`: Most common git alias (muscle memory)
- `l`: Daily log viewing (ancestors of current commit)
- `sync`: Multi-remote workflow helper

**Omitted git aliases**:
- `co` (checkout): Not applicable (jj uses `jj edit`)
- `br` (branch): JJ uses bookmarks (`jj bookmark`)
- `cm` (commit): JJ workflow different (auto-commits working copy)

## Cross-References

- **Git config**: `../git/config.tmpl` (delta settings source of truth)
- **Git delta docs**: `../git/CLAUDE.md` (merge protection, template variables)
- **Template vars**: `../../.chezmoi.yaml.tmpl` (fullname, workEmail)
- **Packages**: `../../.chezmoidata/packages.yaml` (jujutsu, git-delta installation)
- **JJ docs**: https://docs.jj-vcs.dev/latest/config/

## Troubleshooting

### Issue: Template Variables Not Rendered

**Symptom**: Literal `{{ .fullname }}` in config

**Diagnosis**:
```bash
cat ~/.config/jj/config.toml
# Shows: name = "{{ .fullname }}" (wrong)
```

**Solution**: Verify `.tmpl` extension on source file

### Issue: Delta Not Using Navigate/Side-by-Side

**Symptom**: Delta works but no navigation

**Diagnosis**:
```bash
delta --show-config | grep navigate
# Should show: navigate = true
```

**Solution**: Verify git config applied
```bash
git config --get delta.navigate
chezmoi apply  # Re-apply git config
```

### Issue: JJ Doesn't Find Config

**Symptom**: Still sees 'less' warning

**Diagnosis**:
```bash
ls -la ~/.config/jj/config.toml
# Should exist

jj config list --user
# Should show settings
```

**Solution**:
```bash
chezmoi status  # Check if needs apply
chezmoi apply   # Apply config
```

## Integration Points

- **Git config**: `../git/config.tmpl` (delta settings)
- **Template vars**: `../../.chezmoi.yaml.tmpl` (user identity)
- **Packages**: `../../.chezmoidata/packages.yaml` (jujutsu, git-delta)
- **Pattern**: Mirrors git config (NOT themed like lazygit/bat)
