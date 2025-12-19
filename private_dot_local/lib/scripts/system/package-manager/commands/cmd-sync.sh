#!/usr/bin/env bash

# Script: cmd-sync.sh
# Purpose: Sync system to packages.yaml state (validation-first pattern)
# Requirements: paru, yq, flatpak

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
            *)
                ui_error "Unknown flag: $1"
                ui_info "Usage: package-manager sync [--prune] [--no-lock] [--locked]"
                return 1
                ;;
        esac
    done

    # Override auto-lock if --no-lock specified
    [[ "$no_lock" == "true" ]] && AUTO_LOCK=false

    ui_title "$ICON_PACKAGE Syncing System to packages.yaml"

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

    # Validate packages.yaml structure
    if ! _with_context "Validating packages.yaml syntax" \
         yq eval '.' "$PACKAGES_FILE" >/dev/null; then
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
# PHASE 1: BUILD SYNC PLAN
# =============================================================================

_sync_build_plan() {
    local -n plan_ref=$1
    ui_step "Phase 1: Building sync plan..."

    local total=0
    local -a pacman_packages=()
    local -a flatpak_packages=()

    # Collect packages from enabled modules
    while IFS= read -r module; do
        ui_info "  $ICON_BULLET $module"

        while IFS= read -r package; do
            ((total++))

            local pkg_data=$(_parse_package_constraint "$package")
            IFS='|' read -r name version constraint_type <<< "$pkg_data"

            if [[ "$name" == flatpak:* ]]; then
                flatpak_packages+=("$package|$module")
            else
                pacman_packages+=("$package|$module")
            fi
        done < <(_get_module_packages "$module")
    done < <(_get_enabled_modules)

    ui_success "Found $total packages (${#pacman_packages[@]} pacman, ${#flatpak_packages[@]} flatpak)"

    # Validate pacman packages exist
    if [[ ${#pacman_packages[@]} -gt 0 ]]; then
        ui_step "Validating pacman packages..."

        local -a pkg_names=()
        for pkg_entry in "${pacman_packages[@]}"; do
            local package="${pkg_entry%%|*}"
            local pkg_data=$(_parse_package_constraint "$package")
            IFS='|' read -r name version constraint_type <<< "$pkg_data"
            pkg_names+=("$name")
        done

        local invalid=$(_check_packages_batch "${pkg_names[@]}")
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

    # Initialize results
    results_ref[installed]=0
    results_ref[upgraded]=0
    results_ref[downgraded]=0
    results_ref[skipped]=0
    results_ref[failed]=0

    # Cache installed versions (performance optimization)
    ui_step "Caching installed package versions..."
    declare -A installed_versions_map
    while IFS=' ' read -r pkg ver; do
        [[ -n "$pkg" ]] && installed_versions_map[$pkg]="$ver"
    done < <(pacman -Q 2>/dev/null | awk '{print $1, $2}')
    local cached_count
    cached_count=${#installed_versions_map[@]}
    ui_info "Cached ${cached_count} package versions"

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
    if [[ $total_errors -gt 0 ]]; then
        ui_error "Sync execution completed with $total_errors failures"
        return 1
    fi

    ui_success "Sync execution successful"
    return 0
}

_sync_execute_pacman() {
    local -n versions_map=$1
    local -n results=$2

    ui_step "Analyzing pacman packages..."

    local batch_install=""
    local batch_upgrade=""

    # Classify packages into batches
    for pkg_entry in "${SYNC_PACMAN_PACKAGES[@]}"; do
        IFS='|' read -r package module <<< "$pkg_entry"

        local pkg_data=$(_parse_package_constraint "$package")
        IFS='|' read -r name version constraint_type <<< "$pkg_data"

        local installed_version="${versions_map[$name]:-}"
        local locked_version="${lockfile_versions[$name]:-}"

        # Fast-path: lockfile match
        if [[ "$USE_LOCKFILE_FASTPATH" == "true" ]] && [[ -n "$locked_version" ]] &&
           [[ "$installed_version" == "$locked_version" ]] && [[ "$constraint_type" == "none" ]]; then
            ui_info "$ICON_PACKAGE $name: OK (lockfile match $locked_version)"
            continue
        fi

        # Not installed - add to batch
        if [[ -z "$installed_version" ]]; then
            if [[ "$constraint_type" == "exact" ]] && [[ -n "$version" ]]; then
                batch_install+="$name|$version|$module "
            else
                batch_install+="$name|null|$module "
            fi
            ((results[installed]++))
            continue
        fi

        # Already installed, check constraints
        case "$constraint_type" in
            "exact")
                if [[ "$installed_version" != "$version" ]]; then
                    batch_upgrade+="$name|$version|$module "
                    ((results[upgraded]++))
                else
                    ui_info "$ICON_PACKAGE $name: OK (exact $version)"
                fi
                ;;

            "minimum")
                _compare_versions "$installed_version" "$version"
                local cmp=$?

                if [[ $cmp -eq 2 ]]; then  # installed < required
                    batch_upgrade+="$name|null|$module "
                    ((results[upgraded]++))
                else
                    ui_info "$ICON_PACKAGE $name: OK (>=$version, have $installed_version)"
                fi
                ;;

            "maximum")
                _compare_versions "$installed_version" "$version"
                local cmp=$?

                if [[ $cmp -eq 2 ]]; then
                    ui_info "$ICON_PACKAGE $name: OK (<$version, have $installed_version)"
                else
                    # Interactive downgrade (not batched)
                    if _sync_handle_downgrade "$name" "$installed_version" "$version" "$module"; then
                        ((results[downgraded]++))
                    else
                        ((results[skipped]++))
                    fi
                fi
                ;;

            "none")
                ui_info "$ICON_PACKAGE $name: OK ($installed_version)"
                ;;
        esac
    done

    # Execute batches
    if [[ -n "$batch_install" ]]; then
        local -a install_entries
        read -ra install_entries <<< "$batch_install"
        if _install_packages_batch "install" "${install_entries[@]}"; then
            ui_success "Batch install successful"
        else
            ((results[failed] += ${#install_entries[@]}))
        fi
    fi

    if [[ -n "$batch_upgrade" ]]; then
        local -a upgrade_entries
        read -ra upgrade_entries <<< "$batch_upgrade"
        if _install_packages_batch "upgrade" "${upgrade_entries[@]}"; then
            ui_success "Batch upgrade successful"
        else
            ((results[failed] += ${#upgrade_entries[@]}))
        fi
    fi
}

_sync_execute_flatpak() {
    local -n results=$1

    ui_step "Processing flatpak packages..."
    _load_flatpak_cache

    for pkg_entry in "${SYNC_FLATPAK_PACKAGES[@]}"; do
        IFS='|' read -r package module <<< "$pkg_entry"

        local pkg_data=$(_parse_package_constraint "$package")
        IFS='|' read -r name version constraint_type <<< "$pkg_data"

        local flatpak_id="${name#flatpak:}"

        if _is_flatpak_installed "$flatpak_id"; then
            ui_info "$ICON_PACKAGE $flatpak_id: OK"
        else
            ui_step "$ICON_PACKAGE $flatpak_id: Installing"
            if _install_flatpak "$name" "$module"; then
                ((results[installed]++))
            else
                ((results[failed]++))
            fi
        fi
    done
}

_sync_handle_downgrade() {
    local name="$1"
    local installed="$2"
    local max_version="$3"
    local module="$4"

    ui_warning "$ICON_PACKAGE $name: Installed $installed violates <$max_version constraint"

    if ! ui_confirm "Interactive downgrade for $name?"; then
        ui_info "Skipped downgrade"
        return 1
    fi

    local selected_version=$(_select_downgrade_version "$name")

    if [[ -z "$selected_version" ]]; then
        ui_info "Downgrade cancelled"
        return 1
    fi

    _compare_versions "$selected_version" "$max_version"
    local ver_cmp=$?

    if [[ $ver_cmp -ne 2 ]]; then  # selected >= max (invalid)
        ui_error "Selected version $selected_version does not meet <$max_version constraint"
        return 1
    fi

    ui_step "$ICON_PACKAGE $name: Downgrading $installed → $selected_version"

    if paru -S --noconfirm "${name}=${selected_version}"; then
        _update_package_state "$name" "$selected_version" "pacman" "$module" "\"<$max_version\""
        ui_success "Downgraded $name to $selected_version"
        return 0
    else
        ui_error "Failed to downgrade $name"
        return 1
    fi
}

# =============================================================================
# PHASE 4: PRUNE ORPHANS
# =============================================================================

_sync_prune_orphans() {
    ui_step "Phase 4: Checking for orphaned packages..."

    local -a orphans=()

    # Build declared package set for O(1) lookups
    declare -A declared_set
    while IFS= read -r module; do
        while IFS= read -r package; do
            local pkg_data=$(_parse_package_constraint "$package")
            IFS='|' read -r name version constraint_type <<< "$pkg_data"

            # Strip flatpak: prefix for comparison
            local name_stripped="${name#flatpak:}"
            [[ -n "$name_stripped" ]] && declared_set[$name_stripped]=1
        done < <(_get_module_packages "$module")
    done < <(_get_enabled_modules)

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
    ui_info "  Total packages: ${SYNC_PLAN_TOTAL:-0}"

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

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Interactive downgrade version selection
# Usage: version=$(_select_downgrade_version <package_name>)
# Returns: Selected version string, or empty if cancelled
_select_downgrade_version() {
    local package="$1"

    ui_step "Fetching available versions for $package..."

    # Get available versions from paru
    local versions=$(paru -Si "$package" 2>/dev/null | grep -E '^Version' | awk '{print $3}' | head -20)

    if [[ -z "$versions" ]]; then
        ui_error "No versions found for $package"
        return 1
    fi

    # Use fzf if available
    if command -v fzf >/dev/null 2>&1; then
        local selected_version
        selected_version=$(echo "$versions" | \
            fzf --height=50% \
                --border=rounded \
                --prompt="Select version for $package: " \
                --header="ENTER: confirm | ESC: cancel" \
                --preview="echo 'Version: {}'" \
                --preview-window=up:3:wrap)

        if [[ -z "$selected_version" ]]; then
            return 1
        fi

        echo "$selected_version"
        return 0
    fi

    # Fallback to numbered menu
    ui_info "Available versions for $package:"
    echo ""

    local -a version_array=()
    local i=1
    while IFS= read -r ver; do
        ui_info "  [$i] $ver"
        version_array+=("$ver")
        ((i++))
    done <<< "$versions"

    ui_info "  [q] Cancel"
    ui_spacer

    # Get user selection
    local selection
    while true; do
        read -p "Select version (1-${#version_array[@]}, or 'q' to cancel): " selection

        if [[ "$selection" == "q" ]] || [[ "$selection" == "Q" ]]; then
            return 1
        fi

        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le "${#version_array[@]}" ]]; then
            local selected_version="${version_array[$((selection - 1))]}"
            echo "$selected_version"
            return 0
        else
            ui_warning "Invalid selection, try again"
        fi
    done
}
