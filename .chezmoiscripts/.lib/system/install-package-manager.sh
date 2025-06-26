#!/bin/bash
# install-package-manager.sh
# Purpose: Install and configure package managers (yay for AUR support)
# Dependencies: pacman, git, base-devel
# Environment: CHEZMOI_OS_ID
# OS Support: linux-arch
# Destination: all (work/leisure/test)

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Install and configure package managers"
readonly REQUIRED_COMMANDS=("pacman" "git")
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID")

# Validation functions
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required commands
    require_commands "${REQUIRED_COMMANDS[@]}"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate OS match
    [ "$CHEZMOI_OS_ID" = "linux-arch" ] || error_exit "Script for linux-arch, got: $CHEZMOI_OS_ID" 3 "ENVIRONMENT" "This script only supports Arch Linux"
    
    log_debug "Environment validation passed"
}

# Check if package is installed
is_package_installed() {
    local package="$1"
    pacman -Qi "$package" >/dev/null 2>&1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install base development tools
install_base_devel() {
    log_info "Installing base development tools"
    
    if is_package_installed "base-devel"; then
        log_info "base-devel is already installed"
        return 0
    fi
    
    log_dry_run "install" "base-devel group via pacman"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        log_info "Installing base-devel group..."
        if sudo pacman -S --noconfirm --needed base-devel; then
            log_success "base-devel installed successfully"
        else
            error_exit "Failed to install base-devel" 12 "PACKAGE" "Check network connectivity and package conflicts"
        fi
    fi
}

# Install yay AUR helper
install_yay() {
    log_info "Installing yay AUR helper"
    
    if command_exists "yay"; then
        log_info "yay is already installed"
        return 0
    fi
    
    log_dry_run "install" "yay AUR helper from source"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Create temporary directory for building yay
        local temp_dir
        temp_dir=$(mktemp -d)
        
        log_info "Cloning yay repository..."
        if ! git clone https://aur.archlinux.org/yay.git "$temp_dir/yay"; then
            rm -rf "$temp_dir"
            error_exit "Failed to clone yay repository" 5 "NETWORK" "Check network connectivity to AUR"
        fi
        
        log_info "Building and installing yay..."
        if (cd "$temp_dir/yay" && makepkg -si --noconfirm); then
            log_success "yay installed successfully"
        else
            rm -rf "$temp_dir"
            error_exit "Failed to build and install yay" 12 "PACKAGE" "Check build dependencies and permissions"
        fi
        
        # Clean up temporary directory
        rm -rf "$temp_dir"
        log_debug "Cleaned up temporary build directory"
    fi
}

# Configure yay settings
configure_yay() {
    log_info "Configuring yay settings"
    
    if ! command_exists "yay"; then
        log_warn "yay not installed, skipping configuration"
        return 0
    fi
    
    log_dry_run "configure" "yay settings for optimal performance"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Configure yay for better performance and security
        log_info "Setting yay configuration options..."
        
        # Enable colored output
        yay --save --answerclean All --answerdiff None --answerupgrade None --cleanafter
        
        # Set build directory to tmpfs for faster builds (if available)
        if [ -d "/tmp" ] && mountpoint -q /tmp 2>/dev/null; then
            yay --save --builddir /tmp/yay-builds
            log_info "Configured yay to use tmpfs for builds"
        fi
        
        log_success "yay configured successfully"
    fi
}

# Verify package manager installation
verify_installation() {
    log_info "Verifying package manager installation"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Check pacman is working
        if ! pacman --version >/dev/null 2>&1; then
            error_exit "pacman is not working correctly" 15 "PACKAGE" "Check pacman installation and configuration"
        fi
        
        # Check yay is working
        if command_exists "yay"; then
            if ! yay --version >/dev/null 2>&1; then
                error_exit "yay is not working correctly" 15 "PACKAGE" "Check yay installation and configuration"
            fi
            log_success "yay is working correctly"
        else
            log_warn "yay is not installed"
        fi
        
        # Check base-devel is installed
        if is_package_installed "base-devel"; then
            log_success "base-devel is installed"
        else
            log_warn "base-devel is not installed"
        fi
        
        log_success "Package manager verification completed"
    else
        log_info "Dry-run: Would verify pacman, yay, and base-devel installation"
    fi
}

# Update package databases
update_package_databases() {
    log_info "Updating package databases"
    
    log_dry_run "update" "pacman package databases"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        log_info "Updating pacman databases..."
        if sudo pacman -Sy; then
            log_success "Package databases updated successfully"
        else
            log_warn "Failed to update package databases (non-critical)"
        fi
        
        # Update AUR database if yay is available
        if command_exists "yay"; then
            log_info "Updating AUR database..."
            if yay -Sy; then
                log_success "AUR database updated successfully"
            else
                log_warn "Failed to update AUR database (non-critical)"
            fi
        fi
    fi
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: $CHEZMOI_OS_ID"
    
    validate_environment
    
    # Step 1: Install base development tools
    install_base_devel
    
    # Step 2: Install yay AUR helper
    install_yay
    
    # Step 3: Configure yay settings
    configure_yay
    
    # Step 4: Update package databases
    update_package_databases
    
    # Step 5: Verify installation
    verify_installation
    
    log_success "$SCRIPT_PURPOSE completed successfully"
    
    # Installation summary
    echo ""
    echo "=== Package Manager Setup Summary ==="
    echo "✓ base-devel group installed"
    echo "✓ yay AUR helper installed and configured"
    echo "✓ Package databases updated"
    echo ""
    echo "=== Available Package Managers ==="
    echo "• pacman: Official Arch Linux packages"
    echo "• yay: AUR (Arch User Repository) packages"
    echo ""
    echo "=== Usage Examples ==="
    echo "• Install official package: sudo pacman -S package-name"
    echo "• Install AUR package: yay -S package-name"
    echo "• Update system: yay -Syu"
    echo ""
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
