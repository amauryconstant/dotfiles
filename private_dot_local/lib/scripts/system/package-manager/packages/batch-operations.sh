#!/usr/bin/env bash

# Script: batch-operations.sh
# Purpose: Batch package installation for performance optimization
# Requirements: paru

# =============================================================================
# BATCH INSTALLATION UTILITIES
# =============================================================================

_install_packages_batch() {
    # Execute batch installation with fallback to individual installs
    # Usage: _install_packages_batch <batch_type> <pkg1|ver1|mod1> <pkg2|ver2|mod2> ...
    local batch_type="$1"
    shift
    local -a entries=("$@")

    if [[ ${#entries[@]} -eq 0 ]]; then
        return 0
    fi

    # Parse entries and build package list
    local -a pkg_specs=()
    local -a pkg_names=()
    local -a pkg_modules=()

    for entry in "${entries[@]}"; do
        IFS='|' read -r name version module <<< "$entry"
        pkg_names+=("$name")
        pkg_modules+=("$module")

        # Build package spec for paru
        if [[ -n "$version" ]] && [[ "$version" != "null" ]]; then
            pkg_specs+=("${name}=${version}")
        else
            pkg_specs+=("$name")
        fi
    done

    ui_step "$ICON_PACKAGE Batch $batch_type: ${#pkg_specs[@]} packages"

    # Try batch install
    if [[ "$BATCH_INSTALLS" == "true" ]]; then
        if paru -S --noconfirm --needed "${pkg_specs[@]}" 2>&1; then
            ui_success "Batch install complete (${#pkg_specs[@]} packages)"

            # Update state for all packages
            _update_batch_state "${pkg_names[@]}"
            return 0
        else
            ui_warning "Batch failed, falling back to individual installs"
        fi
    fi

    # Fallback: install individually
    local success=0
    local failed=0

    for idx in "${!pkg_names[@]}"; do
        local name="${pkg_names[$idx]}"
        local module="${pkg_modules[$idx]}"
        local spec="${pkg_specs[$idx]}"

        # Extract version from spec if present
        local cached_version=""
        if [[ "$spec" == *"="* ]]; then
            cached_version="${spec#*=}"
        fi

        if _install_package "$name" "$module" "$cached_version"; then
            ((success++))
        else
            ((failed++))
        fi
    done

    if [[ $failed -gt 0 ]]; then
        ui_warning "Batch fallback: $success succeeded, $failed failed"
        return 1
    else
        ui_success "Batch fallback: all $success packages installed"
        return 0
    fi
}

_update_batch_state() {
    # Update state file for all packages in batch
    # Usage: _update_batch_state <pkg1> <pkg2> <pkg3> ...
    local -a package_names=("$@")

    if [[ ${#package_names[@]} -eq 0 ]]; then
        return 0
    fi

    # Query installed versions once for all packages
    declare -A new_versions
    while IFS=' ' read -r pkg ver; do
        [[ -n "$pkg" ]] && new_versions[$pkg]="$ver"
    done < <(pacman -Q "$(printf '%s\n' "${package_names[@]}")" 2>/dev/null)

    # Update state for each package
    for name in "${package_names[@]}"; do
        local new_version="${new_versions[$name]:-}"
        if [[ -n "$new_version" ]]; then
            _update_package_state "$name" "$new_version" "pacman" "batch" "null"
        fi
    done
}
