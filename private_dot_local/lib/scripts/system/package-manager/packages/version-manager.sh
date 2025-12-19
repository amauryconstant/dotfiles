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

_get_flatpak_version() {
    local app_id="$1"
    flatpak list --app --columns=application,version --user 2>/dev/null | grep "^${app_id}" | awk '{print $2}' || true
}

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
