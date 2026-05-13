# Package-Manager v3.0 - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/system/package-manager/`
**Parent**: See `../CLAUDE.md` for system scripts overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Version**: 3.0.0
- **Purpose**: Module-based declarative package management with NixOS-style version pinning
- **Architecture**: 4-layer modular design (31 files)
- **Key features**: Version constraints, lockfile, hybrid update, Timeshift backup integration

## Quick Commands

```bash
# Module management
package-manager module list
package-manager module enable base shell

# Package operations
package-manager sync              # Sync to packages.yaml
package-manager sync --prune      # Sync + remove orphans
package-manager install firefox   # Install single package
package-manager update            # Sync + update all packages

# Version pinning
package-manager pin firefox 120.0
package-manager lock              # Generate lockfile

# Status & validation
package-manager status
package-manager validate
package-manager outdated
```

---

## Architecture Overview

```
package-manager/ (31 files)
├── executable_package-manager.sh  # Entry point (521 lines)
├── core/               # Foundation
│   ├── state-manager.sh     # Centralized state/cache (5 assoc. arrays)
│   ├── constants.sh         # Type-safe constants (PACKAGE_TYPE_*, etc.)
│   ├── config.sh            # Module access with caching (16 yq → 1)
│   ├── state.sh             # State file I/O, atomic mutations, backups
│   ├── performance.sh       # Lazy-loading caches (Flatpak + Pacman)
│   └── validation.sh        # Batch AUR validation (24x faster)
├── operations/         # Workflows
│   ├── sync-orchestrator.sh # 5-phase sync workflow
│   ├── sync-pacman.sh       # Pacman sync + lockfile fast-path
│   ├── sync-flatpak.sh      # Flatpak sync (user-scope only)
│   ├── sync-lock.sh         # Flock-based concurrent sync protection
│   ├── backup-manager.sh    # Timeshift/Snapper integration
│   └── lockfile-manager.sh  # Lockfile I/O, staleness detection
├── packages/           # Logic
│   ├── manager-interface.sh # Package manager abstraction (pacman/flatpak)
│   ├── version-manager.sh   # Constraint parsing + vercmp comparison
│   ├── batch-operations.sh  # Batch installs (5-10x faster)
│   ├── package-operations.sh # Individual ops + state tracking
│   └── flatpak-manager.sh   # Flatpak operations (user-scope)
└── commands/           # CLI (13 files: cmd-sync, cmd-lock, cmd-status, ...)
```

**Dependency rule**: Commands → Operations → Packages → Core (never reverse)

---

## Initialization Sequence (CRITICAL)

`STATE_DIR` **must** be defined BEFORE sourcing core modules (executable_package-manager.sh:28-60):

```
1. Define SCRIPT_DIR (line 26)
2. Define global config: PACKAGES_FILE, STATE_DIR, STATE_FILE, LOCKFILE, feature flags (lines 28-52)
3. mkdir -p "$STATE_DIR"
4. Source core modules: constants → state-manager → config → state → performance → validation
```

**Why this matters**: `state-manager.sh` uses `CONSTRAINT_CACHE_FILE="${STATE_DIR:-.}/.constraint-cache"` — if `STATE_DIR` is undefined at load time, cache files are created in the CWD instead. This caused a real bug (v3.0.1) where `.constraint-cache` appeared in `~/.local/share/chezmoi/`. If you see stale files there: `rm ~/.local/share/chezmoi/.constraint-cache`

---

## Core Module Purposes

| Module | What it does |
|--------|-------------|
| `state-manager.sh` | 5 assoc. array caches (flatpak_apps, flatpak_versions, pacman_versions, modules, constraints); `_state_*` + `_cache_*` API |
| `constants.sh` | PACKAGE_TYPE_PACMAN/FLATPAK, CONSTRAINT_TYPE_*, scope constants; sourced first (no deps) |
| `config.sh` | Single yq query loads all enabled modules into cache; subsequent calls from memory |
| `state.sh` | Atomic state mutations (temp file + mv); auto-backup before sync; keep last 10 backups |
| `performance.sh` | Lazy caches for `pacman -Q` and `flatpak list`; populated on first access |
| `validation.sh` | Batch AUR check (single paru query, 15s timeout, 24h disk cache) — 24x faster than sequential |

---

## Implementation Patterns

### Never Use ui_spin for Interactive Operations

`ui_spin` runs in a subshell — **global state changes (cache updates) are lost** and **sudo/TTY prompts break**:

```bash
# WRONG: Spinner breaks sudo prompts AND loses _CACHE_* updates
ui_spin_verbose "Installing" "paru -S firefox"

# CORRECT: Direct call preserves TTY + global state
ui_step "Installing packages..."
if paru -S --needed firefox; then
    ui_success "Packages installed"
fi
```

**Safe for ui_spin**: queries (`ui_spin_silent`), build steps (`ui_spin_on_error`). Never for paru, flatpak, timeshift, snapper, or any function that mutates global caches.

### Stdout/Stderr Separation

Functions returning values via `echo` MUST redirect UI output to stderr:

```bash
_my_function() {
    ui_info "Processing..." >&2    # UI → stderr
    echo "$result"                  # Return value → stdout
}
```

### Exit Code Capture

Capture `$?` before any other statement — `if` clears it:

```bash
# WRONG: $? always 0 inside if block
if cmd; then local status=$?; fi

# CORRECT
cmd; local status=$?
if [[ $status -ne 0 ]]; then ...
```

### yq Variable Substitution (Security)

All yq operations MUST use `env()` — `--arg` is jq-only, not supported by yq v4:

```bash
# WRONG (injection risk)
yq eval ".packages.modules.$module.enabled = true"

# CORRECT (safe, yq v4 style)
MODULE="$module" yq eval '.packages.modules[env(MODULE)].enabled = true'
```

---

## packages.yaml Structure

```yaml
packages:
  backup_tool: "timeshift"      # or "snapper" (auto-detects if omitted)

  modules:
    base:
      enabled: true
      packages:
        - firefox                       # No constraint (latest)
        - name: neovim
          version: "0.9.5"             # Exact version
        - name: python
          version: ">=3.11"            # Minimum version
        - name: nodejs
          version: "<21.0.0"           # Maximum version
        - flatpak:com.spotify.Client   # Flatpak (prefix required)
```

**Rules**: Flat module structure (no nesting); `enabled` required; Flatpak prefix `flatpak:`.

---

## Integration Points

**Chezmoi trigger**: `run_onchange_before_sync_packages.sh.tmpl` — hash change on packages.yaml → `package-manager sync --prune`

**Topgrade**: Pre-command calls `package-manager update` (sync + update all) before firmware/git/cleanup.

**State file locations**:
- `~/.local/state/package-manager/package-state.yaml` — installed package records
- `~/.local/state/package-manager/locked-versions.yaml` — lockfile
- `~/.local/state/package-manager/constraint-cache.yaml` — 1h TTL
- `~/.cache/package-manager/aur-packages/` — AUR validation cache, 24h TTL

---

## Troubleshooting

**Cache in wrong location** (STATE_DIR init order bug):
```bash
ls ~/.local/share/chezmoi/.constraint-cache  # Should NOT exist
rm -f ~/.local/share/chezmoi/.constraint-cache
```

**Slow sync** (>10s for status):
```bash
package-manager lock  # Generate lockfile for fast-path
rm -f ~/.local/state/package-manager/constraint-cache.yaml  # Clear stale cache
```

**Concurrent sync blocked**:
```bash
stat /tmp/package-manager-sync.lock  # Check age
rm -f /tmp/package-manager-sync.lock  # Remove if stale (>30 min)
```

**YAML validation errors**:
```bash
package-manager validate    # Shows line numbers + context
yq eval '.' ~/.chezmoidata/packages.yaml  # Verify syntax
# Common: use 2-space indents, quote version constraints (">=1.0")
```

**Package state corruption**:
```bash
yq eval '.' ~/.local/state/package-manager/package-state.yaml  # Check syntax
ls -t ~/.local/state/package-manager/backups/                  # List backups
cp ~/.local/state/package-manager/backups/package-state-LATEST.yaml \
   ~/.local/state/package-manager/package-state.yaml
```

**AUR validation timeout** (sequential fallback kicks in): Normal behavior — batch query timed out (15s), sequential with cache runs instead. Clear cache if slow repeatedly: `rm -rf ~/.cache/package-manager/aur-packages/`
