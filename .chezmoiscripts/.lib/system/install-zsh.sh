#!/bin/bash
# install-zsh.sh
# Purpose: Install zsh, ghostty terminal, and starship prompt
# Dependencies: yay, chsh, which
# Environment: CHEZMOI_OS_ID
# OS Support: linux-arch
# Destination: all

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Install zsh, ghostty terminal, and starship prompt"
readonly REQUIRED_COMMANDS=("yay" "chsh" "which")
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID")

# Package definitions
readonly ZSH_PACKAGES=(
    "ghostty"
    "zsh"
    "zsh-antidote"
    "starship"
)

# Validation functions
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required commands
    require_commands "${REQUIRED_COMMANDS[@]}"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate OS (Arch Linux specific)
    require_os "linux-arch"
    
    log_debug "Environment validation passed"
}

# Check if packages are already installed
check_package_status() {
    log_info "Checking package installation status"
    
    local packages_to_install=()
    local packages_already_installed=()
    
    for package in "${ZSH_PACKAGES[@]}"; do
        if yay -Qi "$package" >/dev/null 2>&1; then
            packages_already_installed+=("$package")
            log_debug "Package already installed: $package"
        else
            packages_to_install+=("$package")
            log_debug "Package needs installation: $package"
        fi
    done
    
    if [ ${#packages_already_installed[@]} -gt 0 ]; then
        log_info "Already installed: ${packages_already_installed[*]}"
    fi
    
    if [ ${#packages_to_install[@]} -gt 0 ]; then
        log_info "Need to install: ${packages_to_install[*]}"
        return 0  # Packages need installation
    else
        log_success "All zsh packages are already installed"
        return 1  # No packages need installation
    fi
}

# Install zsh packages
install_zsh_packages() {
    log_info "Installing zsh and terminal environment packages"
    
    local packages="${ZSH_PACKAGES[*]}"
    
    log_dry_run "install" "$packages via yay"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if yay -S --noconfirm "${ZSH_PACKAGES[@]}"; then
            log_success "Successfully installed zsh packages"
        else
            error_exit "Failed to install zsh packages" \
                      $EXIT_PACKAGE_INSTALL_FAILED \
                      $CATEGORY_PACKAGE \
                      "Try running: yay -S ${ZSH_PACKAGES[*]}"
        fi
    fi
}

# Change default shell to zsh
change_shell_to_zsh() {
    log_info "Changing default shell to zsh"
    
    # Get current shell
    local current_shell=$(getent passwd "$USER" | cut -d: -f7)
    local zsh_path=$(which zsh)
    
    log_debug "Current shell: $current_shell"
    log_debug "Zsh path: $zsh_path"
    
    if [ "$current_shell" = "$zsh_path" ]; then
        log_success "Default shell is already zsh"
        return 0
    fi
    
    log_dry_run "change" "default shell to zsh ($zsh_path)"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if chsh -s "$zsh_path"; then
            log_success "Default shell changed to zsh"
            log_info "Note: You may need to log out and back in for the shell change to take effect"
        else
            # Non-fatal error - user can change shell manually
            log_warn "Failed to change default shell to zsh - you may need to do this manually"
            log_info "To change shell manually, run: chsh -s $zsh_path"
        fi
    fi
}

# Verify zsh installation
verify_zsh_installation() {
    log_info "Verifying zsh installation"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Check if zsh is installed and executable
        if command -v zsh >/dev/null 2>&1; then
            local zsh_version=$(zsh --version 2>/dev/null | head -1)
            log_success "Zsh is installed and accessible: $zsh_version"
        else
            error_exit "Zsh installation verification failed" \
                      $EXIT_PACKAGE_INSTALL_FAILED \
                      $CATEGORY_PACKAGE \
                      "Check if zsh package was installed correctly"
        fi
        
        # Check if starship is installed
        if command -v starship >/dev/null 2>&1; then
            local starship_version=$(starship --version 2>/dev/null | head -1)
            log_success "Starship is installed and accessible: $starship_version"
        else
            log_warn "Starship installation verification failed"
        fi
        
        # Check if ghostty is installed
        if command -v ghostty >/dev/null 2>&1; then
            log_success "Ghostty terminal is installed and accessible"
        else
            log_warn "Ghostty installation verification failed"
        fi
    fi
}

# Log installation summary
log_installation_summary() {
    log_info "Zsh installation summary:"
    log_info "  Packages installed: ${#ZSH_PACKAGES[@]}"
    log_info "  Shell configuration: zsh set as default"
    log_info "  Terminal emulator: ghostty"
    log_info "  Prompt: starship"
    log_info "  Plugin manager: zsh-antidote"
    
    log_debug "Installed packages:"
    for package in "${ZSH_PACKAGES[@]}"; do
        log_debug "  - $package"
    done
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: ${CHEZMOI_OS_ID:-unknown}, Destination: ${CHEZMOI_DESTINATION:-unknown}"
    
    validate_environment
    
    # Check if installation is needed
    if check_package_status; then
        install_zsh_packages
    fi
    
    change_shell_to_zsh
    verify_zsh_installation
    log_installation_summary
    
    log_success "$SCRIPT_PURPOSE completed successfully"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
