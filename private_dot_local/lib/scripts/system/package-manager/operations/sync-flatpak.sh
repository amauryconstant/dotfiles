#!/usr/bin/env bash

# Script: sync-flatpak.sh
# Purpose: Flatpak package sync execution for package-manager
# Requirements: flatpak (optional)

# =============================================================================
# FLATPAK PACKAGE SYNC
# =============================================================================

_sync_execute_flatpak() {
    local -n results=$1

    ui_step "Processing flatpak packages..."
    ui_info "Loading flatpak cache..." >&2
    if ! _load_flatpak_cache; then
        ui_warning "Failed to load flatpak cache, continuing..."
    fi

    for pkg_entry in "${SYNC_FLATPAK_PACKAGES[@]}"; do
        IFS='|' read -r package module <<< "$pkg_entry"

        local pkg_data=$(_parse_package_constraint_cached "$package")
        IFS='|' read -r name _version _constraint_type <<< "$pkg_data"

        local flatpak_id="${name#flatpak:}"

        if _is_flatpak_installed "$flatpak_id"; then
            [[ "$VERBOSE" == "true" ]] && ui_info "$ICON_PACKAGE $flatpak_id: OK"
        else
            ui_step "$ICON_PACKAGE $flatpak_id: Installing"
            if _install_flatpak "$name" "$module"; then
                # shellcheck disable=SC2154  # results initialized by caller
                ((results[installed]++))
            else
                # shellcheck disable=SC2154  # results initialized by caller
                ((results[failed]++))
            fi
        fi
    done
}
