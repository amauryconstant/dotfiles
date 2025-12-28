#!/usr/bin/env bash

# Package Manager - Module-based declarative package management with version pinning
# Purpose: NixOS/dcli-inspired package management for Arch Linux
# Requirements: Arch Linux, paru, yq, gum (UI library)
# Version: 3.0.0 (comprehensive refactoring, new modules, performance optimizations)

# Source UI library (check if already sourced to avoid readonly variable conflicts)
if ! declare -F ui_title >/dev/null 2>&1; then
    if [ -n "$UI_LIB" ] && [ -f "$UI_LIB" ]; then
        # shellcheck source=/dev/null
        . "$UI_LIB"
    elif [ -f "$HOME/.local/lib/scripts/core/gum-ui.sh" ]; then
        # shellcheck source=/dev/null
        . "$HOME/.local/lib/scripts/core/gum-ui.sh"
    else
        echo "Error: UI library not found" >&2
        exit 1
    fi
fi

# =============================================================================
# LOAD CORE MODULES
# =============================================================================

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# =============================================================================
# GLOBAL CONFIGURATION (must be defined before sourcing modules)
# =============================================================================
#
# CRITICAL: This section must execute BEFORE sourcing core modules.
#
# Why: Core modules use STATE_DIR during initialization:
#   - state-manager.sh:338 → CONSTRAINT_CACHE_FILE="${STATE_DIR:-.}/.constraint-cache"
#   - validation.sh:12     → AUR_CACHE_DIR="${STATE_DIR:-.}/.aur-cache"
#
# If STATE_DIR is undefined, fallback "." creates cache files in current directory.
# Historical bug: STATE_DIR defined at line 69 (after modules) caused cache files
# to be created in ~/.local/share/chezmoi/ instead of ~/.local/state/package-manager/
#

PACKAGES_FILE="$HOME/.local/share/chezmoi/.chezmoidata/packages.yaml"
STATE_DIR="$HOME/.local/state/package-manager"
# shellcheck disable=SC2034  # Used in sourced modules: core/state.sh, commands/cmd-{sync,lock,status}.sh
STATE_FILE="$STATE_DIR/package-state.yaml"
# shellcheck disable=SC2034  # Used in sourced modules: core/validation.sh, commands/cmd-{sync,lock,status,validate}.sh
LOCKFILE="$STATE_DIR/locked-versions.yaml"

# Feature flags (can be overridden by environment)
# shellcheck disable=SC2034  # Used in sourced cmd-sync.sh
AUTO_LOCK=${PACKAGE_MANAGER_AUTO_LOCK:-true}
# shellcheck disable=SC2034  # Used in sourced cmd-sync.sh
USE_LOCKFILE_FASTPATH=${PACKAGE_MANAGER_USE_LOCKFILE:-true}
# shellcheck disable=SC2034  # Used in sourced packages/batch-operations.sh
BATCH_INSTALLS=${PACKAGE_MANAGER_BATCH:-true}

# Logging verbosity
# shellcheck disable=SC2034  # Used in sourced cmd-sync.sh
VERBOSE=false

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Source core modules (order matters: constants first, then state manager, then config and dependencies)
. "$SCRIPT_DIR/core/constants.sh"
. "$SCRIPT_DIR/core/state-manager.sh"
. "$SCRIPT_DIR/core/config.sh"
. "$SCRIPT_DIR/core/state.sh"
. "$SCRIPT_DIR/core/performance.sh"
. "$SCRIPT_DIR/core/validation.sh"

# Source operations modules (NEW in v3.0)
. "$SCRIPT_DIR/operations/backup-manager.sh"
. "$SCRIPT_DIR/operations/lockfile-manager.sh"
. "$SCRIPT_DIR/operations/sync-lock.sh"
. "$SCRIPT_DIR/operations/sync-orchestrator.sh"

# Source package modules
. "$SCRIPT_DIR/packages/manager-interface.sh"
. "$SCRIPT_DIR/packages/version-manager.sh"
. "$SCRIPT_DIR/packages/batch-operations.sh"
. "$SCRIPT_DIR/packages/package-operations.sh"
. "$SCRIPT_DIR/packages/flatpak-manager.sh"

# Source command modules
. "$SCRIPT_DIR/commands/cmd-install.sh"
. "$SCRIPT_DIR/commands/cmd-remove.sh"
. "$SCRIPT_DIR/commands/cmd-lock.sh"
. "$SCRIPT_DIR/commands/cmd-pin.sh"
. "$SCRIPT_DIR/commands/cmd-module.sh"
. "$SCRIPT_DIR/commands/cmd-versions.sh"
. "$SCRIPT_DIR/commands/cmd-outdated.sh"
. "$SCRIPT_DIR/commands/cmd-merge.sh"
. "$SCRIPT_DIR/commands/cmd-update.sh"
. "$SCRIPT_DIR/commands/cmd-status.sh"
. "$SCRIPT_DIR/commands/cmd-validate.sh"
. "$SCRIPT_DIR/commands/cmd-find.sh"
. "$SCRIPT_DIR/commands/cmd-search.sh"

# =============================================================================
# MODULE LOADING COMPLETE
# =============================================================================

# State file I/O functions now in core/state.sh

# Performance cache functions now in core/performance.sh

# Package type detection and version utilities now in packages/version-manager.sh

# Lockfile utilities now in operations/lockfile-manager.sh
# Validation and helper functions now in core/validation.sh

# Batch installation functions now in packages/batch-operations.sh

# =============================================================================
# SECTION 2: MODULE SYSTEM
# =============================================================================

# Module access functions now in core/config.sh
# Functions: _get_modules(), _get_enabled_modules(), _get_module_packages(),
#            _is_module_enabled(), _get_module_conflicts(), _load_module_cache()

# =============================================================================
# SECTION 3: COMMAND MODULES
# =============================================================================
# All command implementations have been extracted to modular files in commands/
# and are sourced at the top of this script (lines 42-53).
#
# Available commands (implemented in commands/cmd-*.sh):
#   - Module management: module list, enable, disable (cmd-module.sh)
#   - Version pinning: pin, unpin, lock, versions, outdated (cmd-pin.sh, cmd-lock.sh, cmd-versions.sh, cmd-outdated.sh)
#   - Package operations: install, remove, merge, sync, update (cmd-install.sh, cmd-remove.sh, cmd-merge.sh, cmd-sync.sh, cmd-update.sh)
#   - Status & validation: status, validate (cmd-status.sh, cmd-validate.sh)

# =============================================================================
# SECTION 4: PACKAGE OPERATIONS
# =============================================================================

# Package install/remove operations now in packages/package-operations.sh
# Flatpak operations now in packages/flatpak-manager.sh
# Functions: _install_package(), _remove_package(), _install_flatpak(), _remove_flatpak(), _update_flatpaks()

# =============================================================================
# VERSION SELECTION
# =============================================================================

# Version selection now in commands/cmd-sync.sh (with fzf support)
# Function: _select_downgrade_version()


# =============================================================================
# SECTION 5: ENHANCED SYNC
# =============================================================================

# Backup operations now in operations/backup-manager.sh
# Functions: _get_backup_tool(), _get_snapper_config(), _create_backup(), _prompt_backup()


# =============================================================================
# SECTION 7: HELP & VERSION
# =============================================================================

show_help() {
    cat << 'EOF'
package-manager v3.0.0 - Declarative package management for Arch Linux

USAGE
    package-manager <command> [options]

COMMON COMMANDS
    sync                             Sync system to packages.yaml
    update                           Complete system update (sync + upgrade all)
    status                           Show package status
    module list                      List all modules
    module enable [module...]        Enable module(s)

MODULES
    module list                      List modules with status
    module enable <module>...        Enable modules (interactive if no args)
    module disable <module>...       Disable modules (interactive if no args)

PACKAGES
    install <package>                Install package
    remove <package>                 Remove package
    find <package>                   Find which module contains package
    search                           Interactive package search (fzf)
    merge [--dry-run]                Import unmanaged packages

SYNC & UPDATE
    sync [--prune] [--no-lock]       Sync to packages.yaml state
    sync --locked                    Enforce lockfile versions strictly
    update [--no-sync] [--no-flatpak] Sync + update all packages

VERSION PINNING
    pin <package> <version>          Pin to version (e.g., "120.0", ">=0.9", "<3.12")
    unpin <package>                  Remove constraint
    lock                             Generate lockfile
    versions [package]               Show version info
    outdated                         List constraint violations

VALIDATION
    validate                         Validate packages.yaml
    validate --check-packages        Check package availability
    validate --check-lockfile        Validate lockfile

EXAMPLES
    package-manager module enable shell desktop
    package-manager pin firefox 120.0
    package-manager sync
    package-manager merge --dry-run

FILES
    ~/.local/share/chezmoi/.chezmoidata/packages.yaml
    ~/.local/state/package-manager/package-state.yaml
    ~/.local/state/package-manager/locked-versions.yaml

For detailed help: package-manager help --full
For documentation: ~/.local/lib/scripts/system/CLAUDE.md
EOF
}

show_help_full() {
    cat << 'EOF'
package-manager v3.0.0
Module-based declarative package management with version pinning and lockfile integration

USAGE
    package-manager <command> [options] [arguments]

MODULES
    module list                      List all modules with status
    module enable <module>...        Enable modules (interactive if no args)
    module disable <module>...       Disable modules (interactive if no args)

PACKAGES
    install <package>                Install single package
    remove <package>                 Remove package
    find <package> [--json]          Find which module(s) contain package
    search                           Interactive package search (requires fzf)
    merge [--dry-run]                Import unmanaged packages to modules

SYNC & UPDATE
    sync [--prune] [--no-lock]       Sync system to packages.yaml state
                                     --prune: Remove orphaned packages
                                     --no-lock: Skip lockfile update
    sync --locked                    Enforce lockfile versions strictly

    update [--no-sync] [--no-flatpak]
                                     Complete system update (5 phases):
                                       1. Sync to packages.yaml
                                       2. Update all Arch/AUR packages
                                       3. Update all Flatpak packages
                                       4. System validation
                                       5. Lockfile generation
                                     --no-sync: Skip phase 1
                                     --no-flatpak: Skip phase 3

VERSION PINNING
    pin <package> <version>          Pin to version (e.g., "120.0", ">=0.9", "<3.12")
    unpin <package>                  Remove version constraint
    lock [--quiet]                   Generate lockfile with current versions
    versions [package]               Show version info (includes lockfile)
    outdated                         List packages violating constraints

VALIDATION
    status                           Show package status with lockfile analysis
    validate [--check-packages]      Validate packages.yaml structure
    validate --check-lockfile        Validate lockfile (staleness, syntax)

VERSION CONSTRAINT SYNTAX
    Exact version:     { name: "firefox", version: "120.0" }
    Minimum version:   { name: "neovim", version: ">=0.9.0" }
    Maximum version:   { name: "python", version: "<3.12" }

EXAMPLES
    # Enable modules
    package-manager module enable base shell desktop

    # Discover unmanaged packages
    package-manager merge --dry-run
    package-manager merge

    # Pin package version
    package-manager pin firefox 120.0

    # Sync system
    package-manager sync

    # Check status
    package-manager status

FEATURES
    • Module system with conflict detection
    • NixOS-style version constraints (exact, >=, <)
    • Batch operations (5-10x faster bulk installs)
    • Lockfile integration (auto-lock, fast-path)
    • Unmanaged package discovery
    • Interactive downgrade selection
    • Backup integration (Timeshift/Snapper)
    • Drift detection and staleness warnings

PERFORMANCE
    • Batch installs: 5-10x faster for bulk operations
    • Lockfile fast-path: 30-50% faster sync
    • State-based lockfile: 100x faster generation
    • Batch AUR validation: 24x faster

FILES
    Config:    ~/.local/share/chezmoi/.chezmoidata/packages.yaml
    State:     ~/.local/state/package-manager/package-state.yaml
    Lockfile:  ~/.local/state/package-manager/locked-versions.yaml

TROUBLESHOOTING
    Sync failed - YAML syntax:
        yq eval . ~/.chezmoidata/packages.yaml

    Sync failed - Package not found:
        package-manager validate --check-packages

    Sync failed - Constraint violation:
        package-manager outdated

    Sync already running:
        rm ~/.local/state/package-manager/.sync.lock

For documentation: ~/.local/lib/scripts/system/CLAUDE.md
EOF
}

show_version() {
    ui_title "package-manager v3.0.0"
    ui_info "Module-based package management for Arch Linux"
}

# =============================================================================
# LEGACY FUNCTIONS (PRESERVED FOR COMPATIBILITY)
# =============================================================================

check_health() {
    # DEPRECATED in v3.0.0 - Use 'package-manager validate --check-packages' instead
    ui_warning "DEPRECATED: 'health' command is deprecated in v3.0.0"
    ui_info "Use: package-manager validate --check-packages"
    ui_info "This command will be removed in v4.0.0"
    echo ""

    if [[ "$BRIEF" != "true" ]]; then
        ui_title "$ICON_HEALTH Package System Health Check"
    fi

    local issues=0

    # Check essential dependencies
    if command -v yq >/dev/null 2>&1; then
        [[ "$BRIEF" != "true" ]] && ui_success "yq: Available"
    else
        ui_error "yq: Missing (required for package management)"
        ((issues++))
    fi

    if command -v pacman >/dev/null 2>&1; then
        [[ "$BRIEF" != "true" ]] && ui_success "pacman: Available"
    else
        ui_error "pacman: Missing"
        ((issues++))
    fi

    local aur_helper=$(_get_aur_helper)
    if [[ -n "$aur_helper" ]]; then
        [[ "$BRIEF" != "true" ]] && ui_success "$aur_helper: Available"
    else
        [[ "$BRIEF" != "true" ]] && ui_warning "No AUR helper (paru): AUR packages unavailable"
    fi

    # Check packages file
    if [[ -f "$PACKAGES_FILE" ]]; then
        [[ "$BRIEF" != "true" ]] && ui_success "packages.yaml: Found"

        # Validate YAML syntax
        if command -v yq >/dev/null 2>&1 && yq eval '.' "$PACKAGES_FILE" >/dev/null 2>&1; then
            [[ "$BRIEF" != "true" ]] && ui_success "packages.yaml: Valid syntax"
        else
            ui_error "packages.yaml: Invalid syntax"
            ((issues++))
        fi
    else
        ui_error "packages.yaml: Not found at $PACKAGES_FILE"
        ((issues++))
    fi

    # Summary
    if [[ "$BRIEF" == "true" ]]; then
        if [[ $issues -eq 0 ]]; then
            ui_success "Package system health: OK"
            return 0
        else
            ui_error "Package system health: $issues issues found"
            return 1
        fi
    else
        if [[ $issues -eq 0 ]]; then
            ui_success "Essential dependencies available" --before 1
            return 0
        else
            ui_error "Missing essential dependencies" --before 1
            return 1
        fi
    fi
}

update_strategy() {
    # DEPRECATED in v3.0.0 - Use 'package-manager update' instead
    ui_warning "DEPRECATED: 'update-strategy' command is deprecated in v3.0.0"
    ui_info "Use: package-manager update"
    ui_info "This command will be removed in v4.0.0"
    echo ""

    if [[ "$BRIEF" != "true" ]]; then
        ui_title "$ICON_REFRESH Package Update"
        ui_info "This command updates system packages using paru"
        ui_spacer
    fi

    _check_yq_dependency || return 1

    local aur_helper=$(_get_aur_helper)

    if [[ -z "$aur_helper" ]]; then
        ui_error "No AUR helper found. Install paru: paru -S paru-bin"
        return 1
    fi

    # Run standard updates
    _log_verbose "Running package updates..."
    _execute_or_dry_run "Running $aur_helper update" "$aur_helper -Syu --noconfirm" || {
        ui_error "Package update failed"
        return 1
    }

    # Validate health
    _log_verbose "Validating package system health..."

    if check_health; then
        [[ "$BRIEF" != "true" ]] && ui_success "Update completed successfully"
        return 0
    else
        ui_warning "Update completed but validation found issues"
        return 1
    fi
}


# =============================================================================
# MAIN FUNCTION AND ARGUMENT PARSING
# =============================================================================

package-manager() {
    # Initialize variables (can be overridden by environment or command line)
    VERBOSE=${PACKAGE_MANAGER_VERBOSE:-false}
    DRY_RUN=${PACKAGE_MANAGER_DRY_RUN:-false}
    BRIEF=${PACKAGE_MANAGER_BRIEF:-false}

    # Parse global options that can appear before command
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                return 0
                ;;
            --version|-V)
                show_version
                return 0
                ;;
            --verbose|-v)
                export VERBOSE="true"
                shift
                ;;
            --dry-run|-n)
                export DRY_RUN="true"
                shift
                ;;
            --brief|-b)
                export BRIEF="true"
                shift
                ;;
            *)
                # Stop parsing global options when we hit something else
                break
                ;;
        esac
    done

    # Handle commands
    if [[ $# -eq 0 ]]; then
        ui_error "No command provided"
        echo ""
        show_help
        return 1
    fi

    local command="$1"
    shift

    case "$command" in
        "module")
            local subcommand="${1:-}"
            shift 2>/dev/null || true
            case "$subcommand" in
                "list")
                    cmd_module_list
                    ;;
                "enable")
                    if [[ $# -eq 0 ]]; then
                        cmd_module_enable_interactive
                    else
                        cmd_module_enable "$@"
                    fi
                    ;;
                "disable")
                    if [[ $# -eq 0 ]]; then
                        cmd_module_disable_interactive
                    else
                        cmd_module_disable "$@"
                    fi
                    ;;
                *)
                    ui_error "Unknown module subcommand: $subcommand"
                    ui_info "Usage: package-manager module {list|enable|disable}"
                    return 1
                    ;;
            esac
            ;;
        "pin")
            cmd_pin "$@"
            ;;
        "unpin")
            cmd_unpin "$@"
            ;;
        "lock")
            cmd_lock
            ;;
        "versions")
            cmd_versions "$@"
            ;;
        "outdated")
            cmd_outdated
            ;;
        "install")
            cmd_install "$@"
            ;;
        "remove")
            cmd_remove "$@"
            ;;
        "merge")
            cmd_merge "$@"
            ;;
        "sync")
            cmd_sync "$@"
            ;;
        "update")
            cmd_update "$@"
            ;;
        "status")
            cmd_status
            ;;
        "validate")
            cmd_validate "$@"
            ;;
        "find")
            cmd_find "$@"
            ;;
        "search")
            cmd_search "$@"
            ;;
        "health")
            check_health
            ;;
        "update-strategy")
            update_strategy
            ;;
        "help"|"-h"|"--help")
            if [[ "$1" == "--full" ]]; then
                show_help_full
            else
                show_help
            fi
            return 0
            ;;
        "version"|"-V"|"--version")
            show_version
            return 0
            ;;
        *)
            ui_error "Unknown command: $command"
            ui_info "Run 'package-manager --help' for usage information"
            return 1
            ;;
    esac
}

# Execute the function if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    package-manager "$@"
fi
