#!/usr/bin/env bash

# Script: validation.sh
# Purpose: Validation and dependency checking for package-manager
# Requirements: pacman, paru (optional), yq

# =============================================================================
# DEPENDENCY VALIDATION
# =============================================================================

_check_yq_dependency() {
    if ! command -v yq >/dev/null 2>&1; then
        ui_error "yq is required. Install with: paru -S go-yq"
        return 1
    fi
    return 0
}

_get_aur_helper() {
    # Detect AUR helper (paru only)
    if command -v paru &>/dev/null; then
        echo "paru"
    else
        echo ""
    fi
}

# =============================================================================
# ERROR CONTEXT WRAPPER
# =============================================================================

# Wrapper function that adds context to errors
# Usage: _with_context "Operation description" command args...
# Example: _with_context "Reading module 'base' from packages.yaml" yq eval '.modules.base' file.yaml
_with_context() {
    local context="$1"
    shift

    # Capture command output and status
    local output
    local status
    output=$("$@" 2>&1)
    status=$?

    if [[ $status -ne 0 ]]; then
        ui_error "$context"
        ui_error "  Command failed: $*"
        [[ -n "$output" ]] && ui_error "  Error: $output"
        return $status
    fi

    # Success - output result
    echo "$output"
    return 0
}

# =============================================================================
# PACKAGE VALIDATION
# =============================================================================

_check_package_exists() {
    # Check if a package exists in official repos or AUR
    # Returns: 0 if exists, 1 if not found
    local pkg="$1"

    # Check official repos first (fastest)
    if pacman -Si "$pkg" &>/dev/null; then
        return 0
    fi

    # Check AUR with paru (15-second timeout to prevent hangs)
    if command -v paru >/dev/null 2>&1; then
        if timeout 15 paru -Si "$pkg" &>/dev/null 2>&1; then
            return 0
        fi
    fi

    return 1
}

# =============================================================================
# AUR VALIDATION BATCHING
# =============================================================================

# Batch validate AUR packages (single paru call for performance)
# Prints invalid package names to stdout
# Returns: 0 on success, 1 on timeout (triggers fallback)
_validate_aur_packages_batch() {
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        return 0
    fi

    # Single batch query with timeout (Optimization 1)
    # Replaces N × 5s with 1 × 10s worst case
    local aur_output
    if ! aur_output=$(timeout 10 paru -Si "${packages[@]}" 2>/dev/null); then
        # Timeout or error - return 1 to trigger fallback
        return 1
    fi

    # Parse valid package names from output
    local valid_names
    valid_names=$(echo "$aur_output" | grep -E '^Name\s+:' | awk '{print $3}')

    # Build hash set of valid packages for O(1) lookup
    declare -A valid_set
    while IFS= read -r name; do
        [[ -n "$name" ]] && valid_set[$name]=1
    done <<< "$valid_names"

    # Output invalid packages (those not in valid set)
    for pkg in "${packages[@]}"; do
        if [[ -z "${valid_set[$pkg]:-}" ]]; then
            echo "$pkg"
        fi
    done

    return 0
}

# Sequential AUR validation (fallback for timeout/error)
# Prints invalid package names to stdout
_validate_aur_packages_sequential() {
    local packages=("$@")

    for pkg in "${packages[@]}"; do
        if ! timeout 5 paru -Si "$pkg" &>/dev/null 2>&1; then
            echo "$pkg"
        fi
    done
}

_check_packages_batch() {
    # Batch check if packages exist (more efficient for validation)
    # Prints invalid package names to stdout
    local packages=("$@")

    # First, filter out already installed packages (they're obviously valid)
    local -A installed_packages
    if [[ ${#packages[@]} -gt 0 ]]; then
        for pkg in "${packages[@]}"; do
            if pacman -Q "$pkg" >/dev/null 2>&1; then
                installed_packages[$pkg]=1
            fi
        done
    fi

    # Second, check all packages against official repos (batch query - fast!)
    local -A repo_packages
    if [[ ${#packages[@]} -gt 0 ]]; then
        # Get all available packages from official repos in one call (~0.3s)
        local all_repo_pkgs=$(pacman -Ssq 2>/dev/null)
        while IFS= read -r pkg; do
            [[ -n "$pkg" ]] && repo_packages[$pkg]=1
        done <<< "$all_repo_pkgs"
    fi

    # For packages not in repos and not installed, check AUR
    local remaining_packages=()
    for pkg in "${packages[@]}"; do
        if [[ -z "${installed_packages[$pkg]:-}" ]] && [[ -z "${repo_packages[$pkg]:-}" ]]; then
            remaining_packages+=("$pkg")
        fi
    done

    # AUR check: batch validation with fallback (Optimization 1)
    if [[ ${#remaining_packages[@]} -gt 0 ]] && command -v paru >/dev/null 2>&1; then
        # Try batch validation first (10s timeout for all packages)
        if ! _validate_aur_packages_batch "${remaining_packages[@]}"; then
            # Batch timed out - fall back to sequential (5s per package)
            _validate_aur_packages_sequential "${remaining_packages[@]}"
        fi
    elif [[ ${#remaining_packages[@]} -gt 0 ]]; then
        # No paru available, assume all remaining are invalid
        printf '%s\n' "${remaining_packages[@]}"
    fi
}

# =============================================================================
# LOCKFILE VALIDATION
# =============================================================================

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

# =============================================================================
# HELPER UTILITIES
# =============================================================================

_log_verbose() {
    local message="$1"
    [[ "$VERBOSE" == "true" ]] && ui_info "$message"
    return 0
}

_execute_or_dry_run() {
    local description="$1"
    local command="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        ui_info "[DRY-RUN] Would run: $command"
        return 0
    fi

    _log_verbose "$description"
    eval "$command" 2>/dev/null
}
