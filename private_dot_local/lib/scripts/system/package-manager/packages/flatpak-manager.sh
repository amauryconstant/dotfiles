#!/usr/bin/env bash

# Script: flatpak-manager.sh
# Purpose: Flatpak package management
# Requirements: flatpak

# =============================================================================
# FLATPAK INSTALLATION
# =============================================================================

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
        local installed_version
        installed_version=$(_get_flatpak_version "$flatpak_id")
        ui_info "$ICON_PACKAGE $flatpak_id: Already installed${installed_version:+ ($installed_version)}"
        return 0
    fi

    ui_step "$ICON_PACKAGE Installing Flatpak: $flatpak_id"

    # Install with --user scope (ALWAYS user scope, never system)
    if flatpak install -y --user flathub "$flatpak_id" 2>&1; then
        # Invalidate cache after install
        _FLATPAK_CACHE_LOADED=false
        local version
        version=$(_get_flatpak_version "$flatpak_id")

        # Update state file
        _update_package_state "$flatpak_id" "${version:-unknown}" "flatpak" "$module" "null"

        ui_success "Installed Flatpak: $flatpak_id${version:+ ($version)}"
        return 0
    else
        ui_error "Failed to install Flatpak: $flatpak_id"
        return 1
    fi
}

# =============================================================================
# FLATPAK REMOVAL
# =============================================================================

# Remove a Flatpak package
# Usage: _remove_flatpak <flatpak_id>
_remove_flatpak() {
    local flatpak_id="$1"

    if flatpak uninstall -y --user "$flatpak_id" 2>&1; then
        # Invalidate cache after removal
        _FLATPAK_CACHE_LOADED=false
        ui_success "Removed Flatpak: $flatpak_id"
        return 0
    else
        ui_error "Failed to remove Flatpak: $flatpak_id"
        return 1
    fi
}

# =============================================================================
# FLATPAK UPDATES
# =============================================================================

# Update all Flatpak packages
# Usage: _update_flatpaks
_update_flatpaks() {
    if ! command -v flatpak >/dev/null 2>&1; then
        ui_info "Flatpak not installed, skipping"
        return 0
    fi

    ui_step "$ICON_PACKAGE Updating Flatpak packages..."

    if flatpak update -y --user 2>&1; then
        ui_success "Flatpak packages updated"
        # Invalidate cache after updates
        _FLATPAK_CACHE_LOADED=false
        return 0
    else
        ui_error "Failed to update Flatpak packages"
        return 1
    fi
}
