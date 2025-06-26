#!/bin/bash
# install-chezmoi-modify-manager.sh
# Purpose: Install chezmoi_modify_manager for INI file management
# Dependencies: yay (AUR helper)
# Environment: CHEZMOI_OS_ID
# OS Support: linux-arch
# Destination: all (work/leisure/test)

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Install chezmoi_modify_manager for INI file management"
readonly REQUIRED_COMMANDS=("yay")
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
    pacman -Qi "$package" >/dev/null 2>&1 || yay -Qi "$package" >/dev/null 2>&1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install chezmoi_modify_manager
install_chezmoi_modify_manager() {
    log_info "Installing chezmoi_modify_manager from AUR"
    
    if is_package_installed "chezmoi_modify_manager"; then
        log_info "chezmoi_modify_manager is already installed"
        return 0
    fi
    
    log_dry_run "install" "chezmoi_modify_manager via yay"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        log_info "Installing chezmoi_modify_manager from AUR..."
        if yay -S --noconfirm chezmoi_modify_manager; then
            log_success "chezmoi_modify_manager installed successfully"
        else
            error_exit "Failed to install chezmoi_modify_manager" 12 "PACKAGE" "Check AUR connectivity and build dependencies"
        fi
    fi
}

# Verify installation
verify_installation() {
    log_info "Verifying chezmoi_modify_manager installation"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Check if command is available
        if ! command_exists "chezmoi_modify_manager"; then
            error_exit "chezmoi_modify_manager command not found after installation" 15 "PACKAGE" "Check installation and PATH configuration"
        fi
        
        # Check if package is properly installed
        if ! is_package_installed "chezmoi_modify_manager"; then
            error_exit "chezmoi_modify_manager package not properly installed" 15 "PACKAGE" "Reinstall the package"
        fi
        
        # Test basic functionality
        if ! chezmoi_modify_manager --version >/dev/null 2>&1; then
            error_exit "chezmoi_modify_manager is not working correctly" 15 "PACKAGE" "Check package integrity"
        fi
        
        log_success "chezmoi_modify_manager installation verified"
    else
        log_info "Dry-run: Would verify chezmoi_modify_manager installation and functionality"
    fi
}

# Display usage information
show_usage_info() {
    log_info "Displaying chezmoi_modify_manager usage information"
    
    echo ""
    echo "=== chezmoi_modify_manager Installation Complete ==="
    echo ""
    echo "chezmoi_modify_manager is a tool for managing configuration files that contain"
    echo "both settings (that should be managed) and state (that should be ignored)."
    echo ""
    echo "=== Common Use Cases ==="
    echo "• KDE configuration files (kdeglobals, plasma settings)"
    echo "• Nextcloud client configuration"
    echo "• Application settings with mixed content"
    echo ""
    echo "=== Basic Usage ==="
    echo "1. Create a modify script: modify_config.tmpl"
    echo "2. Create a source file: config.src.ini"
    echo "3. Run: chezmoi_modify_manager modify_config.tmpl"
    echo ""
    echo "=== Example modify script ==="
    echo "#!/usr/bin/env chezmoi_modify_manager"
    echo "source auto"
    echo "ignore \"General\" \"ColorSchemeHash\""
    echo "set \"User\" \"Name\" \"John Doe\""
    echo ""
    echo "=== Documentation ==="
    echo "• chezmoi_modify_manager --help"
    echo "• See .clinerules/03-chezmoi-modify-manager-mastery.md"
    echo ""
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: $CHEZMOI_OS_ID"
    
    validate_environment
    
    install_chezmoi_modify_manager
    
    verify_installation
    
    show_usage_info
    
    log_success "$SCRIPT_PURPOSE completed successfully"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
