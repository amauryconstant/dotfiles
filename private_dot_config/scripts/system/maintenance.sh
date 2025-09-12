#!/usr/bin/env bash

# System Maintenance Tool - Interactive system maintenance operations
# Purpose: User-friendly interface for common system maintenance tasks
# Requirements: Arch Linux, pacman, optionally yay, topgrade, gum (UI library)

system-maintenance() {
    # Interactive system maintenance - uses standardized UI library
    
    # Note: Using standardized ui_* functions instead of custom print_message
    
    # Note: Using standardized ui_spin instead of custom ui_spin
    
    # Note: Using standardized ui_confirm instead of custom ui_confirm
    
    # Main interactive loop
    while true; do
        ui_title "🔧 System Maintenance Tool"
        
        ACTION=$(ui_choose "Select a maintenance action:" \
            "🔄 Full System Update - Run topgrade (recommended)" \
            "📦 Package Updates - Update Arch packages only" \
            "🍃 AUR Updates - Update AUR packages (requires yay)" \
            "🧹 System Cleanup - Clean package cache and orphans" \
            "🔍 System Health Check - Run system health dashboard" \
            "💾 Disk Cleanup - Clean temporary files and caches" \
            "🗂️  Log Cleanup - Clean system logs" \
            "🔐 Security Update - Update and check security status" \
            "📊 System Information - Detailed system info" \
            "⚡ Quick Status - Brief system overview" \
            "🚪 Exit")
        
        case "$ACTION" in
            "🔄 Full System Update - Run topgrade (recommended)")
                if command -v topgrade >/dev/null 2>&1; then
                    ui_info "Running comprehensive system update with topgrade..."
                    topgrade
                    ui_success "System update completed!"
                else
                    ui_error "topgrade is not installed. Install with: pacman -S topgrade"
                fi
                ;;
                
            "📦 Package Updates - Update Arch packages only")
                if ui_confirm "Update all Arch Linux packages?"; then
                    ui_spin "Syncing package databases..." "sudo pacman -Sy"
                    ui_info "Updating packages..."
                    sudo pacman -Su
                    ui_success "Package update completed!"
                else
                    ui_info "Operation cancelled"
                fi
                ;;
                
            "🍃 AUR Updates - Update AUR packages (requires yay)")
                if command -v yay >/dev/null 2>&1; then
                    if ui_confirm "Update all AUR packages?"; then
                        ui_info "Updating AUR packages..."
                        yay -Sua
                        ui_success "AUR update completed!"
                    else
                        ui_info "Operation cancelled"
                    fi
                else
                    ui_error "yay is not installed. Install with: pacman -S yay"
                fi
                ;;
                
            "🧹 System Cleanup - Clean package cache and orphans")
                ui_title "🧹 System Cleanup Session" --after 1
                
                # Log cleanup activities
                ui_action "Starting system cleanup"
                
                # Clean package cache
                ui_step "Cleaning package cache..."
                sudo pacman -Sc --noconfirm
                ui_success "Package cache cleaned"
                
                # Find and optionally remove orphaned packages
                local orphans
                orphans=$(pacman -Qtdq 2>/dev/null)
                if [[ -n "$orphans" ]]; then
                    local orphan_count
                    orphan_count=$(echo "$orphans" | wc -l)
                    ui_warning "Found $orphan_count orphaned package(s):"
                    
                    # Create table for orphaned packages
                    echo "Package|Description" > /tmp/orphans_table.txt
                    echo "$orphans" | while read pkg; do
                        desc=$(pacman -Qi "$pkg" 2>/dev/null | grep "Description" | cut -d: -f2- | xargs || echo "No description")
                        echo "$pkg|$desc" >> /tmp/orphans_table.txt
                    done
                    
                    ui_table < /tmp/orphans_table.txt
                    rm -f /tmp/orphans_table.txt
                    
                    if ui_confirm "Remove these orphaned packages?"; then
                        echo "$orphans" | sudo pacman -Rns -
                        ui_info "Removed $orphan_count orphaned packages"
                        ui_success "Orphaned packages removed!"
                    fi
                else
                    ui_success "No orphaned packages found"
                fi
                
                # Clean yay cache if available
                if command -v yay >/dev/null 2>&1; then
                    ui_spin "Cleaning AUR cache..." "yay -Sc --noconfirm"
                    ui_success "AUR cache cleaned"
                fi
                
                ui_info "System cleanup completed"
                ui_complete "System cleanup completed!"
                ;;
                
            "🔍 System Health Check - Run system health dashboard")
                if command -v system-health >/dev/null 2>&1; then
                    system-health
                else
                    ui_error "system-health function not available"
                fi
                ;;
                
            "💾 Disk Cleanup - Clean temporary files and caches")
                ui_info "Starting disk cleanup..."
                
                # Show disk usage before cleanup
                ui_info "Current disk usage:"
                df -h / | tail -1
                ui_spacer
                
                if ui_confirm "Clean temporary files and caches?"; then
                    # Clean various cache directories
                    ui_spin "Cleaning user cache..." "rm -rf ~/.cache/thumbnails/* 2>/dev/null || true"
                    ui_spin "Cleaning browser caches..." "rm -rf ~/.cache/mozilla/* ~/.cache/chromium/* 2>/dev/null || true"
                    ui_spin "Cleaning temporary files..." "sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null || true"
                    
                    # Clean journal logs (keep last week)
                    if command -v journalctl >/dev/null 2>&1; then
                        ui_spin "Cleaning old journal logs..." "sudo journalctl --vacuum-time=1week"
                    fi
                    
                    # Show disk usage after cleanup
                    ui_info "Disk usage after cleanup:" --before 1
                    df -h / | tail -1
                    ui_success "Disk cleanup completed!"
                else
                    ui_info "Operation cancelled"
                fi
                ;;
                
            "🗂️  Log Cleanup - Clean system logs")
                if ui_confirm "Clean system logs (keep last 2 weeks)?"; then
                    if command -v journalctl >/dev/null 2>&1; then
                        ui_spin "Cleaning journal logs..." "sudo journalctl --vacuum-time=2weeks"
                        ui_success "Log cleanup completed!"
                    else
                        ui_error "journalctl not available"
                    fi
                else
                    ui_info "Operation cancelled"
                fi
                ;;
                
            "🔐 Security Update - Update and check security status")
                ui_info "Running security-focused maintenance..."
                
                # Update packages first
                ui_spin "Updating packages for security..." "sudo pacman -Syu --noconfirm"
                
                # Check for failed services
                local failed_services
                failed_services=$(systemctl list-units --type=service --state=failed --no-legend 2>/dev/null | wc -l)
                if [[ $failed_services -gt 0 ]]; then
                    ui_warning "$failed_services failed service(s) detected"
                    systemctl list-units --type=service --state=failed --no-legend
                else
                    ui_success "All services running normally"
                fi
                
                ui_success "Security update completed!"
                ;;
                
            "📊 System Information - Detailed system info")
                ui_info "Gathering detailed system information..." --after 1
                
                if command -v fastfetch >/dev/null 2>&1; then
                    fastfetch
                elif command -v neofetch >/dev/null 2>&1; then
                    neofetch
                else
                    # Basic system info
                    ui_info "System: $(uname -sr)"
                    ui_info "Hostname: $(hostname)"
                    ui_info "Uptime: $(uptime -p 2>/dev/null || uptime)"
                    ui_info "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
                    ui_info "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
                fi
                ;;
                
            "⚡ Quick Status - Brief system overview")
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
                
            "🚪 Exit"|"")
                ui_info "Goodbye! 👋"
                break
                ;;
                
            *)
                ui_error "Unknown action. Please try again."
                ;;
        esac
        
        # Pause before showing menu again (except for exit)
        if [[ "$ACTION" != "🚪 Exit" && "$ACTION" != "" ]]; then
            ui_info "Press any key to continue..." --before 1
            read -n 1
            ui_spacer
        fi
    done
}
