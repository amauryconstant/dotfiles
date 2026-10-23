# CLAUDE.md

Technical guidance for Claude Code when developing in this repository.

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

---

## Quick Reference

- **Project**: Chezmoi dotfiles repository
- **Target OS**: Arch Linux (archinstall + Hyprland profile)
- **Desktop**: Hyprland + **Quickshell** (bar, launcher, notifications, power menu, popovers,
  pickers). Waybar, swaync, wlogout, polkit-gnome, hyprlock and Wofi are retired (no fallback tools; cliphist
  stays as the clipboard store)
- **Terminal**: Ghostty (only chezmoi-managed terminal — there is no `private_dot_config/kitty/`)
- **Languages**: Go templates (text/template + Sprig), Shell (POSIX sh)
- **Constraint**: Security-first — manual encryption at rest + package supply-chain policy (see `private_dot_local/lib/scripts/system/CLAUDE.md` → "Package Security Policy")
- **Monitor automation**: HyprDynamicMonitors (profiles)
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
| (nested `private_`) | — | Only on top-level dirs and inside `private_dot_ssh/`/`private_dot_keys/`. umask 0077 already makes all targets 600/700; after `chezmoi add` run `chezmoi chattr -- noprivate <target>` (`lint:private-prefix` enforces) |
| `encrypted_*` | Age-encrypted | `encrypted_key.txt.age` → `key.txt` |
| `executable_*` | Executable | `executable_script` → `script` (755) |
| `modify_*` | chezmoi_modify_manager | `modify_app.conf.tmpl` → managed |
| `create_*` | Write once, never update | `create_settings.json` → seed only |
| `run_once_*` | Run once | Setup scripts |
| `run_onchange_*` | Hash-triggered | Content-driven scripts |
| `*.tmpl` | Template | `config.tmpl` → `config` (processed) |

### Repository Structure (High-Level)

```
~/.local/share/chezmoi/
├── .claude/rules/          # Cross-cutting docs (chezmoi-data/scripts/templates/modify-entries, hyprland-lua)
├── .claude/settings.json   # Claude Code: permissions, hooks, env (ponytail mode + subagent scope)
├── .chezmoidata/           # Template data (packages, colors, globals)
├── _guides/                # Operational procedures and setup guides
├── _research/              # Technology investigation and decision records
├── _plans/                 # Feature roadmaps and phased implementation plans
├── _ai/                    # Vendored upstream sources (git subtree) — API reference, not our code
├── .chezmoiscripts/        # Lifecycle scripts (run_once_*, run_onchange_*)
├── .chezmoitemplates/      # Reusable includes (log_*)
├── .scripts/               # Repository utilities (merge-driver, merge-guard)
├── .patches/               # Patches applied to upstream sources at build time (not deployed)
├── .mise/                  # Lint/format tasks + pre-commit hook entrypoints
├── .chezmoiexternal.yaml   # Externally-fetched assets
├── private_dot_config/     # XDG config (hypr, quickshell, zsh, etc.)
│   ├── dotfiles/           # Hook system
│   ├── quickshell/         # Quickshell shell (bar) — behind a features flag
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

**Never run `chezmoi merge` / `merge-all` on a `modify_*` or `*.tmpl` entry.** `.Source` is the *generator*, not a prior revision of the target, so merging overwrites it with rendered data — this has destroyed files here, once silently, and once leaking a decrypted API key into a tracked file. `.scripts/chezmoi-merge-guard.sh` now refuses these via `merge.command`, but it cannot repair an already-corrupt source. Use `chezmoi_modify_manager --smart-add` (modify_manager) or hand-edit after `chezmoi diff` (templates). See `.claude/rules/chezmoi-modify-entries.md`.

**Commit only through the `commit` skill.** `.claude/hooks/require-commit-skill.sh` blocks `git commit` until the session has invoked it (Skill tool or typed `/commit`); one invocation covers the rest of the session.

Recovery: `git checkout HEAD~1 && chezmoi apply` reverts to the prior committed state. For a clobbered generator: `git checkout HEAD -- <path>`. For merge conflicts see `private_dot_config/git/CLAUDE.md`; for the template merge driver see `.scripts/CLAUDE.md`.

### Lint & Format (mise)

`mise` owns every linter/formatter and installs the pre-commit hook (`[tools]` postinstall).

```bash
mise run lint       # sh + yaml + json + lua (+ lua-tmpl) + qml + qml-rules + md + theme-contrast + theme-hex + hypr-lua; silent unless something fails
mise run format     # sh + yaml + lua + qml + md, write mode
mise run verify     # format, then lint (manual — pre-commit only lints, it never rewrites)
mise run chezmoi:orphans # staged deletions whose deployed target is not in .chezmoiremove (the pre-commit hook)
mise run chezmoi:orphans -- --all # audit owned dirs (chezmoi unmanaged); exit 1 on leftovers, also after the commit
```

**Deleting a deployed file's source?** Add its target to `.chezmoiremove` in the same commit: chezmoi never removes a target on its own, and `chezmoi apply` deletes the listed ones on every machine. A hand-run `rm` fixes one chassis. Stopping a running unit or process stays manual.

Scope is deliberately narrow: `lint:md` covers `**/opencode/**` only, `lint:yaml` covers `.chezmoidata/` only. `format:lua` is `*.lua` only — templates are check-only (rendering discards the template actions).

Pre-commit runs staged-file variants: `chezmoi:orphans`, `lint:staged` (shellcheck), `lint:chezmoi-sources` (generator marker-loss vs HEAD + `chezmoi cat` render + gitleaks), `lint:lua-staged`, `lint:json-staged`, `lint:yaml-staged`, then the full `lint`.

---

## Documentation Location Map

**This section is your navigation guide**. Location-based CLAUDE.md files are automatically loaded when working in subdirectories.

### Knowledge Directories (repo-only, not deployed)

| Directory | Purpose | Examples |
|-----------|---------|---------|
| `_guides/` | Operational procedures and reference guides | `MULTI_DEVICE_BTRFS_SETUP.md` |
| `_research/` | Technology investigation and decision records | `FIREFOX_NVIDIA_EGL_DEADLOCK.md` |
| `_plans/` | Feature roadmaps and phased implementation plans | `RESTIC_OFFSITE_BACKUP.md` |
| `.patches/` | Patches a `.chezmoiscripts/` build applies to a pinned upstream commit; rationale lives in `_research/` | `egl-wayland2-bounded-frame-wait.patch` |
| `_ai/` | Vendored upstream sources via `git subtree` — read-only API/code reference (see `_guides/VENDORED_SUBTREES.md`) | `_ai/quickshell/` |

**Archives**: each of `_guides/`, `_plans/`, `_research/` has an `archive/` for finished or superseded docs (banner `**Status**: ARCHIVED <date>` names why). They are evidence, not backlogs: do not take work from them or trust their file paths.

**`_ai/` is vendored, not ours**: ignored by chezmoi, linters, and formatters; marked `linguist-vendored`. Never hand-edit, lint, or reformat it — update via `git subtree pull`. See `_guides/VENDORED_SUBTREES.md` for per-subtree remotes + update commands.

### Cross-Cutting Topics (.claude/rules/)

**Path-scoped**: each file loads only when you touch matching paths (`paths:` frontmatter), so
read the relevant one explicitly when starting from elsewhere.

**When working with chezmoi features across the codebase**:

| File | Topics Covered |
|------|----------------|
| `chezmoi-data.md` | Data files (packages.yaml, ai.yaml, etc.), template variables, hash triggers |
| `chezmoi-scripts.md` | Lifecycle scripts (run_once_*, run_onchange_*), execution order, script types |
| `chezmoi-templates.md` | Template system, log templates, Go template syntax, validation |
| `chezmoi-chassis.md` | Laptop/desktop gating: where the condition goes, rendering the other chassis branch |
| `chezmoi-modify-entries.md` | `modify_*` entries — the two kinds (modify_manager vs native modify-template), merge safety, directive/validation reference |
| `hyprland-lua.md` | Hyprland Lua config — `hl`/`o` globals, theme/monitor profile patterns, rgba format, stylua + `--verify-config` validation |
| `quickshell-qml.md` | Quickshell QML — imports, Qt5/Qt6 tooling trap, lint exemption discipline, runtime gotchas, IPC |
| `quickshell-design.md` | Quickshell geometry, accent rule, contrast, `Theme.action`, theming (loads for files that draw something) |

### Repository Utilities

| Directory | Topics Covered |
|-----------|----------------|
| `.scripts/` | Template merge driver, repository tools |

### Configuration (private_dot_config/)

**Desktop environment**:
- `hypr/` - Hyprland compositor config
- `themes/` - Theme system (semantic variables, Firefox/Spotify integration)
- `dotfiles/` - **Hook system** (user extensibility)
- `hyprdynamicmonitors/` - Monitor profile manager (port-agnostic matching)

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

**Working on Hyprland Lua config?**
→ `.claude/rules/hyprland-lua.md` (globals, formatting, validation tasks)
→ `private_dot_config/hypr/CLAUDE.md` (Hyprland overview)

**Working on themes?**
→ `private_dot_config/themes/CLAUDE.md` (semantic variables, app integration)

**Working on hooks?**
→ `private_dot_config/dotfiles/CLAUDE.md` (hook system)

**Working on merge conflicts?**
→ `private_dot_config/git/CLAUDE.md` (merge workflow)
→ `.scripts/CLAUDE.md` (merge driver details)

**Working on backups?**
→ `private_dot_local/lib/scripts/system/CLAUDE.md` (Timeshift integration)

**Working on the Quickshell shell?** (the bar is one of its 21 shipped surfaces)
→ `private_dot_config/quickshell/CLAUDE.md` — **start here**: what the shell is today, surface by
surface, and why each departure
→ `.claude/rules/quickshell-qml.md` (QML syntax, tooling, runtime traps) and `quickshell-design.md` (geometry, accent, contrast, theming)
→ `_research/archive/QUICKSHELL_RULE_EVIDENCE.md` (the measurements behind both)
→ `_plans/archive/QUICKSHELL_TOOL_RETIREMENT.md` (the removal side, closed 2026-10-19) — **no Quickshell plan is open**
→ `_research/QUICKSHELL_QML_API.md` (the quickshell 0.3.1 API, corrected five times)

🚨 **The build closed on 2026-09-13 and nine of the eleven Quickshell documents are now in
`_research/archive/` or `_plans/archive/`.** They are evidence — measurements, rulings, what each
surface is made of — not backlogs. Taking a task from one is the standing hazard.

**Testing a Hyprland/Quickshell change visually before `chezmoi apply`?**
→ `.claude/skills/desk/SKILL.md` (nested desktop on the rendered source; screenshots Claude can read)

**Working on monitor automation?**
→ `private_dot_config/hyprdynamicmonitors/CLAUDE.md` (TUI, profiles, port-agnostic matching)

---

## Documentation Maintenance Protocol

### Update Patterns

**Package additions**:
- Update `.chezmoidata/packages.yaml` only
- Global mise tools: `.chezmoidata/mise.yaml` (module by job, never by backend)
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
