#!/bin/bash
# Error handling utilities for pure shell scripts
# Provides structured error reporting with standardized exit codes

# Source logging if available
if [ -f "$(dirname "$0")/logging-lib.sh" ]; then
    source "$(dirname "$0")/logging-lib.sh"
else
    # Fallback logging functions
    log_error() { echo "[ERROR] $1" >&2; }
    log_warn() { echo "[WARN] $1" >&2; }
    log_debug() { echo "[DEBUG] $1"; }
fi

# Exit code standards (only define if not already defined)
if [ -z "${EXIT_SUCCESS:-}" ]; then
    readonly EXIT_SUCCESS=0
    readonly EXIT_GENERAL_FAILURE=1
    readonly EXIT_INVALID_ARGS=2
    readonly EXIT_MISSING_DEPENDENCY=3
    readonly EXIT_PERMISSION_DENIED=4
    readonly EXIT_NETWORK_ERROR=5
    readonly EXIT_FILESYSTEM_ERROR=6
    readonly EXIT_CONFIG_ERROR=7
    readonly EXIT_PACKAGE_NOT_FOUND=11
    readonly EXIT_PACKAGE_INSTALL_FAILED=12
    readonly EXIT_PACKAGE_CONFLICT=13
    readonly EXIT_REPOSITORY_ERROR=14
    readonly EXIT_PACKAGE_MANAGER_UNAVAILABLE=15
    readonly EXIT_SERVICE_START_FAILED=21
    readonly EXIT_SERVICE_CONFIG_ERROR=22
    readonly EXIT_SYSTEM_CONFIG_ERROR=23
    readonly EXIT_USER_GROUP_ERROR=24
    readonly EXIT_ENCRYPTION_KEY_ERROR=31
    readonly EXIT_PERMISSION_SETUP_FAILED=32
    readonly EXIT_SECURITY_VALIDATION_FAILED=33
fi

# Error categories (only define if not already defined)
if [ -z "${CATEGORY_GENERAL:-}" ]; then
    readonly CATEGORY_GENERAL="GENERAL"
    readonly CATEGORY_ENVIRONMENT="ENVIRONMENT"
    readonly CATEGORY_DEPENDENCY="DEPENDENCY"
    readonly CATEGORY_PACKAGE="PACKAGE"
    readonly CATEGORY_SYSTEM="SYSTEM"
    readonly CATEGORY_SECURITY="SECURITY"
    readonly CATEGORY_NETWORK="NETWORK"
    readonly CATEGORY_FILESYSTEM="FILESYSTEM"
fi

# Error exit with structured message
error_exit() {
    local message="$1"
    local exit_code="${2:-$EXIT_GENERAL_FAILURE}"
    local category="${3:-$CATEGORY_GENERAL}"
    local suggestion="${4:-}"
    
    # Structured error format: "ERROR_CODE:CATEGORY:MESSAGE:SUGGESTION"
    local error_msg="$exit_code:$category:$message"
    [ -n "$suggestion" ] && error_msg="$error_msg:$suggestion"
    
    log_error "$error_msg"
    exit "$exit_code"
}

# Validate required commands
require_commands() {
    local missing_commands=()
    
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        error_exit "Missing required commands: ${missing_commands[*]}" \
                   "$EXIT_MISSING_DEPENDENCY" \
                   "$CATEGORY_DEPENDENCY" \
                   "Install missing commands and retry"
    fi
}

# Validate environment variables
require_env_vars() {
    local missing_vars=()
    
    for var in "$@"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        error_exit "Missing required environment variables: ${missing_vars[*]}" \
                   "$EXIT_INVALID_ARGS" \
                   "$CATEGORY_ENVIRONMENT" \
                   "Set required variables and retry"
    fi
}

# Validate OS compatibility (distribution-independent)
require_os() {
    local required_os="$1"
    local current_os="${CHEZMOI_OS:-unknown}"
    
    if [ "$current_os" != "$required_os" ]; then
        error_exit "Script requires OS '$required_os', got '$current_os'" \
                   "$EXIT_INVALID_ARGS" \
                   "$CATEGORY_ENVIRONMENT" \
                   "Run this script on the correct operating system"
    fi
}

# Validate OS ID compatibility (distribution-specific)
require_os_id() {
    local required_os_id="$1"
    local current_os_id="${CHEZMOI_OS_ID:-unknown}"
    
    if [ "$current_os_id" != "$required_os_id" ]; then
        error_exit "Script requires OS ID '$required_os_id', got '$current_os_id'" \
                   "$EXIT_INVALID_ARGS" \
                   "$CATEGORY_ENVIRONMENT" \
                   "Run this script on the correct operating system"
    fi
}

# Validate destination compatibility
require_destination() {
    local required_dest="$1"
    local current_dest="${CHEZMOI_DESTINATION:-unknown}"
    
    if [ "$current_dest" != "$required_dest" ]; then
        error_exit "Script requires destination '$required_dest', got '$current_dest'" \
                   "$EXIT_INVALID_ARGS" \
                   "$CATEGORY_ENVIRONMENT" \
                   "Run this script with the correct destination"
    fi
}

# Check if package manager is available
check_package_manager() {
    local manager="$1"
    
    case "$manager" in
        "pacman")
            if ! command -v pacman >/dev/null 2>&1; then
                error_exit "Pacman package manager not available" \
                           "$EXIT_PACKAGE_MANAGER_UNAVAILABLE" \
                           "$CATEGORY_PACKAGE" \
                           "Install pacman or run on Arch Linux"
            fi
            ;;
        "yay")
            if ! command -v yay >/dev/null 2>&1; then
                error_exit "Yay AUR helper not available" \
                           "$EXIT_PACKAGE_MANAGER_UNAVAILABLE" \
                           "$CATEGORY_PACKAGE" \
                           "Install yay AUR helper"
            fi
            ;;
        "dnf")
            if ! command -v dnf >/dev/null 2>&1; then
                error_exit "DNF package manager not available" \
                           "$EXIT_PACKAGE_MANAGER_UNAVAILABLE" \
                           "$CATEGORY_PACKAGE" \
                           "Install dnf or run on Fedora"
            fi
            ;;
        *)
            error_exit "Unknown package manager: $manager" \
                       "$EXIT_INVALID_ARGS" \
                       "$CATEGORY_PACKAGE" \
                       "Use a supported package manager"
            ;;
    esac
}

# Check if running as root when required
require_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "This script must be run as root" \
                   "$EXIT_PERMISSION_DENIED" \
                   "$CATEGORY_SECURITY" \
                   "Run with sudo or as root user"
    fi
}

# Check if NOT running as root when required
require_non_root() {
    if [ "$EUID" -eq 0 ]; then
        error_exit "This script must NOT be run as root" \
                   "$EXIT_PERMISSION_DENIED" \
                   "$CATEGORY_SECURITY" \
                   "Run as regular user, not root"
    fi
}

# Validate file exists and is readable
require_file() {
    local file="$1"
    local description="${2:-file}"
    
    if [ ! -f "$file" ]; then
        error_exit "$description not found: $file" \
                   "$EXIT_FILESYSTEM_ERROR" \
                   "$CATEGORY_FILESYSTEM" \
                   "Ensure the file exists and is accessible"
    fi
    
    if [ ! -r "$file" ]; then
        error_exit "$description not readable: $file" \
                   "$EXIT_PERMISSION_DENIED" \
                   "$CATEGORY_FILESYSTEM" \
                   "Check file permissions"
    fi
}

# Validate directory exists and is writable
require_writable_dir() {
    local dir="$1"
    local description="${2:-directory}"
    
    if [ ! -d "$dir" ]; then
        error_exit "$description not found: $dir" \
                   "$EXIT_FILESYSTEM_ERROR" \
                   "$CATEGORY_FILESYSTEM" \
                   "Create the directory first"
    fi
    
    if [ ! -w "$dir" ]; then
        error_exit "$description not writable: $dir" \
                   "$EXIT_PERMISSION_DENIED" \
                   "$CATEGORY_FILESYSTEM" \
                   "Check directory permissions"
    fi
}

# Handle package installation errors
handle_package_error() {
    local package="$1"
    local manager="$2"
    local exit_code="$3"
    
    case "$exit_code" in
        1)
            error_exit "Package '$package' not found in $manager repositories" \
                       "$EXIT_PACKAGE_NOT_FOUND" \
                       "$CATEGORY_PACKAGE" \
                       "Check package name or try alternative repositories"
            ;;
        2)
            error_exit "Package conflict while installing '$package'" \
                       "$EXIT_PACKAGE_CONFLICT" \
                       "$CATEGORY_PACKAGE" \
                       "Resolve package conflicts manually"
            ;;
        *)
            error_exit "Failed to install package '$package' via $manager" \
                       "$EXIT_PACKAGE_INSTALL_FAILED" \
                       "$CATEGORY_PACKAGE" \
                       "Try running: $manager -S $package"
            ;;
    esac
}

# Trap handler for cleanup on exit
cleanup_on_exit() {
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        log_error "Script exited with code $exit_code"
    fi
    
    # Perform any cleanup here
    # This function can be overridden by individual scripts
    
    exit $exit_code
}

# Set up trap for cleanup
trap cleanup_on_exit EXIT
