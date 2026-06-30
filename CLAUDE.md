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
- **Constraint**: Security-first — manual encryption at rest + package supply-chain policy (see `private_dot_local/lib/scripts/system/CLAUDE.md` → "Package Security Policy")
- **Monitor automation**: HyprDynamicMonitors (profiles), hyprwhenthen (events)
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
├── _guides/                # Operational procedures and setup guides
├── _research/              # Technology investigation and decision records
├── _plans/                 # Feature roadmaps and phased implementation plans
├── _ai/                    # Vendored upstream sources (git subtree) — API reference, not our code
├── .chezmoiscripts/        # Lifecycle scripts (run_once_*, run_onchange_*)
├── .chezmoitemplates/      # Reusable includes (log_*)
├── .scripts/               # Repository utilities (merge-driver)
├── private_dot_config/     # XDG config (hypr, waybar, wofi, zsh, etc.)
│   ├── dotfiles/           # Hook system
│   └── themes/             # Theme system
├── private_dot_keys/       # 🔐 Encrypted secrets
├── private_dot_ssh/        # SSH + encrypted keys
└── private_dot_local/
    ├── bin/                # CLI wrappers
    └── lib/scripts/        # Script library (per-domain categories)
```

**See**: Documentation Location Map (below) for detailed references

---

## Quality Standards (MANDATORY)

**Never run `chezmoi apply` without first reviewing `chezmoi diff`.** Templates and `modify_*` scripts render before they apply — validate rendered output, not source:

```bash
chezmoi execute-template < file.tmpl     # render a template (catches Go-template errors)
chezmoi cat path/to/target               # preview final applied output (templates + modify_manager merge)
chezmoi_modify_manager --help-syntax     # modify_manager directives are non-obvious; never assume syntax
```

Recovery: `git checkout HEAD~1 && chezmoi apply` reverts to the prior committed state. For merge conflicts see `private_dot_config/git/CLAUDE.md`; for the template merge driver see `.scripts/CLAUDE.md`.

---

## Documentation Location Map

**This section is your navigation guide**. Location-based CLAUDE.md files are automatically loaded when working in subdirectories.

### Knowledge Directories (repo-only, not deployed)

| Directory | Purpose | Examples |
|-----------|---------|---------|
| `_guides/` | Operational procedures and reference guides | `MULTI_DEVICE_BTRFS_SETUP.md` |
| `_research/` | Technology investigation and decision records | `LLM_BACKENDS_RESEARCH.md` |
| `_plans/` | Feature roadmaps and phased implementation plans | `VOICE_STT_ROADMAP.md` |
| `_ai/` | Vendored upstream sources via `git subtree` — read-only API/code reference (see `_guides/VENDORED_SUBTREES.md`) | `_ai/quickshell/` |

**`_ai/` is vendored, not ours**: ignored by chezmoi, linters, and formatters; marked `linguist-vendored`. Never hand-edit, lint, or reformat it — update via `git subtree pull`. See `_guides/VENDORED_SUBTREES.md` for per-subtree remotes + update commands.

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
- `wofi/` - Launcher
- `wlogout/` - Power menu
- `swaync/` - Notification center (themed via `.tmpl`)
- `themes/` - Theme system (semantic variables, Firefox/Spotify integration)
- `dotfiles/` - **Hook system** (user extensibility)
- `hyprdynamicmonitors/` - Monitor profile manager (port-agnostic matching)
- `hyprwhenthen/` - Event-driven window automation (OAuth popups, etc.)

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
| `lib/scripts/core/` | Gum UI library |
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
→ `private_dot_config/dotfiles/CLAUDE.md` (hook system)

**Working on merge conflicts?**
→ `private_dot_config/git/CLAUDE.md` (merge workflow)
→ `.scripts/CLAUDE.md` (merge driver details)

**Working on backups?**
→ `private_dot_local/lib/scripts/system/CLAUDE.md` (Timeshift integration)

**Working on monitor automation?**
→ `private_dot_config/hyprdynamicmonitors/CLAUDE.md` (TUI, profiles, port-agnostic matching)
→ `private_dot_config/hyprwhenthen/CLAUDE.md` (event handlers, regex patterns)

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
