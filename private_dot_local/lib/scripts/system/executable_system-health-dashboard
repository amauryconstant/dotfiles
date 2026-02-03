#!/usr/bin/env bash

# System Health Dashboard
# Purpose: Comprehensive system status overview with interactive UI
# Requirements: Arch Linux, gum (UI library), glances, inxi, lm_sensors, pacman-contrib

# Load UI library
if [ -f "$SCRIPTS_DIR/core/gum-ui.sh" ]; then
    . "$SCRIPTS_DIR/core/gum-ui.sh"
else
    echo "Error: UI library not found at $SCRIPTS_DIR/core/gum-ui.sh" >&2
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Interactive system health dashboard - uses standardized UI library

# Interactive mode selection if gum is available and no arguments provided
BRIEF=false
FULL=false
SERVICES=false
PACKAGES=false
HARDWARE=false
NETWORK=false

# Handle help flag
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    ui_title "System Health Dashboard"
    ui_spacer
    ui_warning "Interactive mode (default):"
    ui_text "  Run without arguments to use interactive menus" --before 1 --after 1
    ui_warning "Command line options:"
    ui_text "  --brief      Show brief system overview"
    ui_text "  --full       Show comprehensive system information"
    ui_text "  --services   Show only service status"
    ui_text "  --packages   Show only package information"
    ui_text "  --hardware   Show only hardware information"
    ui_text "  --network    Show only network status"
    ui_text "  --help, -h   Show this help message"
    exit 0
fi

# Store original argument count for interactive mode check
ORIGINAL_ARGC=$#

# Parse command line arguments (maintain backward compatibility)
while [[ $# -gt 0 ]]; do
    case $1 in
        --brief)
            BRIEF=true
            shift
            ;;
        --full)
            FULL=true
            shift
            ;;
        --services)
            SERVICES=true
            shift
            ;;
        --packages)
            PACKAGES=true
            shift
            ;;
        --hardware)
            HARDWARE=true
            shift
            ;;
        --network)
            NETWORK=true
            shift
            ;;
        *)
            ui_error "Unknown option: $1"
            ui_info "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Interactive mode selection if no arguments provided
if [[ $ORIGINAL_ARGC -eq 0 ]]; then
    MODE=$(ui_choose "Select system health check mode:" \
        "📊 Standard Dashboard (All Sections)" \
        "⚡ Brief Overview" \
        "🔍 Comprehensive Report" \
        "⚙️  Services Only" \
        "📦 Packages Only" \
        "🔧 Hardware Only" \
        "🌐 Network Only")
    
    case "$MODE" in
        "📊 Standard Dashboard (All Sections)")
            SERVICES=true
            PACKAGES=true
            HARDWARE=true
            NETWORK=true
            ;;
        "⚡ Brief Overview")
            BRIEF=true
            ;;
        "🔍 Comprehensive Report")
            FULL=true
            ;;
        "⚙️  Services Only")
            SERVICES=true
            ;;
        "📦 Packages Only")
            PACKAGES=true
            ;;
        "🔧 Hardware Only")
            HARDWARE=true
            ;;
        "🌐 Network Only")
            NETWORK=true
            ;;
        *)
            # User cancelled, exit gracefully
            ui_warning "Operation cancelled"
            exit 0
            ;;
    esac
fi

# System Overview (always shown unless --brief or specific sections)
if [[ "$BRIEF" == false && "$SERVICES" == false && "$PACKAGES" == false && "$HARDWARE" == false && "$NETWORK" == false ]] || [[ "$FULL" == true ]]; then
    ui_title "🖥️  SYSTEM OVERVIEW"
    
    if command_exists fastfetch; then
        fastfetch --config none --structure "Title:Separator:OS:Host:Kernel:Uptime:Packages:Shell:Display:DE:WM:WMTheme:Theme:Icons:Font:Cursor:Terminal:TerminalFont:CPU:GPU:Memory:Disk:LocalIP:Battery:PowerAdapter:Locale:Break:Colors"
    else
        ui_warning "fastfetch not available - install for better system overview"
        ui_info "System: $(uname -sr)"
        ui_info "Hostname: $(hostname)"
        ui_info "Uptime: $(uptime -p 2>/dev/null || uptime)"
    fi
fi

# Brief mode - just essential info
if [[ "$BRIEF" == true ]]; then
    ui_title "📊 BRIEF SYSTEM STATUS"
    
    # Load average
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    ui_info "Load Average: $load_avg"
    
    # Memory usage
    memory_info=$(free -h | awk '/^Mem:/ {printf "Memory: %s used / %s total (%.1f%%)", $3, $2, ($3/$2)*100}')
    ui_info "$memory_info"
    
    # Disk usage for root
    disk_usage=$(df -h / | awk 'NR==2 {printf "Disk /: %s used / %s total (%s)", $3, $2, $5}')
    ui_info "$disk_usage"
    
    # Failed services count (explicitly exclude disabled services)
    failed_services=$(systemctl list-units --type=service --state=failed --no-legend --no-pager 2>/dev/null | grep -E '^●.*\.service' | wc -l)
    if [[ $failed_services -eq 0 ]]; then
        ui_success "No failed services detected"
    else
        ui_warning "$failed_services service(s) in failed state"
    fi
    
    exit 0
fi

# Resource Usage
if [[ "$SERVICES" == false && "$PACKAGES" == false && "$HARDWARE" == false && "$NETWORK" == false ]] || [[ "$FULL" == true ]]; then
    ui_title "📊 RESOURCE USAGE"
    
    # CPU and Memory usage
    if command_exists glances; then
        ui_subtitle "Real-time resource usage (5 second snapshot):"
        timeout 5s glances --time 1 --export stdout 2>/dev/null | head -20 || {
            ui_warning "glances timeout or not available"
            
            # Fallback to basic commands
            ui_info "Load Average: $(uptime | awk -F'load average:' '{print $2}')" --after 1
            free -h
            ui_spacer
            df -h
        }
    else
        ui_info "glances not available - showing basic resource info" --after 1
        free -h
        ui_spacer
        df -h
    fi
    
    # Temperature monitoring
    if command_exists sensors; then
        ui_subtitle "System Temperatures:" --before 1
        sensors 2>/dev/null | grep -E "Core|Package|temp" | head -10 || ui_info "No temperature sensors detected"
    fi
fi

# Service Status
if [[ "$SERVICES" == true ]] || [[ "$FULL" == true ]]; then
    ui_title "⚙️  SERVICE STATUS"
    
    # Failed services (only shows services in actual failed state, not disabled)
    failed_services=$(systemctl list-units --type=service --state=failed --no-legend --no-pager 2>/dev/null | grep -E '^●.*\.service')
    if [[ -z "$failed_services" ]]; then
        ui_success "No services in failed state"
    else
        ui_error "Services in failed state:"
        echo "$failed_services" | while read -r line; do
            # Extract service name (second field after the ● symbol)
            service_name=$(echo "$line" | awk '{print $2}')
            ui_error "  $service_name"
        done
        ui_info "Note: Disabled services are not considered failed" --before 1
    fi
    
    # Key services status
    ui_subtitle "Key Services Status:" --after 1
    
    # Create table for service status
    echo "Service|Status|State" > /tmp/services_table.txt
    
    # Essential services that should be running
    essential_services=("NetworkManager" "bluetooth" "cups")
    # Optional services that are OK if disabled
    optional_services=("docker" "sshd")
    
    # Check essential services
    for service in "${essential_services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "$service|✅ Active|Running" >> /tmp/services_table.txt
        elif systemctl is-failed --quiet "$service" 2>/dev/null; then
            echo "$service|❌ Failed|Needs Attention" >> /tmp/services_table.txt
        elif systemctl list-unit-files --type=service | grep -q "^$service.service"; then
            # Service exists but is not active (could be disabled, inactive, etc.)
            service_state=$(systemctl is-enabled "$service" 2>/dev/null || echo "unknown")
            echo "$service|⚠️  Inactive|$service_state" >> /tmp/services_table.txt
        else
            echo "$service|ℹ️  Not Found|Not Installed" >> /tmp/services_table.txt
        fi
    done
    
    # Check optional services
    for service in "${optional_services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "$service|✅ Active|Running" >> /tmp/services_table.txt
        elif systemctl is-failed --quiet "$service" 2>/dev/null; then
            echo "$service|❌ Failed|Needs Attention" >> /tmp/services_table.txt
        elif systemctl list-unit-files --type=service | grep -q "^$service.service"; then
            # Optional service exists but is not active (disabled is expected/OK)
            service_state=$(systemctl is-enabled "$service" 2>/dev/null || echo "unknown")
            echo "$service|ℹ️  Disabled|$service_state (OK)" >> /tmp/services_table.txt
        else
            echo "$service|ℹ️  Not Found|Not Installed" >> /tmp/services_table.txt
        fi
    done
    
    ui_table < /tmp/services_table.txt
    rm -f /tmp/services_table.txt
fi

# Package Information
if [[ "$PACKAGES" == true ]] || [[ "$FULL" == true ]]; then
    ui_title "📦 PACKAGE INFORMATION"
    
    # Installed packages count
    total_packages=$(pacman -Q 2>/dev/null | wc -l)
    explicit_packages=$(pacman -Qe 2>/dev/null | wc -l)
    
    ui_info "Total packages: $total_packages (${explicit_packages} explicitly installed)"
    
    # Check for updates
    if command_exists checkupdates; then
        ui_info "Checking for updates..."
        updates=$(ui_spin_silent "Checking package updates..." "checkupdates 2>/dev/null")
        update_count=$(echo "$updates" | wc -l)
        
        if [[ -n "$updates" && "$updates" != "" ]]; then
            ui_warning "$update_count package update(s) available"
            if [[ "$FULL" == true ]]; then
                # Use gum table for better package update display
                ui_warning "Available Updates:" --before 1
                echo "Package|Current|New" > /tmp/updates_table.txt
                echo "$updates" | head -10 | awk '{print $1"|"$2"|"$4}' >> /tmp/updates_table.txt
                ui_table < /tmp/updates_table.txt
                rm -f /tmp/updates_table.txt
                if [[ $update_count -gt 10 ]]; then
                    ui_info "... and $((update_count - 10)) more"
                fi
            fi
        else
            ui_success "System is up to date"
        fi
    else
        ui_info "checkupdates not available - install pacman-contrib for update checking"
    fi
    
    # AUR updates (if paru is available)
    if command_exists paru; then
        aur_updates=$(ui_spin_silent "Checking AUR updates..." "paru -Qua 2>/dev/null | wc -l")
        if [[ $aur_updates -gt 0 ]]; then
            ui_warning "$aur_updates AUR package update(s) available"
        else
            ui_success "AUR packages are up to date"
        fi
    fi
    
    # Orphaned packages
    orphans=$(pacman -Qtdq 2>/dev/null | wc -l)
    if [[ $orphans -gt 0 ]]; then
        ui_warning "$orphans orphaned package(s) found (use: pacman -Qtdq | sudo pacman -Rns -)"
    else
        ui_success "No orphaned packages"
    fi
fi

# Hardware Information
if [[ "$HARDWARE" == true ]] || [[ "$FULL" == true ]]; then
    ui_title "🔧 HARDWARE INFORMATION"
    
    if command_exists inxi; then
        ui_subtitle "System Hardware Overview:"
        inxi -b 2>/dev/null || ui_warning "inxi command failed"
        
        if [[ "$FULL" == true ]]; then
            ui_subtitle "Detailed Hardware Information:" --before 1
            inxi -Fxz 2>/dev/null | head -50
        fi
    else
        ui_info "inxi not available - showing basic hardware info"
        ui_info "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
        ui_info "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
        ui_info "Architecture: $(uname -m)"
    fi
    
    # Disk health (basic check)
    ui_subtitle "Storage Devices:" --before 1
    lsblk -f 2>/dev/null | grep -E "(NAME|sd|nvme)" || ui_info "Storage information unavailable"
fi

# Network Status
if [[ "$NETWORK" == true ]] || [[ "$FULL" == true ]]; then
    ui_title "🌐 NETWORK STATUS"
    
    # Network interfaces
    ui_subtitle "Network Interfaces:"
    ip -br addr show 2>/dev/null | grep -v "lo.*127.0.0.1" | while read -r line; do
        interface=$(echo "$line" | awk '{print $1}')
        interface_status=$(echo "$line" | awk '{print $2}')
        ip_addr=$(echo "$line" | awk '{print $3}' | cut -d'/' -f1)
        
        if [[ "$interface_status" == "UP" ]]; then
            ui_success "$interface: $ip_addr"
        else
            ui_info "$interface: $interface_status"
        fi
    done
    
    # Internet connectivity
    ui_subtitle "Connectivity Test:"
    if ui_spin_silent "Testing internet connectivity..." "ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1"; then
        ui_success "Internet connectivity: Available"
    else
        ui_warning "Internet connectivity: Limited or unavailable"
    fi
    
    # DNS resolution test
    if ui_spin_silent "Testing DNS resolution..." "nslookup google.com >/dev/null 2>&1"; then
        ui_success "DNS resolution: Working"
    else
        ui_warning "DNS resolution: Issues detected"
    fi
    
    # Active connections (if requested in full mode)
    if [[ "$FULL" == true ]]; then
        ui_subtitle "Active Network Connections:" --before 1
        ss -tuln 2>/dev/null | head -10 || ui_info "Network connection info unavailable"
    fi
fi

# System Summary
if [[ "$BRIEF" == false && "$SERVICES" == false && "$PACKAGES" == false && "$HARDWARE" == false && "$NETWORK" == false ]] || [[ "$FULL" == true ]]; then
    ui_title "📋 SYSTEM SUMMARY"
    
    # Last update check
    if [[ -f /var/log/pacman.log ]]; then
        last_update=$(grep -E "starting full system upgrade|synchronizing package lists" /var/log/pacman.log 2>/dev/null | tail -1 | awk '{print $1, $2}')
        if [[ -n "$last_update" ]]; then
            ui_info "Last system update: $last_update"
        fi
    fi
    
    # System load status
    load_1min=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
    cpu_cores=$(nproc)
    
    if (( $(echo "$load_1min > $cpu_cores" | bc -l 2>/dev/null || echo 0) )); then
        ui_warning "System load is high: $load_1min (cores: $cpu_cores)"
    else
        ui_success "System load is normal: $load_1min (cores: $cpu_cores)"
    fi
    
    # Disk space warning
    disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 90 ]]; then
        ui_error "Root filesystem is ${disk_usage}% full"
    elif [[ $disk_usage -gt 80 ]]; then
        ui_warning "Root filesystem is ${disk_usage}% full"
    else
        ui_success "Disk space is adequate (${disk_usage}% used)"
    fi
    
    ui_complete "System health check completed!" --before 1
    ui_info "Run 'system-health --help' for more options, or just 'system-health' for interactive mode."
fi