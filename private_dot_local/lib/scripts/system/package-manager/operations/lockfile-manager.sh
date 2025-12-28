#!/usr/bin/env bash

# Script: lockfile-manager.sh
# Purpose: Lockfile I/O and validation operations
# Requirements: yq

# =============================================================================
# LOCKFILE I/O
# =============================================================================

_read_lockfile() {
    # Parse lockfile into associative array
    # Sets global lockfile_versions array
    # Returns: 0 on success, 1 if lockfile doesn't exist

    declare -g -A lockfile_versions

    if [[ ! -f "$LOCKFILE" ]]; then
        return 1
    fi

    # Parse YAML: packages.<module>.<pkg>: "version"
    while IFS=': ' read -r pkg ver; do
        [[ -z "$pkg" ]] && continue
        ver="${ver//\"/}"  # Strip quotes
        ver="${ver// #*/}"  # Strip comments
        # shellcheck disable=SC2034  # Global array used in sourced command files
        [[ -n "$ver" ]] && lockfile_versions[$pkg]="$ver"
    done < <(yq eval '.packages | to_entries[] | .value | to_entries[] | "\(.key): \(.value)"' "$LOCKFILE" 2>/dev/null)

    return 0
}

# =============================================================================
# LOCKFILE VALIDATION
# =============================================================================

_validate_lockfile_syntax() {
    # Validate lockfile YAML syntax
    # Returns: 0 if valid, 1 if invalid or missing

    if [[ ! -f "$LOCKFILE" ]]; then
        return 1  # No lockfile
    fi

    # Validate YAML syntax with yq
    if ! yq eval '.' "$LOCKFILE" >/dev/null 2>&1; then
        return 1  # Invalid syntax
    fi

    return 0
}

_check_lockfile_staleness() {
    # Detect stale lockfile based on age
    # Returns: 0 if fresh, 1 if warning (>30 days), 2 if error (>90 days)

    if [[ ! -f "$LOCKFILE" ]]; then
        return 1  # No lockfile
    fi

    # Check age
    local age_days=$(( ($(date +%s) - $(stat -c %Y "$LOCKFILE")) / 86400 ))

    if [[ $age_days -gt 90 ]]; then
        ui_error "Lockfile is $age_days days old (>90 days)"
        return 2
    elif [[ $age_days -gt 30 ]]; then
        ui_warning "Lockfile is $age_days days old (>30 days)"
        return 1
    fi

    return 0
}
