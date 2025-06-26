#!/bin/bash
# create-directories.sh
# Purpose: Create necessary directories for XDG, SSH, keys, and synchronized files
# Dependencies: mkdir, chmod
# Environment: CHEZMOI_FIRSTNAME
# OS Support: linux
# Destination: all

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Create necessary directories for XDG, SSH, keys, and synchronized files"
readonly REQUIRED_COMMANDS=("mkdir" "chmod")
readonly REQUIRED_ENV_VARS=("CHEZMOI_FIRSTNAME")

# Directory definitions
readonly XDG_DIRECTORIES=(
    "$HOME/.local/bin"
    "$HOME/.local/pvm"
    "$HOME/.local/share"
    "$HOME/.local/state"
    "$HOME/.cache"
)

readonly SECURE_DIRECTORIES=(
    "$HOME/.ssh"
    "$HOME/.keys"
)

readonly SYNC_DIRECTORIES=(
    "$HOME/Synchronized"
)

# Validation functions
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required commands
    require_commands "${REQUIRED_COMMANDS[@]}"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate OS
    require_os "linux"
    
    # Validate HOME directory exists
    if [ ! -d "$HOME" ]; then
        error_exit "HOME directory not found: $HOME" \
                  $EXIT_FILESYSTEM_ERROR \
                  $CATEGORY_FILESYSTEM \
                  "Check user environment and permissions"
    fi
    
    log_debug "Environment validation passed"
}

# Create XDG directories
create_xdg_directories() {
    log_info "Creating XDG Base Directory specification directories"
    
    for dir in "${XDG_DIRECTORIES[@]}"; do
        create_directory "$dir" "755"
    done
    
    log_success "XDG directories created successfully"
}

# Create secure directories
create_secure_directories() {
    log_info "Creating secure directories for SSH and keys"
    
    for dir in "${SECURE_DIRECTORIES[@]}"; do
        create_directory "$dir" "700"
    done
    
    log_success "Secure directories created successfully"
}

# Create synchronization directories
create_sync_directories() {
    log_info "Creating synchronization directories"
    
    for dir in "${SYNC_DIRECTORIES[@]}"; do
        create_directory "$dir" "755"
    done
    
    log_success "Synchronization directories created successfully"
}

# Generic directory creation function
create_directory() {
    local dir="$1"
    local permissions="$2"
    
    log_dry_run "create" "directory: $dir (permissions: $permissions)"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if [ -d "$dir" ]; then
            log_debug "Directory already exists: $dir"
            
            # Ensure correct permissions
            if chmod "$permissions" "$dir"; then
                log_debug "Updated permissions for existing directory: $dir"
            else
                log_warn "Failed to update permissions for directory: $dir"
            fi
        else
            # Create directory
            if mkdir -p "$dir"; then
                log_success "Created directory: $dir"
                
                # Set permissions
                if chmod "$permissions" "$dir"; then
                    log_debug "Set permissions ($permissions) for directory: $dir"
                else
                    log_warn "Failed to set permissions for directory: $dir"
                fi
            else
                error_exit "Failed to create directory: $dir" \
                          $EXIT_FILESYSTEM_ERROR \
                          $CATEGORY_FILESYSTEM \
                          "Check parent directory permissions and disk space"
            fi
        fi
    fi
}

# Validate created directories
validate_directories() {
    log_info "Validating created directories"
    
    local validation_failed=false
    
    # Check XDG directories
    for dir in "${XDG_DIRECTORIES[@]}"; do
        if [ ! -d "$dir" ]; then
            log_error "XDG directory missing: $dir"
            validation_failed=true
        fi
    done
    
    # Check secure directories
    for dir in "${SECURE_DIRECTORIES[@]}"; do
        if [ ! -d "$dir" ]; then
            log_error "Secure directory missing: $dir"
            validation_failed=true
        else
            # Check permissions for secure directories
            local perms=$(stat -c "%a" "$dir" 2>/dev/null || echo "unknown")
            if [ "$perms" != "700" ]; then
                log_warn "Secure directory has incorrect permissions: $dir ($perms, expected 700)"
            fi
        fi
    done
    
    # Check sync directories
    for dir in "${SYNC_DIRECTORIES[@]}"; do
        if [ ! -d "$dir" ]; then
            log_error "Sync directory missing: $dir"
            validation_failed=true
        fi
    done
    
    if [ "$validation_failed" = "true" ]; then
        error_exit "Directory validation failed" \
                  $EXIT_FILESYSTEM_ERROR \
                  $CATEGORY_FILESYSTEM \
                  "Check directory creation and permissions"
    fi
    
    log_success "All directories validated successfully"
}

# Log directory summary
log_directory_summary() {
    log_info "Directory creation summary:"
    log_info "  XDG directories: ${#XDG_DIRECTORIES[@]} created"
    log_info "  Secure directories: ${#SECURE_DIRECTORIES[@]} created (permissions: 700)"
    log_info "  Sync directories: ${#SYNC_DIRECTORIES[@]} created"
    
    log_debug "XDG directories created:"
    for dir in "${XDG_DIRECTORIES[@]}"; do
        log_debug "  - $dir"
    done
    
    log_debug "Secure directories created:"
    for dir in "${SECURE_DIRECTORIES[@]}"; do
        log_debug "  - $dir (700)"
    done
    
    log_debug "Sync directories created:"
    for dir in "${SYNC_DIRECTORIES[@]}"; do
        log_debug "  - $dir"
    done
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: ${CHEZMOI_OS_ID:-unknown}, Destination: ${CHEZMOI_DESTINATION:-unknown}"
    log_debug "User: ${CHEZMOI_FIRSTNAME:-unknown}, HOME: $HOME"
    
    validate_environment
    
    create_xdg_directories
    create_secure_directories
    create_sync_directories
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        validate_directories
    fi
    
    log_directory_summary
    
    log_success "$SCRIPT_PURPOSE completed successfully"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
