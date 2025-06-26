#!/bin/bash
# write-globals.sh
# Purpose: Write global environment variables to PAM configuration
# Dependencies: sudo, cp, rm, touch, grep, sed, tee
# Environment: CHEZMOI_GLOBALS_DATA
# OS Support: linux
# Destination: all

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Write global environment variables to PAM configuration"
readonly REQUIRED_COMMANDS=("sudo" "cp" "rm" "touch" "grep" "sed" "tee")
readonly REQUIRED_ENV_VARS=("CHEZMOI_GLOBALS_DATA")
readonly PAM_CONF_PATH="/etc/security/pam_env.conf"

# Validation functions
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required commands
    require_commands "${REQUIRED_COMMANDS[@]}"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate OS
    require_os "linux"
    
    # Check if PAM configuration directory exists
    if [ ! -d "/etc/security" ]; then
        error_exit "PAM security directory not found: /etc/security" \
                  $EXIT_SYSTEM_CONFIG_ERROR \
                  $CATEGORY_SYSTEM \
                  "Ensure PAM is installed and configured"
    fi
    
    log_debug "Environment validation passed"
}

# Backup existing PAM configuration
backup_pam_config() {
    log_info "Backing up PAM configuration"
    
    local backup_path="${PAM_CONF_PATH}.bck"
    
    log_dry_run "backup" "$PAM_CONF_PATH to $backup_path"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if [ -f "$PAM_CONF_PATH" ]; then
            if sudo cp -v "$PAM_CONF_PATH" "$backup_path"; then
                log_success "Backed up PAM configuration to $backup_path"
            else
                error_exit "Failed to backup PAM configuration" \
                          $EXIT_PERMISSION_DENIED \
                          $CATEGORY_SYSTEM \
                          "Check sudo permissions and disk space"
            fi
        else
            log_info "PAM configuration file does not exist, will create new one"
        fi
    fi
}

# Initialize PAM configuration file
initialize_pam_config() {
    log_info "Initializing PAM configuration file"
    
    log_dry_run "initialize" "$PAM_CONF_PATH"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Remove existing file and create new one
        if sudo rm -f "$PAM_CONF_PATH" && sudo touch "$PAM_CONF_PATH"; then
            log_success "Initialized PAM configuration file"
        else
            error_exit "Failed to initialize PAM configuration file" \
                      $EXIT_PERMISSION_DENIED \
                      $CATEGORY_SYSTEM \
                      "Check sudo permissions"
        fi
    fi
}

# Process and write environment variables
write_environment_variables() {
    log_info "Writing environment variables to PAM configuration"
    
    # Parse the globals data (expected format: KEY1=VALUE1,KEY2=VALUE2,...)
    local globals_data="$CHEZMOI_GLOBALS_DATA"
    
    if [ -z "$globals_data" ]; then
        log_warn "No globals data provided, skipping environment variable setup"
        return 0
    fi
    
    # Split by comma and process each key-value pair
    IFS=',' read -ra GLOBALS <<< "$globals_data"
    
    for global_entry in "${GLOBALS[@]}"; do
        # Split by equals sign
        if [[ "$global_entry" =~ ^([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Transform HOME placeholder to PAM format
            value="${value//HOME/@{HOME\}}"
            
            log_debug "Processing: $key = $value"
            
            write_pam_variable "$key" "$value"
        else
            log_warn "Invalid global entry format: $global_entry"
        fi
    done
    
    log_success "Environment variables written successfully"
}

# Write individual PAM variable
write_pam_variable() {
    local key="$1"
    local value="$2"
    
    log_dry_run "set" "PAM variable $key=$value"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Check if key already exists (not commented out)
        if sudo grep -q "^[^#]*$key " "$PAM_CONF_PATH"; then
            # Update existing line
            if sudo sed -i "/^[^#]*$key /c\\$key DEFAULT=$value" "$PAM_CONF_PATH"; then
                log_debug "Updated existing PAM variable: $key"
            else
                log_error "Failed to update PAM variable: $key"
                return 1
            fi
        else
            # Add new line
            if echo "$key DEFAULT=$value" | sudo tee -a "$PAM_CONF_PATH" >/dev/null; then
                log_debug "Added new PAM variable: $key"
            else
                log_error "Failed to add PAM variable: $key"
                return 1
            fi
        fi
        
        log_info "Set PAM variable: $key = $value"
    fi
}

# Validate PAM configuration
validate_pam_config() {
    log_info "Validating PAM configuration"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Check if file exists and is readable
        if [ -f "$PAM_CONF_PATH" ] && [ -r "$PAM_CONF_PATH" ]; then
            local line_count=$(sudo wc -l < "$PAM_CONF_PATH")
            log_success "PAM configuration validated: $line_count lines"
        else
            error_exit "PAM configuration file is not accessible" \
                      $EXIT_SYSTEM_CONFIG_ERROR \
                      $CATEGORY_SYSTEM \
                      "Check file permissions and existence"
        fi
    fi
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: ${CHEZMOI_OS_ID:-unknown}, Destination: ${CHEZMOI_DESTINATION:-unknown}"
    
    validate_environment
    
    backup_pam_config
    initialize_pam_config
    write_environment_variables
    validate_pam_config
    
    log_success "$SCRIPT_PURPOSE completed successfully"
    log_info "Note: Environment variables will be available after next login"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
