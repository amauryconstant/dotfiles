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
        # Direct call (paru needs TTY for sudo prompts and progress display)
        if paru -S --noconfirm --needed "${pkg_specs[@]}"; then
            ui_success "Batch install complete (${#pkg_specs[@]} packages)"

            # Update state for all packages
            _update_batch_state "${pkg_names[@]}"

            # Invalidate pacman cache after batch install
            _invalidate_pacman_cache

            return 0
        else
            # Batch failed - detect partial success to avoid redundant work
            ui_warning "Batch install encountered errors"

            local -a succeeded=()
            local -a failed_packages=()

            # Check which packages actually got installed
            for pkg_name in "${pkg_names[@]}"; do
                if pacman -Q "$pkg_name" &>/dev/null; then
                    succeeded+=("$pkg_name")
                else
                    failed_packages+=("$pkg_name")
                fi
            done

            # Update state for successful installs (performance optimization)
            if [[ ${#succeeded[@]} -gt 0 ]]; then
                ui_info "Partial success: ${#succeeded[@]}/${#pkg_names[@]} packages installed"
                _update_batch_state "${succeeded[@]}"
                _invalidate_pacman_cache
            fi

            # Fall back to individual installs for failed packages only
            if [[ ${#failed_packages[@]} -eq 0 ]]; then
                # All packages actually succeeded despite error exit code
                ui_success "All packages installed (batch reported errors but succeeded)"
                return 0
            fi

            ui_warning "Retrying ${#failed_packages[@]} failed packages individually..."

            # Rebuild arrays to match failed packages only
            local -a failed_modules=()
            local -a failed_specs=()
            for idx in "${!pkg_names[@]}"; do
                local pkg_name="${pkg_names[$idx]}"
                # Check if this package failed
                for failed_pkg in "${failed_packages[@]}"; do
                    if [[ "$pkg_name" == "$failed_pkg" ]]; then
                        failed_modules+=("${pkg_modules[$idx]}")
                        failed_specs+=("${pkg_specs[$idx]}")
                        break
                    fi
                done
            done

            pkg_names=("${failed_packages[@]}")
            pkg_modules=("${failed_modules[@]}")
            pkg_specs=("${failed_specs[@]}")
        fi
    fi

    # Fallback: install individually (only failed packages now)
    local success=0
    local failed=0

    for idx in "${!pkg_names[@]}"; do
        local current=$((idx + 1))
        local total=${#pkg_names[@]}
        local name="${pkg_names[$idx]}"
        local module="${pkg_modules[$idx]}"
        local spec="${pkg_specs[$idx]}"

        # Extract version from spec if present
        local cached_version=""
        if [[ "$spec" == *"="* ]]; then
            cached_version="${spec#*=}"
        fi

        ui_step "[$current/$total] Installing: $name"

        if _install_package "$name" "$module" "$cached_version"; then
            ((success++))
            ui_success "  ✓ Installed: $name"
        else
            ((failed++))
            ui_error "  ✗ Failed: $name"
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

    # Query installed versions with error detection
    declare -A new_versions
    local pacman_output pacman_status

    pacman_output=$(pacman -Q "${package_names[@]}" 2>&1)
    pacman_status=$?

    if [[ $pacman_status -ne 0 ]]; then
        ui_warning "Batch version query failed, falling back to individual queries"
        # Fallback: query each package individually
        for name in "${package_names[@]}"; do
            local ver
            ver=$(_get_package_version "$name")
            if [[ -n "$ver" ]]; then
                if ! _update_package_state "$name" "$ver" "pacman" "batch" "null"; then
                    ui_error "Failed to update state for $name"
                fi
            else
                ui_warning "Package $name not found after batch install"
            fi
        done
        return 0
    fi

    while IFS=' ' read -r pkg ver; do
        [[ -n "$pkg" ]] && new_versions[$pkg]="$ver"
    done <<< "$pacman_output"

    # Update state using batch update (80-90% faster than loop)
    if [[ ${#new_versions[@]} -gt 0 ]]; then
        if ! _update_batch_package_state new_versions "pacman" "batch"; then
            ui_error "Failed to update batch state"
            return 1
        fi
    else
        ui_warning "No packages found after batch install"
        return 1
    fi

    return 0
}
