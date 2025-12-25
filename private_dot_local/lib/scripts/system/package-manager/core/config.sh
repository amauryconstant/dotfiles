#!/usr/bin/env bash

# Script: config.sh
# Purpose: Configuration and packages.yaml access helpers
# Requirements: yq

# =============================================================================
# ICON CONSTANTS
# =============================================================================

# Source icon library (Material Design Nerd Fonts)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$SCRIPT_DIR/core/icons.sh"

# =============================================================================
# GLOBAL CONFIGURATION
# =============================================================================

# Note: These are re-declared here for module independence
# They will be set in the main script before sourcing modules
: "${PACKAGES_FILE:=$HOME/.local/share/chezmoi/.chezmoidata/packages.yaml}"
: "${STATE_DIR:=$HOME/.local/state/package-manager}"
: "${STATE_FILE:=$STATE_DIR/package-state.yaml}"
: "${LOCKFILE:=$STATE_DIR/locked-versions.yaml}"

# Ensure packages.yaml exists (alias for backward compatibility - used in main script)
export PACKAGES_YAML="$PACKAGES_FILE"

# =============================================================================
# MODULE ACCESS HELPERS
# =============================================================================

_get_modules() {
    yq eval '.packages.modules | keys | .[]' "$PACKAGES_FILE" 2>/dev/null
}

_get_enabled_modules() {
    yq eval '.packages.modules | to_entries | .[] | select(.value.enabled == true) | .key' "$PACKAGES_FILE" 2>/dev/null
}

_get_module_packages() {
    local module="$1"
    MOD="$module" yq eval '.packages.modules[env(MOD)].packages | .[]' "$PACKAGES_FILE" 2>/dev/null
}

_is_module_enabled() {
    local module="$1"
    local enabled
    enabled=$(MOD="$module" yq eval '.packages.modules[env(MOD)].enabled' "$PACKAGES_FILE" 2>/dev/null)
    [[ "$enabled" == "true" ]]
}

_get_module_conflicts() {
    local module="$1"
    MOD="$module" yq eval '.packages.modules[env(MOD)].conflicts[]?' "$PACKAGES_FILE" 2>/dev/null
}

_get_module_description() {
    local module="$1"
    MOD="$module" yq eval '.packages.modules[env(MOD)].description' "$PACKAGES_FILE" 2>/dev/null
}

_get_module_package_count() {
    local module="$1"
    MOD="$module" yq eval '.packages.modules[env(MOD)].packages | length' "$PACKAGES_FILE" 2>/dev/null
}

_module_exists() {
    local module="$1"
    MOD="$module" yq eval '.packages.modules | has(env(MOD))' "$PACKAGES_FILE" 2>/dev/null | grep -q "true"
}

# =============================================================================
# BACKUP TOOL CONFIGURATION
# =============================================================================

_get_backup_tool_config() {
    # Returns: backup_tool (timeshift/snapper/none)
    local tool=$(yq eval '.packages.backup_tool // ""' "$PACKAGES_FILE" 2>/dev/null)

    if [[ -n "$tool" && "$tool" != "null" ]]; then
        echo "$tool"
        return 0
    fi

    # Auto-detect if not configured
    if command -v timeshift >/dev/null 2>&1; then
        echo "timeshift"
    elif command -v snapper >/dev/null 2>&1; then
        echo "snapper"
    else
        echo "none"
    fi
}

_get_snapper_config() {
    # Returns snapper config name (default: root)
    local config=$(yq eval '.packages.snapper_config // "root"' "$PACKAGES_FILE" 2>/dev/null)
    echo "${config:-root}"
}

# =============================================================================
# MODULE CACHE (Performance optimization for sync command)
# =============================================================================

# Cache for module data (populated once per sync with single yq call)
declare -gA _MODULE_CACHE=()
declare -g _MODULE_CACHE_LOADED=false

_load_module_cache() {
    # Load all enabled modules and their packages in a single yq call
    # Significantly faster than separate queries per module (16 calls → 1 call)

    if [[ "$_MODULE_CACHE_LOADED" == "true" ]]; then
        return 0
    fi

    # Ensure cache is properly declared as associative array
    if ! declare -p _MODULE_CACHE &>/dev/null || [[ "$(declare -p _MODULE_CACHE 2>/dev/null)" != *"-A"* ]]; then
        declare -gA _MODULE_CACHE=()
    fi

    # Single yq call to load all enabled modules and their packages
    local cache_data
    cache_data=$(yq eval '
        .packages.modules
        | to_entries
        | .[]
        | select(.value.enabled == true)
        | .key + "|" + (.value.packages | join(","))
    ' "$PACKAGES_FILE" 2>/dev/null)

    # Parse and store in cache
    if [[ -n "$cache_data" ]]; then
        while IFS='|' read -r mod_name mod_packages; do
            [[ -n "$mod_name" ]] && _MODULE_CACHE["$mod_name"]="$mod_packages"
        done <<< "$cache_data"
    fi

    _MODULE_CACHE_LOADED=true
}

_get_enabled_modules_cached() {
    # Get list of enabled modules (uses cache)
    _load_module_cache
    printf '%s\n' "${!_MODULE_CACHE[@]}"
}

_get_module_packages_cached() {
    # Get packages for a specific module (uses cache)
    local module="$1"
    _load_module_cache

    local packages="${_MODULE_CACHE[$module]:-}"
    if [[ -n "$packages" ]]; then
        echo "$packages" | tr ',' '\n'
    fi
}

_invalidate_module_cache() {
    # Invalidate cache (call after modifying packages.yaml)
    _MODULE_CACHE_LOADED=false
    unset _MODULE_CACHE
    declare -gA _MODULE_CACHE=()
}
