# System Management Tools - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/system/`
**Parent**: See `../CLAUDE.md` for script library overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: System maintenance and monitoring tools (6 scripts)
- **CLI wrappers**: `system-health`, `system-maintenance`, `system-troubleshoot`, `package-manager`
- **Integration**: topgrade, sudoers

## Tool Overview

| Tool | Purpose | Mode |
|------|---------|------|
| `system-health.sh` | Health monitoring | Non-interactive (load, memory, disk, services) |
| `system-health-dashboard.sh` | Interactive dashboard | TUI with gum |
| `system-maintenance.sh` | Maintenance tasks | `--update`, `--cleanup` modes |
| `troubleshoot.sh` | Diagnostic tool | Interactive troubleshooting |
| `package-manager.sh` v2.1 | Module-based pkg management | NixOS-style version pinning, dcli v2 features (2,539 lines) |
| `pacman-lock-cleanup.sh` | Clean stale pacman locks | Sudo required (configured in sudoers) |

## system-health.sh

**Purpose**: Non-interactive health monitoring

**Checks**:
- **Load average**: 1/5/15 minute averages
- **Memory**: Used/free/available
- **Disk**: Usage per mount point
- **Services**: systemd failed units
- **Journal**: Recent errors

**Output**: Human-readable summary

**Usage**:
```bash
system-health
system-health --json  # JSON output for scripts
```

**Integration**: Called by manual maintenance, monitoring scripts

## system-health-dashboard.sh

**Purpose**: Interactive TUI dashboard

**Features**:
- Real-time metrics
- Service status
- Journal viewer
- Navigation with gum

**Usage**:
```bash
system-health-dashboard
```

**Dependencies**: gum (required), jaq (JSON parsing)

## system-maintenance.sh

**Purpose**: System maintenance tasks

**Modes**:

| Mode | Actions |
|------|---------|
| `--update` | Update packages (pacman, AUR, flatpak) |
| `--cleanup` | Clean caches (pacman, AUR, flatpak, journal) |
| `--full` | Update + cleanup |
| (no args) | Interactive menu |

**Usage**:
```bash
system-maintenance --update
system-maintenance --cleanup
system-maintenance --full
system-maintenance  # Interactive
```

**Cleanup actions**:
- Pacman cache (keep last 3 versions)
- AUR cache
- Flatpak unused runtimes
- Journal (keep 2 weeks)
- Orphaned packages

**Integration**: Can be called from topgrade custom commands (manual execution only)

## troubleshoot.sh

**Purpose**: Interactive diagnostic tool

**Diagnostics**:
1. **System info**: OS, kernel, hardware
2. **Service status**: Failed units, logs
3. **Disk space**: Usage, inodes
4. **Network**: Connectivity, DNS
5. **GPU**: Driver status (NVIDIA/AMD)
6. **Journal**: Recent errors

**Usage**:
```bash
system-troubleshoot
```

**Output**: Guided diagnostics with fixes

## package-manager.sh v2.2

**Purpose**: Module-based declarative package management with NixOS-style version pinning and hybrid update mode

**Version**: 2.2.0 (dcli v2 improvements: merge, snapper, performance, hybrid updates)

**Key features**:
- Module system with conflict detection
- NixOS-style version constraints (exact, >=, <)
- Unmanaged package discovery with `merge` command
- Lockfile generation for reproducibility
- **Hybrid update mode**: sync to packages.yaml + update all installed packages
- Interactive downgrade selection
- Rolling package detection (-git packages)
- Batch package validation with timeout
- Backup integration (Timeshift or Snapper)
- Performance-optimized sync operations (batch installs, lockfile fast-path)
- Comprehensive validation and status checks
- **Topgrade integration**: Called as pre-command for unified update workflow

### Command Categories

**Module Management**:
```bash
package-manager module list                    # Show all modules with status
package-manager module enable base shell       # Enable modules
package-manager module enable                  # Interactive selection
package-manager module disable development     # Disable modules
```

**Version Pinning**:
```bash
package-manager pin firefox 120.0              # Exact version
package-manager pin neovim ">=0.9.0"           # Minimum version
package-manager pin python "<3.12"             # Maximum version
package-manager unpin firefox                  # Remove constraint
package-manager lock                           # Generate lockfile
package-manager versions firefox               # Show version info
package-manager outdated                       # List constraint violations
```

**Package Operations**:
```bash
package-manager install firefox                # Install single package
package-manager remove firefox                 # Remove package
package-manager sync                           # Sync to packages.yaml
package-manager sync --prune                   # Sync + remove orphans
package-manager update                         # Hybrid update (sync + update all)
package-manager update --no-sync               # Update all packages without sync
package-manager update --no-flatpak            # Update without Flatpak
```

**Package Discovery**:
```bash
package-manager merge                          # Discover unmanaged packages
package-manager merge --dry-run                # Preview without changes
```

**Status & Validation**:
```bash
package-manager status                         # Comprehensive status
package-manager validate                       # Validate YAML structure
package-manager validate --check-packages      # Validate + check existence
```

**Legacy Commands** (preserved for compatibility):
```bash
package-manager health                         # Check dependencies
package-manager update-strategy                # Update packages
```

### Version Constraint Syntax

**In packages.yaml**:
```yaml
packages:
  modules:
    base:
      packages:
        - firefox                              # No constraint (latest)
        - name: neovim                         # Exact version
          version: "0.9.5"
        - name: python                         # Minimum version
          version: ">=3.11"
        - name: nodejs                         # Maximum version
          version: "<21.0.0"
```

**Constraint types**:
- **Exact**: `version: "1.2.3"` → Install exactly 1.2.3
- **Minimum**: `version: ">=1.2.3"` → Install 1.2.3 or newer
- **Maximum**: `version: "<2.0.0"` → Install anything below 2.0.0

### State Files

**Location**: `~/.local/state/package-manager/` (NOT in chezmoi)

**package-state.yaml** (Rich metadata):
```yaml
packages:
  - name: "firefox"
    version: "120.0-1"
    type: "pacman"                             # or "flatpak"
    module: "desktop_gui_apps"
    constraint: "120.0"                        # or ">=1.0", "<2.0", null
    pinned: true
    installed_at: "2025-11-16T12:34:56+00:00"
    last_updated: "2025-11-16T12:34:56+00:00"
```

**locked-versions.yaml** (Reproducible builds):
```yaml
# Generated: 2025-11-16 12:34:56
# Host: archlinux
packages:
  base:
    firefox: "120.0-1"
    base-devel: "1-2"
  shell_environment:
    zsh: "5.9-4"
    hyprland-git: "0.35.0.r1"                  # rolling (-git package)
```

### Features from dcli Integration

1. **vercmp** - Accurate version comparison (handles epochs)
2. **Interactive downgrade** - Numbered menu for version selection
3. **Package validation** - Batch checking with 15-second timeout
4. **Module conflicts** - Auto-detection with resolution prompts
5. **Interactive modules** - Fallback menus when no args
6. **Rolling packages** - Detection and warnings for -git packages
7. **Comprehensive validate** - YAML, conflicts, naming, duplicates
8. **Backup integration** - Optional Timeshift or Snapper snapshots before sync
9. **Version caching** - Performance optimization during sync operations
10. **Unmanaged package discovery** - Merge command for package onboarding

### Advanced Usage

**Constraint-aware sync**:
```bash
# packages.yaml has: { name: "firefox", version: "<121.0" }
# System has: firefox 121.0-1 (violates constraint)
package-manager sync
# → Prompts for interactive downgrade to compatible version
```

**Module conflict resolution**:
```bash
# kde_desktop conflicts with gnome_desktop
package-manager module enable gnome_desktop
# → Auto-detects conflict, prompts to disable kde_desktop
```

**Orphan removal**:
```bash
package-manager sync --prune
# → Removes packages not in any enabled module
```

**Validation workflow**:
```bash
package-manager validate --check-packages      # Validate + check existence
package-manager lock                           # Generate lockfile
package-manager status                         # Review system state
package-manager sync                           # Apply changes
```

**Package discovery workflow**:
```bash
# Find unmanaged packages (installed but not in modules)
package-manager merge --dry-run

# Interactively add to modules
package-manager merge
# → Shows unmanaged packages
# → Select target module
# → Packages added to packages.yaml
# → Run 'package-manager sync' to reconcile
```

### Backup Tool Configuration

**Optional configuration in packages.yaml**:
```yaml
packages:
  # Backup tool configuration (auto-detects if omitted)
  backup_tool: "snapper"        # or "timeshift" (prefers timeshift if both installed)
  snapper_config: "root"        # snapper config name (default: "root")

  modules:
    # ... module definitions
```

**Auto-detection behavior**:
- Prefers Timeshift if installed
- Falls back to Snapper if Timeshift not found
- Silently skips if neither tool available
- Prompts before creating snapshot

### Integration Points

**packages.yaml** (`.chezmoidata/packages.yaml`):
- Flat module structure: `packages.modules.<name>`
- No `post_install_hook` (use chezmoi scripts instead)
- No `flatpak.scope` (always user scope)
- Prefix Flatpak packages: `flatpak:com.spotify.Client`

**Run scripts**:
- `run_onchange_before_sync_packages.sh.tmpl` → Calls package-manager sync for both Arch and Flatpak
- Hash-triggered on packages.yaml changes

**Topgrade integration** (v2.2 unified update workflow):
```toml
# Pre-command: Package updates run BEFORE firmware/git/cleanup
[pre_commands]
"Package Update (package-manager)" = "~/.local/bin/package-manager update"

# Post-update commands
[commands]
"Check for unmanaged packages" = "~/.local/bin/package-manager merge --dry-run"
"Post-update system status" = "~/.local/bin/system-health --brief"
```

**Update workflow** (single command: `topgrade`):
1. Pre-command: `package-manager update` (sync + update all Arch/AUR + Flatpak)
2. Firmware updates (fwupdmgr) - handled by topgrade
3. Git repo pulls (chezmoi, ~/Projects/*) - handled by topgrade
4. Cleanup hooks (orphan removal, cache cleanup) - handled by topgrade
5. Post-update validation

**Update command behavior**:
- Default: Sync to packages.yaml, update all Arch/AUR and Flatpak packages
- `--no-sync`: Skip sync phase (only update packages)
- `--no-flatpak`: Skip Flatpak updates
- Validates package system and updates lockfile (if AUTO_LOCK enabled)

### Migration from v1.0

**Removed features**:
- Strategy system (pacman → yay_bin → yay_source)
- `--strategy` flag
- Search command (use paru directly)

**Replaced by**:
- Single paru command for all installs
- Module-based organization
- Version constraint system

**Breaking changes**:
- State files moved to `~/.local/state/package-manager/`
- No longer uses chezmoi state directory

## pacman-lock-cleanup.sh

**Purpose**: Clean stale pacman lock file

**Problem**: pacman crashes leave `/var/lib/pacman/db.lck`

**Solution**: Safe cleanup with validation

**Safety checks**:
1. Verify no pacman process running
2. Check lock file age (>5 min)
3. Confirm with user (unless `--force`)

**Usage**:
```bash
sudo pacman-lock-cleanup
sudo pacman-lock-cleanup --force  # No confirmation
```

**Sudoers config**: Can be configured in sudoers for passwordless sudo (optional)

## CLI Wrappers

**Wrapper pattern** (`~/.local/bin/`):
```bash
#!/usr/bin/env bash
SCRIPT="$SCRIPTS_DIR/system/script-name.sh"

# Source UI library
. "$UI_LIB"

# Execute script
"$SCRIPT" "$@"
```

**Available wrappers**:
- `system-health` → `system-health.sh`
- `system-maintenance` → `system-maintenance.sh`
- `system-troubleshoot` → `troubleshoot.sh`
- `package-manager` → `package-manager.sh`

## Integration Points

### topgrade.toml.tmpl (Manual Execution)

**Custom commands**:
```toml
[commands]
"System Health" = "system-health"
"Maintenance Cleanup" = "system-maintenance --cleanup"
```

**Note**: Topgrade runs manually by user (`topgrade` command), not as automated service

### Menu System

**Integration**: Called from `menu-update.sh`, `menu-install.sh`

**Example**:
```bash
# menu-update.sh
system-maintenance --update
```

## Usage Patterns

**Daily health check**:
```bash
system-health
```

**Before/after updates**:
```bash
system-health --json > pre-update.json
system-maintenance --update
system-health --json > post-update.json
```

**Troubleshooting**:
```bash
system-troubleshoot  # Interactive guided diagnostics
```

**Clean system**:
```bash
system-maintenance --cleanup
```
