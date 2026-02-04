#!/usr/bin/env bash

# Script: sync-orchestrator.sh
# Purpose: Sync system to packages.yaml state (validation-first pattern)
# Requirements: paru, yq, flatpak (optional), fzf (optional)

# Source sync operation modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$SCRIPT_DIR/operations/sync-pacman.sh"
. "$SCRIPT_DIR/operations/sync-flatpak.sh"

# NOTE: SYNC_PLAN_TOTAL now managed via state-manager.sh (_state_get/set sync_plan_total)

# =============================================================================
# SYNC COMMAND - VALIDATION-FIRST ARCHITECTURE
# =============================================================================

cmd_sync() {
    local prune=false
    local no_lock=false
    local _locked_mode=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --prune)
                prune=true
                shift
                ;;
            --no-lock)
                no_lock=true
                shift
                ;;
            --locked)
                _locked_mode=true
                shift
                ;;
            --verbose)
                export VERBOSE=true
                shift
                ;;
            *)
                ui_error "Unknown flag: $1"
                ui_info "Usage: package-manager sync [--prune] [--no-lock] [--locked] [--verbose]"
                return 1
                ;;
        esac
    done

    # Override auto-lock if --no-lock specified
    [[ "$no_lock" == "true" ]] && AUTO_LOCK=false

    ui_title "$ICON_PACKAGE Syncing System to packages.yaml"

    # Set sync-in-progress flag (prevents redundant backups)
    export SYNC_IN_PROGRESS=true

    # Acquire sync lock (prevent concurrent syncs)
    if ! _acquire_sync_lock; then
        ui_error "Another sync operation is running"
        ui_info "Wait for it to complete, or remove $STATE_DIR/.sync.lock if stale"
        unset SYNC_IN_PROGRESS
        return 1
    fi

    # Setup cleanup trap (release lock and clear flag)
    trap 'unset SYNC_IN_PROGRESS; _release_sync_lock' EXIT INT TERM

    # Phase 0: Validation (fail fast)
    if ! _sync_validate; then
        return 1
    fi

    # Phase 1: Build sync plan
    # shellcheck disable=SC2034  # sync_plan populated but not read
    local -A sync_plan
    if ! _sync_build_plan sync_plan; then
        return 1
    fi

    # Phase 2: Optional backup
    _create_backup

    # Phase 3: Execute sync plan
    # shellcheck disable=SC2034  # sync_results modified via nameref in _sync_execute
    local -A sync_results
    if ! _sync_execute sync_plan sync_results; then
        ui_warning "Sync completed with errors"
        return 1
    fi

    # Phase 4: Prune orphans (if requested)
    if [[ "$prune" == "true" ]]; then
        _sync_prune_orphans
    fi

    # Phase 5: Display summary and update lockfile
    _sync_finalize sync_results

    # Call user hook
    if [ -f "$HOME/.local/lib/scripts/core/hook-runner" ]; then
        "$HOME/.local/lib/scripts/core/hook-runner" package-sync "sync" 2>/dev/null || true
    fi

    ui_success "Sync complete!"
    return 0
}

# =============================================================================
# PHASE 0: VALIDATION
# =============================================================================

_sync_validate() {
    ui_step "Phase 0: Validating configuration..."

    # Check required dependencies
    if ! _check_yq_dependency; then
        return 1
    fi

    # Validate packages.yaml structure with enhanced error reporting
    ui_step "Validating packages.yaml syntax..."
    local yq_output
    if ! yq_output=$(yq eval '.' "$PACKAGES_FILE" 2>&1 >/dev/null); then
        ui_error "YAML syntax validation failed"
        echo ""

        # Parse yq error for line number
        if [[ "$yq_output" =~ line[[:space:]]([0-9]+) ]]; then
            local line_num="${BASH_REMATCH[1]}"
            ui_error "  Error at line $line_num in packages.yaml"
            echo ""

            # Show context around error line (5 lines before and after)
            ui_info "  Context:"
            local start_line=$((line_num > 5 ? line_num - 5 : 1))
            local end_line=$((line_num + 5))

            sed -n "${start_line},${end_line}p" "$PACKAGES_FILE" | \
                awk -v errline="$line_num" -v start="$start_line" '
                    { linenum = NR + start - 1 }
                    linenum == errline { printf "  > %4d: %s\n", linenum, $0 }
                    linenum != errline { printf "    %4d: %s\n", linenum, $0 }
                '
            echo ""
        fi

        # Common error translations
        if echo "$yq_output" | grep -q "did not find expected key"; then
            ui_info "  Likely cause: Missing colon (:) after a key"
        elif echo "$yq_output" | grep -q "mapping values are not allowed"; then
            ui_info "  Likely cause: Invalid indentation or missing quotes"
        elif echo "$yq_output" | grep -q "found character that cannot start"; then
            ui_info "  Likely cause: Invalid character or incorrect YAML syntax"
        fi

        return 1
    fi

    # Check if any modules are enabled
    local enabled_count
    enabled_count=$(_get_enabled_modules | wc -l)
    if [[ $enabled_count -eq 0 ]]; then
        ui_warning "No modules enabled in packages.yaml"
        return 0  # Not an error, just nothing to do
    fi

    ui_success "Validation passed"
    return 0
}

# =============================================================================
# ERROR RECOVERY
# =============================================================================

_sync_cleanup_on_error() {
    # Cleanup handler for sync errors
    # Called automatically on ERR trap during sync execution

    ui_error "Sync operation failed"

    # Check for available state backups
    local backup_dir="$STATE_DIR/backups"
    if [[ -d "$backup_dir" ]]; then
        local latest_backup=$(ls -t "$backup_dir"/state-*.yaml 2>/dev/null | head -1)
        if [[ -n "$latest_backup" ]]; then
            ui_info "State backup available: $latest_backup"
            ui_info "To restore: mv \"$latest_backup\" \"$STATE_FILE\""
        fi
    fi
}

# =============================================================================
# PHASE 1: BUILD SYNC PLAN
# =============================================================================

_sync_build_plan() {
    local -n plan_ref=$1
    ui_step "Phase 1: Building sync plan..."

    local total=0
    local -a pacman_packages=()
    local -a flatpak_packages=()
    local -a pkg_names=()  # Declare early for validation (optimize: single parse)

    # Global array for prune optimization (avoid re-iteration)
    declare -ga SYNC_DECLARED_PACKAGES=()

    # Collect packages from enabled modules (OPTIMIZED - single YAML read + parse once)
    # Read modules into array to get count for progress display
    local -a enabled_modules=()
    while IFS= read -r module; do
        enabled_modules+=("$module")
    done < <(_get_enabled_modules_cached)

    local module_count=0
    local total_modules=${#enabled_modules[@]}

    for module in "${enabled_modules[@]}"; do
        ((module_count++))
        ui_info "  [$module_count/$total_modules] Processing module: $module"

        while IFS= read -r package; do
            ((total++))

            # Use cached constraint parsing (PERF: 10-15% faster)
            local pkg_data=$(_parse_package_constraint_cached "$package")
            local name="${pkg_data%%|*}"

            # Store declared name for prune phase (optimization)
            SYNC_DECLARED_PACKAGES+=("$name")

            if [[ "$name" == flatpak:* ]]; then
                flatpak_packages+=("$package|$module")
            else
                # Store package string AND parsed name (avoid reparse in validation)
                pacman_packages+=("$package|$module|$name")
                pkg_names+=("$name")  # Build validation list during collection
            fi
        done < <(_get_module_packages_cached "$module")
    done

    ui_success "Found $total packages (${#pacman_packages[@]} pacman, ${#flatpak_packages[@]} flatpak)"

    # Validate pacman packages exist (NO REPARSING)
    if [[ ${#pkg_names[@]} -gt 0 ]]; then
        ui_step "Validating pacman packages..."

        # Use --skip-installed-filter since sync classifies packages later (20-30% faster)
        local invalid=$(_check_packages_batch --skip-installed-filter "${pkg_names[@]}")
        if [[ -n "$invalid" ]]; then
            ui_error "Invalid packages found:"
            echo "$invalid" | while IFS= read -r pkg; do
                ui_error "  $ICON_BULLET $pkg"
            done
            ui_warning "Fix packages.yaml before continuing"
            return 1
        fi

        ui_success "All packages valid"
    fi

    # Store plan data (arrays can't be in associative arrays, use global scope)
    SYNC_PACMAN_PACKAGES=("${pacman_packages[@]}")
    SYNC_FLATPAK_PACKAGES=("${flatpak_packages[@]}")
    _state_set sync_plan_total "$total"  # Store in state manager for display in finalize
    plan_ref["total"]=$total
    plan_ref["pacman_count"]=${#pacman_packages[@]}
    plan_ref["flatpak_count"]=${#flatpak_packages[@]}

    ui_success "Sync plan ready"
    return 0
}

# =============================================================================
# PHASE 3: EXECUTE SYNC PLAN
# =============================================================================

_sync_execute() {
    # shellcheck disable=SC2034,SC2178  # plan_ref unused (uses global arrays instead)
    local -n plan_ref=$1
    # shellcheck disable=SC2178  # nameref creates string from array name
    local -n results_ref=$2

    ui_step "Phase 3: Executing sync plan..."

    # Backup state before execution
    _backup_state_file

    # Setup error recovery trap
    trap '_sync_cleanup_on_error; return 1' ERR

    # Initialize results
    results_ref[installed]=0
    results_ref[upgraded]=0
    results_ref[downgraded]=0
    results_ref[skipped]=0
    results_ref[failed]=0

    # Cache installed versions (performance optimization - reuse existing cache)
    ui_step "Loading package version cache..."
    ui_info "Querying pacman database..." >&2
    if _load_pacman_version_cache; then
        declare -n installed_versions_map=_PACMAN_VERSION_CACHE  # nameref to existing cache
        local cached_count
        cached_count=${#installed_versions_map[@]}
        ui_success "Loaded ${cached_count} package versions"
    else
        ui_error "Failed to load package cache"
        return 1
    fi

    # Load lockfile for fast-path optimization
    if [[ "$USE_LOCKFILE_FASTPATH" == "true" ]] && _read_lockfile; then
        local lockfile_count
        # shellcheck disable=SC2154  # lockfile_versions populated by _read_lockfile
        lockfile_count=${#lockfile_versions[@]}
        ui_info "Loaded lockfile with ${lockfile_count} versions"
    fi

    # Process pacman packages
    if [[ ${#SYNC_PACMAN_PACKAGES[@]} -gt 0 ]]; then
        _sync_execute_pacman installed_versions_map results_ref
    fi

    # Process flatpak packages
    if [[ ${#SYNC_FLATPAK_PACKAGES[@]} -gt 0 ]]; then
        _sync_execute_flatpak results_ref
    fi

    local total_errors=${results_ref[failed]}

    # Clear error trap on success
    trap - ERR

    if [[ $total_errors -gt 0 ]]; then
        ui_error "Sync execution completed with $total_errors failures"
        return 1
    fi

    ui_success "Sync execution successful"
    return 0
}


# =============================================================================
# PHASE 4: PRUNE ORPHANS
# =============================================================================

_sync_prune_orphans() {
    ui_step "Phase 4: Checking for orphaned packages..."

    local -a orphans=()

    # Build declared package set for O(1) lookups (OPTIMIZED - reuse build_plan data)
    declare -A declared_set
    for name in "${SYNC_DECLARED_PACKAGES[@]}"; do
        # Strip flatpak: prefix for comparison
        local name_stripped="${name#flatpak:}"
        [[ -n "$name_stripped" ]] && declared_set[$name_stripped]=1
    done

    # Find orphans
    while IFS= read -r pkg_name; do
        if [[ -z "${declared_set[$pkg_name]:-}" ]]; then
            orphans+=("$pkg_name")
        fi
    done < <(yq eval '.packages[].name' "$STATE_FILE" 2>/dev/null)

    if [[ ${#orphans[@]} -eq 0 ]]; then
        ui_success "No orphaned packages found"
        return 0
    fi

    ui_warning "Found ${#orphans[@]} orphaned packages:"
    for orphan in "${orphans[@]}"; do
        ui_info "  $ICON_BULLET $orphan"
    done

    if ! ui_confirm "Remove orphaned packages?"; then
        ui_info "Skipped orphan removal"
        return 0
    fi

    local removed=0
    for orphan in "${orphans[@]}"; do
        if _remove_package "$orphan"; then
            ((removed++))
        fi
    done

    ui_success "Removed $removed orphaned packages"
}

# =============================================================================
# PHASE 5: FINALIZE
# =============================================================================

_sync_finalize() {
    # shellcheck disable=SC2178  # nameref creates string from array name
    local -n results_ref=$1

    # Display summary
    ui_title "$ICON_CHART Sync Summary"
    ui_info "  Total packages: $(_state_get sync_plan_total 0)"

    local installed=${results_ref[installed]}
    local upgraded=${results_ref[upgraded]}
    local downgraded=${results_ref[downgraded]}
    local skipped=${results_ref[skipped]}
    local failed=${results_ref[failed]}

    [[ $installed -gt 0 ]] && ui_success "  Installed: $installed" || ui_info "  Installed: $installed"
    [[ $upgraded -gt 0 ]] && ui_success "  Upgraded: $upgraded" || ui_info "  Upgraded: $upgraded"
    [[ $downgraded -gt 0 ]] && ui_success "  Downgraded: $downgraded" || ui_info "  Downgraded: $downgraded"
    [[ $skipped -gt 0 ]] && ui_warning "  Skipped: $skipped" || ui_info "  Skipped: $skipped"
    [[ $failed -gt 0 ]] && ui_error "  Failed: $failed" || ui_info "  Failed: $failed"

    # Auto-lock after successful sync
    if [[ $failed -eq 0 ]] && [[ "$AUTO_LOCK" == "true" ]]; then
        echo ""
        ui_step "Updating lockfile..."
        if cmd_lock --quiet; then
            ui_success "Lockfile updated"
        else
            ui_warning "Failed to update lockfile"
        fi
    fi
}

