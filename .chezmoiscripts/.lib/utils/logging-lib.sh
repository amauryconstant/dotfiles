#!/bin/bash
# Simplified logging library for pure shell scripts
# Integrates with chezmoi logging system through environment variables

# Configuration from environment
LOG_LEVEL="${CHEZMOI_LOG_LEVEL:-INFO}"
DRY_RUN="${CHEZMOI_DRY_RUN:-false}"
VERBOSE="${CHEZMOI_VERBOSE:-false}"
SCRIPT_NAME="$(basename "$0" .sh)"

# Log level hierarchy: DEBUG < INFO < WARN < ERROR
declare -A LOG_LEVELS=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
CURRENT_LEVEL=${LOG_LEVELS[$LOG_LEVEL]}

# Color codes (respect NO_COLOR environment variable)
if [ -z "${NO_COLOR:-}" ] && [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    NC=''
fi

# Timestamp function
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Core logging functions
log_debug() {
    [ ${LOG_LEVELS[DEBUG]} -ge $CURRENT_LEVEL ] && echo -e "${CYAN}[$(timestamp)] [DEBUG] [$SCRIPT_NAME] 🔍 $1${NC}"
}

log_info() {
    [ ${LOG_LEVELS[INFO]} -ge $CURRENT_LEVEL ] && echo -e "${BLUE}[$(timestamp)] [INFO] [$SCRIPT_NAME] ℹ $1${NC}"
}

log_warn() {
    [ ${LOG_LEVELS[WARN]} -ge $CURRENT_LEVEL ] && echo -e "${YELLOW}[$(timestamp)] [WARN] [$SCRIPT_NAME] ⚠ $1${NC}" >&2
}

log_error() {
    [ ${LOG_LEVELS[ERROR]} -ge $CURRENT_LEVEL ] && echo -e "${RED}[$(timestamp)] [ERROR] [$SCRIPT_NAME] ✗ $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[$(timestamp)] [SUCCESS] [$SCRIPT_NAME] ✅ $1${NC}"
}

log_step() {
    echo -e "${CYAN}[$(timestamp)] [STEP] [$SCRIPT_NAME] 📋 $1${NC}"
}

# Dry-run aware logging
log_dry_run() {
    local action="$1"
    local description="$2"
    
    if [ "$DRY_RUN" = "true" ]; then
        echo -e "${YELLOW}[$(timestamp)] [DRY-RUN] [$SCRIPT_NAME] Would $action: $description${NC}"
    else
        log_info "$action: $description"
    fi
}

# Progress logging
log_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    
    echo -e "${CYAN}[$(timestamp)] [PROGRESS] [$SCRIPT_NAME] [$current/$total] $message${NC}"
}

# Package operation logging (compatible with existing system)
log_package_operation() {
    local operation="$1"
    local category="$2"
    local count="$3"
    local method="$4"
    local packages="$5"
    
    log_info "Package $operation: $category ($count packages via $method)"
    log_debug "Packages: $packages"
}

log_package_success() {
    local category="$1"
    local method="$2"
    local count="$3"
    local duration="$4"
    
    log_success "Installed $category ($count packages via $method in ${duration}s)"
}

# System operation logging (compatible with existing system)
log_system_operation() {
    local operation="$1"
    log_step "System operation: $operation"
}
