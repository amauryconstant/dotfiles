# CLAUDE.md

Technical guidance for Claude Code when developing in this repository.

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

---

## Quick Reference

- **Project**: Chezmoi dotfiles repository
- **Target OS**: Arch Linux (archinstall + Hyprland profile)
- **Desktop**: Hyprland + Waybar + Wofi
- **Terminal**: Ghostty (primary), Kitty (baseline)
- **Languages**: Go templates (text/template + Sprig), Shell (POSIX sh)
- **Constraint**: Security-first, manual encryption only
- **Docs**: README.md for user-facing, CLAUDE.md for dev patterns

---

## 🚨 CRITICAL SAFETY PROTOCOLS

### **NEVER** Attempt These

❌ Decrypt encrypted files programmatically
❌ Read `.age` file contents
❌ Access encryption keys directly
❌ Modify encryption config without explicit user guidance
❌ Bypass security protocols for convenience

### **ALWAYS** Guide Manual Encryption

```bash
# Guide user to run manually:
chezmoi decrypt path/to/file.age        # View
chezmoi edit path/to/file.age           # Edit
chezmoi add --encrypt path/to/file      # Encrypt
```

---

## Architecture Quick Reference

### File Naming Conventions

| Prefix | Target | Example |
|--------|--------|---------|
| `private_dot_*` | `~/.{name}` | `private_dot_config/` → `~/.config/` |
| `encrypted_*` | Age-encrypted | `encrypted_key.txt.age` → `key.txt` |
| `executable_*` | Executable | `executable_script` → `script` (755) |
| `modify_*` | chezmoi_modify_manager | `modify_app.conf.tmpl` → managed |
| `run_once_*` | Run once | Setup scripts |
| `run_onchange_*` | Hash-triggered | Content-driven scripts |
| `*.tmpl` | Template | `config.tmpl` → `config` (processed) |

### Repository Structure (High-Level)

```
~/.local/share/chezmoi/
├── .claude/rules/          # Cross-cutting documentation (chezmoi-data, scripts, templates)
├── .chezmoidata/           # Template data (packages, colors, globals)
├── .chezmoiscripts/        # Lifecycle scripts (run_once_*, run_onchange_*)
├── .chezmoitemplates/      # Reusable includes (log_*)
├── .scripts/               # Repository utilities (merge-driver)
├── private_dot_config/     # XDG config (hypr, waybar, wofi, zsh, etc.)
│   ├── dotfiles/           # Hook system (6 hook points)
│   └── themes/             # Theme system (8 variants)
├── private_dot_keys/       # 🔐 Encrypted secrets
├── private_dot_ssh/        # SSH + encrypted keys
└── private_dot_local/
    ├── bin/                # CLI wrappers (14 executables)
    └── lib/scripts/        # Script library (49 scripts in 10 categories)
```

**See**: Documentation Location Map (below) for detailed references

---

## Quality Standards (MANDATORY)

### Pre-Change Validation

```bash
# 1. Check current state
chezmoi diff

# 2. Check for merge conflicts
chezmoi status

# 3. Dry-run validation
chezmoi apply --dry-run

# 4. Template syntax validation
chezmoi execute-template < template.tmpl

# 5. Script syntax validation
bash -n script.sh.tmpl

# 6. chezmoi_modify_manager validation
chezmoi_modify_manager --help-syntax
chezmoi execute-template < modify_script.tmpl
chezmoi cat path/to/target/file
```

### Never Skip

❌ Run `chezmoi apply` without `chezmoi diff`
❌ Modify templates without syntax validation
❌ Change scripts without testing
❌ Modify chezmoi_modify_manager without validating syntax
❌ Assume chezmoi_modify_manager syntax

---

## Emergency Procedures

### If Something Goes Wrong

```bash
# Immediate response
git checkout HEAD~1
chezmoi apply

# Assessment
chezmoi diff
chezmoi status

# Recovery
chezmoi apply specific/file
chezmoi verify
```

### If Merge Conflicts Occur

```bash
# Detection
chezmoi status

# Resolution
chezmoi merge <file>        # Targeted
chezmoi merge-all          # All conflicts

# Validation
chezmoi diff
chezmoi status
```

**See**: `private_dot_config/git/CLAUDE.md` for merge conflict resolution
**See**: `.scripts/CLAUDE.md` for template merge driver

---

## Documentation Location Map

**This section is your navigation guide**. Location-based CLAUDE.md files are automatically loaded when working in subdirectories.

### Cross-Cutting Topics (.claude/rules/)

**When working with chezmoi features across the codebase**:

| File | Topics Covered |
|------|----------------|
| `chezmoi-data.md` | Data files (packages.yaml, ai.yaml, etc.), template variables, hash triggers |
| `chezmoi-scripts.md` | Lifecycle scripts (run_once_*, run_onchange_*), execution order, script types |
| `chezmoi-templates.md` | Template system, log templates, Go template syntax, validation |

### Repository Utilities

| Directory | Topics Covered |
|-----------|----------------|
| `.scripts/` | Template merge driver, repository tools |

### Configuration (private_dot_config/)

**Desktop environment**:
- `hypr/` - Hyprland compositor config
- `waybar/` - Status bar
- `dunst/` - Notifications
- `wofi/` - Launcher
- `wlogout/` - Power menu
- `themes/` - Theme system (8 variants, semantic variables, VSCode/Firefox/Spotify integration)
- `dotfiles/` - **Hook system** (6 hook points, user extensibility)

**Shell & terminal**:
- `shell/` - Common shell config (POSIX)
- `jj/` - Jujutsu version control

**Applications**:
- `git/` - Git config, merge conflict resolution
- `Nextcloud/` - Nextcloud client (chezmoi_modify_manager examples)
- `systemd/user/` - User services

### Scripts & CLI (private_dot_local/)

| Directory | Topics Covered |
|-----------|----------------|
| `CLAUDE.md` | CLI architecture, lazy-loading pattern |
| `bin/` | CLI wrapper patterns |
| `lib/scripts/` | **Script standards (MANDATORY)**, shellcheck integration, UI patterns |
| `lib/scripts/core/` | Gum UI library (35 functions) |
| `lib/scripts/system/` | **Package management**, backup (Timeshift), GPU drivers, DKMS troubleshooting |
| `lib/scripts/desktop/` | Hyprland utilities |

### Key Topics by Task

**Working on scripts?**
→ `private_dot_local/lib/scripts/CLAUDE.md` (Script Standards, Shellcheck)

**Working on packages?**
→ `.claude/rules/chezmoi-data.md` (packages.yaml structure)
→ `private_dot_local/lib/scripts/system/CLAUDE.md` (package-manager deep dive, GPU drivers)

**Working on templates?**
→ `.claude/rules/chezmoi-templates.md` (template syntax, log templates)
→ `.claude/rules/chezmoi-data.md` (template variables)

**Working on lifecycle scripts?**
→ `.claude/rules/chezmoi-scripts.md` (execution order, script types)

**Working on themes?**
→ `private_dot_config/themes/CLAUDE.md` (semantic variables, app integration)

**Working on hooks?**
→ `private_dot_config/dotfiles/CLAUDE.md` (hook system, 6 hook points)

**Working on merge conflicts?**
→ `private_dot_config/git/CLAUDE.md` (merge workflow)
→ `.scripts/CLAUDE.md` (merge driver details)

**Working on backups?**
→ `private_dot_local/lib/scripts/system/CLAUDE.md` (Timeshift integration)

---

## Documentation Maintenance Protocol

### Update Patterns

**Package additions**:
- Update `.chezmoidata/packages.yaml` only
- No additional documentation needed (self-documenting)

**New script patterns**:
- Update `private_dot_local/lib/scripts/CLAUDE.md` if introducing new patterns
- Reference actual scripts, don't create inline examples

**New template techniques**:
- Add to `.claude/rules/chezmoi-templates.md`
- Reference working files: `See: private_dot_config/zsh/dot_zshrc.tmpl`
- Keep inline examples minimal

**Location-specific docs**:
- Update relevant subdirectory CLAUDE.md files
- Keep root CLAUDE.md for core standards only
- Cross-reference between files

**General principles**:
- ✅ ALWAYS reference working files (not inline examples)
- ✅ Keep docs close to code (single source of truth)
- ✅ Update README.md for user-facing, CLAUDE.md for dev patterns
- ✅ Use location-specific CLAUDE.md for detailed implementation docs
- ❌ NEVER duplicate information
- ❌ NEVER create extensive inline examples
