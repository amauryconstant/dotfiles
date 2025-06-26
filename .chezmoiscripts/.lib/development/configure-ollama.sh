#!/bin/bash
# configure-ollama.sh
# Purpose: Configure Ollama user, permissions, and service
# Dependencies: systemctl, useradd, usermod
# Environment: CHEZMOI_OS_ID, CHEZMOI_DESTINATION, CHEZMOI_OLLAMA_ENABLED, CHEZMOI_SOURCE_DIR

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Configure Ollama user, permissions, and service"
readonly REQUIRED_COMMANDS=("systemctl" "useradd" "usermod")
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID" "CHEZMOI_DESTINATION" "CHEZMOI_OLLAMA_ENABLED" "CHEZMOI_SOURCE_DIR")

# Validation functions
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate required commands
    require_commands "${REQUIRED_COMMANDS[@]}"
    
    # Validate OS
    [ "$CHEZMOI_OS_ID" = "linux-arch" ] || error_exit "Script for linux-arch, got: $CHEZMOI_OS_ID" 3 "ENVIRONMENT"
    
    log_debug "Environment validation passed"
}

# Create Ollama user
create_ollama_user() {
    log_info "Creating Ollama system user"
    
    # Check if ollama user already exists
    if id ollama >/dev/null 2>&1; then
        log_success "Ollama user already exists"
        return 0
    fi
    
    log_info "Creating system user 'ollama'"
    log_dry_run "create" "system user ollama with home directory /usr/share/ollama"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Create system user with specific parameters
        # -r: system user
        # -s /bin/false: no shell access
        # -U: create group with same name
        # -m: create home directory
        # -d: specify home directory
        if ! sudo useradd -r -s /bin/false -U -m -d /usr/share/ollama ollama; then
            error_exit "Failed to create ollama user" 24 "USER_GROUP" "Check sudo permissions and user creation policies"
        fi
    fi
    
    log_success "Created ollama system user"
}

# Configure user permissions
configure_user_permissions() {
    log_info "Configuring user permissions for Ollama"
    
    local current_user=$(whoami)
    
    # Check if current user is already in ollama group
    if id -nG "$current_user" | grep -qw "ollama"; then
        log_success "User $current_user is already in ollama group"
        return 0
    fi
    
    log_info "Adding user $current_user to ollama group"
    log_dry_run "add" "user $current_user to ollama group"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if ! sudo usermod -a -G ollama "$current_user"; then
            error_exit "Failed to add user to ollama group" 24 "USER_GROUP" "Check sudo permissions and group existence"
        fi
    fi
    
    log_success "Added user $current_user to ollama group"
    log_info "Note: You may need to log out and log back in for group membership to take effect"
}

# Install Ollama service
install_ollama_service() {
    log_info "Installing Ollama systemd service"
    
    local service_source="$CHEZMOI_SOURCE_DIR/.data/ollama.service"
    local service_target="/etc/systemd/system/ollama.service"
    
    # Check if service source file exists
    if [ ! -f "$service_source" ]; then
        log_warn "Ollama service file not found: $service_source"
        log_info "Skipping service installation"
        return 0
    fi
    
    log_info "Installing Ollama service from $service_source"
    log_dry_run "copy" "Ollama service file to $service_target"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Copy service file
        if ! sudo cp -v "$service_source" "$service_target"; then
            error_exit "Failed to copy Ollama service file" 6 "FILESYSTEM" "Check permissions and source file existence"
        fi
        
        # Reload systemd daemon
        log_info "Reloading systemd daemon"
        if ! sudo systemctl daemon-reload; then
            error_exit "Failed to reload systemd daemon" 21 "SERVICE" "Check systemctl permissions"
        fi
    fi
    
    log_success "Ollama service installed"
}

# Enable and start Ollama service
enable_ollama_service() {
    log_info "Enabling and starting Ollama service"
    
    log_dry_run "enable" "Ollama service (systemctl enable --now ollama)"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Enable and start the service
        if ! sudo systemctl enable --now ollama; then
            error_exit "Failed to enable and start Ollama service" 21 "SERVICE" "Check service file and systemctl permissions"
        fi
        
        # Wait a moment for service to start
        sleep 2
        
        # Verify service is running
        if systemctl is-active --quiet ollama; then
            log_success "Ollama service is running"
        else
            log_warn "Ollama service may not have started properly"
            log_info "Check service status: sudo systemctl status ollama"
        fi
    fi
    
    log_success "Ollama service enabled and started"
}

# Verify Ollama configuration
verify_ollama_config() {
    log_debug "Verifying Ollama configuration"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" = "true" ]; then
        log_debug "Skipping verification in dry-run mode"
        return 0
    fi
    
    # Check if ollama user exists
    if id ollama >/dev/null 2>&1; then
        log_success "Ollama user exists"
    else
        log_error "Ollama user does not exist"
    fi
    
    # Check if current user is in ollama group
    local current_user=$(whoami)
    if id -nG "$current_user" | grep -qw "ollama"; then
        log_success "User $current_user is in ollama group"
    else
        log_warn "User $current_user is not in ollama group"
    fi
    
    # Check service status
    if systemctl is-enabled --quiet ollama 2>/dev/null; then
        log_success "Ollama service is enabled"
    else
        log_warn "Ollama service is not enabled"
    fi
    
    if systemctl is-active --quiet ollama 2>/dev/null; then
        log_success "Ollama service is active"
    else
        log_warn "Ollama service is not active"
    fi
    
    # Test Ollama connectivity if available
    if command -v ollama >/dev/null 2>&1; then
        log_debug "Testing Ollama connectivity"
        if ollama list >/dev/null 2>&1; then
            log_success "Ollama is accessible and responding"
        else
            log_warn "Ollama may not be properly configured or accessible"
        fi
    else
        log_debug "Ollama command not available for testing"
    fi
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: $CHEZMOI_OS_ID, Destination: $CHEZMOI_DESTINATION"
    
    validate_environment
    
    # Check if Ollama is enabled for this destination
    if [ "$CHEZMOI_OLLAMA_ENABLED" != "true" ]; then
        log_info "Skipping Ollama configuration for destination: $CHEZMOI_DESTINATION"
        log_info "Ollama service is not configured for this destination type"
        return 0
    fi
    
    log_info "Configuring Ollama for destination: $CHEZMOI_DESTINATION"
    
    create_ollama_user
    configure_user_permissions
    install_ollama_service
    enable_ollama_service
    verify_ollama_config
    
    log_success "Ollama configuration completed for $CHEZMOI_DESTINATION destination"
    log_success "$SCRIPT_PURPOSE completed successfully"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
