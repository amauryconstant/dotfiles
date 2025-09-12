#!/usr/bin/env bash

# Package Manager - Interactive package management tool
# Purpose: User-friendly interface for package operations
# Requirements: Arch Linux, pacman, yay, gum (UI library)

package-manager() {
    # Note: Using standardized UI library which handles gum availability
    
    # Note: Using standardized ui_* functions instead of custom helper functions
    
    # Main interactive loop
    while true; do
        ui_title "📦 Package Manager"
        
        ACTION=$(ui_choose "Select a package operation:" \
            "🔍 Search - Search for packages" \
            "📥 Install - Install packages" \
            "🗑️  Remove - Remove packages" \
            "ℹ️  Info - Show package information" \
            "📋 List - List installed packages" \
            "🔄 Update - Update packages" \
            "🧹 Clean - Clean package cache" \
            "🔍 AUR Search - Search AUR packages" \
            "📥 AUR Install - Install from AUR" \
            "📊 Statistics - Show package statistics" \
            "👥 Dependencies - Show package dependencies" \
            "🚪 Exit")
        
        case "$ACTION" in
            "🔍 Search - Search for packages")
                local search_term
                search_term=$(ui_input "Enter search term" "package name or keyword")
                if [[ -n "$search_term" ]]; then
                    ui_spin "Searching packages..." "sleep 0.5"
                    ui_info "Search results for: $search_term" --after 1
                    
                    local search_results
                    search_results=$(pacman -Ss "$search_term" 2>/dev/null)
                    if [[ -n "$search_results" ]]; then
                        echo "$search_results" | while IFS= read -r line; do
                            if [[ "$line" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_+-]+ ]]; then
                                ui_info "$line"
                            else
                                ui_text "    $line"
                            fi
                        done
                    else
                        ui_warning "No packages found matching '$search_term'"
                    fi
                else
                    ui_error "No search term provided"
                fi
                ;;
                
            "📥 Install - Install packages")
                local packages
                packages=$(ui_input "Enter package name(s) to install" "package1 package2 ...")
                if [[ -n "$packages" ]]; then
                    if ui_confirm "Install packages: $packages?"; then
                        ui_info "Installing packages..."
                        sudo pacman -S "$packages"
                        ui_success "Package installation completed!"
                    else
                        ui_info "Operation cancelled"
                    fi
                else
                    ui_error "No packages specified"
                fi
                ;;
                
            "🗑️  Remove - Remove packages")
                local packages
                packages=$(ui_input "Enter package name(s) to remove" "package1 package2 ...")
                if [[ -n "$packages" ]]; then
                    ui_warning "The following packages will be removed:"
                    pacman -Qi "$packages" 2>/dev/null | grep "Name" | awk '{print "  • " $3}' || echo "  • $packages"
                    
                    if ui_confirm "Remove these packages and their dependencies?"; then
                        ui_info "Removing packages..."
                        sudo pacman -Rs "$packages"
                        ui_success "Package removal completed!"
                    else
                        ui_info "Operation cancelled"
                    fi
                else
                    ui_error "No packages specified"
                fi
                ;;
                
            "ℹ️  Info - Show package information")
                local package
                package=$(ui_input "Enter package name" "package-name")
                if [[ -n "$package" ]]; then
                    ui_info "Package information for: $package" --after 1
                    pacman -Qi "$package" 2>/dev/null || pacman -Si "$package" 2>/dev/null || ui_error "Package not found"
                else
                    ui_error "No package specified"
                fi
                ;;
                
            "📋 List - List installed packages")
                local list_type
                list_type=$(ui_choose "What would you like to list?" \
                    "All installed packages" \
                    "Explicitly installed packages" \
                    "Recently installed packages" \
                    "Largest packages")
                
                case "$list_type" in
                    "All installed packages")
                        local total_packages
                        total_packages=$(pacman -Q | wc -l)
                        ui_info "All installed packages (Total: $total_packages)" --after 1
                        
                        # Use gum filter for searchable package list
                        local selected_package
                        selected_package=$(pacman -Q | ui_filter "Type to search packages...")
                        if [[ -n "$selected_package" ]]; then
                            local pkg_name
                            pkg_name=$(echo "$selected_package" | awk '{print $1}')
                            ui_info "Package Details: $pkg_name" --after 1
                            pacman -Qi "$pkg_name" 2>/dev/null || echo "Package details not available"
                        fi
                        ;;
                    "Explicitly installed packages")
                        ui_info "Explicitly installed packages:" --after 1
                        
                        # Create a table for explicitly installed packages
                        echo "Package|Version|Repository" > /tmp/explicit_packages.txt
                        pacman -Qe | while read -r pkg ver; do
                            local repo
                            repo=$(pacman -Qi "$pkg" 2>/dev/null | grep "Repository" | awk '{print $3}' || echo "local")
                            echo "$pkg|$ver|$repo" >> /tmp/explicit_packages.txt
                        done
                        
                        ui_table < /tmp/explicit_packages.txt
                        rm -f /tmp/explicit_packages.txt
                        ;;
                    "Recently installed packages")
                        ui_info "Recently installed packages:" --after 1
                        
                        # Format recent installations with better styling
                        grep -E "installed|upgraded" /var/log/pacman.log | tail -20 | while IFS= read -r line; do
                            local date_time
                            date_time=$(echo "$line" | awk '{print $1, $2}')
                            local action
                            action=$(echo "$line" | grep -o -E "(installed|upgraded)")
                            local package
                            package=$(echo "$line" | awk '{print $4}')
                            
                            if [[ "$action" == "installed" ]]; then
                                ui_success "📦 $date_time - INSTALLED: $package"
                            else
                                ui_info "🔄 $date_time - UPGRADED: $package"
                            fi
                        done
                        ;;
                    "Largest packages")
                        ui_info "Largest installed packages:" --after 1
                        
                        # Create table for largest packages
                        echo "Size|Package|Description" > /tmp/largest_packages.txt
                        pacman -Qi | awk '
                            /^Name/{name=$3} 
                            /^Description/{desc=substr($0,14)} 
                            /^Installed Size/{
                                size=$4 " " $5; 
                                print size"|"name"|"desc
                            }' | sort -hr | head -10 >> /tmp/largest_packages.txt
                        
                        ui_table < /tmp/largest_packages.txt
                        rm -f /tmp/largest_packages.txt
                        ;;
                esac
                ;;
                
            "🔄 Update - Update packages")
                # Check for available updates first
                ui_info "Checking for available updates..."
                local updates
                updates=$(checkupdates 2>/dev/null)
                
                if [[ -n "$updates" ]]; then
                    local update_count
                    update_count=$(echo "$updates" | wc -l)
                    ui_warning "$update_count package update(s) available:"
                    echo "$updates" | head -10
                    if [[ $update_count -gt 10 ]]; then
                        ui_text "... and $((update_count - 10)) more"
                    fi
                    
                    if ui_confirm "Update all packages?"; then
                        ui_info "Updating packages..."
                        sudo pacman -Syu
                        ui_success "Package updates completed!"
                    else
                        ui_info "Operation cancelled"
                    fi
                else
                    ui_success "System is up to date!"
                fi
                ;;
                
            "🧹 Clean - Clean package cache")
                ui_info "Package cache cleanup options:"
                local cache_size
                cache_size=$(du -sh /var/cache/pacman/pkg/ 2>/dev/null | cut -f1 || echo "unknown")
                ui_info "Current cache size: $cache_size"
                
                local clean_type
                clean_type=$(ui_choose "Select cleanup type:" \
                    "Clean uninstalled packages only" \
                    "Clean all cached packages" \
                    "Clean all except 3 most recent versions")
                
                case "$clean_type" in
                    "Clean uninstalled packages only")
                        if ui_confirm "Clean cache of uninstalled packages?"; then
                            sudo pacman -Sc
                            ui_success "Cache cleanup completed!"
                        fi
                        ;;
                    "Clean all cached packages")
                        if ui_confirm "Clean ALL cached packages? (Warning: this will remove all cached packages)"; then
                            sudo pacman -Scc
                            ui_success "Full cache cleanup completed!"
                        fi
                        ;;
                    "Clean all except 3 most recent versions")
                        if command -v paccache >/dev/null 2>&1; then
                            if ui_confirm "Keep only 3 most recent versions of each package?"; then
                                sudo paccache -r
                                ui_success "Cache cleanup completed!"
                            fi
                        else
                            ui_error "paccache not available (install pacman-contrib)"
                        fi
                        ;;
                esac
                ;;
                
            "🔍 AUR Search - Search AUR packages")
                if command -v yay >/dev/null 2>&1; then
                    local search_term
                    search_term=$(ui_input "Enter AUR search term" "package name or keyword")
                    if [[ -n "$search_term" ]]; then
                        ui_info "Searching AUR for: $search_term" --after 1
                        yay -Ss "$search_term"
                    else
                        ui_error "No search term provided"
                    fi
                else
                    ui_error "yay is not installed. Install with: pacman -S yay"
                fi
                ;;
                
            "📥 AUR Install - Install from AUR")
                if command -v yay >/dev/null 2>&1; then
                    local packages
                    packages=$(ui_input "Enter AUR package name(s)" "aur-package1 aur-package2 ...")
                    if [[ -n "$packages" ]]; then
                        if ui_confirm "Install AUR packages: $packages?"; then
                            ui_info "Installing AUR packages..."
                            yay -S $packages
                            ui_success "AUR package installation completed!"
                        else
                            ui_info "Operation cancelled"
                        fi
                    else
                        ui_error "No packages specified"
                    fi
                else
                    ui_error "yay is not installed. Install with: pacman -S yay"
                fi
                ;;
                
            "📊 Statistics - Show package statistics")
                ui_info "Package Statistics:" --after 1
                
                local total_packages
                total_packages=$(pacman -Q | wc -l)
                local explicit_packages
                explicit_packages=$(pacman -Qe | wc -l)
                local dependency_packages
                dependency_packages=$(pacman -Qd | wc -l)
                local foreign_packages
                foreign_packages=$(pacman -Qm | wc -l)
                
                ui_info "📦 Total installed packages: $total_packages"
                ui_info "🎯 Explicitly installed: $explicit_packages"
                ui_info "🔗 Dependencies: $dependency_packages"
                ui_info "🌐 Foreign (AUR/manual): $foreign_packages"
                
                if command -v checkupdates >/dev/null 2>&1; then
                    local available_updates
                    available_updates=$(checkupdates 2>/dev/null | wc -l)
                    ui_info "🔄 Available updates: $available_updates"
                fi
                
                local orphaned
                orphaned=$(pacman -Qtdq 2>/dev/null | wc -l)
                ui_info "🗑️  Orphaned packages: $orphaned"
                
                # Cache size
                local cache_size
                cache_size=$(du -sh /var/cache/pacman/pkg/ 2>/dev/null | cut -f1 || echo "unknown")
                ui_info "💾 Package cache size: $cache_size"
                ;;
                
            "👥 Dependencies - Show package dependencies")
                local package
                package=$(ui_input "Enter package name" "package-name")
                if [[ -n "$package" ]]; then
                    local dep_type
                    dep_type=$(ui_choose "What dependencies to show?" \
                        "Dependencies of this package" \
                        "Packages that depend on this package" \
                        "Dependency tree")
                    
                    case "$dep_type" in
                        "Dependencies of this package")
                            ui_info "Dependencies of $package:"
                            pacman -Qi "$package" 2>/dev/null | grep "Depends On" | cut -d: -f2
                            ;;
                        "Packages that depend on this package")
                            ui_info "Packages that depend on $package:"
                            pacman -Qi "$package" 2>/dev/null | grep "Required By" | cut -d: -f2
                            ;;
                        "Dependency tree")
                            if command -v pactree >/dev/null 2>&1; then
                                ui_info "Dependency tree for $package:"
                                pactree "$package"
                            else
                                ui_error "pactree not available (install pacman-contrib)"
                            fi
                            ;;
                    esac
                else
                    ui_error "No package specified"
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
            read -r -n 1
            ui_spacer
        fi
    done
}
