#!/bin/bash
# Environment validation utilities for pure shell scripts
# Provides comprehensive validation of chezmoi environment and system state

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/logging-lib.sh"
source "$SCRIPT_DIR/error-handler.sh"

# Standard chezmoi environment variables that should be available
readonly REQUIRED_CHEZMOI_VARS=(
    "CHEZMOI_OS_ID"
    "CHEZMOI_DESTINATION"
    "CHEZMOI_SOURCE_DIR"
)

# Optional but commonly used chezmoi environment variables
readonly OPTIONAL_CHEZMOI_VARS=(
    "CHEZMOI_FIRSTNAME"
    "CHEZMOI_FULLNAME"
    "CHEZMOI_WORK_EMAIL"
    "CHEZMOI_PERSONAL_EMAIL"
    "CHEZMOI_PRIVATE_SERVER"
    "CHEZMOI_LOG_LEVEL"
    "CHEZMOI_DRY_RUN"
    "CHEZMOI_VERBOSE"
)

# Validate basic chezmoi environment
validate_chezmoi_environment() {
    log_debug "Validating chezmoi environment"
    
    # Check required variables
    require_env_vars "${REQUIRED_CHEZMOI_VARS[@]}"
    
    # Validate source directory exists
    if [ ! -d "${CHEZMOI_SOURCE_DIR}" ]; then
        error_exit "Chezmoi source directory not found: ${CHEZMOI_SOURCE_DIR}" \
                   "$EXIT_FILESYSTEM_ERROR" \
                   "$CATEGORY_ENVIRONMENT" \
                   "Ensure chezmoi is properly initialized"
    fi
    
    log_debug "Chezmoi environment validation passed"
}

# Validate OS compatibility
validate_os_compatibility() {
    local required_os="$1"
    
    log_debug "Validating OS compatibility (required: $required_os)"
    
    require_os "$required_os"
    
    # Additional OS-specific validations
    case "$required_os" in
        "linux-arch")
            # Validate Arch Linux specific requirements
            require_commands "pacman"
            
            # Check if we're actually on Arch or Arch-based system
            if [ ! -f "/etc/arch-release" ] && [ ! -f "/etc/endeavouros-release" ]; then
                log_warn "OS ID is 'linux-arch' but system doesn't appear to be Arch-based"
                log_warn "This may cause package installation issues"
            fi
            ;;
        "linux-fedora")
            # Validate Fedora specific requirements
            require_commands "dnf"
            
            # Check if we're actually on Fedora or RHEL-based system
            if [ ! -f "/etc/fedora-release" ] && [ ! -f "/etc/redhat-release" ]; then
                log_warn "OS ID is 'linux-fedora' but system doesn't appear to be Fedora/RHEL-based"
                log_warn "This may cause package installation issues"
            fi
            ;;
        *)
            log_warn "Unknown OS ID: $required_os"
            ;;
    esac
    
    log_debug "OS compatibility validation passed"
}

# Validate destination configuration
validate_destination() {
    local required_dest="$1"
    
    log_debug "Validating destination (required: $required_dest)"
    
    require_destination "$required_dest"
    
    # Validate destination is one of the known types
    case "$required_dest" in
        "work"|"leisure"|"test")
            log_debug "Valid destination: $required_dest"
            ;;
        *)
            log_warn "Unknown destination: $required_dest"
            log_warn "Expected one of: work, leisure, test"
            ;;
    esac
    
    log_debug "Destination validation passed"
}

# Validate package management environment
validate_package_environment() {
    local os_id="${CHEZMOI_OS_ID}"
    
    log_debug "Validating package management environment for $os_id"
    
    case "$os_id" in
        "linux-arch")
            # Check pacman
            check_package_manager "pacman"
            
            # Check if yay is available (optional but recommended)
            if ! command -v yay >/dev/null 2>&1; then
                log_warn "Yay AUR helper not available - AUR packages cannot be installed"
                log_warn "Install yay for full package management capabilities"
            fi
            
            # Check if pacman database is up to date
            local db_age=$(find /var/.lib/pacman/sync -name "*.db" -mtime +1 | wc -l)
            if [ "$db_age" -gt 0 ]; then
                log_warn "Pacman database may be outdated (>1 day old)"
                log_warn "Consider running 'sudo pacman -Sy' to update"
            fi
            ;;
        "linux-fedora")
            # Check dnf
            check_package_manager "dnf"
            
            # Check if flatpak is available (optional)
            if ! command -v flatpak >/dev/null 2>&1; then
                log_warn "Flatpak not available - some packages may not be installable"
            fi
            ;;
        *)
            log_warn "Package management validation not implemented for OS: $os_id"
            ;;
    esac
    
    log_debug "Package management environment validation passed"
}

# Validate user permissions and context
validate_user_context() {
    log_debug "Validating user context"
    
    # Check if running as root (usually not desired for chezmoi scripts)
    if [ "$EUID" -eq 0 ]; then
        log_warn "Running as root - this may cause permission issues with user files"
        log_warn "Consider running as regular user unless root access is specifically required"
    fi
    
    # Check if user has sudo access (often needed for package installation)
    if ! sudo -n true 2>/dev/null; then
        log_warn "User does not have passwordless sudo access"
        log_warn "Package installation may require password prompts"
    fi
    
    # Validate home directory access
    if [ ! -w "$HOME" ]; then
        error_exit "Home directory not writable: $HOME" \
                   "$EXIT_PERMISSION_DENIED" \
                   "$CATEGORY_FILESYSTEM" \
                   "Check home directory permissions"
    fi
    
    log_debug "User context validation passed"
}

# Validate system resources
validate_system_resources() {
    log_debug "Validating system resources"
    
    # Check available disk space (warn if less than 1GB free)
    local available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 1048576 ]; then  # 1GB in KB
        log_warn "Low disk space available: $(($available_space / 1024))MB"
        log_warn "Package installation may fail due to insufficient space"
    fi
    
    # Check if system is up to date (Arch-specific)
    if [ "${CHEZMOI_OS_ID}" = "linux-arch" ]; then
        local updates_available=$(pacman -Qu 2>/dev/null | wc -l)
        if [ "$updates_available" -gt 0 ]; then
            log_warn "$updates_available system updates available"
            log_warn "Consider updating system before installing new packages"
        fi
    fi
    
    log_debug "System resources validation passed"
}

# Comprehensive validation function
validate_script_environment() {
    local required_os="$1"
    local required_dest="$2"
    local check_packages="${3:-true}"
    
    log_step "Validating script environment"
    
    # Core validations
    validate_chezmoi_environment
    validate_os_compatibility "$required_os"
    validate_destination "$required_dest"
    validate_user_context
    
    # Optional validations
    if [ "$check_packages" = "true" ]; then
        validate_package_environment
    fi
    
    validate_system_resources
    
    log_success "Script environment validation completed"
}

# Quick validation for simple scripts
validate_basic_environment() {
    local required_os="$1"
    local required_dest="$2"
    
    log_debug "Performing basic environment validation"
    
    require_env_vars "CHEZMOI_OS_ID" "CHEZMOI_DESTINATION"
    require_os "$required_os"
    require_destination "$required_dest"
    
    log_debug "Basic environment validation passed"
}

# Display environment information for debugging
show_environment_info() {
    log_info "Environment Information:"
    log_info "  OS ID: ${CHEZMOI_OS_ID:-not set}"
    log_info "  Destination: ${CHEZMOI_DESTINATION:-not set}"
    log_info "  Source Dir: ${CHEZMOI_SOURCE_DIR:-not set}"
    log_info "  User: $(whoami)"
    log_info "  Home: $HOME"
    log_info "  PWD: $PWD"
    
    if [ "${CHEZMOI_VERBOSE:-false}" = "true" ]; then
        log_debug "Extended Environment:"
        log_debug "  First Name: ${CHEZMOI_FIRSTNAME:-not set}"
        log_debug "  Full Name: ${CHEZMOI_FULLNAME:-not set}"
        log_debug "  Work Email: ${CHEZMOI_WORK_EMAIL:-not set}"
        log_debug "  Personal Email: ${CHEZMOI_PERSONAL_EMAIL:-not set}"
        log_debug "  Private Server: ${CHEZMOI_PRIVATE_SERVER:-not set}"
        log_debug "  Log Level: ${CHEZMOI_LOG_LEVEL:-not set}"
        log_debug "  Dry Run: ${CHEZMOI_DRY_RUN:-not set}"
    fi
}
