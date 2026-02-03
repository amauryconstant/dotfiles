#!/usr/bin/env bash

# System Health Check Tool
# Purpose: Non-interactive system health monitoring for automation
# Requirements: Arch Linux, systemctl

# Source UI library
if [ -n "$UI_LIB" ] && [ -f "$UI_LIB" ]; then
    . "$UI_LIB"
elif [ -f "$HOME/.local/lib/scripts/core/gum-ui.sh" ]; then
    . "$HOME/.local/lib/scripts/core/gum-ui.sh"
else
    echo "Error: UI library not found" >&2
    exit 1
fi

# Non-interactive system health check
# Usage: system-health [--brief|--help]
system-health() {
    case "$1" in
        --help|-h)
            ui_info "Usage: system-health [--brief|--help]"
            ui_info "Simple system health check for automation"
            echo ""
            ui_info "Options:"
            ui_info "  --brief      Show brief system status (default)"
            ui_info "  --help, -h   Show this help message"
            return 0
            ;;
        --brief|"")
            # Brief system status - essential info only
            ui_title "SYSTEM STATUS"

            # Load average
            load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ ]*//g')
            ui_info "Load Average: $load_avg"

            # Memory usage
            memory_info=$(free -h | awk '/^Mem:/ {printf "%s used / %s total", $3, $2}')
            ui_info "Memory: $memory_info"

            # Disk usage for root
            disk_info=$(df -h / | awk 'NR==2 {printf "%s used / %s total (%s)", $3, $2, $5}')
            ui_info "Disk /: $disk_info"

            # Failed services count
            if command -v systemctl >/dev/null 2>&1; then
                failed_count=$(systemctl list-units --type=service --state=failed --no-legend 2>/dev/null | wc -l)
                if [ "$failed_count" -eq 0 ]; then
                    ui_success "All services running normally"
                else
                    ui_warning "$failed_count failed service(s)"
                fi
            else
                ui_info "Service status: systemctl not available"
            fi

            return 0
            ;;
        *)
            ui_error "Unknown option '$1'"
            ui_info "Use --help for usage information"
            return 1
            ;;
    esac
}

# Execute function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    system-health "$@"
fi