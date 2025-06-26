#!/bin/bash
# install-ai-models.sh
# Purpose: Install AI models using Ollama
# Dependencies: ollama
# Environment: CHEZMOI_OS_ID, CHEZMOI_DESTINATION, CHEZMOI_AI_MODELS_ENABLED, CHEZMOI_AI_MODELS_LIST

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Install AI models using Ollama"
readonly REQUIRED_COMMANDS=("ollama")
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID" "CHEZMOI_DESTINATION" "CHEZMOI_AI_MODELS_ENABLED")

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

# AI models installation
install_ai_models() {
    log_info "Installing AI models for destination: $CHEZMOI_DESTINATION"
    
    # Check if AI models are enabled for this destination
    if [ "$CHEZMOI_AI_MODELS_ENABLED" != "true" ]; then
        log_info "Skipping AI models installation for destination: $CHEZMOI_DESTINATION"
        log_info "AI models are not configured for this destination type"
        return 0
    fi
    
    # Parse and install AI models
    if [ -n "${CHEZMOI_AI_MODELS_LIST:-}" ]; then
        IFS=',' read -ra MODELS <<< "$CHEZMOI_AI_MODELS_LIST"
        
        local total_models=${#MODELS[@]}
        local current_model=0
        
        for model in "${MODELS[@]}"; do
            current_model=$((current_model + 1))
            log_progress $current_model $total_models "Installing AI model: $model"
            log_dry_run "pull" "AI model $model via ollama"
            
            if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
                if ! ollama pull "$model"; then
                    log_error "Failed to install AI model: $model"
                    # Continue with other models rather than failing completely
                    continue
                fi
            fi
            
            log_success "Successfully installed AI model: $model"
        done
        
        log_success "AI models installation completed for $CHEZMOI_DESTINATION destination"
    else
        log_warn "No AI models list provided in CHEZMOI_AI_MODELS_LIST"
    fi
}

# Verify Ollama service
verify_ollama_service() {
    log_info "Verifying Ollama service status"
    
    # Check if Ollama service is running
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet ollama; then
            log_success "Ollama service is running"
        else
            log_warn "Ollama service is not running"
            log_info "You may need to start the Ollama service: sudo systemctl start ollama"
        fi
    else
        log_debug "systemctl not available, skipping service check"
    fi
    
    # Test Ollama connectivity
    log_debug "Testing Ollama connectivity"
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if ollama list >/dev/null 2>&1; then
            log_success "Ollama is accessible and responding"
        else
            log_warn "Ollama may not be properly configured or running"
        fi
    fi
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: $CHEZMOI_OS_ID, Destination: $CHEZMOI_DESTINATION"
    
    validate_environment
    verify_ollama_service
    install_ai_models
    
    log_success "$SCRIPT_PURPOSE completed successfully"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
