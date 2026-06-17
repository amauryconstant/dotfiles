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

# Supply-chain tripwire (AUR PKGBUILD gate)
package-manager approve --seed     # Bootstrap hash DB (run once after deploy)
package-manager approve <pkg>...   # Review + approve changed/new AUR PKGBUILD
package-manager approve --all      # Review every currently-blocked AUR package
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
│   ├── lockfile-manager.sh  # Lockfile I/O, staleness detection
│   └── pkgbuild-tripwire.sh # AUR PKGBUILD hash gate (tier detect + scan + record)
├── packages/           # Logic
│   ├── manager-interface.sh # Package manager abstraction (pacman/flatpak)
│   ├── version-manager.sh   # Constraint parsing + vercmp comparison
│   ├── batch-operations.sh  # Batch installs (5-10x faster)
│   ├── package-operations.sh # Individual ops + state tracking
│   └── flatpak-manager.sh   # Flatpak operations (user-scope)
└── commands/           # CLI (14 files: cmd-sync, cmd-lock, cmd-status, cmd-approve, ...)
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
- `~/.local/state/package-manager/pkgbuild-hashes.yaml` — tripwire approved-hash DB
- `~/.local/state/package-manager/pkgbuilds/<name>.snapshot` — tripwire snapshots (PKGBUILD + .install, for diffs)

---

## Supply-Chain Tripwire

**Why**: pipeline was fully unattended (`--noconfirm`) — a hijacked AUR/`-git` PKGBUILD would build
+ execute arbitrary code (build user, sudo available) on next sync/update with no review. See
`_research/PACKAGE_SUPPLY_CHAIN_RESEARCH.md` (Atomic Arch / CHAOS RAT). Roadmap:
`_plans/PACKAGE_SUPPLY_CHAIN_HARDENING.md`.

**Mechanism**: hash gate between `packages.yaml` and the AUR build.
- **Tier detection** (`_pkg_is_aur`): AUR-built iff NOT in any pacman sync repo (`pacman -Si` fails)
  but resolvable via `paru -Si --aur`. Official + **chaotic-aur** (signed binary sync repos) are
  never gated — only true AUR (PKGBUILD runs locally).
- **Hash**: `paru -G` clones the AUR repo to a temp dir; the blob = `PKGBUILD` + every `*.install`
  hook (sorted), `sha256sum`'d. `.install` hooks run as **root** via `pacman -U`, so they must be
  covered — `paru -Gp` (PKGBUILD only) would miss them. Compared to the approved hash in
  `pkgbuild-hashes.yaml`. Unchanged → builds unattended (`--noconfirm` kept). New/changed → **held**,
  diff shown, requires `package-manager approve`. `paru -G` clones into a **pkgbase**-named dir
  (≠ pkgname for split packages, e.g. samsung-unified-driver-common); the code takes the sole subdir.
- **Fail-CLOSED**: if the clone/fetch fails, the package is **blocked** (cannot verify), not allowed.
- **Module**: `operations/pkgbuild-tripwire.sh` (`_pkg_is_aur`, `_tripwire_fetch`, `_tripwire_check`,
  `_tripwire_scan`, `_tripwire_record`, `_tripwire_seed`). Command: `commands/cmd-approve.sh`.

**Wired into** (both pipelines): `cmd-update.sh` Phase 2 (scans `paru -Qua`; if any held → official
`pacman -Syu` only, AUR held); `batch-operations.sh` + `package-operations.sh` (drop held AUR from
the build); `sync-pacman.sh` `_sync_handle_downgrade` (gate AUR downgrades); and the self-contained
`run_onchange_before_sync_packages.sh.tmpl` (inline gate sharing the same DB — it cannot source lib/,
runs before file application). **The inline blob recipe must stay byte-identical to
`_tripwire_fetch`** or hashes diverge and every AUR package falsely reads as "changed".

**New-package gate (bootstrap-aware)**: `_tripwire_is_bootstrap` distinguishes two states.
- **Bootstrap** = DB file absent OR `.approved` empty → trust-on-first-use (fresh-machine
  provisioning isn't bricked). New AUR packages build, no record written mid-run.
- **Established** = DB seeded (non-empty) → an AUR package absent from the DB is genuinely NEW and is
  **BLOCKED** until `package-manager approve <pkg>` (same UX as a changed PKGBUILD). This closes the
  "add a package to `packages.yaml` → builds unreviewed" hole on any provisioned machine.
Run `package-manager approve --seed` **once after deploy** to record current build files of installed
AUR packages (`pacman -Qmq`, excl. `*-debug`) — this is also what flips the host from bootstrap to
established. **Re-seed after any change to the hash recipe** (`_tripwire_fetch`) — old hashes go stale.

**Trust-tier install split**: official/chaotic packages (`pacman -Si` hit) install via
`pacman -S --needed --noconfirm` (no local PKGBUILD); only true AUR builds through paru
(tripwire-gated). Applied in `batch-operations.sh` and the inline sync recipe. `--noconfirm` kept on
both — review is the tripwire block + `approve`, not an interactive paru diff (keeps topgrade
unattended). The bootstrap-aware new-package rule is mirrored byte-consistently in the inline recipe.

**`-git` note**: a *locally-built* `-git` AUR package would be a blind spot — its PKGBUILD hash is
stable while upstream HEAD (the built code) moves. There are currently **none**: both `-git` packages
(`wayfreeze-git`, `gpu-screen-recorder-git`) are served by **chaotic-aur as signed prebuilt binaries**
(not local builds), so `_pkg_is_aur` treats them as trusted (same as official). If a true local-build
`-git` package is ever added, pin it to a reviewed commit out-of-band (vendored `#commit=` PKGBUILD).

**Residual limits**: TOCTOU — `paru -S` re-fetches upstream `source=()` at build time, so a tarball/
git HEAD could change between check and build (out of scope).

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
