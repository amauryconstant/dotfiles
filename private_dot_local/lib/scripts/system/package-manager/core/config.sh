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

_enable_module() {
    # Enable a module in packages.yaml
    # Args: module_name
    # Returns: 0 on success, 1 on failure
    local module="$1"
    MOD="$module" yq eval '.packages.modules[env(MOD)].enabled = true' -i "$PACKAGES_FILE"
    _invalidate_module_cache
}

_disable_module() {
    # Disable a module in packages.yaml
    # Args: module_name
    # Returns: 0 on success, 1 on failure
    local module="$1"
    MOD="$module" yq eval '.packages.modules[env(MOD)].enabled = false' -i "$PACKAGES_FILE"
    _invalidate_module_cache
}

# =============================================================================
# BACKUP TOOL CONFIGURATION
# =============================================================================
# NOTE: Backup tool configuration moved to operations/backup-manager.sh
# Use _get_backup_tool() and _get_snapper_config() from that module

# =============================================================================
# MODULE CACHE (Performance optimization for sync command)
# =============================================================================
# NOTE: Module cache now managed via core/state-manager.sh
# Global state eliminated - use _state_* and _cache_* functions

_load_module_cache() {
    # Load all enabled modules and their packages in a single yq call
    # Significantly faster than separate queries per module (16 calls → 1 call)

    if [[ "$(_state_get module_cache_loaded)" == "true" ]]; then
        return 0
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
            [[ -n "$mod_name" ]] && _cache_set modules "$mod_name" "$mod_packages"
        done <<< "$cache_data"
    fi

    _state_set module_cache_loaded "true"
}

_get_enabled_modules_cached() {
    # Get list of enabled modules (uses cache)
    _load_module_cache
    _cache_keys modules
}

_get_module_packages_cached() {
    # Get packages for a specific module (uses cache)
    local module="$1"
    _load_module_cache

    local packages
    packages=$(_cache_get modules "$module")
    if [[ -n "$packages" ]]; then
        echo "$packages" | tr ',' '\n'
    fi
}

# _invalidate_module_cache() - already defined in state-manager.sh
