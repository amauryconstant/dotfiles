#!/usr/bin/env bash

# Script: performance.sh
# Purpose: Performance optimizations and caching for package-manager
# Requirements: pacman, flatpak (optional)

# =============================================================================
# PERFORMANCE CACHE - Flatpak and Pacman
# =============================================================================

# Global cache for flatpak list (avoids redundant calls)
declare -g -A _FLATPAK_CACHE_APPS
declare -g -A _FLATPAK_CACHE_VERSIONS
declare -g _FLATPAK_CACHE_LOADED=false

_load_flatpak_cache() {
    if [[ "$_FLATPAK_CACHE_LOADED" == "true" ]]; then
        return 0
    fi

    if ! command -v flatpak >/dev/null 2>&1; then
        _FLATPAK_CACHE_LOADED=true
        return 1
    fi

    while IFS=$'\t' read -r app version; do
        [[ -n "$app" ]] && _FLATPAK_CACHE_APPS["$app"]=1
        [[ -n "$app" && -n "$version" ]] && _FLATPAK_CACHE_VERSIONS["$app"]="$version"
    done < <(flatpak list --app --columns=application,version 2>/dev/null)

    _FLATPAK_CACHE_LOADED=true
    return 0
}

_is_flatpak_installed() {
    local flatpak_id="$1"
    _load_flatpak_cache
    [[ -n "${_FLATPAK_CACHE_APPS[$flatpak_id]:-}" ]]
}

_get_flatpak_version() {
    local flatpak_id="$1"
    _load_flatpak_cache
    echo "${_FLATPAK_CACHE_VERSIONS[$flatpak_id]:-}"
}

# Global cache for pacman -Q (avoids redundant queries)
declare -g -A _PACMAN_VERSION_CACHE
declare -g _PACMAN_CACHE_LOADED=false

_load_pacman_version_cache() {
    if [[ "$_PACMAN_CACHE_LOADED" == "true" ]]; then
        return 0
    fi

    while IFS=' ' read -r pkg ver; do
        [[ -n "$pkg" && -n "$ver" ]] && _PACMAN_VERSION_CACHE["$pkg"]="$ver"
    done < <(pacman -Q 2>/dev/null)

    _PACMAN_CACHE_LOADED=true
    return 0
}

_get_cached_package_version() {
    local pkg="$1"
    _load_pacman_version_cache
    echo "${_PACMAN_VERSION_CACHE[$pkg]:-}"
}

# Cache invalidation (for debugging or force refresh)
_invalidate_caches() {
    _FLATPAK_CACHE_LOADED=false
    _PACMAN_CACHE_LOADED=false
    unset _FLATPAK_CACHE_APPS
    unset _FLATPAK_CACHE_VERSIONS
    unset _PACMAN_VERSION_CACHE
    declare -g -A _FLATPAK_CACHE_APPS
    declare -g -A _FLATPAK_CACHE_VERSIONS
    declare -g -A _PACMAN_VERSION_CACHE
}
