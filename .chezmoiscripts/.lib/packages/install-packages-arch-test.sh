#!/bin/bash
# install-packages-arch-test.sh
# Purpose: Install packages for Arch Linux test destination
# Dependencies: pacman, yay (optional for AUR packages)
# Environment: CHEZMOI_OS_ID, CHEZMOI_DESTINATION, CHEZMOI_PACKAGES
# OS Support: linux-arch
# Destination: test

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Install packages for Arch Linux test destination"
readonly REQUIRED_COMMANDS=("pacman")
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID" "CHEZMOI_DESTINATION" "CHEZMOI_PACKAGES")

# Package installation functions with strategy support
install_with_pacman() {
    local packages="$*"
    local start_time=$(date +%s)
    
    log_dry_run "install" "$packages via pacman"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if sudo pacman -S --noconfirm --needed "$@"; then
            local duration=$(($(date +%s) - start_time))
            log_debug "Pacman installation took ${duration}s"
            return 0
        else
            return 1
        fi
    fi
    return 0
}

install_with_yay_bin() {
    local packages="$*"
    local start_time=$(date +%s)
    
    log_dry_run "install" "$packages via yay (binary)"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if yay -S --noconfirm --needed --norebuild --redownload "$@"; then
            local duration=$(($(date +%s) - start_time))
            log_debug "Yay binary installation took ${duration}s"
            return 0
        else
            return 1
        fi
    fi
    return 0
}

install_with_yay_source() {
    local packages="$*"
    local start_time=$(date +%s)
    
    log_dry_run "install" "$packages via yay (source)"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if yay -S --noconfirm --needed --rebuild "$@"; then
            local duration=$(($(date +%s) - start_time))
            log_debug "Yay source installation took ${duration}s"
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
    local package_count=$(echo "$packages" | wc -w)
    
    log_debug "Installing $package_count packages with strategy: $strategy"
    log_debug "Packages: $packages"
    
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

# Category installation functions (minimal test environment)
install_fonts() {
    log_info "Installing fonts for test environment"
    
    local packages="ttf-firacode-nerd ttf-fira-sans"
    local strategy="pacman,yay_bin,yay_source"  # Default strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install fonts" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: pacman -S $packages"
    fi
    
    log_success "Fonts installed successfully"
}

install_terminal_essentials() {
    log_info "Installing terminal essentials for test environment"
    
    local packages="zoxide fzf fd ripgrep bat eza rsync"
    local strategy="pacman,yay_bin,yay_source"  # From source strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install terminal essentials" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: yay -S $packages"
    fi
    
    log_success "Terminal essentials installed successfully"
}

install_terminal_utils() {
    log_info "Installing terminal utilities for test environment"
    
    local packages="fastfetch btop"
    local strategy="pacman,yay_bin,yay_source"  # From source strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install terminal utilities" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: yay -S $packages"
    fi
    
    log_success "Terminal utilities installed successfully"
}

install_system_software() {
    log_info "Installing system software for test environment"
    
    local packages="snapd"
    local strategy="pacman,yay_bin"  # Default strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install system software" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: pacman -S $packages"
    fi
    
    log_success "System software installed successfully"
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

# Validation function
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate required commands
    require_commands "${REQUIRED_COMMANDS[@]}"
    
    # Validate OS and destination
    require_os "linux-arch"
    require_destination "test"
    
    # Check if yay is available (warn if not)
    if ! command -v yay >/dev/null 2>&1; then
        log_warn "Yay AUR helper not available - some packages may not be installable"
        log_warn "Install yay for full package management capabilities"
    fi
    
    log_debug "Environment validation passed"
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: $CHEZMOI_OS_ID, Destination: $CHEZMOI_DESTINATION"
    
    validate_environment
    
    # Remove conflicting packages first
    remove_conflicting_packages
    
    # Parse enabled package categories
    IFS=',' read -ra CATEGORIES <<< "$CHEZMOI_PACKAGES"
    
    log_info "Processing $(echo "${CATEGORIES[@]}" | wc -w) package categories for test destination"
    
    for category in "${CATEGORIES[@]}"; do
        case "$category" in
            "fonts") install_fonts ;;
            "terminal_essentials") install_terminal_essentials ;;
            "terminal_utils") install_terminal_utils ;;
            "system_software") install_system_software ;;
            *) log_warn "Unknown package category: $category" ;;
        esac
    done
    
    log_success "$SCRIPT_PURPOSE completed successfully"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
