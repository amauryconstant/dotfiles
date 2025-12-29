#!/usr/bin/env bash

# Script: sync-pacman.sh
# Purpose: Pacman package sync execution for package-manager
# Requirements: paru, fzf (optional)

# =============================================================================
# PACMAN PACKAGE SYNC
# =============================================================================

_sync_execute_pacman() {
    local -n versions_map=$1
    local -n results=$2

    ui_step "Analyzing pacman packages..."

    # NOTE: Constraint cache now managed via state-manager.sh
    # No need to declare cache - _parse_package_constraint_cached uses state manager

    local batch_install=""
    local batch_upgrade=""

    local count=0
    local total_packages=${#SYNC_PACMAN_PACKAGES[@]}

    # Classify packages into batches
    for pkg_entry in "${SYNC_PACMAN_PACKAGES[@]}"; do
        ((count++))

        # Show progress every 10 packages or if verbose
        if [[ "$VERBOSE" == "true" ]] || [[ $((count % 10)) -eq 0 ]]; then
            ui_info "  Analyzing package $count/$total_packages..."
        fi

        IFS='|' read -r package module cached_name <<< "$pkg_entry"

        local pkg_data=$(_parse_package_constraint_cached "$package")
        IFS='|' read -r name version constraint_type <<< "$pkg_data"

        # Use cached name if available (optimization from build_plan)
        [[ -n "$cached_name" ]] && name="$cached_name"

        local installed_version="${versions_map[$name]:-}"
        local locked_version="${lockfile_versions[$name]:-}"

        # Fast-path: lockfile match
        if [[ "$USE_LOCKFILE_FASTPATH" == "true" ]] && [[ -n "$locked_version" ]] &&
           [[ "$installed_version" == "$locked_version" ]] && [[ "$constraint_type" == "none" ]]; then
            [[ "$VERBOSE" == "true" ]] && ui_info "$ICON_PACKAGE $name: OK (lockfile match $locked_version)"
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

        # Already installed, check constraints (using centralized logic)
        if _check_constraint_satisfaction "$installed_version" "$version" "$constraint_type"; then
            [[ "$VERBOSE" == "true" ]] && ui_info "$ICON_PACKAGE $name: OK"
            continue
        fi

        # Constraint violated - handle based on type
        case "$constraint_type" in
            "exact"|"minimum")
                batch_upgrade+="$name|$version|$module "
                # shellcheck disable=SC2154  # results initialized by caller
                ((results[upgraded]++))
                ;;
            "maximum")
                # Interactive downgrade (not batched)
                if _sync_handle_downgrade "$name" "$installed_version" "$version" "$module"; then
                    # shellcheck disable=SC2154  # results initialized by caller
                    ((results[downgraded]++))
                else
                    # shellcheck disable=SC2154  # results initialized by caller
                    ((results[skipped]++))
                fi
                ;;
        esac
    done

    # Display sync summary table
    local total_ops=$((results[installed] + results[upgraded] + results[downgraded]))
    if [[ $total_ops -gt 0 ]]; then
        ui_step "Package Classification Summary"
        {
            printf "Operation\tPackages\tDescription\n"
            [[ ${results[installed]} -gt 0 ]] && \
                printf "Install\t%d\tNew packages to install\n" "${results[installed]}"
            [[ ${results[upgraded]} -gt 0 ]] && \
                printf "Upgrade\t%d\tUpdate to newer versions\n" "${results[upgraded]}"
            [[ ${results[downgraded]} -gt 0 ]] && \
                printf "Downgrade\t%d\tDowngrade to match constraints\n" "${results[downgraded]}"
        } | ui_table
    else
        ui_success "All packages already satisfied - no operations needed"
    fi

    # Execute batches
    if [[ -n "$batch_install" ]]; then
        local -a install_entries
        read -ra install_entries <<< "$batch_install"
        if _install_packages_batch "install" "${install_entries[@]}"; then
            ui_success "Batch install successful"
        else
            # shellcheck disable=SC2154  # results initialized by caller
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

# =============================================================================
# DOWNGRADE HANDLING
# =============================================================================

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

    # Direct call (paru needs TTY for sudo prompts and progress display)
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
        # Add 60-second timeout to prevent hanging
        read -t 60 -r -p "Select version (1-${#version_array[@]}, or 'q' to cancel, timeout 60s): " selection || {
            ui_warning "Selection timed out, skipping downgrade"
            return 1
        }

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
