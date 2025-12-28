#!/usr/bin/env bash

# Script: constants.sh
# Purpose: Type-safe constants for package-manager
# Requirements: None

# =============================================================================
# PACKAGE TYPES
# =============================================================================

readonly PACKAGE_TYPE_PACMAN="pacman"
readonly PACKAGE_TYPE_FLATPAK="flatpak"

# =============================================================================
# CONSTRAINT OPERATORS
# =============================================================================

# shellcheck disable=SC2034  # Used by external modules
readonly CONSTRAINT_EXACT="exact"
# shellcheck disable=SC2034  # Used by external modules
readonly CONSTRAINT_MINIMUM="minimum"
# shellcheck disable=SC2034  # Used by external modules
readonly CONSTRAINT_MAXIMUM="maximum"
# shellcheck disable=SC2034  # Used by external modules
readonly CONSTRAINT_NONE="none"

# =============================================================================
# FLATPAK SCOPES
# =============================================================================

# shellcheck disable=SC2034  # Used by external modules
readonly FLATPAK_SCOPE_USER="user"
# shellcheck disable=SC2034  # Used by external modules
readonly FLATPAK_SCOPE_SYSTEM="system"

# =============================================================================
# MODULE STATES
# =============================================================================

# shellcheck disable=SC2034  # Used by external modules
readonly MODULE_ENABLED="true"
# shellcheck disable=SC2034  # Used by external modules
readonly MODULE_DISABLED="false"

# =============================================================================
# BACKUP TOOLS
# =============================================================================

# shellcheck disable=SC2034  # Used by external modules
readonly BACKUP_TOOL_TIMESHIFT="timeshift"
# shellcheck disable=SC2034  # Used by external modules
readonly BACKUP_TOOL_SNAPPER="snapper"

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Validate package type (used in state operations)
# Returns: 0 if valid, 1 if invalid
_validate_package_type() {
    local type="$1"
    case "$type" in
        "$PACKAGE_TYPE_PACMAN"|"$PACKAGE_TYPE_FLATPAK")
            return 0
            ;;
        *)
            ui_error "CRITICAL: Invalid package type '$type'"
            ui_error "Valid types: $PACKAGE_TYPE_PACMAN, $PACKAGE_TYPE_FLATPAK"
            return 1
            ;;
    esac
}
