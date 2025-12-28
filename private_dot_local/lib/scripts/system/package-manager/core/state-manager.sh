#!/usr/bin/env bash

# Script: state-manager.sh
# Purpose: Centralized state management for caches and global variables
# Requirements: None (self-contained)

# =============================================================================
# STATE MANAGER - Centralized Global State Encapsulation
# =============================================================================

# Single source of truth for all package-manager state
declare -gA _STATE_STORE=()

# Cache storage (separate from scalar state for performance)
declare -gA _CACHE_FLATPAK_APPS=()
declare -gA _CACHE_FLATPAK_VERSIONS=()
declare -gA _CACHE_PACMAN_VERSIONS=()
declare -gA _CACHE_MODULES=()
declare -gA _CACHE_CONSTRAINTS=()

# =============================================================================
# INITIALIZATION
# =============================================================================

_state_init() {
    # Initialize scalar state values
    _STATE_STORE[module_cache_loaded]="false"
    _STATE_STORE[flatpak_cache_loaded]="false"
    _STATE_STORE[pacman_cache_loaded]="false"
    _STATE_STORE[sync_plan_total]="0"
}

# =============================================================================
# SCALAR STATE OPERATIONS
# =============================================================================

_state_get() {
    # Get scalar state value
    # Args: key [default_value]
    # Returns: value or default
    local key="$1"
    local default="${2:-}"
    echo "${_STATE_STORE[$key]:-$default}"
}

_state_set() {
    # Set scalar state value
    # Args: key value
    local key="$1"
    local value="$2"
    _STATE_STORE[$key]="$value"
}

_state_has() {
    # Check if state key exists
    # Args: key
    # Returns: 0 if exists, 1 otherwise
    local key="$1"
    [[ -n "${_STATE_STORE[$key]+x}" ]]
}

_state_unset() {
    # Remove state key
    # Args: key
    local key="$1"
    unset "_STATE_STORE[$key]"
}

_state_invalidate() {
    # Invalidate matching state keys
    # Args: pattern (glob pattern)
    # Example: _state_invalidate "*_cache_loaded"
    local pattern="$1"

    for key in "${!_STATE_STORE[@]}"; do
        # shellcheck disable=SC2053  # Glob matching is intentional
        if [[ "$key" == $pattern ]]; then
            unset "_STATE_STORE[$key]"
        fi
    done
}

# =============================================================================
# CACHE OPERATIONS (Associative Arrays)
# =============================================================================

_cache_get() {
    # Get value from named cache
    # Args: cache_name key [default_value]
    # Returns: value or default
    local cache_name="$1"
    local key="$2"
    local default="${3:-}"

    case "$cache_name" in
        flatpak_apps)
            echo "${_CACHE_FLATPAK_APPS[$key]:-$default}"
            ;;
        flatpak_versions)
            echo "${_CACHE_FLATPAK_VERSIONS[$key]:-$default}"
            ;;
        pacman_versions)
            echo "${_CACHE_PACMAN_VERSIONS[$key]:-$default}"
            ;;
        modules)
            echo "${_CACHE_MODULES[$key]:-$default}"
            ;;
        constraints)
            echo "${_CACHE_CONSTRAINTS[$key]:-$default}"
            ;;
        *)
            return 1
            ;;
    esac
}

_cache_set() {
    # Set value in named cache
    # Args: cache_name key value
    local cache_name="$1"
    local key="$2"
    local value="$3"

    case "$cache_name" in
        flatpak_apps)
            _CACHE_FLATPAK_APPS[$key]="$value"
            ;;
        flatpak_versions)
            _CACHE_FLATPAK_VERSIONS[$key]="$value"
            ;;
        pacman_versions)
            _CACHE_PACMAN_VERSIONS[$key]="$value"
            ;;
        modules)
            _CACHE_MODULES[$key]="$value"
            ;;
        constraints)
            _CACHE_CONSTRAINTS[$key]="$value"
            ;;
        *)
            return 1
            ;;
    esac
}

_cache_has() {
    # Check if cache key exists
    # Args: cache_name key
    # Returns: 0 if exists, 1 otherwise
    local cache_name="$1"
    local key="$2"

    case "$cache_name" in
        flatpak_apps)
            [[ -n "${_CACHE_FLATPAK_APPS[$key]+x}" ]]
            ;;
        flatpak_versions)
            [[ -n "${_CACHE_FLATPAK_VERSIONS[$key]+x}" ]]
            ;;
        pacman_versions)
            [[ -n "${_CACHE_PACMAN_VERSIONS[$key]+x}" ]]
            ;;
        modules)
            [[ -n "${_CACHE_MODULES[$key]+x}" ]]
            ;;
        constraints)
            [[ -n "${_CACHE_CONSTRAINTS[$key]+x}" ]]
            ;;
        *)
            return 1
            ;;
    esac
}

_cache_clear() {
    # Clear entire named cache
    # Args: cache_name
    local cache_name="$1"

    case "$cache_name" in
        flatpak_apps)
            unset _CACHE_FLATPAK_APPS
            declare -gA _CACHE_FLATPAK_APPS=()
            ;;
        flatpak_versions)
            unset _CACHE_FLATPAK_VERSIONS
            declare -gA _CACHE_FLATPAK_VERSIONS=()
            ;;
        pacman_versions)
            unset _CACHE_PACMAN_VERSIONS
            declare -gA _CACHE_PACMAN_VERSIONS=()
            ;;
        modules)
            unset _CACHE_MODULES
            declare -gA _CACHE_MODULES=()
            ;;
        constraints)
            unset _CACHE_CONSTRAINTS
            declare -gA _CACHE_CONSTRAINTS=()
            ;;
        all)
            _cache_clear flatpak_apps
            _cache_clear flatpak_versions
            _cache_clear pacman_versions
            _cache_clear modules
            _cache_clear constraints
            ;;
        *)
            return 1
            ;;
    esac
}

_cache_keys() {
    # Get all keys from named cache
    # Args: cache_name
    # Returns: keys (one per line)
    local cache_name="$1"

    case "$cache_name" in
        flatpak_apps)
            printf '%s\n' "${!_CACHE_FLATPAK_APPS[@]}"
            ;;
        flatpak_versions)
            printf '%s\n' "${!_CACHE_FLATPAK_VERSIONS[@]}"
            ;;
        pacman_versions)
            printf '%s\n' "${!_CACHE_PACMAN_VERSIONS[@]}"
            ;;
        modules)
            printf '%s\n' "${!_CACHE_MODULES[@]}"
            ;;
        constraints)
            printf '%s\n' "${!_CACHE_CONSTRAINTS[@]}"
            ;;
        *)
            return 1
            ;;
    esac
}

_cache_size() {
    # Get size of named cache
    # Args: cache_name
    # Returns: number of entries
    local cache_name="$1"

    case "$cache_name" in
        flatpak_apps)
            echo "${#_CACHE_FLATPAK_APPS[@]}"
            ;;
        flatpak_versions)
            echo "${#_CACHE_FLATPAK_VERSIONS[@]}"
            ;;
        pacman_versions)
            echo "${#_CACHE_PACMAN_VERSIONS[@]}"
            ;;
        modules)
            echo "${#_CACHE_MODULES[@]}"
            ;;
        constraints)
            echo "${#_CACHE_CONSTRAINTS[@]}"
            ;;
        *)
            echo "0"
            ;;
    esac
}

# =============================================================================
# NAMEREF OPERATIONS (For Direct Cache Access)
# =============================================================================

_cache_get_ref() {
    # Get nameref to cache for direct access (performance optimization)
    # Args: cache_name
    # Usage: local -n cache_ref=$(_cache_get_ref pacman_versions)
    #        echo "${cache_ref[$key]}"
    local cache_name="$1"

    case "$cache_name" in
        flatpak_apps)
            echo "_CACHE_FLATPAK_APPS"
            ;;
        flatpak_versions)
            echo "_CACHE_FLATPAK_VERSIONS"
            ;;
        pacman_versions)
            echo "_CACHE_PACMAN_VERSIONS"
            ;;
        modules)
            echo "_CACHE_MODULES"
            ;;
        constraints)
            echo "_CACHE_CONSTRAINTS"
            ;;
        *)
            return 1
            ;;
    esac
}

# =============================================================================
# CACHE INVALIDATION (Convenience Wrappers)
# =============================================================================

_invalidate_flatpak_cache() {
    _state_set flatpak_cache_loaded "false"
    _cache_clear flatpak_apps
    _cache_clear flatpak_versions
}

_invalidate_pacman_cache() {
    _state_set pacman_cache_loaded "false"
    _cache_clear pacman_versions
}

_invalidate_module_cache() {
    _state_set module_cache_loaded "false"
    _cache_clear modules
}

_invalidate_constraint_cache() {
    _cache_clear constraints
}

_invalidate_all_caches() {
    _invalidate_pacman_cache
    _invalidate_flatpak_cache
    _invalidate_module_cache
    _invalidate_constraint_cache
}

# =============================================================================
# CACHE PERSISTENCE (Performance Optimization)
# =============================================================================

# Constants
CONSTRAINT_CACHE_FILE="${STATE_DIR:-.}/.constraint-cache"
CONSTRAINT_CACHE_TTL=3600  # 1 hour

_load_constraint_cache_from_disk() {
    # Load constraint cache from disk with TTL validation
    # Returns: 0 if loaded, 1 if cache invalid/missing

    [[ ! -f "$CONSTRAINT_CACHE_FILE" ]] && return 1

    # Check cache age (TTL: 1 hour)
    local cache_age=$(($(date +%s) - $(stat -c %Y "$CONSTRAINT_CACHE_FILE" 2>/dev/null || echo 0)))
    if [[ $cache_age -gt $CONSTRAINT_CACHE_TTL ]]; then
        rm -f "$CONSTRAINT_CACHE_FILE"
        return 1
    fi

    # Invalidate cache if packages.yaml is newer (packages changed)
    if [[ -f "${PACKAGES_FILE:-}" ]]; then
        local packages_mtime cache_mtime
        packages_mtime=$(stat -c %Y "$PACKAGES_FILE" 2>/dev/null || echo 0)
        cache_mtime=$(stat -c %Y "$CONSTRAINT_CACHE_FILE" 2>/dev/null || echo 0)

        if [[ $packages_mtime -gt $cache_mtime ]]; then
            rm -f "$CONSTRAINT_CACHE_FILE"
            return 1
        fi
    fi

    # Load cache entries (format: pkg_spec|name|version|constraint_type)
    local loaded_count=0
    while IFS='|' read -r pkg_spec result; do
        if [[ -n "$pkg_spec" ]] && [[ -n "$result" ]]; then
            _CACHE_CONSTRAINTS["$pkg_spec"]="$result"
            ((loaded_count++))
        fi
    done < "$CONSTRAINT_CACHE_FILE"

    if [[ $loaded_count -gt 0 ]]; then
        return 0
    fi

    return 1
}

_save_constraint_cache_to_disk() {
    # Save constraint cache to disk for persistence across commands
    # Saves only if cache has entries

    local cache_size
    cache_size=$(_cache_size constraints)
    [[ $cache_size -eq 0 ]] && return 0

    # Create state directory if needed
    mkdir -p "${STATE_DIR:-.}"

    # Write cache to temp file, then atomic move
    local temp_file="${CONSTRAINT_CACHE_FILE}.tmp.$$"
    : > "$temp_file"

    for pkg_spec in "${!_CACHE_CONSTRAINTS[@]}"; do
        echo "$pkg_spec|${_CACHE_CONSTRAINTS[$pkg_spec]}" >> "$temp_file"
    done

    mv "$temp_file" "$CONSTRAINT_CACHE_FILE" 2>/dev/null || {
        rm -f "$temp_file"
        return 1
    }

    return 0
}

_auto_load_constraint_cache() {
    # Auto-load constraint cache on first access (lazy loading)
    # Called automatically by _parse_package_constraint_cached if cache empty

    [[ $(_cache_size constraints) -gt 0 ]] && return 0

    if _load_constraint_cache_from_disk; then
        local loaded_count
        loaded_count=$(_cache_size constraints)
        [[ "${VERBOSE:-false}" == "true" ]] && \
            ui_info "Loaded $loaded_count cached constraints from disk"
        return 0
    fi

    return 1
}

# =============================================================================
# AUTO-INITIALIZATION
# =============================================================================

# Initialize state on module load
_state_init
