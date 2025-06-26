#!/bin/bash
# setup-logging.sh
# Purpose: Set up unified logging system directory structure
# Dependencies: mkdir, touch, chmod, cat, find
# Environment: CHEZMOI_LOG_DIR, CHEZMOI_LOG_FILE
# OS Support: linux
# Destination: all

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Set up unified logging system directory structure"
readonly REQUIRED_COMMANDS=("mkdir" "touch" "chmod" "cat" "find")
readonly REQUIRED_ENV_VARS=("CHEZMOI_LOG_DIR" "CHEZMOI_LOG_FILE")

# Validation functions
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required commands
    require_commands "${REQUIRED_COMMANDS[@]}"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate OS
    require_os "linux"
    
    log_debug "Environment validation passed"
}

# Create log directory structure
create_log_directory() {
    log_info "Creating log directory structure"
    
    local log_dir="$CHEZMOI_LOG_DIR"
    
    log_dry_run "create" "log directory: $log_dir"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if mkdir -p "$log_dir"; then
            log_success "Created log directory: $log_dir"
        else
            error_exit "Failed to create log directory: $log_dir" \
                      $EXIT_FILESYSTEM_ERROR \
                      $CATEGORY_FILESYSTEM \
                      "Check directory permissions and disk space"
        fi
        
        # Set appropriate permissions
        if chmod 755 "$log_dir"; then
            log_debug "Set permissions on log directory"
        else
            log_warn "Failed to set permissions on log directory"
        fi
    fi
}

# Initialize log file
initialize_log_file() {
    log_info "Initializing log file"
    
    local log_file="$CHEZMOI_LOG_FILE"
    
    log_dry_run "create" "log file: $log_file"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if touch "$log_file"; then
            log_success "Initialized log file: $log_file"
        else
            error_exit "Failed to create log file: $log_file" \
                      $EXIT_FILESYSTEM_ERROR \
                      $CATEGORY_FILESYSTEM \
                      "Check directory permissions and disk space"
        fi
        
        # Set appropriate permissions
        if chmod 644 "$log_file"; then
            log_debug "Set permissions on log file"
        else
            log_warn "Failed to set permissions on log file"
        fi
    fi
}

# Create log rotation script
create_log_rotation_script() {
    log_info "Creating log rotation script"
    
    local log_dir="$CHEZMOI_LOG_DIR"
    local rotation_script="$log_dir/rotate_logs.sh"
    
    log_dry_run "create" "log rotation script: $rotation_script"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        cat > "$rotation_script" << 'EOF'
#!/bin/sh
# Log rotation script for chezmoi logs

LOG_DIR="$1"
MAX_FILES="${2:-10}"

if [ ! -d "$LOG_DIR" ]; then
    echo "Log directory does not exist: $LOG_DIR"
    exit 1
fi

# Rotate main log file
if [ -f "$LOG_DIR/chezmoi-setup.log" ]; then
    # Create dated backup
    DATE=$(date '+%Y-%m-%d')
    cp "$LOG_DIR/chezmoi-setup.log" "$LOG_DIR/chezmoi-setup-$DATE.log"
    
    # Clear main log file
    > "$LOG_DIR/chezmoi-setup.log"
    
    # Remove old log files (keep only MAX_FILES)
    find "$LOG_DIR" -name "chezmoi-setup-*.log" -type f | \
        sort -r | \
        tail -n +$((MAX_FILES + 1)) | \
        xargs rm -f
fi

echo "Log rotation completed"
EOF

        if [ $? -eq 0 ]; then
            log_success "Created log rotation script"
            
            # Make executable
            if chmod +x "$rotation_script"; then
                log_debug "Made log rotation script executable"
            else
                log_warn "Failed to make log rotation script executable"
            fi
        else
            error_exit "Failed to create log rotation script" \
                      $EXIT_FILESYSTEM_ERROR \
                      $CATEGORY_FILESYSTEM \
                      "Check directory permissions and disk space"
        fi
    fi
}

# Log system information for debugging
log_system_info() {
    log_debug "Logging system configuration for debugging"
    log_debug "log_dir=$CHEZMOI_LOG_DIR log_file=$CHEZMOI_LOG_FILE"
    log_debug "console_logging=${LOG_TO_CONSOLE:-true} file_logging=${LOG_TO_FILE:-true}"
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: ${CHEZMOI_OS_ID:-unknown}, Destination: ${CHEZMOI_DESTINATION:-unknown}"
    
    validate_environment
    
    create_log_directory
    initialize_log_file
    create_log_rotation_script
    log_system_info
    
    log_success "$SCRIPT_PURPOSE completed successfully"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
