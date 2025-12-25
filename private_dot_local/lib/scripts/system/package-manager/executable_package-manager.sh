#!/usr/bin/env bash

# Package Manager - Module-based declarative package management with version pinning
# Purpose: NixOS/dcli-inspired package management for Arch Linux
# Requirements: Arch Linux, paru, yq, gum (UI library)
# Version: 2.2.1 (security: yq injection fix, strict mode)

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

# Source core modules (order matters: constants first, then config and dependencies)
. "$SCRIPT_DIR/core/constants.sh"
. "$SCRIPT_DIR/core/config.sh"
. "$SCRIPT_DIR/core/state.sh"
. "$SCRIPT_DIR/core/performance.sh"
. "$SCRIPT_DIR/core/validation.sh"

# Source package modules
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
. "$SCRIPT_DIR/commands/cmd-sync.sh"
. "$SCRIPT_DIR/commands/cmd-update.sh"
. "$SCRIPT_DIR/commands/cmd-status.sh"
. "$SCRIPT_DIR/commands/cmd-validate.sh"
. "$SCRIPT_DIR/commands/cmd-find.sh"
. "$SCRIPT_DIR/commands/cmd-search.sh"

# =============================================================================
# GLOBAL CONFIGURATION
# =============================================================================

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

# State file I/O functions now in core/state.sh

# Performance cache functions now in core/performance.sh

# Package type detection and version utilities now in packages/version-manager.sh

# =============================================================================
# LOCKFILE UTILITIES
# =============================================================================

_read_lockfile() {
    # Parse lockfile into associative array
    # Sets global lockfile_versions array
    # Returns: 0 on success, 1 if lockfile doesn't exist

    declare -g -A lockfile_versions

    if [[ ! -f "$LOCKFILE" ]]; then
        return 1
    fi

    # Parse YAML: packages.<module>.<pkg>: "version"
    while IFS=': ' read -r pkg ver; do
        [[ -z "$pkg" ]] && continue
        ver="${ver//\"/}"  # Strip quotes
        ver="${ver// #*/}"  # Strip comments
        # shellcheck disable=SC2034  # Global array used in sourced command files
        [[ -n "$ver" ]] && lockfile_versions[$pkg]="$ver"
    done < <(yq eval '.packages | to_entries[] | .value | to_entries[] | "\(.key): \(.value)"' "$LOCKFILE" 2>/dev/null)

    return 0
}

# Validation and helper functions now in core/validation.sh

# Batch installation functions now in packages/batch-operations.sh

# =============================================================================
# SECTION 2: MODULE SYSTEM
# =============================================================================

# Module access functions now in core/config.sh
# Wrapper functions that add yq dependency check
_get_modules() {
    _check_yq_dependency || return 1
    yq eval '.packages.modules | keys | .[]' "$PACKAGES_FILE" 2>/dev/null
}

_get_enabled_modules() {
    _check_yq_dependency || return 1
    yq eval '.packages.modules | to_entries | .[] | select(.value.enabled == true) | .key' "$PACKAGES_FILE" 2>/dev/null
}

_get_module_packages() {
    local module="$1"
    _check_yq_dependency || return 1
    MOD="$module" yq eval '.packages.modules[env(MOD)].packages | .[]' "$PACKAGES_FILE" 2>/dev/null
}

_is_module_enabled() {
    local module="$1"
    _check_yq_dependency || return 1
    local enabled
    enabled=$(MOD="$module" yq eval '.packages.modules[env(MOD)].enabled' "$PACKAGES_FILE" 2>/dev/null)
    [[ "$enabled" == "true" ]]
}

_get_module_conflicts() {
    local module="$1"
    _check_yq_dependency || return 1
    MOD="$module" yq eval '.packages.modules[env(MOD)].conflicts[]?' "$PACKAGES_FILE" 2>/dev/null
}

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
# Functions: _install_package(), _remove_package(), _install_flatpak()

# Install a Flatpak package
# Usage: _install_flatpak <flatpak_spec> <module_name>
# flatpak_spec: "flatpak:com.example.App"
_install_flatpak() {
    local package_spec="$1"
    local module="${2:-unknown}"

    # Strip "flatpak:" prefix
    local flatpak_id="${package_spec#flatpak:}"

    # Check if already installed (using cache - 1 call instead of 3)
    if _is_flatpak_installed "$flatpak_id"; then
        local installed_version=$(_get_flatpak_version "$flatpak_id")
        ui_info "$ICON_PACKAGE $flatpak_id: Already installed${installed_version:+ ($installed_version)}"
        return 0
    fi

    ui_step "$ICON_PACKAGE Installing Flatpak: $flatpak_id"

    # Install with --user scope (ALWAYS user scope, never system)
    if flatpak install -y --user flathub "$flatpak_id" 2>&1; then
        # Invalidate cache after install
        _FLATPAK_CACHE_LOADED=false
        local version=$(_get_flatpak_version "$flatpak_id")

        # Validate variables before state update
        if [[ -z "${flatpak_id:-}" ]]; then
            ui_error "CRITICAL: Missing flatpak_id after installation"
            return 1
        fi

        # Update state file (use 'unknown' if version detection failed)
        if ! _update_package_state "$flatpak_id" "${version:-unknown}" "flatpak" "$module" "null"; then
            ui_error "Failed to update state file for $flatpak_id"
            return 1
        fi

        ui_success "Installed Flatpak: $flatpak_id${version:+ ($version)}"
        return 0
    else
        ui_error "Failed to install Flatpak: $flatpak_id"
        return 1
    fi
}

# =============================================================================
# VERSION SELECTION
# =============================================================================

# Version selection now in commands/cmd-sync.sh (with fzf support)
# Function: _select_downgrade_version()


# =============================================================================
# SECTION 5: ENHANCED SYNC
# =============================================================================

# Detect available backup tool (timeshift or snapper)
# Returns: Tool name or empty string if none available
_get_backup_tool() {
    # Check for explicit preference in packages.yaml
    local configured=$(yq eval '.backup_tool // ""' "$PACKAGES_FILE" 2>/dev/null)

    if [[ -n "$configured" ]] && [[ "$configured" != "null" ]]; then
        if command -v "$configured" >/dev/null 2>&1; then
            echo "$configured"
            return
        fi
    fi

    # Auto-detect: prefer timeshift, fallback to snapper
    if command -v timeshift >/dev/null 2>&1; then
        echo "timeshift"
    elif command -v snapper >/dev/null 2>&1; then
        echo "snapper"
    else
        echo ""
    fi
}

# Get snapper config name from packages.yaml (default: root)
_get_snapper_config() {
    local snapper_config=$(yq eval '.snapper_config // "root"' "$PACKAGES_FILE" 2>/dev/null)
    echo "$snapper_config"
}

# Create optional backup before sync (supports timeshift and snapper)
# Usage: _create_backup
# Returns: 0 on success or skip, 1 on failure (non-fatal)
_create_backup() {
    local backup_tool=$(_get_backup_tool)

    # No backup tool available
    if [[ -z "$backup_tool" ]]; then
        return 0  # Skip silently if not installed
    fi

    # Skip backup prompt if not in interactive terminal
    if [[ ! -t 0 ]]; then
        # Non-interactive mode: skip backup silently (no UI calls to avoid hanging)
        return 0
    fi

    ui_info "$backup_tool backup available"

    if ui_confirm "Create system backup before sync?"; then
        ui_step "Creating $backup_tool backup..."

        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        local comment="package-manager sync - $timestamp"

        case "$backup_tool" in
            timeshift)
                if sudo timeshift --create --comments "$comment" --scripted; then
                    ui_success "Timeshift backup created successfully"
                    return 0
                else
                    ui_warning "Timeshift backup failed (continuing anyway)"
                    return 1
                fi
                ;;
            snapper)
                local snapper_config=$(_get_snapper_config)
                if sudo snapper -c "$snapper_config" create -d "$comment"; then
                    ui_success "Snapper snapshot created successfully (config: $snapper_config)"
                    return 0
                else
                    ui_warning "Snapper snapshot failed (continuing anyway)"
                    return 1
                fi
                ;;
            *)
                ui_warning "Unknown backup tool: $backup_tool"
                return 1
                ;;
        esac
    else
        ui_info "Skipping backup"
        return 0
    fi
}





# =============================================================================
# SECTION 7: HELP & VERSION
# =============================================================================

show_help() {
    cat << 'EOF'
Package Manager v2.2.0
Module-based declarative package management with batch operations and lockfile integration

USAGE:
    package-manager <command> [options] [arguments]

MODULE MANAGEMENT:
    module list                      List all modules with status
    module enable <module>...        Enable one or more modules
    module enable                    Interactive module selection
    module disable <module>...       Disable one or more modules
    module disable                   Interactive module selection

VERSION PINNING:
    pin <package> <version>          Pin package to specific version
                                     Examples: pin firefox 120.0
                                               pin neovim ">=0.9.0"
                                               pin python "<3.12"
    unpin <package>                  Remove version constraint
    lock [--quiet]                   Generate lockfile with current versions
    versions [package]               Show version info (includes lockfile)
    outdated                         List packages violating constraints

PACKAGE OPERATIONS:
    install <package>                Install a single package
    remove <package>                 Remove a package
    find <package> [--json]          Find which module(s) contain a package
    search                           Interactive package search with fzf (requires fzf)
    merge [--dry-run]                Add unmanaged packages to modules
    sync [--prune] [--no-lock]       Sync system (auto-locks by default)
    sync --locked                    Enforce lockfile versions strictly
    update [--no-sync] [--no-flatpak]
                                     Update all system packages (hybrid mode)
                                     1. Sync to packages.yaml (--no-sync to skip)
                                     2. Update Arch/AUR packages (paru -Syu)
                                     3. Update Flatpak packages (--no-flatpak to skip)
                                     4. Validate and update lockfile

STATUS & VALIDATION:
    status                           Show status (includes lockfile analysis)
    validate [--check-packages]      Validate packages.yaml structure
    validate --check-lockfile        Validate lockfile (staleness, syntax)

LEGACY COMMANDS:
    health                           Check package system health
    update-strategy                  Update package installation strategies

VERSION CONSTRAINT SYNTAX:
    Exact version:     { name: "firefox", version: "120.0" }
    Minimum version:   { name: "neovim", version: ">=0.9.0" }
    Maximum version:   { name: "python", version: "<3.12" }

EXAMPLES:
    # Enable multiple modules
    package-manager module enable base shell_environment

    # Discover and add unmanaged packages
    package-manager merge --dry-run
    package-manager merge

    # Pin package to specific version
    package-manager pin firefox 120.0

    # Sync with constraint-aware installation
    package-manager sync

    # Check system status
    package-manager status

    # Validate configuration
    package-manager validate --check-packages

FEATURES:
    • Module system with conflict detection
    • NixOS-style version constraints (exact, >=, <)
    • Batch package operations (5-10x faster bulk installs)
    • Lockfile integration (auto-lock, fast-path optimization)
    • Unmanaged package discovery and onboarding
    • Interactive downgrade selection
    • Rolling package detection (-git packages)
    • Optimized validation (24x faster AUR checks)
    • Backup integration (Timeshift or Snapper)
    • Drift detection and staleness warnings
    • Comprehensive validation and status checks

PERFORMANCE:
    • Batch installs: 5-10x faster for bulk operations
    • Lockfile fast-path: 30-50% faster sync on stable systems
    • Optimized lockfile generation: 100x faster (uses state file)
    • Improved AUR validation: 24x faster (batch queries)

STATE FILES:
    Config:    ~/.local/share/chezmoi/.chezmoidata/packages.yaml
    State:     ~/.local/state/package-manager/package-state.yaml
    Lockfile:  ~/.local/state/package-manager/locked-versions.yaml

BACKUP TOOL CONFIGURATION (optional in packages.yaml):
    backup_tool: "timeshift"         # or "snapper" (auto-detects if not set)
    snapper_config: "root"           # snapper config name (default: "root")

For more information, see the CLAUDE.md documentation.
EOF
}

show_version() {
    ui_title "package-manager v2.1.0"
    ui_info "Module-based package management for Arch Linux"
}

# =============================================================================
# LEGACY FUNCTIONS (PRESERVED FOR COMPATIBILITY)
# =============================================================================

check_health() {
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
            show_help
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
