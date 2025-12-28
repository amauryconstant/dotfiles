#!/usr/bin/env bash

# Script: performance.sh
# Purpose: Performance optimizations and caching for package-manager
# Requirements: pacman, flatpak (optional), core/state-manager.sh

# =============================================================================
# PERFORMANCE CACHE - Flatpak and Pacman
# =============================================================================
# NOTE: All caches now managed via core/state-manager.sh
# Global state eliminated - use _state_* and _cache_* functions

_load_flatpak_cache() {
    if [[ "$(_state_get flatpak_cache_loaded)" == "true" ]]; then
        return 0
    fi

    if ! command -v flatpak >/dev/null 2>&1; then
        _state_set flatpak_cache_loaded "true"
        return 1
    fi

    while IFS=$'\t' read -r app version; do
        [[ -n "$app" ]] && _cache_set flatpak_apps "$app" "1"
        [[ -n "$app" && -n "$version" ]] && _cache_set flatpak_versions "$app" "$version"
    done < <(flatpak list --app --columns=application,version 2>/dev/null)

    _state_set flatpak_cache_loaded "true"
    return 0
}

_is_flatpak_installed() {
    local flatpak_id="$1"
    _load_flatpak_cache
    _cache_has flatpak_apps "$flatpak_id"
}

_get_flatpak_version() {
    local flatpak_id="$1"
    _load_flatpak_cache
    _cache_get flatpak_versions "$flatpak_id"
}

_load_pacman_version_cache() {
    if [[ "$(_state_get pacman_cache_loaded)" == "true" ]]; then
        return 0
    fi

    while IFS=' ' read -r pkg ver; do
        [[ -n "$pkg" && -n "$ver" ]] && _cache_set pacman_versions "$pkg" "$ver"
    done < <(pacman -Q 2>/dev/null)

    _state_set pacman_cache_loaded "true"
    return 0
}

_get_cached_package_version() {
    local pkg="$1"
    _load_pacman_version_cache
    _cache_get pacman_versions "$pkg"
}

# =============================================================================
# CACHE INVALIDATION (Wrappers for state-manager functions)
# =============================================================================
# NOTE: These are now convenience wrappers - actual implementation in state-manager.sh

# Individual cache invalidation (delegates to state-manager.sh)
# _invalidate_flatpak_cache()  - already defined in state-manager.sh
# _invalidate_pacman_cache()   - already defined in state-manager.sh
# _invalidate_module_cache()   - already defined in state-manager.sh
# _invalidate_all_caches()     - already defined in state-manager.sh

# Legacy function (for debugging or force refresh)
_invalidate_caches() {
    _invalidate_all_caches
}
