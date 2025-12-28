#!/usr/bin/env bash

# Script: validation.sh
# Purpose: Validation and dependency checking for package-manager
# Requirements: pacman, paru (optional), yq

# =============================================================================
# AUR PACKAGE CACHE (Performance Optimization)
# =============================================================================

# Constants
AUR_CACHE_DIR="${STATE_DIR:-.}/.aur-cache"
AUR_CACHE_TTL=86400  # 24 hours

_check_aur_cached() {
    # Check if AUR package exists with caching (50-80% faster for repeated validations)
    # Args: package_name
    # Returns: "exists" or "not_found"
    local package="$1"
    local cache_file="$AUR_CACHE_DIR/${package}.cache"

    # Create cache directory
    mkdir -p "$AUR_CACHE_DIR" 2>/dev/null

    # Check cache freshness (TTL: 24 hours)
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        if [[ $cache_age -lt $AUR_CACHE_TTL ]]; then
            # Return cached result
            cat "$cache_file"
            return 0
        fi
    fi

    # Not in cache or stale - query AUR
    local result
    if timeout 5 paru -Si --aur "$package" &>/dev/null; then
        result="exists"
    else
        result="not_found"
    fi

    # Save to cache
    echo "$result" > "$cache_file" 2>/dev/null || true
    echo "$result"

    return 0
}

_cleanup_aur_cache() {
    # Remove stale AUR cache entries (older than TTL)
    # Called periodically to prevent unbounded growth
    [[ ! -d "$AUR_CACHE_DIR" ]] && return 0

    # Remove files older than 24 hours
    find "$AUR_CACHE_DIR" -type f -name "*.cache" -mtime +1 -delete 2>/dev/null || true

    return 0
}

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

    ui_info "Validating ${#packages[@]} AUR packages (batch mode, 10s timeout)..." >&2

    # Single batch query with timeout (Optimization 1)
    # Replaces N × 5s with 1 × 10s worst case
    local aur_output
    if ! aur_output=$(timeout 10 paru -Si "${packages[@]}" 2>/dev/null); then
        # Timeout or error - return 1 to trigger fallback
        ui_warning "Batch validation timed out, falling back to sequential checks..." >&2
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
# Uses AUR cache for 50-80% faster repeated validations
_validate_aur_packages_sequential() {
    local packages=("$@")

    for pkg in "${packages[@]}"; do
        # Use cached AUR check (24h TTL)
        local result=$(_check_aur_cached "$pkg")
        if [[ "$result" != "exists" ]]; then
            echo "$pkg"
        fi
    done
}

_check_packages_batch() {
    # Batch check if packages exist (more efficient for validation)
    # Prints invalid package names to stdout
    # Options:
    #   --skip-installed-filter: Skip filtering installed packages (for sync context)

    local skip_installed=false
    local packages=()

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-installed-filter)
                skip_installed=true
                shift
                ;;
            *)
                # End of flags, rest are package names
                packages+=("$1")
                shift
                ;;
        esac
    done

    # Filter out already installed packages using batch query (PERF: single pacman call)
    # Skip this check if --skip-installed-filter is set (sync already classifies packages)
    local -A installed_packages
    local remaining_packages=()

    if [[ "$skip_installed" == "false" ]] && [[ ${#packages[@]} -gt 0 ]]; then
        local check_output
        check_output=$(pacman -Q "${packages[@]}" 2>/dev/null || true)
        while IFS=' ' read -r pkg _ver; do
            [[ -n "$pkg" ]] && installed_packages[$pkg]=1
        done <<< "$check_output"

        # Build list of remaining packages (not installed)
        # NOTE: Removed redundant pacman -Ssq check (500ms-2s saved)
        # The AUR check below handles both official repos AND AUR packages
        for pkg in "${packages[@]}"; do
            if [[ -z "${installed_packages[$pkg]:-}" ]]; then
                remaining_packages+=("$pkg")
            fi
        done
    else
        # Skip installed filter - validate all packages
        remaining_packages=("${packages[@]}")
    fi

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

# Lockfile validation functions now in operations/lockfile-manager.sh

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
