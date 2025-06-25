#!/bin/sh

# chezmoi Dual-Output Logging System
# Provides clean human-readable console output with verbose file logging

# Initialize color variables
init_colors() {
    # Check if we should use colors (only for console output and if terminal supports it)
    if [ "${CONSOLE_COLORS:-true}" = "true" ] && [ -z "${NO_COLOR:-}" ] && [ -t 1 ]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        BRIGHT_GREEN='\033[1;32m'
        BRIGHT_RED='\033[1;31m'
        RESET='\033[0m'
    else
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        CYAN=''
        BRIGHT_GREEN=''
        BRIGHT_RED=''
        RESET=''
    fi
}

# Log levels (numeric for comparison)
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# Convert log level string to numeric
get_log_level_numeric() {
    case "${1:-INFO}" in
        "DEBUG") echo $LOG_LEVEL_DEBUG ;;
        "INFO")  echo $LOG_LEVEL_INFO ;;
        "WARN")  echo $LOG_LEVEL_WARN ;;
        "ERROR") echo $LOG_LEVEL_ERROR ;;
        *) echo $LOG_LEVEL_INFO ;;
    esac
}

# Get current timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Get caller information for debugging
get_caller_info() {
    local frame="${1:-2}"
    local caller_info
    caller_info="$(caller $frame 2>/dev/null || echo "unknown:0:unknown")"
    echo "$caller_info"
}

# Write verbose log entry to file
_log_to_file() {
    local level="$1"
    local symbol="$2"
    local message="$3"
    local details="${4:-}"
    
    if [ "${LOG_TO_FILE:-true}" != "true" ] || [ -z "${LOG_FILE:-}" ]; then
        return 0
    fi
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Build verbose log entry
    local log_entry=""
    
    # Add timestamp
    if [ "${FILE_LOG_TIMESTAMPS:-true}" = "true" ]; then
        log_entry="[$(get_timestamp)]"
    fi
    
    # Add log level
    log_entry="${log_entry} [${level}]"
    
    # Add script context
    if [ "${FILE_LOG_SCRIPT_CONTEXT:-true}" = "true" ]; then
        if [ -n "${SCRIPT_NAME:-}" ]; then
            log_entry="${log_entry} [${SCRIPT_NAME}]"
        fi
        if [ -n "${CHEZMOI_DESTINATION:-}" ]; then
            log_entry="${log_entry} [${CHEZMOI_DESTINATION}]"
        fi
        if [ -n "${EXECUTION_PHASE:-}" ]; then
            log_entry="${log_entry} [${EXECUTION_PHASE}]"
        fi
    fi
    
    # Add message
    log_entry="${log_entry} ${message}"
    
    # Add details if provided
    if [ -n "$details" ]; then
        log_entry="${log_entry} | ${details}"
    fi
    
    # Write to log file (strip colors)
    echo "$log_entry" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
}

# Core dual-output logging function
_dual_log() {
    local level="$1"
    local console_symbol="$2"
    local console_message="$3"
    local file_message="${4:-$console_message}"
    local details="${5:-}"
    
    local level_numeric
    local console_level_numeric
    local file_level_numeric
    
    level_numeric=$(get_log_level_numeric "$level")
    console_level_numeric=$(get_log_level_numeric "${CONSOLE_LOG_LEVEL:-INFO}")
    file_level_numeric=$(get_log_level_numeric "${FILE_LOG_LEVEL:-INFO}")
    
    # Console output (human-friendly) - always clean, never shows debug
    if [ "${LOG_TO_CONSOLE:-true}" = "true" ] && [ "$level_numeric" -ge "$console_level_numeric" ]; then
        local console_output="${console_symbol} ${console_message}"
        
        if [ "$level" = "ERROR" ]; then
            printf '%b\n' "${RED}${console_output}${RESET}" >&2
        elif [ "$level" = "WARN" ]; then
            printf '%b\n' "${YELLOW}${console_output}${RESET}"
        elif [ "$console_symbol" = "✅" ]; then
            printf '%b\n' "${GREEN}${console_output}${RESET}"
        else
            printf '%b\n' "${console_output}"
        fi
    fi
    
    # File output (verbose when -v flag is used)
    if [ "$level_numeric" -ge "$file_level_numeric" ]; then
        _log_to_file "$level" "$console_symbol" "$file_message" "$details"
    fi
}

# Public logging functions - Human-friendly console, verbose file
log_info() {
    local message="$1"
    local symbol="${2:-ℹ️ }"
    _dual_log "INFO" "$symbol" "$message" "$message" "caller=$(get_caller_info)"
}

log_warn() {
    local message="$1"
    _dual_log "WARN" "⚠️ " "$message" "Warning: $message" "caller=$(get_caller_info)"
}

log_error() {
    local message="$1"
    _dual_log "ERROR" "❌ " "$message" "Error: $message" "caller=$(get_caller_info)"
}

log_success() {
    local message="$1"
    _dual_log "INFO" "✅ " "$message" "Success: $message" "caller=$(get_caller_info)"
}

log_debug() {
    local message="$1"
    _dual_log "DEBUG" "🔍 " "$message" "Debug: $message" "caller=$(get_caller_info)"
}

# Context-aware logging functions
log_package_operation() {
    local operation="$1"  # install, remove, update
    local category="$2"   # fonts, terminal_tools, etc.
    local count="${3:-}"  # number of packages
    local method="${4:-}" # pacman, yay, etc.
    local packages="${5:-}" # actual package list
    
    local console_msg="${operation^}ing ${category}"
    if [ -n "$count" ] && [ "$count" -gt 1 ]; then
        console_msg="${console_msg} (${count} packages)"
    fi
    
    local file_msg="Package operation: ${operation} category=${category}"
    local details="method=${method} packages=${packages} count=${count}"
    
    _dual_log "INFO" "📦 " "$console_msg" "$file_msg" "$details"
}

log_package_success() {
    local category="$1"
    local method="$2"
    local count="${3:-}"
    local duration="${4:-}"
    local exit_code="${5:-0}"
    
    local console_msg="${category^} installed"
    local file_msg="Successfully installed ${category} with ${method}"
    local details="count=${count} duration=${duration}s exit_code=${exit_code}"
    
    _dual_log "INFO" "✅ " "$console_msg" "$file_msg" "$details"
}

log_config_operation() {
    local operation="$1"  # configuring, updating, setting up
    local component="$2"  # git, ssh, zsh, etc.
    local details="${3:-}"
    
    local console_msg="${operation^} ${component}"
    local file_msg="Configuration operation: ${operation} component=${component}"
    
    _dual_log "INFO" "🔧 " "$console_msg" "$file_msg" "$details"
}

log_security_operation() {
    local operation="$1"  # setting up, configuring, generating
    local component="$2"  # SSH keys, encryption, etc.
    local details="${3:-}"
    
    local console_msg="${operation^} ${component}"
    local file_msg="Security operation: ${operation} component=${component}"
    
    _dual_log "INFO" "🔑 " "$console_msg" "$file_msg" "$details"
}

log_network_operation() {
    local operation="$1"
    local details="${2:-}"
    
    _dual_log "INFO" "🌐 " "$operation" "Network operation: $operation" "$details"
}

log_file_operation() {
    local operation="$1"  # creating, copying, linking
    local target="$2"
    local details="${3:-}"
    
    local console_msg="${operation^} ${target}"
    local file_msg="File operation: ${operation} target=${target}"
    
    _dual_log "INFO" "📁 " "$console_msg" "$file_msg" "$details"
}

log_system_operation() {
    local operation="$1"
    local details="${2:-}"
    
    _dual_log "INFO" "⚙️ " "$operation" "System operation: $operation" "$details"
}

# Progress logging with clean console output
log_progress() {
    local current="$1"
    local total="$2"
    local operation="$3"
    
    if [ "${CONSOLE_SHOW_PROGRESS:-true}" = "true" ] && [ -t 1 ]; then
        # Interactive progress for console
        printf "\r🔄 %s (%d/%d)" "$operation" "$current" "$total"
        if [ "$current" -eq "$total" ]; then
            echo  # New line when complete
        fi
    fi
    
    # Always log progress to file
    _log_to_file "PROGRESS" "🔄" "Progress: $operation" "step=${current}/${total} timestamp=$(date '+%s')"
}

# Dry-run aware logging
log_dry_run() {
    local action="$1"
    local target="$2"
    local details="${3:-}"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" = "true" ]; then
        _dual_log "INFO" "🔍 " "Would ${action}: ${target}" "Dry-run: would ${action} ${target}" "$details"
    else
        _dual_log "INFO" "▶️ " "${action^}: ${target}" "Executing: ${action} ${target}" "$details"
    fi
}

# Enhanced error handling with helpful output
handle_error() {
    local error_msg="$1"
    local exit_code="${2:-1}"
    local context="${3:-}"
    local suggestion="${4:-Check logs for details}"
    
    # Human console: Simple, actionable
    log_error "$error_msg"
    if [ -n "$suggestion" ]; then
        echo "💡 $suggestion"
    fi
    if [ "${LOG_TO_FILE:-true}" = "true" ] && [ -n "${LOG_FILE:-}" ]; then
        echo "📋 Full logs: tail -f $LOG_FILE"
    fi
    
    # Verbose file: Complete debugging info
    local debug_info="exit_code=$exit_code context=$context script=$SCRIPT_NAME line=$(get_caller_info)"
    debug_info="$debug_info pwd=$(pwd) user=$(whoami)"
    if [ "${FILE_LOG_ENVIRONMENT_VARS:-true}" = "true" ]; then
        debug_info="$debug_info env_vars=$(env | grep -E '(CHEZMOI|LOG)' | tr '\n' ' ')"
    fi
    
    _log_to_file "ERROR" "❌" "Error occurred: $error_msg" "$debug_info"
    _log_to_file "DEBUG" "🔍" "Troubleshooting context" "$debug_info"
    
    # Handle interactive mode
    if [ "${CHEZMOI_INTERACTIVE:-false}" = "true" ]; then
        echo "${YELLOW}Continue anyway? (y/N)${RESET}"
        read -r response
        case "$response" in
            [Yy]*) return 0 ;;
            *) exit "$exit_code" ;;
        esac
    else
        if [ "${CHEZMOI_KEEP_GOING:-false}" = "true" ]; then
            log_warn "Continuing due to --keep-going flag"
            return 0
        else
            exit "$exit_code"
        fi
    fi
}

# Extract clean script name from chezmoi-generated script names
extract_script_name() {
    local full_name="$1"
    local base_name
    local clean_name
    
    # Get basename and remove all extensions (.sh, .tmpl, etc.)
    base_name="$(basename "$full_name")"
    base_name="${base_name%.sh.tmpl}"
    base_name="${base_name%.sh}"
    base_name="${base_name%.tmpl}"
    
    # Remove chezmoi-generated numeric prefix
    clean_name="$(echo "$base_name" | sed 's/^[0-9]*\.\?[0-9]*_\?//')"
    
    # Extract meaningful part from chezmoi script names
    case "$clean_name" in
        run_once_before_*_*)
            echo "$clean_name" | sed 's/^run_once_before_[0-9]*_//'
            ;;
        run_once_after_*_*)
            echo "$clean_name" | sed 's/^run_once_after_[0-9]*_//'
            ;;
        run_onchange_*_*)
            echo "$clean_name" | sed 's/^run_onchange_[^_]*_//'
            ;;
        *)
            echo "$clean_name"
            ;;
    esac
}

# Detect execution phase from script name
detect_execution_phase() {
    local script_name="$1"
    
    case "$script_name" in
        *run_once_before_*|*_before_*) echo "before" ;;
        *run_once_after_*|*_after_*)   echo "after" ;;
        *run_onchange_*|*_onchange_*)  echo "onchange" ;;
        *run_*|*_run_*)                echo "run" ;;
        *) echo "unknown" ;;
    esac
}

# Detect chezmoi execution context
detect_chezmoi_context() {
    # Detect if running under chezmoi
    if [ -n "${CHEZMOI_SOURCE_DIR:-}" ] || [ -n "${CHEZMOI_DEST_DIR:-}" ]; then
        CHEZMOI_CONTEXT="chezmoi"
    else
        CHEZMOI_CONTEXT="standalone"
    fi
    
    # Export for use in other functions
    export CHEZMOI_CONTEXT
}

# Initialize logging for a script
init_chezmoi_logging() {
    local script_path="$1"
    local full_script_name
    
    # Initialize colors first
    init_colors
    
    # Extract clean script name
    full_script_name="$(basename "$script_path")"
    SCRIPT_NAME="$(extract_script_name "$full_script_name")"
    
    # Detect execution phase
    EXECUTION_PHASE="$(detect_execution_phase "$full_script_name")"
    
    # Detect chezmoi context
    detect_chezmoi_context
    
    # Export variables
    export SCRIPT_NAME EXECUTION_PHASE
    
    # Set up log file path
    if [ "${LOG_TO_FILE:-true}" = "true" ]; then
        LOG_FILE="${LOG_FILE:-$HOME/.local/state/chezmoi/logs/chezmoi-setup.log}"
        export LOG_FILE
    fi
    
    # Log script start (only to file to keep console clean)
    _log_to_file "DEBUG" "🚀" "Script started: $SCRIPT_NAME" "context=$CHEZMOI_CONTEXT phase=$EXECUTION_PHASE path=$script_path"
}

# Cleanup function for script end
cleanup_logging() {
    local exit_code="${1:-0}"
    
    if [ "$exit_code" -eq 0 ]; then
        _log_to_file "DEBUG" "✅" "Script completed: $SCRIPT_NAME" "exit_code=$exit_code"
    else
        _log_to_file "ERROR" "❌" "Script failed: $SCRIPT_NAME" "exit_code=$exit_code"
    fi
}

# Set up trap for cleanup
trap 'cleanup_logging $?' EXIT

# Helper function to count items in a space-separated list
count_items() {
    echo "$1" | wc -w
}

# Helper function to extract category name from package list context
get_category_name() {
    local context="$1"
    # This can be enhanced based on how categories are passed
    echo "$context"
}
