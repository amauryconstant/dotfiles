#!/usr/bin/env bash

# Script: version-manager.sh
# Purpose: Version constraint parsing and comparison for package-manager
# Requirements: vercmp (from pacman), yq

# =============================================================================
# PACKAGE CONSTRAINT PARSING
# =============================================================================

_parse_package_constraint() {
    # Parses package constraint and returns: name|version|constraint_type
    # Formats:
    #   - "linux" -> "linux||none"
    #   - {name: linux, version: "6.6.1"} -> "linux|6.6.1|exact"
    #   - {name: linux, version: ">=6.6"} -> "linux|6.6|minimum"
    #   - {name: linux, version: "<6.7"} -> "linux|6.7|maximum"

    local package="$1"

    # Simple string (no constraint)
    if [[ ! "$package" =~ ^name: ]]; then
        echo "$package||none"
        return
    fi

    # Parse YAML object (requires yq)
    local name
    local version
    name=$(echo "$package" | yq eval '.name' -)
    version=$(echo "$package" | yq eval '.version // ""' -)

    if [[ -z "$version" || "$version" == "null" ]]; then
        echo "$name||none"
    elif [[ "$version" =~ ^">=" ]]; then
        echo "$name|${version#>=}|minimum"
    elif [[ "$version" =~ ^"<" ]]; then
        echo "$name|${version#<}|maximum"
    else
        echo "$name|$version|exact"
    fi
}

# =============================================================================
# CONSTRAINT CACHE (Performance Optimization)
# =============================================================================
# NOTE: Constraint cache now managed via core/state-manager.sh
# Global state eliminated - use _cache_* functions

_parse_package_constraint_cached() {
    # Cached version of _parse_package_constraint for performance
    # Returns: name|version|constraint_type (same as uncached version)
    # NOTE: Auto-loads persisted cache on first access, saves after new entries
    local package="$1"

    # Auto-load cache from disk on first access (lazy loading)
    _auto_load_constraint_cache 2>/dev/null || true

    # Return cached result if available
    if _cache_has constraints "$package"; then
        _cache_get constraints "$package"
        return 0
    fi

    # Parse and cache the result
    local result
    result=$(_parse_package_constraint "$package")
    _cache_set constraints "$package" "$result"

    # Persist cache to disk for next command (async to avoid blocking)
    _save_constraint_cache_to_disk &

    echo "$result"
}

# =============================================================================
# VERSION COMPARISON
# =============================================================================

_compare_versions() {
    # Use pacman's vercmp for accurate version comparison
    # Returns: 0 if v1 == v2, 1 if v1 > v2, 2 if v1 < v2
    local v1="$1"
    local v2="$2"

    if [[ -z "$v1" || -z "$v2" ]]; then
        return 0
    fi

    # vercmp returns: -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2
    local result
    result=$(vercmp "$v1" "$v2")

    # Return vercmp result directly
    case "$result" in
        -1) return 2 ;;  # v1 < v2
        0) return 0 ;;   # v1 == v2
        1) return 1 ;;   # v1 > v2
    esac
}

# =============================================================================
# CONSTRAINT CHECKING (Centralized logic - replaces duplication in 6 files)
# =============================================================================

# Check if installed version satisfies constraint
# Returns: 0 if satisfied, 1 if violated
_check_constraint_satisfaction() {
    local installed="$1"
    local constraint_version="$2"
    local constraint_type="$3"

    case "$constraint_type" in
        "exact")
            _version_equals "$installed" "$constraint_version"
            ;;
        "minimum")
            _version_satisfies_minimum "$installed" "$constraint_version"
            ;;
        "maximum")
            _version_satisfies_maximum "$installed" "$constraint_version"
            ;;
        "none")
            return 0  # Always satisfied
            ;;
        *)
            return 1  # Invalid constraint
            ;;
    esac
}

# Semantic wrapper functions for clarity
_version_satisfies_minimum() {
    local installed="$1"
    local required="$2"
    _compare_versions "$installed" "$required"
    local cmp=$?
    [[ $cmp -eq 1 ]] || [[ $cmp -eq 0 ]]
}

_version_satisfies_maximum() {
    local installed="$1"
    local maximum="$2"
    _compare_versions "$installed" "$maximum"
    local cmp=$?
    [[ $cmp -eq 2 ]]
}

_version_equals() {
    local v1="$1"
    local v2="$2"
    [[ "$v1" == "$v2" ]]
}

# =============================================================================
# VERSION QUERIES
# =============================================================================

_get_package_version() {
    local pkg="$1"
    pacman -Q "$pkg" 2>/dev/null | awk '{print $2}' || true
}

_get_repo_version() {
    local pkg="$1"
    pacman -Si "$pkg" 2>/dev/null | grep "^Version" | awk '{print $3}' || true
}

# NOTE: _get_flatpak_version() is defined in core/performance.sh with caching
# Do not redefine here to avoid overriding the cached implementation

# =============================================================================
# PACKAGE TYPE DETECTION
# =============================================================================

_is_flatpak() {
    local package="$1"
    [[ "$package" == flatpak:* ]]
}

_strip_flatpak_prefix() {
    local package="$1"
    echo "${package#flatpak:}"
}

_is_rolling_package() {
    local package="$1"
    [[ "$package" == *"-git" ]]
}
