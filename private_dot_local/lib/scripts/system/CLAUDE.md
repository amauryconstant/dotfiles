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
| `package-manager.sh` | Strategy-based pkg install | Fallback chains (pacman → yay_bin → yay_source) |
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

**Integration**: Called by topgrade, cron jobs, monitoring systems

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

**Integration**: topgrade custom commands

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

## package-manager.sh

**Purpose**: Strategy-based package installation

**Strategy execution**:
1. Try `pacman` (official repos)
2. Try `yay_bin` (AUR precompiled)
3. Try `yay_source` (AUR from source)

**Fallback chain**: Each strategy tried in order until success

**Usage**:
```bash
package-manager install <package>
package-manager install <package> --strategy pacman,yay_bin
package-manager remove <package>
package-manager search <query>
```

**Strategy override**: `--strategy` flag for specific chain

**Integration**: Used by `.chezmoidata/packages.yaml` system

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

**Sudoers config**: Path configured for passwordless sudo

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

### topgrade.toml.tmpl

**Custom commands**:
```toml
[commands]
"System Health" = "system-health"
"Maintenance Cleanup" = "system-maintenance --cleanup"
```

**Pre/post hooks**: Health checks before/after updates

### Sudoers

**Configuration**: Passwordless sudo for specific tools

**Entry**:
```
%wheel ALL=(ALL) NOPASSWD: /home/user/.local/lib/scripts/system/pacman-lock-cleanup.sh
```

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
