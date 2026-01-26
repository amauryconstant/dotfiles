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
| `package-manager.sh` v3.0 | Module-based pkg management | NixOS-style version pinning, modularized architecture (521 lines) |
| `pacman-lock-cleanup.sh` | Clean stale pacman locks | Sudo required (configured in sudoers) |

**Recent changes**:

**v3.0.0 (comprehensive refactoring)**:
- **Modularized architecture**: Extracted to operations/, commands/, packages/, core/ modules
- **Performance optimizations**: Module caching, constraint memoization, single-pass iteration
- **Error recovery**: State backup/restore, concurrent sync protection
- **Code quality**: Deprecated legacy commands, reduced main file by 24.4%

**v2.2.1 (security fix)**:
- **yq injection vulnerability patched**: 16+ vulnerable lines converted to use `--arg` flag
- **State file corruption risk eliminated**: Safe variable substitution in all yq operations
- **Input validation improved**: Module and package names now properly escaped
- **Strict mode added**: `set -euo pipefail` prevents partial state corruption

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

## package-manager.sh v3.0

**Purpose**: Module-based declarative package management with NixOS-style version pinning and hybrid update mode

**Version**: 3.0.0 (comprehensive refactoring: modularized architecture, 31 files, 4-layer design)

**Architecture**: See `package-manager/CLAUDE.md` for complete documentation

**Key features**:
- 4-layer modular design: Core/Operations/Packages/Commands (31 files)
- NixOS-style version constraints (exact, >=, <)
- Lockfile generation for reproducibility
- Hybrid update mode: sync + update all packages
- Backup integration (Timeshift/Snapper)
- Performance optimizations: 5-100x faster operations
- State management with atomic mutations
- Concurrent sync protection
- Batch AUR validation (24x faster)

### Quick Commands

```bash
# Module management
package-manager module list
package-manager module enable base shell

# Version pinning
package-manager pin firefox 120.0
package-manager lock

# Package operations
package-manager install firefox
package-manager sync
package-manager sync --prune
package-manager update

# Status & validation
package-manager status
package-manager validate
package-manager outdated
```

### Documentation

**Complete reference**: `package-manager/CLAUDE.md`

**Topics covered**:
- Architecture overview (4-layer design)
- Module reference (31 files)
- Performance optimizations
- State management
- Data flow
- Development guide
- Troubleshooting
- Migration notes (v1.0 → v2.x → v3.0)

### Integration Points

**packages.yaml**: `.chezmoidata/packages.yaml`
**Run script**: `run_onchange_before_sync_packages.sh.tmpl` (hash-triggered)
**Topgrade**: Pre-command calls `package-manager update`
**State files**: `~/.local/state/package-manager/`

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

---

## Package Management for Development

### Dual System Architecture

**Native Arch** (paru): CLI tools, system services, dev tools, deep integration
**Flatpak**: Proprietary apps, cross-platform GUI apps, sandboxing

### Decision Matrix

**Use Flatpak for**:
- ✅ Proprietary apps (Spotify, Slack, VS Code)
- ✅ Cross-platform GUI apps (Xournalpp, qBittorrent)
- ✅ Sandboxing/isolation needed

**Use Native Arch for**:
- ✅ CLI tools and utilities
- ✅ System services and daemons
- ✅ Development tools and languages
- ✅ Linux-first applications
- ✅ Deep system integration (browsers with extensions, sync clients)
- ✅ Desktop environment components (Thunar, Hyprland polkit agent)

### GPU Driver Selection

**Auto-detection**: NVIDIA driver selection based on GPU generation

**Architecture support**:
- **Modern** (nvidia-open): Turing+ (GTX 16xx, RTX 20xx/30xx/40xx)
- **Legacy** (nvidia-580xx-dkms): Pascal/Maxwell (GTX 9xx/10xx)

**Detection logic** (`.chezmoi.yaml.tmpl`):
1. Check `NVIDIA_DRIVER_OVERRIDE` env var
2. Parse lspci for GPU model
3. Pattern match: GTX 9xx/10xx → legacy, else → modern
4. Default: modern (safe for new systems)

**Package modules** (`packages.yaml`):
- `graphics_drivers_modern`: nvidia-open, nvidia-open-lts, nvidia-utils (enabled by default)
- `graphics_drivers_legacy`: nvidia-580xx-dkms, nvidia-580xx-utils (disabled by default)
- **Dynamic selection**: Sync script enables correct module based on `.nvidiaDriverType`

**Manual override**:
```bash
# Force legacy drivers (Pascal/Maxwell GPUs)
export NVIDIA_DRIVER_OVERRIDE=legacy
chezmoi apply

# Force modern drivers (Turing+ GPUs)
export NVIDIA_DRIVER_OVERRIDE=modern
chezmoi apply

# Clear override (restore auto-detection)
unset NVIDIA_DRIVER_OVERRIDE
chezmoi data | jaq -r '.nvidiaDriverType'  # Verify detection
```

**Migration safety**:
- Interactive prompt before driver changes (integrated in validation script)
- Automatic cleanup of conflicting drivers
- Validation script checks correct driver installed
- Requires reboot after driver change

**Troubleshooting**:
```bash
# Check detection
chezmoi data | jaq -r '.nvidiaDriverType'

# View detected GPU
chezmoi data | jaq -r '.nvidiaGpuDetected'

# Preview which packages will be installed
chezmoi execute-template < .chezmoiscripts/run_onchange_before_sync_packages.sh.tmpl | grep -A5 "NVIDIA"

# Check installed NVIDIA packages
pacman -Q nvidia-open nvidia-open-lts nvidia-utils

# Manual fallback
export NVIDIA_DRIVER_OVERRIDE=legacy  # or modern
chezmoi apply
```

---

## Backup System

**Tool**: Timeshift (preferred) for system snapshots
**Integration**: Automatic pre-sync snapshots via package-manager
**Snapper**: Removed (not configured, Timeshift preferred)

### Automatic Retention Policy Configuration

**Default retention policy** (automatically configured via `run_once_after_009`):
- **Daily**: 7 snapshots (1 week)
- **Weekly**: 4 snapshots (1 month)
- **Monthly**: 6 snapshots (6 months)
- **Boot**: 3 snapshots

**Configuration location**: `.chezmoidata/globals.yaml` (`timeshift:` section)

**Manual override**: Edit globals.yaml and run `chezmoi apply`, or use Timeshift GUI (`sudo timeshift-launcher`)

### Disk Space Management

Timeshift automatically deletes oldest snapshots when retention limits reached.

**No automatic low-disk emergency cleanup** (upstream limitation - [Issue #329](https://github.com/linuxmint/timeshift/issues/329))

Monitor disk usage:
- `system-health` - Health monitoring dashboard
- `df -h /` - Manual filesystem check

### Integration with Package Manager

**Automatic backups**: Package-manager auto-detects Timeshift for pre-sync snapshots.

**Manual snapshots**:
```bash
sudo timeshift --create --comments "Description"
sudo timeshift --list
sudo timeshift --restore
```

**Workflow**: Before `package-manager sync`, interactive prompt offers snapshot creation. Backup tool auto-detected (prefers Timeshift).

**Implementation**: `backup-manager.sh` (line 25-27) auto-detects Timeshift if installed.

### Scheduled Snapshots (Systemd Timers)

**Package**: `timeshift-systemd-timer` (AUR)

**Timers**:
- `timeshift-hourly.timer`: Checks for due snapshots every hour
- `timeshift-boot.timer`: Creates snapshot on system boot (optional)

**How it works**:
1. Timer triggers `/usr/bin/timeshift --check --scripted`
2. Timeshift reads `schedule_*` flags from `/etc/timeshift/timeshift.json`
3. Snapshots created only when due (daily/weekly/monthly logic handled by Timeshift)

**Configuration**: Edit `globals.yaml` schedule flags (requires `chezmoi apply` + manual timer restart for `run_once` scripts)

**Management**:
```bash
# View active timers
systemctl list-timers timeshift-*

# Check timer status
systemctl status timeshift-hourly.timer

# View snapshot logs
journalctl -u timeshift-hourly.service -n 50

# Manual trigger
sudo systemctl start timeshift-hourly.service

# Disable scheduling
sudo systemctl disable --now timeshift-hourly.timer
```

**Note**: Changing `globals.yaml` schedule flags requires manual timer management (run_once scripts don't re-trigger):
```bash
# After changing globals.yaml schedule flags:
sudo systemctl restart timeshift-hourly.timer  # If enabling new schedules
# OR
sudo systemctl disable --now timeshift-hourly.timer  # If disabling all schedules
```

---

## DKMS Troubleshooting

### NVIDIA DKMS Build Failures

| Symptom | Cause | Solution |
|---------|-------|----------|
| GCC internal compiler error | Memory instability (XMP/DOCP) | Disable XMP or use `-j1` flag |
| Stack smashing detected | RAM overclocking | Disable XMP in BIOS |
| Module "added" not "installed" | Build failed | Check build log |

### Manual DKMS Build

```bash
# Check current status
dkms status nvidia

# Build with reduced parallelism (helps with memory issues)
sudo dkms install nvidia/VERSION -k $(uname -r) -j1

# View build log for errors
cat /var/lib/dkms/nvidia/*/build/make.log | tail -50
```

### Common Causes

**GCC Internal Compiler Errors**: These are almost always caused by memory instability, not GCC bugs. The compiler performs intensive memory operations and will crash with unstable RAM.

**Solutions**:
1. Disable XMP/DOCP in BIOS (most reliable)
2. Use looser memory timings
3. Build with `-j1` to reduce memory pressure
4. Run memtest86+ to verify RAM stability

**Reference**: [Arch forums - nvidia-open-dkms build failure](https://bbs.archlinux.org/viewtopic.php?id=309961)
