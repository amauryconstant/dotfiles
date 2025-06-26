#!/bin/bash
# setup-os-specifics.sh
# Purpose: Install and configure OS-specific drivers and optimizations for EndeavourOS
# Dependencies: rate-mirrors, eos-update, yay, nvidia-inst
# Environment: CHEZMOI_OS_ID
# OS Support: linux-arch (EndeavourOS specifically)
# Destination: all (work/leisure/test)

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Install and configure OS-specific drivers and optimizations"
readonly REQUIRED_COMMANDS=("rate-mirrors" "eos-update" "yay" "nvidia-inst")
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID")

# Validation functions
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate OS match - this script is specifically for EndeavourOS
    [ "$CHEZMOI_OS_ID" = "linux-arch" ] || error_exit "Script for linux-arch, got: $CHEZMOI_OS_ID" 3 "ENVIRONMENT" "This script only supports Arch-based systems"
    
    # Check if this is actually EndeavourOS
    if [ -f "/etc/os-release" ]; then
        if ! grep -q "endeavouros" /etc/os-release; then
            log_warn "This script is optimized for EndeavourOS but will attempt to run on Arch-based system"
        fi
    fi
    
    log_debug "Environment validation passed"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update mirror list for better performance
update_mirrors() {
    log_info "Updating EndeavourOS mirror list for optimal performance"
    
    if ! command_exists "rate-mirrors"; then
        log_warn "rate-mirrors not available, skipping mirror optimization"
        return 0
    fi
    
    log_dry_run "update" "EndeavourOS mirror list using rate-mirrors"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        log_info "Running rate-mirrors to find fastest HTTPS mirrors..."
        if rate-mirrors --protocol https endeavouros | sudo tee /etc/pacman.d/endeavouros-mirrorlist; then
            log_success "Mirror list updated successfully"
        else
            log_warn "Failed to update mirror list (non-critical)"
        fi
    fi
}

# Perform system update
perform_system_update() {
    log_info "Performing comprehensive system update"
    
    if ! command_exists "eos-update"; then
        log_warn "eos-update not available, falling back to pacman"
        log_dry_run "update" "system packages using pacman"
        
        if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
            if sudo pacman -Syu --noconfirm; then
                log_success "System updated using pacman"
            else
                error_exit "Failed to update system using pacman" 14 "PACKAGE" "Check network connectivity and package conflicts"
            fi
        fi
        return 0
    fi
    
    log_dry_run "update" "system packages using eos-update"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        log_info "Running eos-update for comprehensive system update..."
        if eos-update; then
            log_success "System updated successfully using eos-update"
        else
            error_exit "Failed to update system using eos-update" 14 "PACKAGE" "Check network connectivity and resolve any conflicts manually"
        fi
    fi
}

# Install and configure NVIDIA drivers
setup_nvidia_drivers() {
    log_info "Setting up NVIDIA drivers and utilities"
    
    # Check if nvidia-inst is available
    if ! command_exists "nvidia-inst"; then
        log_warn "nvidia-inst not available, skipping NVIDIA driver setup"
        return 0
    fi
    
    # Install nvidia-inst if not already installed
    log_dry_run "install" "nvidia-inst package"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if ! pacman -Qi nvidia-inst >/dev/null 2>&1; then
            log_info "Installing nvidia-inst..."
            if ! yay -S --noconfirm nvidia-inst; then
                log_warn "Failed to install nvidia-inst (non-critical)"
                return 0
            fi
        fi
        
        # Run nvidia-inst to install appropriate drivers
        log_info "Running nvidia-inst to install NVIDIA drivers..."
        if nvidia-inst; then
            log_success "NVIDIA drivers installed successfully"
        else
            log_warn "NVIDIA driver installation failed or was skipped (non-critical)"
        fi
        
        # Run kernel-nvidia update check
        if command_exists "eos-kernel-nvidia-update-check"; then
            log_info "Running kernel-nvidia update check..."
            if eos-kernel-nvidia-update-check; then
                log_success "Kernel-NVIDIA compatibility verified"
            else
                log_warn "Kernel-NVIDIA update check reported issues (non-critical)"
            fi
        fi
    fi
}

# Verify system state after setup
verify_system_state() {
    log_info "Verifying system state after OS-specific setup"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Check if system is up to date
        local updates_available
        updates_available=$(pacman -Qu | wc -l)
        
        if [ "$updates_available" -eq 0 ]; then
            log_success "System is fully up to date"
        else
            log_warn "$updates_available package updates still available"
        fi
        
        # Check NVIDIA driver status if applicable
        if lspci | grep -i nvidia >/dev/null 2>&1; then
            if nvidia-smi >/dev/null 2>&1; then
                log_success "NVIDIA drivers are working correctly"
            else
                log_warn "NVIDIA hardware detected but drivers may not be properly configured"
            fi
        else
            log_info "No NVIDIA hardware detected"
        fi
        
        # Check kernel modules
        if lsmod | grep -q nvidia; then
            log_success "NVIDIA kernel modules loaded"
        elif lspci | grep -i nvidia >/dev/null 2>&1; then
            log_warn "NVIDIA hardware present but kernel modules not loaded"
        fi
    else
        log_info "Dry-run: Would verify system update status and driver configuration"
    fi
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: $CHEZMOI_OS_ID"
    
    validate_environment
    
    # Step 1: Update mirrors for better performance
    update_mirrors
    
    # Step 2: Perform comprehensive system update
    perform_system_update
    
    # Step 3: Setup NVIDIA drivers if applicable
    setup_nvidia_drivers
    
    # Step 4: Verify system state
    verify_system_state
    
    log_success "$SCRIPT_PURPOSE completed successfully"
    
    # Post-setup information
    echo ""
    echo "=== OS-Specific Setup Summary ==="
    echo "✓ Mirror list optimized (if rate-mirrors available)"
    echo "✓ System updated to latest packages"
    echo "✓ NVIDIA drivers configured (if hardware present)"
    echo ""
    echo "=== Next Steps ==="
    echo "1. Reboot system if kernel or driver updates were installed"
    echo "2. Verify graphics functionality after reboot"
    echo "3. Check 'nvidia-smi' output if NVIDIA hardware is present"
    echo ""
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
