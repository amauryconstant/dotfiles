#!/bin/bash
# install-extensions.sh
# Purpose: Install VSCode extensions and configure Firefox policies
# Dependencies: code (VSCode), firefox (optional)
# Environment: CHEZMOI_OS_ID, CHEZMOI_DESTINATION, CHEZMOI_EXTENSIONS_ENABLED, CHEZMOI_EXTENSIONS_LIST, CHEZMOI_SOURCE_DIR

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Install VSCode extensions and configure Firefox policies"
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID" "CHEZMOI_DESTINATION" "CHEZMOI_EXTENSIONS_ENABLED" "CHEZMOI_SOURCE_DIR")

# Validation functions
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate OS
    [ "$CHEZMOI_OS_ID" = "linux-arch" ] || error_exit "Script for linux-arch, got: $CHEZMOI_OS_ID" 3 "ENVIRONMENT"
    
    log_debug "Environment validation passed"
}

# VSCode extension installation
install_vscode_extensions() {
    log_info "Installing VSCode extensions for destination: $CHEZMOI_DESTINATION"
    
    # Check if extensions are enabled for this destination
    if [ "$CHEZMOI_EXTENSIONS_ENABLED" != "true" ]; then
        log_info "Skipping VSCode extensions installation for destination: $CHEZMOI_DESTINATION"
        log_info "VSCode extensions are not configured for this destination type"
        return 0
    fi
    
    # Check if VSCode is available
    if ! command -v code >/dev/null 2>&1; then
        log_warn "VSCode not found, skipping extension installation"
        log_warn "Extensions are configured for $CHEZMOI_DESTINATION but VSCode is not installed"
        return 0
    fi
    
    # Parse and install extensions
    if [ -n "${CHEZMOI_EXTENSIONS_LIST:-}" ]; then
        IFS=',' read -ra EXTENSIONS <<< "$CHEZMOI_EXTENSIONS_LIST"
        
        for extension in "${EXTENSIONS[@]}"; do
            log_info "Installing extension: $extension"
            log_dry_run "install" "VSCode extension $extension"
            
            if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
                if ! code --force --install-extension "$extension"; then
                    log_error "Failed to install extension: $extension"
                    # Continue with other extensions rather than failing completely
                fi
            fi
        done
        
        log_success "VSCode extensions installation completed for $CHEZMOI_DESTINATION destination"
    else
        log_warn "No extensions list provided in CHEZMOI_EXTENSIONS_LIST"
    fi
}

# Firefox policies configuration
configure_firefox_policies() {
    log_info "Configuring Firefox policies"
    
    # Check if Firefox is available
    if ! command -v firefox >/dev/null 2>&1; then
        log_info "Firefox not found, skipping policies configuration"
        return 0
    fi
    
    local policies_source="$CHEZMOI_SOURCE_DIR/.data/firefox-policies.json"
    local policies_target="/etc/firefox/policies/policies.json"
    
    # Check if source policies file exists
    if [ ! -f "$policies_source" ]; then
        log_warn "Firefox policies source file not found: $policies_source"
        return 0
    fi
    
    log_info "Copying Firefox policies from $policies_source"
    log_dry_run "copy" "Firefox policies to $policies_target"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if ! sudo mkdir -p /etc/firefox/policies; then
            error_exit "Failed to create Firefox policies directory" 6 "FILESYSTEM" "Check permissions for /etc/firefox/policies"
        fi
        
        if ! sudo cp -v "$policies_source" "$policies_target"; then
            error_exit "Failed to copy Firefox policies" 6 "FILESYSTEM" "Check permissions and source file existence"
        fi
    fi
    
    log_success "Firefox policies configured"
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: $CHEZMOI_OS_ID, Destination: $CHEZMOI_DESTINATION"
    
    validate_environment
    
    install_vscode_extensions
    configure_firefox_policies
    
    log_success "$SCRIPT_PURPOSE completed successfully"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
