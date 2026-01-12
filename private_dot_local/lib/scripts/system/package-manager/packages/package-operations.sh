#!/usr/bin/env bash

# Script: package-operations.sh
# Purpose: Package install/remove operations for pacman/AUR
# Requirements: paru, yq

# =============================================================================
# PACKAGE INSTALLATION
# =============================================================================

# Install a package with version constraint support
# Usage: _install_package <package_spec> <module_name> [cached_version]
# package_spec: Either "package-name" or package object from YAML
_install_package() {
    local package_spec="$1"
    local module="${2:-unknown}"
    local cached_version="${3:-}"  # Optional cached version (from batch fallback or cmd_sync)

    # Parse package constraint
    local pkg_data name version constraint_type
    pkg_data=$(_parse_package_constraint "$package_spec")
    IFS='|' read -r name version constraint_type <<< "$pkg_data"

    # Check if Flatpak package
    if [[ "$name" == flatpak:* ]]; then
        _install_flatpak "$name" "$module"
        return $?
    fi

    # Validate package exists
    if ! _check_package_exists "$name"; then
        ui_error "Package '$name' not found in repos or AUR"
        return 1
    fi

    # Warn about rolling packages
    if _is_rolling_package "$name"; then
        ui_warning "$ICON_WARNING  '$name' is a rolling package (-git suffix)"
        if [[ -n "$version" ]]; then
            ui_warning "Version constraints may not work as expected"
        fi
    fi

    # Check if already installed with correct version
    # Use cached version if provided, otherwise query
    local installed
    if [[ -n "$cached_version" ]]; then
        installed="$cached_version"
    else
        installed=$(_get_package_version "$name")
    fi

    if [[ -n "$installed" ]]; then
        # Already installed, check if version matches constraint (using centralized logic)
        if _check_constraint_satisfaction "$installed" "$version" "$constraint_type"; then
            ui_info "$ICON_PACKAGE $name: Already meets constraint (installed: $installed)"
            return 0
        fi

        # Constraint violated - show appropriate message
        case "$constraint_type" in
            "exact")
                ui_step "$ICON_PACKAGE $name: Switching from $installed to $version"
                ;;
            "minimum")
                ui_step "$ICON_PACKAGE $name: Upgrading from $installed to meet >=$version"
                ;;
            "maximum")
                ui_warning "$ICON_PACKAGE $name: Installed $installed violates <$version constraint"
                ui_warning "Interactive downgrade required (use 'sync' command)"
                return 0
                ;;
        esac
    else
        ui_step "$ICON_PACKAGE Installing $name${version:+ ($constraint_type $version)}"
    fi

    # Execute installation
    local -a install_cmd=(paru -S --noconfirm --needed)

    # Add version specifier if needed
    if [[ -n "$version" ]] && [[ "$constraint_type" == "exact" ]]; then
        install_cmd+=("${name}=${version}")
    else
        install_cmd+=("$name")
    fi

    if "${install_cmd[@]}"; then
        # Get actual installed version
        local new_version
        new_version=$(_get_package_version "$name")

        # Validate variables before state update (security check)
        if [[ -z "${name:-}" ]] || [[ -z "${new_version:-}" ]]; then
            ui_error "CRITICAL: Missing required variables after installation"
            ui_error "name='${name:-}' new_version='${new_version:-}'"
            return 1
        fi

        # Update state file
        local constraint_value="null"
        if [[ -n "$version" ]]; then
            case "$constraint_type" in
                "exact") constraint_value="\"$version\"" ;;
                "minimum") constraint_value="\">=$version\"" ;;
                "maximum") constraint_value="\"<$version\"" ;;
            esac
        fi

        if ! _update_package_state "$name" "$new_version" "pacman" "$module" "$constraint_value"; then
            ui_error "Failed to update state file for $name"
            return 1
        fi

        # Invalidate pacman cache after install
        _invalidate_pacman_cache

        ui_success "Installed $name ($new_version)"
        return 0
    else
        ui_error "Failed to install $name"
        return 1
    fi
}

# =============================================================================
# PACKAGE REMOVAL
# =============================================================================

# Remove a package (pacman or flatpak)
# Usage: _remove_package <package_name>
_remove_package() {
    local package="$1"

    # Check if package is in state file
    local pkg_type
    pkg_type=$(PKG="$package" yq eval '.packages[] | select(.name == env(PKG)) | .type' "$STATE_FILE" 2>/dev/null)

    if [[ -z "$pkg_type" ]]; then
        # Not in state file, try to detect (using cache)
        if pacman -Q "$package" &>/dev/null; then
            pkg_type="pacman"
        elif _is_flatpak_installed "$package"; then
            pkg_type="flatpak"
        else
            ui_warning "Package '$package' not found (not installed or not in state)"
            return 1
        fi
    fi

    # Check if pinned
    local is_pinned
    is_pinned=$(PKG="$package" yq eval '.packages[] | select(.name == env(PKG)) | .pinned' "$STATE_FILE" 2>/dev/null)
    if [[ "$is_pinned" == "true" ]]; then
        ui_warning "$ICON_WARNING  Package '$package' is pinned"
        if ! ui_confirm "Remove anyway?"; then
            ui_info "Cancelled"
            return 0
        fi
    fi

    ui_step "$ICON_TRASH  Removing $package ($pkg_type)"

    # Verify package is actually installed before attempting removal
    local actually_installed=false
    case "$pkg_type" in
        "pacman")
            if pacman -Q "$package" &>/dev/null; then
                actually_installed=true
            fi
            ;;
        "flatpak")
            if _is_flatpak_installed "$package"; then
                actually_installed=true
            fi
            ;;
        *)
            ui_error "Unknown package type: $pkg_type"
            return 1
            ;;
    esac

    if [[ "$actually_installed" == "false" ]]; then
        ui_warning "Package '$package' not installed (state file out of sync)"
        ui_info "Cleaning up state entry..."
        # Skip removal, just clean up state file
    else
        # Remove based on type
        case "$pkg_type" in
            "pacman")
                if paru -R --noconfirm "$package"; then
                    ui_success "Removed $package"
                else
                    ui_error "Failed to remove $package"
                    return 1
                fi
                ;;
            "flatpak")
                if flatpak uninstall -y --user "$package" 2>&1; then
                    ui_success "Removed Flatpak: $package"
                else
                    ui_error "Failed to remove Flatpak: $package"
                    return 1
                fi
                ;;
            *)
                ui_error "Unknown package type: $pkg_type"
                return 1
                ;;
        esac
    fi

    # Remove from state file
    if ! _remove_package_state "$package"; then
        ui_error "Failed to update state file after removing $package"
        return 1
    fi

    # Invalidate cache after removal (depends on type)
    if [[ "$pkg_type" == "pacman" ]]; then
        _invalidate_pacman_cache
    elif [[ "$pkg_type" == "flatpak" ]]; then
        _invalidate_flatpak_cache
    fi

    return 0
}
