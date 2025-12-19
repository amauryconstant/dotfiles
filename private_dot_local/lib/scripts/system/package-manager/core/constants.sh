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

readonly CONSTRAINT_EXACT="exact"
readonly CONSTRAINT_MINIMUM="minimum"
readonly CONSTRAINT_MAXIMUM="maximum"
readonly CONSTRAINT_NONE="none"

# =============================================================================
# FLATPAK SCOPES
# =============================================================================

readonly FLATPAK_SCOPE_USER="user"
readonly FLATPAK_SCOPE_SYSTEM="system"

# =============================================================================
# MODULE STATES
# =============================================================================

readonly MODULE_ENABLED="true"
readonly MODULE_DISABLED="false"

# =============================================================================
# BACKUP TOOLS
# =============================================================================

readonly BACKUP_TOOL_TIMESHIFT="timeshift"
readonly BACKUP_TOOL_SNAPPER="snapper"

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

_validate_package_type() {
    local type="$1"
    case "$type" in
        "$PACKAGE_TYPE_PACMAN"|"$PACKAGE_TYPE_FLATPAK")
            return 0
            ;;
        *)
            ui_error "Invalid package type: $type (expected: $PACKAGE_TYPE_PACMAN or $PACKAGE_TYPE_FLATPAK)"
            return 1
            ;;
    esac
}

_validate_constraint_operator() {
    local operator="$1"
    case "$operator" in
        "$CONSTRAINT_EXACT"|"$CONSTRAINT_MINIMUM"|"$CONSTRAINT_MAXIMUM"|"$CONSTRAINT_NONE")
            return 0
            ;;
        *)
            ui_error "Invalid constraint operator: $operator (expected: exact, minimum, maximum, or none)"
            return 1
            ;;
    esac
}

_validate_flatpak_scope() {
    local scope="$1"
    case "$scope" in
        "$FLATPAK_SCOPE_USER"|"$FLATPAK_SCOPE_SYSTEM")
            return 0
            ;;
        *)
            ui_error "Invalid flatpak scope: $scope (expected: $FLATPAK_SCOPE_USER or $FLATPAK_SCOPE_SYSTEM)"
            return 1
            ;;
    esac
}

_validate_module_state() {
    local state="$1"
    case "$state" in
        "$MODULE_ENABLED"|"$MODULE_DISABLED")
            return 0
            ;;
        *)
            ui_error "Invalid module state: $state (expected: true or false)"
            return 1
            ;;
    esac
}

_validate_backup_tool() {
    local tool="$1"
    case "$tool" in
        "$BACKUP_TOOL_TIMESHIFT"|"$BACKUP_TOOL_SNAPPER")
            return 0
            ;;
        *)
            ui_error "Invalid backup tool: $tool (expected: $BACKUP_TOOL_TIMESHIFT or $BACKUP_TOOL_SNAPPER)"
            return 1
            ;;
    esac
}
