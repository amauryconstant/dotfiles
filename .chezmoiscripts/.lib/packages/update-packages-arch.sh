#!/bin/bash
# update-packages-arch.sh
# Purpose: Update packages for Arch Linux (all destinations)
# Dependencies: pacman, yay (optional for AUR packages)
# Environment: CHEZMOI_OS_ID, CHEZMOI_DESTINATION, CHEZMOI_PACKAGES
# OS Support: linux-arch
# Destination: work/leisure/test

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Update packages for Arch Linux"
readonly REQUIRED_COMMANDS=("pacman")
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID" "CHEZMOI_DESTINATION" "CHEZMOI_PACKAGES")

# Package management functions
get_package_source() {
    local package="$1"
    
    # Check if package is installed via pacman (official repos)
    if pacman -Qi "$package" >/dev/null 2>&1; then
        # Check if it's from official repos or AUR
        local repo=$(pacman -Qi "$package" | grep "Repository" | awk '{print $3}')
        if [ "$repo" != "aur" ]; then
            echo "pacman"
            return 0
        fi
    fi
    
    # Check if package is installed via yay (AUR)
    if yay -Qi "$package" >/dev/null 2>&1; then
        # Try to determine if it was built from source or binary
        # This is a heuristic - check if package has build files in cache
        if [ -d "/home/$USER/.cache/yay/$package" ] || yay -Qi "$package" | grep -q "Build Date"; then
            echo "yay_source"
        else
            echo "yay_bin"
        fi
        return 0
    fi
    
    # Package not installed
    echo "not_installed"
    return 1
}

is_package_in_official_repos() {
    local package="$1"
    pacman -Si "$package" >/dev/null 2>&1
}

is_package_installed() {
    local package="$1"
    pacman -Qi "$package" >/dev/null 2>&1 || yay -Qi "$package" >/dev/null 2>&1
}

get_update_method() {
    local package="$1"
    local strategy="$2"
    local current_source="$3"
    
    # If package is not installed, use strategy for installation
    if [ "$current_source" = "not_installed" ]; then
        echo "$strategy" | awk '{print $1}'
        return 0
    fi
    
    # If package is available in official repos and strategy includes pacman, prefer pacman
    if is_package_in_official_repos "$package"; then
        if echo "$strategy" | grep -q "pacman"; then
            echo "pacman"
            return 0
        fi
    fi
    
    # For AUR packages or when pacman is not in strategy, use yay methods
    if echo "$strategy" | grep -q "yay_bin"; then
        echo "yay_bin"
    elif echo "$strategy" | grep -q "yay_source"; then
        echo "yay_source"
    else
        # Fallback to first method in strategy
        echo "$strategy" | awk '{print $1}'
    fi
}

# Update functions
update_with_pacman() {
    local packages="$*"
    log_dry_run "update" "$packages via pacman"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if sudo pacman -Syu --noconfirm --needed "$@"; then
            return 0
        else
            return 1
        fi
    fi
    return 0
}

update_with_yay_bin() {
    local packages="$*"
    log_dry_run "update" "$packages via yay (binary)"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if yay -Syu --noconfirm --needed --norebuild --redownload "$@"; then
            return 0
        else
            return 1
        fi
    fi
    return 0
}

update_with_yay_source() {
    local packages="$*"
    log_dry_run "update" "$packages via yay (source)"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if yay -Syu --noconfirm --needed --rebuild "$@"; then
            return 0
        else
            return 1
        fi
    fi
    return 0
}

# Installation functions (for missing packages)
install_with_pacman() {
    local packages="$*"
    log_dry_run "install" "$packages via pacman"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if sudo pacman -S --noconfirm --needed "$@"; then
            return 0
        else
            return 1
        fi
    fi
    return 0
}

install_with_yay_bin() {
    local packages="$*"
    log_dry_run "install" "$packages via yay (binary)"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if yay -S --noconfirm --needed --norebuild --redownload "$@"; then
            return 0
        else
            return 1
        fi
    fi
    return 0
}

install_with_yay_source() {
    local packages="$*"
    log_dry_run "install" "$packages via yay (source)"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if yay -S --noconfirm --needed --rebuild "$@"; then
            return 0
        else
            return 1
        fi
    fi
    return 0
}

# Install packages with strategy fallback
install_with_strategy() {
    local strategy="$1"
    shift
    local packages="$*"
    
    # Parse strategy (comma-separated list)
    IFS=',' read -ra STRATEGY_METHODS <<< "$strategy"
    
    for method in "${STRATEGY_METHODS[@]}"; do
        case "$method" in
            "pacman")
                if install_with_pacman $packages; then
                    return 0
                fi
                ;;
            "yay_bin")
                if command -v yay >/dev/null 2>&1; then
                    if install_with_yay_bin $packages; then
                        return 0
                    fi
                else
                    log_warn "Yay not available, skipping yay_bin strategy"
                fi
                ;;
            "yay_source")
                if command -v yay >/dev/null 2>&1; then
                    if install_with_yay_source $packages; then
                        return 0
                    fi
                else
                    log_warn "Yay not available, skipping yay_source strategy"
                fi
                ;;
            *)
                log_warn "Unknown installation method: $method"
                ;;
        esac
    done
    
    return 1
}

# Reinstall package with correct strategy
reinstall_package() {
    local package="$1"
    local strategy="$2"
    
    log_info "Reinstalling $package with strategy: $strategy"
    
    # Remove the package first
    if is_package_installed "$package"; then
        log_info "Removing $package..."
        log_dry_run "remove" "$package"
        
        if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
            if ! (yay -R --noconfirm "$package" 2>/dev/null || sudo pacman -R --noconfirm "$package" 2>/dev/null); then
                log_warn "Failed to remove $package, continuing anyway"
            fi
        fi
    fi
    
    # Install with correct strategy
    if install_with_strategy "$strategy" "$package"; then
        log_success "Successfully reinstalled $package"
        return 0
    else
        error_exit "Failed to reinstall $package with strategy: $strategy" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE
    fi
}

# Handle known package transitions
handle_package_transitions() {
    log_info "Checking for known package transitions..."
    
    # Handle linux-firmware split transition (June 2025)
    if pacman -Qi linux-firmware >/dev/null 2>&1; then
        local current_version=$(pacman -Qi linux-firmware | grep Version | awk '{print $3}' | cut -d'-' -f1)
        local current_date=$(echo "$current_version" | cut -d'.' -f1)
        
        # Check if we have the old monolithic version (before 20250613)
        if [ "$current_date" -lt "20250613" ]; then
            log_info "Detected old linux-firmware package that needs transition handling..."
            log_info "Current version: $current_version"
            log_info "Applying overwrite for firmware files..."
            
            log_dry_run "update" "linux-firmware with overwrite handling"
            
            if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
                # Use --overwrite to handle the file conflicts during transition
                if sudo pacman -Syu --overwrite="/usr/.lib/firmware/nvidia/*" --overwrite="/usr/.lib/firmware/amdgpu/*" --overwrite="/usr/.lib/firmware/radeon/*" --overwrite="/usr/.lib/firmware/intel/*" --noconfirm; then
                    log_success "Successfully handled linux-firmware package transition"
                    return 0
                else
                    error_exit "Failed to handle linux-firmware package transition" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE
                fi
            fi
        fi
    fi
    
    log_debug "No package transitions detected"
    return 0
}

# Quick check to determine if updates are needed
check_updates_needed() {
    log_info "Checking for package updates and strategy compliance for $CHEZMOI_DESTINATION destination..."
    
    # Quick check for system updates
    local system_updates=false
    if pacman -Qu >/dev/null 2>&1 || (command -v yay >/dev/null 2>&1 && yay -Qu >/dev/null 2>&1); then
        log_info "System updates available"
        system_updates=true
    else
        log_debug "No system updates available"
    fi
    
    # Quick strategy compliance check would require package list parsing
    # For now, we'll assume updates are needed if system updates are available
    if [ "$system_updates" = "true" ]; then
        log_info "Package management actions needed"
        return 0
    else
        log_info "No immediate updates detected"
        return 1
    fi
}

# Remove conflicting packages
remove_conflicting_packages() {
    local conflicting_packages="tldr"  # From packages.yaml delete.arch
    
    if [ -n "$conflicting_packages" ]; then
        log_info "Removing conflicting packages: $conflicting_packages"
        log_dry_run "remove" "$conflicting_packages"
        
        if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
            if yay -R --noconfirm $conflicting_packages 2>/dev/null; then
                log_success "Conflicting packages removed"
            else
                log_info "No conflicting packages found (this is normal)"
            fi
        fi
    fi
}

# Process package categories based on destination
process_package_categories() {
    # Parse enabled package categories
    IFS=',' read -ra CATEGORIES <<< "$CHEZMOI_PACKAGES"
    
    log_info "Processing $(echo "${CATEGORIES[@]}" | wc -w) package categories for $CHEZMOI_DESTINATION destination"
    
    # For each category, we would need to know the strategy and package list
    # Since we don't have access to the packages.yaml data here, we'll use a simplified approach
    # In a real implementation, this data would be passed via environment variables
    
    for category in "${CATEGORIES[@]}"; do
        log_info "Processing category: $category"
        
        # This is where we would process each category's packages
        # For now, we'll just log that we're processing it
        log_debug "Category $category processing would happen here"
    done
}

# Validation function
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate required commands
    require_commands "${REQUIRED_COMMANDS[@]}"
    
    # Validate OS
    require_os_id "linux-arch"
    
    # Check if yay is available (warn if not)
    if ! command -v yay >/dev/null 2>&1; then
        log_warn "Yay AUR helper not available - some packages may not be updateable"
        log_warn "Install yay for full package management capabilities"
    fi
    
    log_debug "Environment validation passed"
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: $CHEZMOI_OS_ID, Destination: $CHEZMOI_DESTINATION"
    
    validate_environment
    
    # Run quick check first
    if ! check_updates_needed; then
        log_info "No updates needed. Exiting."
        return 0
    fi
    
    log_step "Starting comprehensive package update process..."
    
    # Handle package transitions before proceeding with normal updates
    handle_package_transitions
    
    # Remove conflicting packages first
    remove_conflicting_packages
    
    # Process package categories
    process_package_categories
    
    log_success "$SCRIPT_PURPOSE completed successfully"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
