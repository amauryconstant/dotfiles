#!/bin/bash
# instantiate-encryption-key.sh
# Purpose: Retrieve and configure encryption key from Bitwarden/Vaultwarden
# Dependencies: rbw (Rust Bitwarden CLI)
# Environment: CHEZMOI_PERSONAL_EMAIL, CHEZMOI_PRIVATE_SERVER
# OS Support: linux-arch
# Destination: all (work/leisure/test)

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Retrieve and configure encryption key from Vaultwarden"
readonly REQUIRED_COMMANDS=("rbw")
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID" "CHEZMOI_PERSONAL_EMAIL" "CHEZMOI_PRIVATE_SERVER")

# Validation functions
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required commands
    require_commands "${REQUIRED_COMMANDS[@]}"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate OS match
    [ "$CHEZMOI_OS_ID" = "linux-arch" ] || error_exit "Script for linux-arch, got: $CHEZMOI_OS_ID" 3 "ENVIRONMENT" "This script only supports Arch Linux"
    
    # Validate keys directory exists
    if [ ! -d "$HOME/.keys" ]; then
        error_exit "Keys directory does not exist: $HOME/.keys" 6 "FILESYSTEM" "Ensure create-directories script has run first"
    fi
    
    log_debug "Environment validation passed"
}

# Configure Bitwarden client
configure_rbw() {
    log_info "Configuring Bitwarden client (rbw)"
    
    # Extract vaultwarden server URL
    local vaultwarden_url
    vaultwarden_url=$(echo "$CHEZMOI_PRIVATE_SERVER" | sed 's/www/vaultwarden/')
    
    log_debug "Setting rbw email: $CHEZMOI_PERSONAL_EMAIL"
    log_dry_run "configure" "rbw email to $CHEZMOI_PERSONAL_EMAIL"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if ! rbw config set email "$CHEZMOI_PERSONAL_EMAIL"; then
            error_exit "Failed to configure rbw email" 7 "CONFIG" "Check rbw installation and permissions"
        fi
    fi
    
    log_debug "Setting rbw base URL: $vaultwarden_url"
    log_dry_run "configure" "rbw base URL to $vaultwarden_url"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if ! rbw config set base_url "$vaultwarden_url"; then
            error_exit "Failed to configure rbw base URL" 7 "CONFIG" "Check vaultwarden server accessibility"
        fi
    fi
    
    log_success "Bitwarden client configured successfully"
}

# Authenticate and retrieve key
retrieve_encryption_key() {
    log_info "Authenticating with Vaultwarden and retrieving encryption key"
    
    log_dry_run "authenticate" "rbw login and sync"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Login to Bitwarden
        log_info "Logging in to Bitwarden (interactive authentication required)"
        if ! rbw login; then
            error_exit "Failed to login to Bitwarden" 31 "SECURITY" "Check credentials and server connectivity"
        fi
        
        # Sync vault
        log_info "Syncing Bitwarden vault"
        if ! rbw sync; then
            error_exit "Failed to sync Bitwarden vault" 5 "NETWORK" "Check network connectivity to vaultwarden server"
        fi
        
        # Retrieve dotfiles key
        log_info "Retrieving dotfiles encryption key"
        if ! rbw get dotfiles-key > "$HOME/.keys/dotfiles-key.txt"; then
            error_exit "Failed to retrieve dotfiles-key from vault" 31 "SECURITY" "Ensure 'dotfiles-key' entry exists in vault"
        fi
        
        # Lock vault for security
        log_info "Locking Bitwarden vault"
        rbw lock || log_warn "Failed to lock vault (non-critical)"
        
        # Set secure permissions
        log_info "Setting secure permissions on key files"
        if ! chmod 600 "$HOME/.keys"/*; then
            error_exit "Failed to set secure permissions on key files" 32 "SECURITY" "Check file ownership and permissions"
        fi
        
        log_success "Encryption key retrieved and secured successfully"
    fi
}

# Verify key installation
verify_key_installation() {
    log_info "Verifying encryption key installation"
    
    local key_file="$HOME/.keys/dotfiles-key.txt"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Check key file exists
        if [ ! -f "$key_file" ]; then
            error_exit "Encryption key file not found: $key_file" 31 "SECURITY" "Key retrieval may have failed"
        fi
        
        # Check key file permissions
        local perms
        perms=$(stat -c "%a" "$key_file")
        if [ "$perms" != "600" ]; then
            error_exit "Incorrect permissions on key file: $perms (expected: 600)" 32 "SECURITY" "Run chmod 600 on key file"
        fi
        
        # Check key file is not empty
        if [ ! -s "$key_file" ]; then
            error_exit "Encryption key file is empty" 31 "SECURITY" "Key retrieval failed or vault entry is empty"
        fi
        
        log_success "Encryption key installation verified"
    else
        log_info "Dry-run: Would verify key file existence, permissions, and content"
    fi
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: $CHEZMOI_OS_ID"
    log_debug "Email: $CHEZMOI_PERSONAL_EMAIL"
    log_debug "Server: $CHEZMOI_PRIVATE_SERVER"
    
    validate_environment
    
    configure_rbw
    
    retrieve_encryption_key
    
    verify_key_installation
    
    log_success "$SCRIPT_PURPOSE completed successfully"
    
    # Security reminder
    echo ""
    echo "=== Security Notice ==="
    echo "Encryption key has been retrieved and secured in ~/.keys/"
    echo "This key is used for chezmoi age encryption/decryption"
    echo "Keep this key secure and backed up safely"
    echo ""
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
