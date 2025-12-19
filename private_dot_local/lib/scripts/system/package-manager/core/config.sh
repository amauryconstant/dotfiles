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
