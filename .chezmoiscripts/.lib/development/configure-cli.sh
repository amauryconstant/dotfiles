#!/bin/bash
# configure-cli.sh
# Purpose: Generate tldr manuals and configure Docker permissions
# Dependencies: tldr, docker (optional)
# Environment: CHEZMOI_OS_ID, CHEZMOI_DESTINATION

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Generate tldr manuals and configure Docker permissions"
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID" "CHEZMOI_DESTINATION")

# Validation functions
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate OS
    [ "$CHEZMOI_OS_ID" = "linux-arch" ] || error_exit "Script for linux-arch, got: $CHEZMOI_OS_ID" 3 "ENVIRONMENT"
    
    log_debug "Environment validation passed"
}

# Configure tldr
configure_tldr() {
    log_info "Configuring tldr (too long; didn't read) manual pages"
    
    # Check if tldr is available
    if ! command -v tldr >/dev/null 2>&1; then
        log_warn "tldr command not found, skipping tldr configuration"
        log_info "Install tldr package to enable enhanced manual pages"
        return 0
    fi
    
    log_info "Generating tldr configuration"
    log_dry_run "generate" "tldr configuration file"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Get the config path and generate configuration
        local config_path
        if config_path=$(tldr --config-path 2>/dev/null); then
            log_debug "tldr config path: $config_path"
            
            if tldr --gen-config > "$config_path"; then
                log_success "Generated tldr configuration at $config_path"
            else
                log_error "Failed to generate tldr configuration"
                return 1
            fi
        else
            log_error "Failed to get tldr config path"
            return 1
        fi
    fi
    
    log_success "tldr configuration completed"
}

# Configure Docker permissions
configure_docker() {
    log_info "Configuring Docker permissions for user: $USER"
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        log_info "Docker not found, skipping Docker configuration"
        log_info "Install Docker package to enable container support"
        return 0
    fi
    
    # Check if user is already in docker group
    if id -nG "$USER" | grep -qw "docker"; then
        log_success "User $USER is already in docker group"
        return 0
    fi
    
    log_info "Adding user $USER to docker group"
    log_dry_run "add" "user $USER to docker group"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Create docker group if it doesn't exist
        if ! getent group docker >/dev/null 2>&1; then
            log_info "Creating docker group"
            if ! sudo groupadd docker; then
                error_exit "Failed to create docker group" 24 "USER_GROUP" "Check sudo permissions"
            fi
        fi
        
        # Add user to docker group
        if ! sudo usermod -aG docker "$USER"; then
            error_exit "Failed to add user to docker group" 24 "USER_GROUP" "Check sudo permissions and user existence"
        fi
        
        # Activate the group membership (for current session)
        log_info "Activating docker group membership for current session"
        if ! newgrp docker; then
            log_warn "Failed to activate docker group in current session"
            log_info "You may need to log out and log back in for Docker permissions to take effect"
        fi
    fi
    
    log_success "Docker permissions configured for user: $USER"
    log_info "Note: You may need to log out and log back in for changes to take full effect"
}

# Verify Docker configuration
verify_docker_config() {
    log_debug "Verifying Docker configuration"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" = "true" ]; then
        log_debug "Skipping Docker verification in dry-run mode"
        return 0
    fi
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        log_debug "Docker not available, skipping verification"
        return 0
    fi
    
    # Test Docker access without sudo
    log_debug "Testing Docker access without sudo"
    if docker version >/dev/null 2>&1; then
        log_success "Docker is accessible without sudo"
    else
        log_warn "Docker may require sudo or group membership is not active"
        log_info "Try: sudo docker version"
        log_info "Or log out and log back in to activate group membership"
    fi
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: $CHEZMOI_OS_ID, Destination: $CHEZMOI_DESTINATION"
    
    validate_environment
    
    configure_tldr
    configure_docker
    verify_docker_config
    
    log_success "$SCRIPT_PURPOSE completed successfully"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
