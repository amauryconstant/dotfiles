#!/usr/bin/env bash

# System Troubleshoot Tool - Interactive system diagnostics and troubleshooting
# Purpose: Diagnostic tools and manual fixes for system issues
# Requirements: Arch Linux, systemd, gum (UI library)

# Source the UI library
if [ -f "$UI_LIB" ]; then
    . "$UI_LIB"
else
    echo "Error: UI library not found at $UI_LIB" >&2
    exit 1
fi

show_troubleshoot_help() {
    ui_title "🛡️ System Troubleshoot Tool - Usage"
    ui_info ""
    ui_info "Usage: system-troubleshoot [command]"
    ui_info ""
    ui_info "Available commands:"
    ui_info "  service      - 🚨 Service Failure Analysis"
    ui_info "  performance  - 📈 Performance Diagnostics"
    ui_info "  repair       - 🔧 System Repair Tools"
    ui_info "  logs         - 🔍 Log Analysis"
    ui_info "  hardware     - 🛠️ Hardware Diagnostics"
    ui_info "  network      - 📡 Network Troubleshooting"
    ui_info "  disk         - 💾 Disk Recovery"
    ui_info "  info         - 📊 System Information"
    ui_info "  health       - 🩺 Quick Health Check"
    ui_info ""
    ui_info "  --help, -h   - Show this help message"
    ui_info ""
    ui_info "Examples:"
    ui_info "  system-troubleshoot service    # Analyze failed services"
    ui_info "  system-troubleshoot            # Interactive menu"
}

execute_troubleshoot_action() {
    local ACTION="$1"

    case "$ACTION" in
        "🚨 Service Failure Analysis - Analyze failed services")
            ui_title "🚨 Service Failure Analysis" --after 1

            # Find failed services
            local failed_services=$(systemctl list-units --type=service --state=failed --no-legend --no-pager 2>/dev/null)
            if [[ -z "$failed_services" ]]; then
                ui_success "No failed services detected"
            else
                ui_warning "Failed services found:"
                echo "$failed_services" | while read -r line; do
                    local service_name=$(echo "$line" | awk '{print $2}')
                    ui_error "  $service_name"
                done

                ui_spacer
                local service=$(ui_input "Enter service name to analyze" "service-name.service")
                if [[ -n "$service" ]]; then
                    ui_info "Service status for: $service" --after 1
                    systemctl status "$service" --no-pager -l
                    ui_spacer
                    ui_info "Recent logs for: $service" --after 1
                    journalctl -u "$service" --no-pager -l -n 20
                fi
            fi
            ;;

        "📈 Performance Diagnostics - CPU/Memory/Disk analysis")
            ui_title "📈 Performance Diagnostics" --after 1

            # Load average analysis
            local load_avg=$(uptime | awk -F'load average:' '{print $2}' | xargs)
            local cpu_cores=$(nproc)
            ui_info "Load Average: $load_avg (CPU cores: $cpu_cores)"

            # Memory analysis
            ui_info "Memory Usage:" --after 1
            free -h

            # Top processes by CPU
            ui_info "Top 10 CPU-intensive processes:" --after 1
            ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -11

            # Top processes by Memory
            ui_info "Top 10 Memory-intensive processes:" --after 1
            ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -11

            # Disk I/O if iotop available
            if command -v iotop >/dev/null 2>&1; then
                ui_info "Disk I/O analysis available - run 'sudo iotop' manually"
            fi
            ;;

        "🔧 System Repair Tools - Common fixes")
            ui_title "🔧 System Repair Tools" --after 1

            local repair_action=$(ui_choose "Select repair action:" \
                "🔄 Reload systemd daemon" \
                "🗂️ Rebuild font cache" \
                "📦 Fix package database" \
                "🗝️ Update keyring" \
                "🌊 Reset DNS cache" \
                "🖥️ Fix desktop database")

            case "$repair_action" in
                "🔄 Reload systemd daemon")
                    ui_spin "Reloading systemd daemon..." "sudo systemctl daemon-reload"
                    ui_success "Systemd daemon reloaded"
                    ;;
                "🗂️ Rebuild font cache")
                    ui_spin "Rebuilding font cache..." "fc-cache -fv"
                    ui_success "Font cache rebuilt"
                    ;;
                "📦 Fix package database")
                    ui_spin "Updating package database..." "sudo pacman -Sy"
                    ui_success "Package database updated"
                    ;;
                "🗝️ Update keyring")
                    ui_spin "Updating keyring..." "sudo pacman -S archlinux-keyring --noconfirm"
                    ui_success "Keyring updated"
                    ;;
                "🌊 Reset DNS cache")
                    ui_spin "Flushing DNS cache..." "sudo systemctl restart systemd-resolved"
                    ui_success "DNS cache reset"
                    ;;
                "🖥️ Fix desktop database")
                    ui_spin "Updating desktop database..." "update-desktop-database ~/.local/share/applications/"
                    ui_success "Desktop database updated"
                    ;;
            esac
            ;;

        "🔍 Log Analysis - Parse system logs for errors")
            ui_title "🔍 Log Analysis" --after 1

            local log_action=$(ui_choose "Select log analysis:" \
                "❌ Critical errors in last 24h" \
                "⚠️ Warnings in last 24h" \
                "🚀 Boot logs analysis" \
                "📶 Network errors" \
                "💿 Disk errors")

            case "$log_action" in
                "❌ Critical errors in last 24h")
                    ui_info "Critical errors from last 24 hours:" --after 1
                    journalctl --since "24 hours ago" -p err --no-pager -l
                    ;;
                "⚠️ Warnings in last 24h")
                    ui_info "Warnings from last 24 hours:" --after 1
                    journalctl --since "24 hours ago" -p warning --no-pager -l
                    ;;
                "🚀 Boot logs analysis")
                    ui_info "Boot log analysis:" --after 1
                    journalctl -b --no-pager -l | grep -E "(error|failed|fatal)" || ui_success "No boot errors found"
                    ;;
                "📶 Network errors")
                    ui_info "Network-related errors:" --after 1
                    journalctl -u NetworkManager --since "24 hours ago" --no-pager -l
                    ;;
                "💿 Disk errors")
                    ui_info "Disk-related errors:" --after 1
                    dmesg | grep -E "(error|fail)" | grep -E "(disk|sda|sdb|nvme)" || ui_success "No disk errors found"
                    ;;
            esac
            ;;

        "🛠️ Hardware Diagnostics - Check hardware health")
            ui_title "🛠️ Hardware Diagnostics" --after 1

            # Temperature monitoring
            if command -v sensors >/dev/null 2>&1; then
                ui_info "System temperatures:" --after 1
                sensors
            else
                ui_warning "lm-sensors not available (install with: pacman -S lm_sensors)"
            fi

            # Disk health
            ui_info "Disk health check:" --after 1
            if command -v smartctl >/dev/null 2>&1; then
                local disks=$(lsblk -dno NAME | grep -E '^(sd|nvme)')
                echo "$disks" | while read -r disk; do
                    ui_info "SMART status for /dev/$disk:"
                    sudo smartctl -H "/dev/$disk" 2>/dev/null || ui_warning "Cannot read SMART data for $disk"
                done
            else
                ui_warning "smartmontools not available (install with: pacman -S smartmontools)"
            fi

            # Memory test suggestion
            ui_info "Memory diagnostics:" --after 1
            ui_info "For comprehensive memory testing, reboot and run memtest86+"
            ;;

        "📡 Network Troubleshooting - Network connectivity issues")
            ui_title "📡 Network Troubleshooting" --after 1

            # Network interfaces
            ui_info "Network interfaces:" --after 1
            ip addr show

            # Connectivity tests
            ui_info "Connectivity tests:" --after 1
            if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
                ui_success "Internet connectivity: Working"
            else
                ui_error "Internet connectivity: Failed"
            fi

            if nslookup google.com >/dev/null 2>&1; then
                ui_success "DNS resolution: Working"
            else
                ui_error "DNS resolution: Failed"
            fi

            # NetworkManager status
            if systemctl is-active --quiet NetworkManager; then
                ui_success "NetworkManager: Running"
            else
                ui_error "NetworkManager: Not running"
            fi
            ;;

        "💾 Disk Recovery - Emergency disk space recovery")
            ui_title "💾 Emergency Disk Recovery" --after 1

            # Show current disk usage
            ui_info "Current disk usage:" --after 1
            df -h

            ui_warning "Emergency disk cleanup options:"
            local cleanup_action=$(ui_choose "Select cleanup action:" \
                "🗑️ Clear package cache (pacman)" \
                "🧹 Remove orphaned packages" \
                "📝 Clean log files (keep 1 week)" \
                "🌍 Clear browser caches" \
                "📂 Find large files (>100MB)" \
                "📁 Clear user cache directories")

            case "$cleanup_action" in
                "🗑️ Clear package cache (pacman)")
                    ui_spin "Clearing package cache..." "sudo pacman -Scc --noconfirm"
                    ui_success "Package cache cleared"
                    ;;
                "🧹 Remove orphaned packages")
                    local orphans=$(pacman -Qtdq 2>/dev/null)
                    if [[ -n "$orphans" ]]; then
                        echo "$orphans" | sudo pacman -Rns - --noconfirm
                        ui_success "Orphaned packages removed"
                    else
                        ui_info "No orphaned packages found"
                    fi
                    ;;
                "📝 Clean log files (keep 1 week)")
                    ui_spin "Cleaning old logs..." "sudo journalctl --vacuum-time=1week"
                    ui_success "Log files cleaned"
                    ;;
                "🌍 Clear browser caches")
                    ui_spin "Clearing browser caches..." "rm -rf ~/.cache/mozilla/* ~/.cache/chromium/* 2>/dev/null || true"
                    ui_success "Browser caches cleared"
                    ;;
                "📂 Find large files (>100MB)")
                    ui_info "Large files in home directory:" --after 1
                    find ~ -type f -size +100M -exec ls -lh {} \; 2>/dev/null | head -20
                    ;;
                "📁 Clear user cache directories")
                    ui_spin "Clearing user caches..." "rm -rf ~/.cache/* 2>/dev/null || true"
                    ui_success "User caches cleared"
                    ;;
            esac

            # Show disk usage after cleanup
            ui_info "Disk usage after cleanup:" --before 1 --after 1
            df -h / | tail -1
            ;;

        "📊 System Information - Detailed diagnostic info")
            ui_info "Gathering detailed system information..." --after 1

            if command -v fastfetch >/dev/null 2>&1; then
                fastfetch
            else
                # Basic system info
                ui_info "System: $(uname -sr)"
                ui_info "Hostname: $(hostname)"
                ui_info "Uptime: $(uptime -p 2>/dev/null || uptime)"
                ui_info "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
                ui_info "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
            fi
            ;;

        "🩺 Quick Health Check - Brief system status")
            if command -v system-health >/dev/null 2>&1; then
                system-health --brief
            else
                ui_info "Quick system status:"
                ui_info "Load: $(uptime | awk -F'load average:' '{print $2}')"
                ui_info "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
                ui_info "Disk: $(df -h / | awk 'NR==2 {print $5 " used"}')"

                local failed_services
                failed_services=$(systemctl list-units --type=service --state=failed --no-legend 2>/dev/null | wc -l)
                if [[ $failed_services -eq 0 ]]; then
                    ui_success "All services running normally"
                else
                    ui_warning "$failed_services failed service(s)"
                fi
            fi
            ;;

        *)
            ui_error "Unknown action. Please try again."
            ;;
    esac
}

system-troubleshoot() {
    # Parse command line arguments
    if [[ $# -gt 0 ]]; then
        local command="$1"

        # Handle help flags
        if [[ "$command" == "--help" || "$command" == "-h" ]]; then
            show_troubleshoot_help
            return 0
        fi

        # Map command shortcuts to full action strings
        local action=""
        case "$command" in
            "service")
                action="🚨 Service Failure Analysis - Analyze failed services"
                ;;
            "performance")
                action="📈 Performance Diagnostics - CPU/Memory/Disk analysis"
                ;;
            "repair")
                action="🔧 System Repair Tools - Common fixes"
                ;;
            "logs")
                action="🔍 Log Analysis - Parse system logs for errors"
                ;;
            "hardware")
                action="🛠️ Hardware Diagnostics - Check hardware health"
                ;;
            "network")
                action="📡 Network Troubleshooting - Network connectivity issues"
                ;;
            "disk")
                action="💾 Disk Recovery - Emergency disk space recovery"
                ;;
            "info")
                action="📊 System Information - Detailed diagnostic info"
                ;;
            "health")
                action="🩺 Quick Health Check - Brief system status"
                ;;
            *)
                ui_error "Unknown command: $command"
                show_troubleshoot_help
                return 1
                ;;
        esac

        # Execute the action directly and exit
        execute_troubleshoot_action "$action"
        return 0
    fi

    # Main interactive loop
    while true; do
        ui_title "🛡️ System Troubleshoot Tool"
        
        ACTION=$(ui_choose "Select a troubleshooting action:" \
            "🚨 Service Failure Analysis - Analyze failed services" \
            "📈 Performance Diagnostics - CPU/Memory/Disk analysis" \
            "🔧 System Repair Tools - Common fixes" \
            "🔍 Log Analysis - Parse system logs for errors" \
            "🛠️ Hardware Diagnostics - Check hardware health" \
            "📡 Network Troubleshooting - Network connectivity issues" \
            "💾 Disk Recovery - Emergency disk space recovery" \
            "📊 System Information - Detailed diagnostic info" \
            "🩺 Quick Health Check - Brief system status" \
            "🚪 Exit")

        # Handle exit separately since it breaks the loop
        if [[ "$ACTION" == "🚪 Exit" || "$ACTION" == "" ]]; then
            ui_info "Goodbye! 👋"
            break
        fi

        # Execute the selected action using the helper function
        execute_troubleshoot_action "$ACTION"
        
        # Pause before showing menu again (except for exit)
        if [[ "$ACTION" != "🚪 Exit" && "$ACTION" != "" ]]; then
            ui_info "Press any key to continue..." --before 1
            read -r -n 1
            ui_spacer
        fi
    done
}
