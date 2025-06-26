#!/bin/bash
# create-git-hooks.sh
# Purpose: Install git hooks from the .gitscripts directory to .git/hooks
# Dependencies: git
# Environment: CHEZMOI_OS_ID, CHEZMOI_SOURCE_DIR

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Install git hooks from .gitscripts directory"
readonly REQUIRED_COMMANDS=("git")
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID" "CHEZMOI_SOURCE_DIR")

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

# Validate git repository and directories
validate_git_setup() {
    local hooks_dir="$CHEZMOI_SOURCE_DIR/.git/hooks"
    local source_hooks_dir="$CHEZMOI_SOURCE_DIR/.gitscripts"
    
    log_debug "Validating git repository setup"
    
    # Check if we're in a git repository
    if [ ! -d "$CHEZMOI_SOURCE_DIR/.git" ]; then
        error_exit "Not in a git repository: $CHEZMOI_SOURCE_DIR/.git does not exist" 7 "CONFIG" "Ensure you're running from a git repository"
    fi
    
    # Check if hooks directory exists
    if [ ! -d "$hooks_dir" ]; then
        error_exit "Git hooks directory does not exist: $hooks_dir" 6 "FILESYSTEM" "Initialize git repository properly"
    fi
    
    # Check if source hooks directory exists
    if [ ! -d "$source_hooks_dir" ]; then
        log_warn "Source hooks directory does not exist: $source_hooks_dir"
        log_info "No git hooks to install"
        return 1
    fi
    
    # Check if source hooks directory has any files
    if [ -z "$(ls -A "$source_hooks_dir" 2>/dev/null)" ]; then
        log_info "Source hooks directory is empty: $source_hooks_dir"
        log_info "No git hooks to install"
        return 1
    fi
    
    log_debug "Git repository setup validation passed"
    return 0
}

# Install git hooks
install_git_hooks() {
    local hooks_dir="$CHEZMOI_SOURCE_DIR/.git/hooks"
    local source_hooks_dir="$CHEZMOI_SOURCE_DIR/.gitscripts"
    
    log_info "Installing git hooks from $source_hooks_dir to $hooks_dir"
    
    local hooks_installed=0
    local hooks_failed=0
    
    for hook_file in "$source_hooks_dir"/*; do
        # Skip if no files match the pattern
        [ -e "$hook_file" ] || continue
        
        local hook_name=$(basename "$hook_file")
        local target_hook="$hooks_dir/$hook_name"
        
        log_info "Installing $hook_name hook"
        log_dry_run "install" "git hook $hook_name from $hook_file to $target_hook"
        
        if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
            # Copy the hook file
            if ! cp "$hook_file" "$target_hook"; then
                log_error "Failed to copy hook: $hook_name"
                hooks_failed=$((hooks_failed + 1))
                continue
            fi
            
            # Make the hook executable
            if ! chmod +x "$target_hook"; then
                log_error "Failed to make hook executable: $hook_name"
                hooks_failed=$((hooks_failed + 1))
                continue
            fi
        fi
        
        log_success "Successfully installed hook: $hook_name"
        hooks_installed=$((hooks_installed + 1))
    done
    
    # Report results
    if [ $hooks_installed -gt 0 ]; then
        log_success "Successfully installed $hooks_installed git hooks"
    fi
    
    if [ $hooks_failed -gt 0 ]; then
        log_error "Failed to install $hooks_failed git hooks"
        error_exit "Some git hooks failed to install" 6 "FILESYSTEM" "Check file permissions and disk space"
    fi
    
    if [ $hooks_installed -eq 0 ] && [ $hooks_failed -eq 0 ]; then
        log_info "No git hooks found to install"
    fi
}

# Verify installed hooks
verify_installed_hooks() {
    local hooks_dir="$CHEZMOI_SOURCE_DIR/.git/hooks"
    
    log_debug "Verifying installed git hooks"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" = "true" ]; then
        log_debug "Skipping verification in dry-run mode"
        return 0
    fi
    
    local verified_hooks=0
    
    for hook_file in "$hooks_dir"/*; do
        # Skip if no files match the pattern or if it's a sample file
        [ -e "$hook_file" ] || continue
        [[ "$(basename "$hook_file")" == *.sample ]] && continue
        
        local hook_name=$(basename "$hook_file")
        
        # Check if hook is executable
        if [ -x "$hook_file" ]; then
            log_debug "Verified hook: $hook_name (executable)"
            verified_hooks=$((verified_hooks + 1))
        else
            log_warn "Hook not executable: $hook_name"
        fi
    done
    
    if [ $verified_hooks -gt 0 ]; then
        log_success "Verified $verified_hooks executable git hooks"
    fi
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "Source directory: $CHEZMOI_SOURCE_DIR"
    
    validate_environment
    
    if validate_git_setup; then
        install_git_hooks
        verify_installed_hooks
        log_success "All git hooks installed successfully"
    else
        log_info "No git hooks to install or setup validation failed"
    fi
    
    log_success "$SCRIPT_PURPOSE completed successfully"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
