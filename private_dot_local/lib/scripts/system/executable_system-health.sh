#!/usr/bin/env bash

# System Health Check Tool
# Purpose: Non-interactive system health monitoring for automation
# Requirements: Arch Linux, systemctl

# Non-interactive system health check
# Usage: system-health [--brief|--help]
system-health() {
    case "$1" in
        --help|-h)
            printf "Usage: system-health [--brief|--help]\n"
            printf "Simple system health check for automation\n"
            printf "\n"
            printf "Options:\n"
            printf "  --brief      Show brief system status (default)\n"
            printf "  --help, -h   Show this help message\n"
            return 0
            ;;
        --brief|"")
            # Brief system status - essential info only
            printf "\033[1;34m=== SYSTEM STATUS ===\033[0m\n"
            
            # Load average
            load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ ]*//g')
            printf "\033[0;36mLoad Average:\033[0m %s\n" "$load_avg"
            
            # Memory usage
            memory_info=$(free -h | awk '/^Mem:/ {printf "%s used / %s total", $3, $2}')
            printf "\033[0;36mMemory:\033[0m %s\n" "$memory_info"
            
            # Disk usage for root
            disk_info=$(df -h / | awk 'NR==2 {printf "%s used / %s total (%s)", $3, $2, $5}')
            printf "\033[0;36mDisk /:\033[0m %s\n" "$disk_info"
            
            # Failed services count
            if command -v systemctl >/dev/null 2>&1; then
                failed_count=$(systemctl list-units --type=service --state=failed --no-legend 2>/dev/null | wc -l)
                if [ "$failed_count" -eq 0 ]; then
                    printf "\033[0;32m✓ All services running normally\033[0m\n"
                else
                    printf "\033[1;33m⚠ %d failed service(s)\033[0m\n" "$failed_count"
                fi
            else
                printf "\033[0;37mService status: systemctl not available\033[0m\n"
            fi
            
            return 0
            ;;
        *)
            printf "\033[0;31mError: Unknown option '%s'\033[0m\n" "$1" >&2
            printf "Use --help for usage information\n" >&2
            return 1
            ;;
    esac
}

# Execute function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    system-health "$@"
fi