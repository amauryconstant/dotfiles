# Package-Manager v3.0 - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/system/package-manager/`
**Parent**: See `../CLAUDE.md` for system scripts overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Version**: 3.0.0 (comprehensive refactor)
- **Purpose**: Module-based declarative package management with NixOS-style version pinning
- **Architecture**: 4-layer modular design (31 files)
- **Key features**: Version constraints, lockfile, hybrid update, backup integration, performance optimizations

## Architecture Overview

### 4-Layer Modular Design

```
package-manager/ (31 files)
├── executable_package-manager.sh (521 lines) # Entry point
├── core/                                      # Foundation (6 files)
│   ├── state-manager.sh     (432 lines)      # Centralized state/cache
│   ├── constants.sh         (63 lines)       # Type-safe constants
│   ├── config.sh            (147 lines)      # Module access with caching
│   ├── state.sh             (353 lines)      # State file I/O, backups
│   ├── performance.sh       (78 lines)       # Version caching
│   └── validation.sh        (282 lines)      # Package validation
├── operations/                                # Workflows (6 files)
│   ├── backup-manager.sh    (101 lines)      # Timeshift/Snapper integration
│   ├── lockfile-manager.sh  (75 lines)       # Lockfile I/O, validation
│   ├── sync-orchestrator.sh (430 lines)      # 5-phase sync workflow
│   ├── sync-lock.sh         (80 lines)       # Concurrent sync protection
│   ├── sync-pacman.sh       (246 lines)      # Pacman sync execution
│   └── sync-flatpak.sh                       # Flatpak sync execution
├── packages/                                  # Logic (6 files)
│   ├── manager-interface.sh (269 lines)      # Package manager abstraction
│   ├── version-manager.sh   (190 lines)      # Constraint parsing/comparison
│   ├── batch-operations.sh                   # Batch installs/upgrades
│   ├── package-operations.sh                 # Individual operations
│   └── flatpak-manager.sh                    # Flatpak operations
└── commands/                                  # CLI (13 files)
    ├── cmd-sync.sh          # Sync orchestration
    ├── cmd-lock.sh          # Lockfile generation
    ├── cmd-status.sh        # Status reporting
    ├── cmd-module.sh        # Module management
    ├── cmd-update.sh        # Hybrid update
    ├── cmd-outdated.sh      # Constraint violations
    └── [7 more commands]
```

### Dependency Flow

```
Commands → Operations → Packages → Core
  ↓            ↓           ↓        ↓
User CLI   Workflows   Logic   Foundation
```

**Principle**: Higher layers call lower layers, never reverse

## Initialization Sequence

**Critical ordering requirement**: `STATE_DIR` must be defined BEFORE sourcing core modules.

**Initialization steps** (executable_package-manager.sh:26-55):
1. Define `SCRIPT_DIR` (line 26)
2. **Define global configuration** (lines 28-52):
   - `PACKAGES_FILE`, `STATE_DIR`, `STATE_FILE`, `LOCKFILE`
   - Feature flags: `AUTO_LOCK`, `USE_LOCKFILE_FASTPATH`, `BATCH_INSTALLS`
   - `VERBOSE` logging flag
   - `mkdir -p "$STATE_DIR"` (creates state directory)
3. **Source core modules** (lines 54-60):
   - constants.sh → state-manager.sh → config.sh → state.sh → performance.sh → validation.sh

**Why this order matters**:
- `state-manager.sh:338`: `CONSTRAINT_CACHE_FILE="${STATE_DIR:-.}/.constraint-cache"`
- `validation.sh:12`: `AUR_CACHE_DIR="${STATE_DIR:-.}/.aur-cache"`
- Both use `${STATE_DIR:-.}` fallback (defaults to `.` if undefined)
- If STATE_DIR undefined at module load time, cache files created in wrong location

**Historical issue** (fixed in v3.0.1):
- STATE_DIR was defined at line 69 (AFTER module sourcing at line 29)
- Result: `.constraint-cache` created in `~/.local/share/chezmoi/` (current directory)
- Fix: Moved STATE_DIR definition to line 33 (BEFORE module sourcing)

## Core Modules (Foundation Layer)

### state-manager.sh (432 lines)

**Purpose**: Centralized global state encapsulation

**Initialization dependency**: Requires `STATE_DIR` defined before sourcing (see Initialization Sequence)

**Cache types** (5 associative arrays):
- `flatpak_apps`: Installed Flatpak applications
- `flatpak_versions`: Flatpak version cache
- `pacman_versions`: Pacman version cache
- `modules`: Module configuration cache
- `constraints`: Package constraint cache

**Scalar state**:
- `module_cache_loaded`: Module cache initialization flag
- `flatpak_cache_loaded`: Flatpak cache initialization flag
- `pacman_cache_loaded`: Pacman cache initialization flag
- `sync_plan_total`: Total packages in sync plan

**Operations**:
```bash
_state_get "key"              # Get scalar state
_state_set "key" "value"      # Set scalar state
_state_has "key"              # Check scalar state exists
_state_unset "key"            # Remove scalar state

_cache_get "cache_name" "key" # Get cached value
_cache_set "cache_name" "key" "value" # Set cached value
_cache_has "cache_name" "key" # Check cache key exists
_cache_clear "cache_name"     # Clear entire cache
```

**Cache persistence**:
- Constraint cache saved to disk: `~/.local/state/package-manager/constraint-cache.yaml`
- TTL: 1 hour
- Invalidation: Automatic on TTL expiry or manual clear

**Pattern**: All modules access state via these functions only (no direct globals)

### constants.sh (63 lines)

**Purpose**: Type-safe constants for package types, constraints, scopes

**Note**: This module has no external dependencies (sourced first)

**Exports**:
```bash
PACKAGE_TYPE_PACMAN="pacman"
PACKAGE_TYPE_FLATPAK="flatpak"
CONSTRAINT_TYPE_EXACT="exact"
CONSTRAINT_TYPE_MIN="min"
CONSTRAINT_TYPE_MAX="max"
SCOPE_USER="user"
SCOPE_SYSTEM="system"
```

**Functions**:
- `_is_valid_package_type()`: Validate package type
- Icon constants for UI (`ICON_*`)
- Path constants (`STATE_DIR`, `CACHE_DIR`, etc.)

**Benefit**: Eliminates magic strings across 31 files

### config.sh (147 lines)

**Purpose**: Module access helpers with caching

**Key optimization**: 16 yq calls → 1 call
- Before: Each function called yq separately
- After: Single query loads all enabled modules into cache
- Impact: 2-5s faster status/lock commands

**Functions**:
```bash
_get_modules()                     # Get all modules from packages.yaml
_get_enabled_modules_cached()      # Get enabled modules (cached)
_get_module_packages_cached "name" # Get packages for module (cached)
_is_module_enabled "name"          # Check if module enabled
```

**Caching strategy**:
- First call: Load all modules from packages.yaml via single yq query
- Store in `modules` cache (state-manager)
- Subsequent calls: Return from cache
- Session lifetime (no disk persistence)

### performance.sh (78 lines)

**Purpose**: Performance caching for Flatpak and Pacman queries

**Lazy-loading pattern**:
- Caches populated on first access, not at startup
- Reduces initialization overhead for commands that don't need package queries

**Functions**:
```bash
_load_flatpak_cache()           # Populate Flatpak cache
_is_flatpak_installed "app"     # Check if Flatpak installed (cached)
_get_flatpak_version "app"      # Get Flatpak version (cached)

_load_pacman_cache()            # Populate Pacman cache
_is_pacman_installed "pkg"      # Check if Pacman package installed (cached)
_get_pacman_version "pkg"       # Get Pacman version (cached)
```

**Cache population**:
- Flatpak: `flatpak list --app --columns=application,version` (single query)
- Pacman: `pacman -Q` (single query)
- Stored in state-manager caches

**Session lifetime**: Cleared on exit, no disk persistence

### validation.sh (282 lines)

**Purpose**: Package validation with batch AUR caching

**Performance**: 24x faster (48 packages: 10s vs 240s)

**Key features**:
- Batch AUR validation (single 10-second query for all packages)
- 24-hour cache TTL (disk-persisted)
- Intelligent fallback on timeout
- Cache invalidation on TTL expiry

**Functions**:
```bash
_check_packages_batch "pkg1 pkg2 ..."        # Batch package validation
_validate_aur_packages_batch "pkg1 pkg2 ..." # Batch AUR check
_check_aur_cached "pkg"                      # Check single package (cached)
_validate_yaml_syntax                        # Validate packages.yaml syntax
_validate_module_conflicts                   # Check module conflicts
```

**AUR cache location**: `~/.cache/package-manager/aur-packages/`
**Cache structure**: One file per package with timestamp

**Timeout handling**:
- Batch query: 15-second timeout
- On timeout: Fall back to sequential validation with cache
- Cache prevents repeated slow queries

### state.sh (353 lines)

**Purpose**: State file I/O with atomic mutations

**State file**: `~/.local/state/package-manager/package-state.yaml`

**Structure**:
```yaml
packages:
  - name: "firefox"
    version: "120.0-1"
    type: "pacman"
    module: "desktop_gui_apps"
    constraint: "120.0"
    pinned: true
    installed_at: "2025-11-16T12:34:56+00:00"
    last_updated: "2025-11-16T12:34:56+00:00"
```

**Atomic mutation pattern**:
```bash
# 1. Backup current state
_backup_state_file

# 2. Create temp file
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT ERR

# 3. Perform mutation
yq eval --arg name "$package" '...' "$STATE_FILE" > "$TEMP_FILE"

# 4. Atomic replace
mv "$TEMP_FILE" "$STATE_FILE"
```

**Functions**:
```bash
_update_package_state "name" "version" "type" "module" "constraint"
_remove_package_state "name"
_get_package_state "name"
_backup_state_file
_restore_state_file "backup_path"
```

**Backup retention**:
- Automatic before sync operations
- Keep last 10 backups
- Location: `~/.local/state/package-manager/backups/`
- Naming: `package-state-YYYYMMDD-HHMMSS.yaml`

**Security**: All yq operations use `--arg` flag (prevents injection, v2.2.1 fix)

## Operations Modules (Workflow Layer)

### backup-manager.sh (101 lines)

**Purpose**: Timeshift/Snapper backup integration

**Auto-detection**:
1. Check `backup_tool` in packages.yaml
2. If unset, prefer Timeshift if installed
3. Fall back to Snapper if Timeshift not found
4. Silently skip if neither available

**Configuration** (packages.yaml):
```yaml
packages:
  backup_tool: "snapper"     # or "timeshift" (optional, auto-detects)
  snapper_config: "root"     # snapper config name (default: "root")
```

**Functions**:
```bash
_create_backup "description"  # Create backup with auto-detected tool
_detect_backup_tool           # Detect available backup tool
```

**Workflow**:
- Prompt before creating snapshot (interactive)
- Show backup tool name and description
- Create snapshot with descriptive comment
- Report success/failure

### lockfile-manager.sh (75 lines)

**Purpose**: Lockfile I/O and validation

**Lockfile**: `~/.local/state/package-manager/locked-versions.yaml`

**Structure**:
```yaml
# Generated: 2025-11-16 12:34:56
# Host: archlinux
packages:
  base:
    firefox: "120.0-1"
    base-devel: "1-2"
  shell_environment:
    zsh: "5.9-4"
    hyprland-git: "0.35.0.r1"  # rolling (-git package)
```

**Staleness detection**:
- Warning: >30 days old
- Error: >90 days old
- Recommendation: Regenerate with `package-manager lock`

**Functions**:
```bash
_read_lockfile                    # Read lockfile into memory
_validate_lockfile_syntax         # Validate YAML syntax
_check_lockfile_staleness         # Check age and warn
_get_locked_version "module" "pkg" # Get version from lockfile
```

**Drift detection**: Status command shows packages with version mismatch

### sync-orchestrator.sh (430 lines)

**Purpose**: Main sync command with 5-phase validation-first architecture

**Phase 0: Validation**
- YAML syntax validation
- Module conflict detection
- Enabled module verification

**Phase 1: Build Sync Plan**
- Classify packages: install / upgrade / downgrade
- Validate package existence (batch AUR check)
- Calculate constraint satisfaction

**Phase 2: Optional Backup**
- Detect backup tool (Timeshift/Snapper)
- Prompt user for pre-sync snapshot
- Create backup if approved

**Phase 3: Execute Sync**
- Delegate to sync-pacman.sh and sync-flatpak.sh
- Batch installs for performance
- Interactive downgrade selection
- Update state file after each operation
- **State integration**: Direct function calls preserve global state (see Implementation Patterns → UI Function Usage)

**Phase 4: Prune Orphans**
- Only if `--prune` flag provided
- Find packages not in any enabled module
- Interactive confirmation before removal
- Remove orphaned packages

**Phase 5: Finalize**
- Show summary (installed/upgraded/downgraded/removed)
- Auto-generate lockfile if AUTO_LOCK enabled
- Release sync lock

**Error recovery**:
- State backup before execution (Phase 2)
- ERR trap for cleanup on failure
- Sync lock prevents concurrent operations
- Restore state on critical failures

**Functions**:
```bash
_sync_orchestrator           # Main orchestration function
_build_sync_plan             # Phase 1 implementation
_execute_sync                # Phase 3 implementation
_prune_orphans               # Phase 4 implementation
```

### sync-lock.sh (80 lines)

**Purpose**: Flock-based sync operation locking

**Lock file**: `/tmp/package-manager-sync.lock`

**Concurrent protection**:
- Acquire exclusive lock before sync
- Block other sync operations
- Release lock on completion or error

**Stale lock detection**:
- Age threshold: 30 minutes
- Interactive prompt for removal
- PID validation (check if process still running)

**Functions**:
```bash
_acquire_sync_lock           # Acquire exclusive lock
_release_sync_lock           # Release lock
_check_stale_lock            # Check lock age, prompt removal
```

**Pattern**:
```bash
# In sync-orchestrator.sh
_acquire_sync_lock || return 1
trap '_release_sync_lock' EXIT ERR
# ... perform sync operations ...
```

### sync-pacman.sh (246 lines)

**Purpose**: Pacman package sync execution

**Lockfile fast-path**:
- Check if package version matches lockfile
- Skip install/upgrade if versions match
- Impact: 30-50% faster sync operations

**Batch classification**:
- Collect packages by operation: install / upgrade / downgrade
- Batch installs: `paru -S --needed pkg1 pkg2 pkg3`
- Impact: 5-10x faster than sequential installs

**Interactive downgrade**:
- Query available versions: `paru -Si package`
- Present numbered menu for selection
- Fallback to fzf if available
- Install selected version

**Constraint satisfaction**:
- Parse constraints via version-manager
- Check current version against constraint
- Determine operation: upgrade / downgrade / skip

**Functions**:
```bash
_sync_pacman_packages        # Main sync function
_classify_pacman_package     # Determine operation type
_batch_install_pacman        # Batch install packages
_interactive_downgrade       # Downgrade with version selection
```

### sync-flatpak.sh

**Purpose**: Flatpak package sync execution

**Scope**: User-scope installation (consistent with architecture)
- All Flatpak packages installed with `--user` flag
- No system-scope support

**Functions**:
```bash
_sync_flatpak_packages       # Main sync function
_install_flatpak             # Install Flatpak package
_upgrade_flatpak             # Upgrade Flatpak package
```

**Pattern**: Similar to sync-pacman.sh but simpler (no downgrades, no lockfile fast-path)

## Packages Modules (Logic Layer)

### manager-interface.sh (269 lines)

**Purpose**: Package manager abstraction layer

**Supported managers**:
- `pacman`: Arch Linux package manager
- `flatpak`: Flatpak package manager
- `homebrew`: (Future) macOS package manager
- `nix`: (Future) Nix package manager

**Functions**:
```bash
_pm_install "type" "package"           # Install package
_pm_remove "type" "package"            # Remove package
_pm_query_version "type" "package"     # Query installed version
_pm_is_installed "type" "package"      # Check if installed
_pm_search "type" "query"              # Search packages
```

**Pattern**:
```bash
_pm_install() {
    local type="$1"
    local package="$2"

    case "$type" in
        "$PACKAGE_TYPE_PACMAN")
            paru -S --needed "$package"
            ;;
        "$PACKAGE_TYPE_FLATPAK")
            flatpak install --user -y "$package"
            ;;
        *)
            ui_error "Unsupported package type: $type"
            return 1
            ;;
    esac
}
```

**Benefit**: Single interface for multiple package managers, extensible to new managers

### version-manager.sh (190 lines)

**Purpose**: Version constraint parsing and comparison

**Constraint types**:
- **Exact**: `"1.2.3"` → Must match exactly
- **Minimum**: `">=1.2.3"` → Must be 1.2.3 or newer
- **Maximum**: `"<2.0.0"` → Must be below 2.0.0

**Caching**:
- Disk-persisted: `~/.local/state/package-manager/constraint-cache.yaml`
- TTL: 1 hour
- Structure: `package_name: {type: "min", version: "1.2.3"}`

**Functions**:
```bash
_parse_package_constraint_cached "pkg" "constraint" # Parse constraint (cached)
_check_constraint_satisfaction "pkg" "version" "constraint" # Check if version satisfies
_compare_versions "v1" "v2"                         # Compare versions (uses vercmp)
```

**Constraint parsing**:
```bash
# Input: ">=1.2.3"
# Output: type="min", version="1.2.3"

# Input: "<2.0.0"
# Output: type="max", version="2.0.0"

# Input: "1.2.3"
# Output: type="exact", version="1.2.3"
```

**Version comparison**:
- Uses `vercmp` (pacman utility) for accurate comparison
- Handles epochs: `1:1.0.0` vs `2.0.0`
- Handles release numbers: `1.0-1` vs `1.0-2`

**Benefit**: Eliminates constraint parsing duplication across 6 files

### batch-operations.sh

**Purpose**: Batch package install/upgrade operations

**Performance**: 5-10x faster than sequential operations

**Functions**:
```bash
_batch_install_packages "pkg1 pkg2 pkg3"    # Batch install
_batch_upgrade_packages "pkg1 pkg2 pkg3"    # Batch upgrade
```

**Pattern**:
```bash
# Collect packages
INSTALL_LIST=""
for pkg in $packages; do
    INSTALL_LIST="$INSTALL_LIST $pkg"
done

# Single batch install
paru -S --needed $INSTALL_LIST
```

### package-operations.sh

**Purpose**: Individual package install/remove with state tracking

**Functions**:
```bash
_install_package "name" "type" "module" "constraint"  # Install + update state
_remove_package "name"                                 # Remove + update state
```

**State integration**:
- Call `_update_package_state()` after successful install
- Call `_remove_package_state()` after successful removal
- Record timestamps, module, constraint

### flatpak-manager.sh

**Purpose**: Flatpak-specific operations

**User-scope enforcement**:
- All operations use `--user` flag
- No system-scope installation

**Functions**:
```bash
_flatpak_install "app"       # Install Flatpak app (user scope)
_flatpak_remove "app"        # Remove Flatpak app
_flatpak_list               # List installed apps
_flatpak_update "app"       # Update app
```

## Commands Layer (CLI)

### Command Structure (13 files)

**Pattern**: Thin wrappers calling operations/packages modules

**Common structure**:
```bash
#!/usr/bin/env bash
# Command: commandname
# Purpose: [description]

cmd_commandname() {
    local arg="$1"

    # Validate arguments
    if [ -z "$arg" ]; then
        ui_error "Missing argument"
        return 1
    fi

    # Call operations/packages
    _operation_function "$arg"

    # Report result
    ui_success "Complete"
}
```

**Available commands**:
- `cmd-sync.sh`: Sync to packages.yaml
- `cmd-lock.sh`: Generate lockfile
- `cmd-status.sh`: Show system status
- `cmd-module.sh`: Module management
- `cmd-update.sh`: Hybrid update (sync + update all)
- `cmd-outdated.sh`: Show constraint violations
- `cmd-install.sh`: Install single package
- `cmd-remove.sh`: Remove package
- `cmd-pin.sh`: Pin package version
- `cmd-unpin.sh`: Unpin package
- `cmd-versions.sh`: Show package versions
- `cmd-validate.sh`: Validate YAML
- `cmd-merge.sh`: Discover unmanaged packages

**Self-contained**: Each command has focused responsibility

## Data Flow Architecture

### Sync Command Flow

```
User: package-manager sync
  ↓
executable_package-manager.sh (entry point)
  ↓
[Initialize Global Configuration]
  STATE_DIR="$HOME/.local/state/package-manager"
  mkdir -p "$STATE_DIR"
  Feature flags (AUTO_LOCK, USE_LOCKFILE_FASTPATH, BATCH_INSTALLS)
  ↓
[Load Core Modules]
  state-manager.sh → Centralized state/cache (uses STATE_DIR)
  constants.sh → Type-safe constants
  config.sh → Module access with caching
  state.sh → State file I/O, backups
  performance.sh → Version caching
  validation.sh → Package validation
  ↓
[Load Operations Modules]
  backup-manager.sh → Timeshift/Snapper integration
  lockfile-manager.sh → Lockfile I/O, validation
  sync-lock.sh → Concurrent sync protection
  sync-orchestrator.sh → 5-phase workflow
  sync-pacman.sh → Pacman sync execution
  sync-flatpak.sh → Flatpak sync execution
  ↓
[Load Packages Modules]
  manager-interface.sh → Package manager abstraction
  version-manager.sh → Constraint parsing/comparison
  batch-operations.sh → Batch operations
  package-operations.sh → Individual operations
  flatpak-manager.sh → Flatpak operations
  ↓
[Load Commands]
  cmd-sync.sh → Sync command implementation
  ↓
cmd_sync() → Main entry point
  ↓
sync-orchestrator.sh → _sync_orchestrator()
  ↓
Phase 0: Validation
  _validate_yaml_syntax() → Check YAML syntax
  _validate_module_conflicts() → Check conflicts
  _get_enabled_modules_cached() → Load modules
  ↓
Phase 1: Build Sync Plan
  _get_module_packages_cached() → Get packages
  _classify_pacman_package() → Classify operation
  _check_packages_batch() → Validate existence
  _parse_package_constraint_cached() → Parse constraints
  ↓
Phase 2: Optional Backup
  _detect_backup_tool() → Find Timeshift/Snapper
  _create_backup() → Create snapshot (if approved)
  ↓
Phase 3: Execute Sync
  _sync_pacman_packages() → Sync Arch/AUR packages
    _batch_install_pacman() → Batch installs
    _interactive_downgrade() → Downgrade selection
  _sync_flatpak_packages() → Sync Flatpak packages
  _update_package_state() → Update state file
  ↓
Phase 4: Prune Orphans (if --prune)
  Find orphaned packages
  Interactive confirmation
  _pm_remove() → Remove packages
  _remove_package_state() → Update state
  ↓
Phase 5: Finalize
  Show summary
  _generate_lockfile() → Auto-lock (if enabled)
  _release_sync_lock() → Release lock
```

### Module Interaction Patterns

**State access**:
- All modules use `_state_*` and `_cache_*` functions
- No direct global variable access outside state-manager
- Centralized cache invalidation

**Error recovery**:
- `state.sh` backs up state before mutations
- `sync-orchestrator.sh` uses ERR trap for cleanup
- `sync-lock.sh` prevents concurrent operations
- Atomic file mutations with temp files

**Validation-first**:
- Phase 0 validates YAML before any operations
- Enhanced error reporting: Line numbers, context, fixes
- Batch package validation (single query for all packages)

## Performance Optimizations

### Module Caching

**Problem**: 16 yq calls per status/lock command (slow)
**Solution**: Single yq query loads all enabled modules
**Impact**: 2-5s faster status/lock commands

**Implementation** (config.sh):
```bash
_get_enabled_modules_cached() {
    # Check cache
    if _state_get "module_cache_loaded" 2>/dev/null; then
        _cache_get "modules" "enabled_list"
        return 0
    fi

    # Single query for all modules
    local modules=$(yq eval '.packages.modules | to_entries |
        map(select(.value.enabled == true) | .key) | join(" ")' \
        "$PACKAGES_FILE")

    # Cache result
    _cache_set "modules" "enabled_list" "$modules"
    _state_set "module_cache_loaded" "true"

    echo "$modules"
}
```

### Constraint Memoization

**Problem**: Redundant constraint parsing across sync operations
**Solution**: Parse once, cache to state-manager + disk
**Impact**: Eliminates redundant parsing

**Cache location**: `~/.local/state/package-manager/constraint-cache.yaml`
**TTL**: 1 hour
**Structure**:
```yaml
firefox:
  type: "exact"
  version: "120.0"
neovim:
  type: "min"
  version: "0.9.0"
```

**Implementation** (version-manager.sh):
```bash
_parse_package_constraint_cached() {
    local pkg="$1"
    local constraint="$2"

    # Check memory cache
    if _cache_has "constraints" "$pkg"; then
        _cache_get "constraints" "$pkg"
        return 0
    fi

    # Check disk cache (TTL: 1 hour)
    if [ -f "$CONSTRAINT_CACHE_FILE" ]; then
        local cached=$(yq eval --arg pkg "$pkg" \
            '.[$pkg] // ""' "$CONSTRAINT_CACHE_FILE")
        if [ -n "$cached" ]; then
            _cache_set "constraints" "$pkg" "$cached"
            echo "$cached"
            return 0
        fi
    fi

    # Parse constraint
    local result=$(_parse_constraint "$constraint")

    # Cache to memory + disk
    _cache_set "constraints" "$pkg" "$result"
    yq eval --arg pkg "$pkg" --arg result "$result" \
        '.[$pkg] = $result' -i "$CONSTRAINT_CACHE_FILE"

    echo "$result"
}
```

### Batch AUR Validation

**Problem**: Sequential AUR checks (N × 5s = 240s for 48 packages)
**Solution**: Single batch query (10s for all packages)
**Impact**: 24x faster validation

**Implementation** (validation.sh):
```bash
_validate_aur_packages_batch() {
    local packages="$1"

    # Single paru query for all packages (timeout: 15s)
    timeout 15s paru -Ss $packages > /tmp/aur-batch.txt 2>&1 || {
        # Fallback to sequential with cache
        _sequential_validate_with_cache "$packages"
        return $?
    }

    # Parse results and cache
    for pkg in $packages; do
        if grep -q "^aur/$pkg " /tmp/aur-batch.txt; then
            echo "$pkg" > "$CACHE_DIR/aur-packages/$pkg"
            echo "$(date +%s)" >> "$CACHE_DIR/aur-packages/$pkg"
        fi
    done
}
```

### Lockfile Fast-Path

**Problem**: Unnecessary package operations when versions match lockfile
**Solution**: Skip packages matching locked versions
**Impact**: 30-50% faster sync operations

**Implementation** (sync-pacman.sh):
```bash
_sync_pacman_packages() {
    for pkg in $packages; do
        local locked_version=$(_get_locked_version "$module" "$pkg")
        local current_version=$(_get_pacman_version "$pkg")

        # Fast-path: Skip if versions match
        if [ "$locked_version" = "$current_version" ]; then
            ui_skip "Already at locked version: $pkg $locked_version"
            continue
        fi

        # Proceed with install/upgrade/downgrade
        _classify_and_sync_package "$pkg"
    done
}
```

### State-Based Lockfile Generation

**Problem**: Query pacman for each package (slow)
**Solution**: Read from package-state.yaml
**Impact**: 100x faster lockfile generation

**Implementation** (cmd-lock.sh):
```bash
_generate_lockfile() {
    # Read state file (fast)
    local packages=$(yq eval '.packages[]' "$STATE_FILE")

    # Single-pass iteration
    for pkg in $packages; do
        local name=$(echo "$pkg" | yq eval '.name')
        local version=$(echo "$pkg" | yq eval '.version')
        local module=$(echo "$pkg" | yq eval '.module')

        # Write to lockfile
        yq eval --arg module "$module" --arg name "$name" \
            --arg version "$version" \
            '.packages[$module][$name] = $version' -i "$LOCKFILE"
    done
}
```

### Single-Pass Iteration

**Problem**: Multiple loops for classify, validate, update
**Solution**: One loop for all operations
**Impact**: 50% faster lockfile generation

**Pattern**:
```bash
# Before (3 passes)
for pkg in $packages; do classify "$pkg"; done
for pkg in $packages; do validate "$pkg"; done
for pkg in $packages; do update "$pkg"; done

# After (1 pass)
for pkg in $packages; do
    classify "$pkg"
    validate "$pkg"
    update "$pkg"
done
```

## Development Guide

### Adding a New Command

**Step 1**: Create `commands/cmd-newcommand.sh`

```bash
#!/usr/bin/env bash
# Command: newcommand
# Purpose: [description]

cmd_newcommand() {
    local arg1="$1"

    # Validate arguments
    if [ -z "$arg1" ]; then
        ui_error "Missing required argument"
        _show_newcommand_help
        return 1
    fi

    # Use operations/packages modules
    _operation_function "$arg1"

    # Update state if needed
    _update_package_state "$arg1" "$version" "$type" "$module" "$constraint"

    ui_success "Operation complete"
}

_show_newcommand_help() {
    cat <<EOF
Usage: package-manager newcommand <arg>

Description of command.

Arguments:
  arg    Description of argument

Examples:
  package-manager newcommand example
EOF
}
```

**Step 2**: Register in `executable_package-manager.sh`

```bash
# Load command module
. "$PACKAGE_MANAGER_DIR/commands/cmd-newcommand.sh"

# Add to case statement
case "$COMMAND" in
    newcommand)
        cmd_newcommand "$@"
        ;;
esac
```

**Step 3**: Add help text to `commands/cmd-help.sh`

```bash
# In _show_general_help()
echo "  newcommand       Description of command"

# Add detailed help
_show_newcommand_help() {
    # Implemented in cmd-newcommand.sh
    _show_newcommand_help
}
```

### Adding a New Operation Module

**Step 1**: Create `operations/new-operation.sh`

```bash
#!/usr/bin/env bash
# Module: new-operation
# Purpose: [description]

_new_operation_function() {
    local param="$1"

    # Use core modules
    local cached_value=$(_cache_get "cache_name" "$param")
    if [ -n "$cached_value" ]; then
        echo "$cached_value"
        return 0
    fi

    # Use packages modules
    local version=$(_pm_query_version "$PACKAGE_TYPE_PACMAN" "$param")

    # Perform operation
    local result="..."

    # Update cache
    _cache_set "cache_name" "$param" "$result"

    echo "$result"
}
```

**Step 2**: Load in `executable_package-manager.sh`

```bash
# Load operations modules
. "$PACKAGE_MANAGER_DIR/operations/new-operation.sh"
```

**Step 3**: Use in command implementations

```bash
# In cmd-newcommand.sh
cmd_newcommand() {
    local result=$(_new_operation_function "$arg")
    ui_info "Result: $result"
}
```

### Performance Considerations

**Caching strategy**:
- Use state-manager for session-lifetime caches
- Use disk persistence for long TTLs (1+ hours)
- Clear caches on relevant events (package install/remove)

**Batch operations**:
- Collect operations, execute in single batch
- 5-10x faster than sequential
- Example: Batch installs, batch AUR validation

**Minimize external commands**:
- Cache yq queries (config.sh pattern)
- Cache pacman/flatpak queries (performance.sh)
- Use bash built-ins when possible

**Lazy-loading**:
- Populate caches on first access, not at startup
- Reduces initialization overhead
- Example: Flatpak cache loaded only if Flatpak command used

**Disk-persisted caches**:
- Use for expensive operations (AUR validation, constraint parsing)
- Implement TTL for freshness
- Store in `~/.local/state/package-manager/` or `~/.cache/package-manager/`

**Best practices**:
- See "Implementation Patterns" for ui_spin usage guidelines
- See "Implementation Patterns" for stdout/stderr separation
- See "Implementation Patterns" for exit code and timeout handling

### Testing Changes

**Syntax validation**:
```bash
# Validate YAML
yq eval '.' ~/.chezmoidata/packages.yaml

# Shellcheck validation
shellcheck private_dot_local/lib/scripts/system/package-manager/**/*.sh
```

**Module loading**:
```bash
# Test module cache
package-manager module list

# Test enabled modules
package-manager status
```

**Package operations**:
```bash
# Test install
package-manager install testpkg
package-manager status

# Test removal
package-manager remove testpkg
package-manager status
```

**State validation**:
```bash
# Check state file syntax
yq eval '.' ~/.local/state/package-manager/package-state.yaml

# Check state content
cat ~/.local/state/package-manager/package-state.yaml
```

**Backup validation**:
```bash
# List backups
ls -la ~/.local/state/package-manager/backups/

# Restore from backup (if needed)
cp ~/.local/state/package-manager/backups/package-state-*.yaml \
   ~/.local/state/package-manager/package-state.yaml
```

**Cache validation**:
```bash
# Check constraint cache
cat ~/.local/state/package-manager/constraint-cache.yaml

# Check AUR cache
ls -la ~/.cache/package-manager/aur-packages/
```

## Implementation Patterns

### UI Function Usage Guidelines

**When to avoid `ui_spin`**:

`ui_spin` wraps commands with a spinner animation and hides their output. Avoid in these contexts:

1. **Interactive operations** (requires user input):
   - Sudo prompts: `paru -S` and `flatpak install` need visible sudo authentication
   - Package manager confirmations
   - Pattern: Call commands directly without ui_spin wrapper

2. **Progress feedback operations** (user needs real-time info):
   - Package downloads: Users need download progress/speed/ETA
   - Large file transfers
   - Pattern: Use `ui_info` before operation, direct command call, `ui_success` after

3. **State-modifying operations** (global variable mutations):
   - Functions that update `_CACHE_*` associative arrays
   - State file mutations
   - Reason: ui_spin runs in subshell, global state changes lost
   - Pattern: Call directly, not via ui_spin

**Examples from codebase**:
- `flatpak-manager.sh:32-34`: Flatpak install shows download progress
- `batch-operations.sh:44-46`: Batch install preserves sudo prompt
- `sync-flatpak.sh:15`: Direct call preserves `_CACHE_FLATPAK_*` updates
- `sync-orchestrator.sh:302`: Sync functions update global state

### Stdout/Stderr Separation

**Pattern**: Functions returning values via `echo` must redirect UI messages to stderr.

**Why**: UI output on stdout pollutes function return values.

**Implementation**:
```bash
_my_function() {
    local result

    # UI messages to stderr (>&2)
    ui_info "Processing..." >&2
    ui_warning "Issue detected..." >&2

    # Return value to stdout
    echo "$result"
}
```

**Examples from codebase**:
- `validation.sh:149`: Batch validation returns package list
- `validation.sh:158`: Fallback validation returns status

### Exit Code Handling

**Pattern**: Capture `$?` immediately after command, before any other operations.

**Why**: `$?` is cleared/overwritten by subsequent commands (including `if` statements).

**Anti-pattern**:
```bash
# WRONG: $? always 0 inside if block
if cmd; then
    local status=$?  # Always 0!
fi
```

**Correct pattern**:
```bash
# Capture BEFORE if statement
cmd
local status=$?

if [[ $status -ne 0 ]]; then
    # Handle error
fi
```

**Example from codebase**:
- `cmd-update.sh:39-41`: Sync exit code captured before if statement

### Timeout Handling

**Pattern**: Use `timeout` directly, not via `ui_spin` wrapper.

**Why**: Signal propagation issues when timeout sends SIGTERM through ui_spin's subshell.

**Implementation**:
```bash
# Direct timeout call
if ! output=$(timeout 10 command 2>&1); then
    ui_warning "Command timed out" >&2
    return 1
fi
```

**Examples from codebase**:
- `validation.sh:154-156`: AUR batch validation with 10s timeout
- `sync-pacman.sh:227`: Version query with 60s timeout

### Resource Management

**File descriptor cleanup**:

**Pattern**: Explicitly close file descriptors after flock operations.

**Why**: Prevents resource leaks in long-running processes.

**Implementation**:
```bash
_acquire_lock() {
    exec 200>"$LOCK_FILE"
    flock -n 200 || return 1
}

_release_lock() {
    flock -u 200 2>/dev/null || true
    exec 200>&-  # Close file descriptor
}
```

**Example from codebase**:
- `sync-lock.sh:40-45`: Sync lock file descriptor cleanup

### Version Validation

**Pattern**: Fail operations if version cannot be determined.

**Why**: Prevents "unknown" or empty versions in lockfile, which breaks reproducibility.

**Implementation**:
```bash
version=$(_get_package_version "$pkg")

# Fail if version is empty/unknown
if [[ -z "$version" ]]; then
    ui_error "Failed to determine version for $pkg"
    return 1
fi

# Proceed with version
_update_lockfile "$pkg" "$version"
```

**Example from codebase**:
- `flatpak-manager.sh:40-44`: Flatpak install fails if version unknown

### Verbose Mode Awareness

**Pattern**: Respect `VERBOSE` flag for optional logging.

**Why**: Reduces noise in normal operation, enables debugging when needed.

**Implementation**:
```bash
if [[ "${VERBOSE:-false}" == "true" ]]; then
    ui_info "Detailed operation info..."
fi
```

**Example from codebase**:
- `backup-manager.sh:57`: Skip logging respects verbose mode

## Migration Notes

### v1.0 → v2.x

**Removed features**:
- Strategy system (pacman → yay_bin → yay_source)
- `--strategy` flag
- Search command (use `paru` directly)

**Replaced by**:
- Single `paru` command for all installs
- Module-based organization
- Version constraint system

**Breaking changes**:
- State files moved to `~/.local/state/package-manager/`
- No longer uses chezmoi state directory

### v2.x → v3.0

**Architecture changes**:
- Modularized: 31 files (was monolithic)
- 4-layer design: Core/Operations/Packages/Commands
- 75% reduction in main file (2,133 → 521 lines)

**New modules**:
- `core/state-manager.sh`: Centralized state/cache
- `operations/backup-manager.sh`: Timeshift/Snapper integration
- `operations/lockfile-manager.sh`: Lockfile I/O
- `operations/sync-orchestrator.sh`: 5-phase sync workflow
- `operations/sync-lock.sh`: Concurrent sync protection
- `operations/sync-pacman.sh`: Pacman sync execution
- `operations/sync-flatpak.sh`: Flatpak sync execution

**Performance optimizations**:
- Module caching: 16 yq calls → 1 call
- Constraint memoization with disk persistence
- Batch AUR validation: 24x faster
- Lockfile fast-path: 30-50% faster sync
- State-based lockfile: 100x faster generation
- Single-pass iteration: 50% faster

**New features**:
- Backup integration (Timeshift/Snapper)
- Enhanced YAML validation with error context
- Concurrent sync protection
- Stale lock detection
- State backups (keep last 10)

**Deprecated commands**:
- `health` → Use `validate --check-packages`
- `update-strategy` → Use `update`

**Breaking API changes**:
- Some internal functions renamed
- Use documented public APIs only
- Private functions (\_prefix) subject to change

### Security Fix (v2.2.1)

**yq injection vulnerability patched**:
- 16+ vulnerable lines converted to `--arg` flag
- All yq operations now use safe substitution
- Example:
  ```bash
  # Before (vulnerable)
  yq eval ".packages.modules.$module.enabled = true"

  # After (safe)
  yq eval --arg module "$module" \
      '.packages.modules[$module].enabled = true'
  ```

**Strict mode enabled**:
- `set -euo pipefail` in all scripts
- Prevents partial state corruption
- Exits on undefined variables

**Input validation**:
- Module and package names validated
- No special characters in yq keys
- Prevents command injection

### v3.0.1 (Bug Fix: State Initialization)

**Issue**: Constraint cache created in wrong location
- Cache file: `~/.local/share/chezmoi/.constraint-cache` (incorrect)
- Expected: `~/.local/state/package-manager/.constraint-cache`

**Root cause**: STATE_DIR undefined when state-manager.sh sourced

**Fix**: Moved global configuration before module sourcing
- Old: Line 69 (after modules)
- New: Lines 28-52 (before modules)

**Action required**:
```bash
# Clean up misplaced cache file
rm ~/.local/share/chezmoi/.constraint-cache

# Verify correct location
ls -la ~/.local/state/package-manager/.constraint-cache
```

## Troubleshooting

### State Directory Not Initialized

**Diagnosis**:
```bash
# Check if constraint cache in wrong location
ls -la ~/.local/share/chezmoi/.constraint-cache
ls -la ~/.local/state/package-manager/.constraint-cache
```

**Symptoms**:
- Cache files created in current directory instead of `~/.local/state/package-manager/`
- Untracked files in chezmoi repository (`.constraint-cache`)

**Root cause**: STATE_DIR defined after module sourcing

**Solution**:
- Ensure STATE_DIR defined before sourcing core modules in executable_package-manager.sh
- Pattern: Global config (lines 28-52) → Module sourcing (lines 54+)
- Clean up misplaced files: `rm ~/.local/share/chezmoi/.constraint-cache`

### Sync Operations Slow

**Diagnosis**:
```bash
# Check module cache (should be fast: 2-5s)
time package-manager status

# Check lockfile exists
ls -la ~/.local/state/package-manager/locked-versions.yaml

# Check constraint cache
cat ~/.local/state/package-manager/constraint-cache.yaml
```

**Solutions**:
- Ensure lockfile exists: `package-manager lock`
- Clear stale constraint cache: `rm ~/.local/state/package-manager/constraint-cache.yaml`
- Module caching auto-enabled in v3.0 (no action needed)

### Concurrent Sync Operations

**Diagnosis**:
```bash
# Check for sync lock
ls -la /tmp/package-manager-sync.lock

# Check lock age
stat -c %Y /tmp/package-manager-sync.lock
```

**Solutions**:
- Wait for other operation to complete
- If stale (>30 min): Interactive prompt offers removal
- Manual removal: `rm /tmp/package-manager-sync.lock`

### YAML Validation Errors

**Diagnosis**:
```bash
package-manager validate
```

**Common fixes**:
- **Indentation errors**: Use 2-space indents (not tabs)
- **Missing quotes**: Quote version constraints (`">=1.0"`)
- **Duplicate packages**: Check for package name conflicts
- **Module conflicts**: Disable conflicting modules with `package-manager module disable`
- **Invalid YAML**: Validate with `yq eval '.' ~/.chezmoidata/packages.yaml`

**Enhanced error reporting** (v3.0):
- Line numbers in error messages
- Context (surrounding lines)
- Common fixes suggested

### Package State Corruption

**Diagnosis**:
```bash
# Check state file syntax
yq eval '.' ~/.local/state/package-manager/package-state.yaml
```

**Recovery**:
```bash
# Option 1: Restore from backup
ls -la ~/.local/state/package-manager/backups/
cp ~/.local/state/package-manager/backups/package-state-20251116-123456.yaml \
   ~/.local/state/package-manager/package-state.yaml

# Option 2: Regenerate from scratch
rm ~/.local/state/package-manager/package-state.yaml
package-manager sync
```

**Prevention**:
- Automatic backups before sync (keep last 10)
- Atomic mutations with temp files
- ERR trap for cleanup on failure

### Lockfile Drift Warnings

**Diagnosis**:
```bash
# Show drift (locked vs installed versions)
package-manager status

# Show constraint violations
package-manager outdated
```

**Solutions**:
```bash
# Option 1: Update lockfile to match current state
package-manager lock

# Option 2: Sync to locked versions (downgrades if needed)
package-manager sync
```

**Causes**:
- Manual package installs outside package-manager
- Lockfile not regenerated after updates
- System updates via different tool (topgrade, pacman)

### AUR Validation Timeout

**Diagnosis**:
```bash
# Check if batch validation used
grep "_validate_aur_packages_batch" \
  ~/.local/lib/scripts/system/package-manager/core/validation.sh
```

**Solutions**:
- Batch validation has 15-second timeout (automatic)
- Falls back to sequential validation with cache (automatic)
- Clear stale cache: `rm -rf ~/.cache/package-manager/aur-packages/`
- Network issues: Check connectivity, retry

**Performance**:
- Batch: 10s for 48 packages
- Sequential with cache: 24s (cache hits fast)
- Sequential without cache: 240s (5s × 48 packages)

### Module Not Found

**Diagnosis**:
```bash
# List all modules
package-manager module list

# Check packages.yaml
yq eval '.packages.modules' ~/.chezmoidata/packages.yaml
```

**Solutions**:
- Check module name spelling
- Ensure module enabled: `package-manager module enable <name>`
- Validate YAML syntax: `package-manager validate`
- Check module exists in packages.yaml

### Backup Creation Failed

**Diagnosis**:
```bash
# Check backup tool config
yq eval '.packages.backup_tool' ~/.chezmoidata/packages.yaml

# Check Timeshift installed
command -v timeshift

# Check Snapper installed
command -v snapper
```

**Solutions**:
- Install backup tool: `paru -S timeshift` or `paru -S snapper`
- Configure in packages.yaml: `backup_tool: "timeshift"` or `"snapper"`
- Snapper: Ensure config exists: `snapper -c root list-configs`
- Skip backup prompt: Decline when prompted (sync continues)

## State Management

### State File Location

**Primary state**: `~/.local/state/package-manager/package-state.yaml`
**Backups**: `~/.local/state/package-manager/backups/`
**Lockfile**: `~/.local/state/package-manager/locked-versions.yaml`
**Constraint cache**: `~/.local/state/package-manager/constraint-cache.yaml`
**AUR cache**: `~/.cache/package-manager/aur-packages/`

### Cache TTLs

| Cache | Location | TTL | Invalidation |
|-------|----------|-----|--------------|
| Constraint | `~/.local/state/package-manager/constraint-cache.yaml` | 1 hour | TTL expiry or manual clear |
| AUR packages | `~/.cache/package-manager/aur-packages/` | 24 hours | TTL expiry or manual clear |
| Module config | Memory (state-manager) | Session | Process exit |
| Pacman versions | Memory (state-manager) | Session | Process exit |
| Flatpak versions | Memory (state-manager) | Session | Process exit |

### Atomic Mutation Pattern

**All state mutations use this pattern**:
```bash
# 1. Backup current state
_backup_state_file

# 2. Create temp file
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT ERR

# 3. Perform mutation (yq with --arg for safety)
yq eval --arg name "$package" --arg version "$version" \
    '.packages += [{"name": $name, "version": $version}]' \
    "$STATE_FILE" > "$TEMP_FILE"

# 4. Atomic replace
mv "$TEMP_FILE" "$STATE_FILE"

# 5. Cleanup (automatic via trap)
```

**Benefits**:
- Never corrupts state on error
- Backup available for recovery
- Safe concurrent access (with sync lock)
- Prevents yq injection (v2.2.1 security fix)

### Backup Retention

**Policy**: Keep last 10 backups
**Naming**: `package-state-YYYYMMDD-HHMMSS.yaml`
**Location**: `~/.local/state/package-manager/backups/`

**Automatic cleanup**:
```bash
# In _backup_state_file()
ls -t "$BACKUP_DIR"/package-state-*.yaml | tail -n +11 | xargs -r rm
```

**Manual restore**:
```bash
# List backups (newest first)
ls -t ~/.local/state/package-manager/backups/

# Restore specific backup
cp ~/.local/state/package-manager/backups/package-state-20251116-123456.yaml \
   ~/.local/state/package-manager/package-state.yaml
```

## Integration Points

### packages.yaml Structure

**Location**: `.chezmoidata/packages.yaml`

**Structure**:
```yaml
packages:
  # Optional backup configuration
  backup_tool: "timeshift"    # or "snapper" (auto-detects if omitted)
  snapper_config: "root"      # snapper config name (default: "root")

  # Module definitions
  modules:
    base:
      enabled: true
      packages:
        - firefox                      # No constraint (latest)
        - name: neovim                 # Exact version
          version: "0.9.5"
        - name: python                 # Minimum version
          version: ">=3.11"
        - name: nodejs                 # Maximum version
          version: "<21.0.0"

    shell_environment:
      enabled: true
      packages:
        - zsh
        - starship
        - flatpak:com.spotify.Client  # Flatpak package (prefix required)
```

**Module rules**:
- Flat structure: `packages.modules.<name>`
- No nested modules
- Enabled flag required
- Flatpak packages: Prefix with `flatpak:`

### Topgrade Integration

**Configuration**: `~/.config/topgrade.toml`

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
- Auto-generates lockfile if AUTO_LOCK enabled

### Chezmoi Integration

**Run script**: `.chezmoiscripts/run_onchange_before_sync_packages.sh.tmpl`

**Trigger**: Hash-based on packages.yaml changes
```bash
# Hash comment triggers re-run when packages.yaml changes
# {{ .packages | toJson | sha256sum }}

# Call package-manager sync
~/.local/bin/package-manager sync --prune
```

**Workflow**:
1. Edit `.chezmoidata/packages.yaml`
2. Run `chezmoi apply`
3. Script detects hash change
4. Executes `package-manager sync --prune`
5. Packages synchronized

**Benefits**:
- Declarative package management
- Version control for package list
- Automatic sync on config changes
