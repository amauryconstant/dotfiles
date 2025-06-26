#!/bin/bash
# install-packages-arch-work.sh
# Purpose: Install packages for Arch Linux work destination
# Dependencies: pacman, yay (optional for AUR packages)
# Environment: CHEZMOI_OS_ID, CHEZMOI_DESTINATION, CHEZMOI_PACKAGES
# OS Support: linux-arch
# Destination: work

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Install packages for Arch Linux work destination"
readonly REQUIRED_COMMANDS=("pacman")
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID" "CHEZMOI_DESTINATION" "CHEZMOI_PACKAGES")

# Package installation functions with strategy support
install_with_pacman() {
    local packages="$*"
    local start_time=$(date +%s)
    
    log_dry_run "install" "$packages via pacman"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if sudo pacman -S --noconfirm --needed "$@"; then
            local duration=$(($(date +%s) - start_time))
            log_debug "Pacman installation took ${duration}s"
            return 0
        else
            return 1
        fi
    fi
    return 0
}

install_with_yay_bin() {
    local packages="$*"
    local start_time=$(date +%s)
    
    log_dry_run "install" "$packages via yay (binary)"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if yay -S --noconfirm --needed --norebuild --redownload "$@"; then
            local duration=$(($(date +%s) - start_time))
            log_debug "Yay binary installation took ${duration}s"
            return 0
        else
            return 1
        fi
    fi
    return 0
}

install_with_yay_source() {
    local packages="$*"
    local start_time=$(date +%s)
    
    log_dry_run "install" "$packages via yay (source)"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if yay -S --noconfirm --needed --rebuild "$@"; then
            local duration=$(($(date +%s) - start_time))
            log_debug "Yay source installation took ${duration}s"
            return 0
        else
            return 1
        fi
    fi
    return 0
}

# Install packages with strategy fallback
install_with_strategy() {
    local strategy="$1"
    shift
    local packages="$*"
    local package_count=$(echo "$packages" | wc -w)
    
    log_debug "Installing $package_count packages with strategy: $strategy"
    log_debug "Packages: $packages"
    
    # Parse strategy (comma-separated list)
    IFS=',' read -ra STRATEGY_METHODS <<< "$strategy"
    
    for method in "${STRATEGY_METHODS[@]}"; do
        case "$method" in
            "pacman")
                if install_with_pacman $packages; then
                    return 0
                fi
                ;;
            "yay_bin")
                if command -v yay >/dev/null 2>&1; then
                    if install_with_yay_bin $packages; then
                        return 0
                    fi
                else
                    log_warn "Yay not available, skipping yay_bin strategy"
                fi
                ;;
            "yay_source")
                if command -v yay >/dev/null 2>&1; then
                    if install_with_yay_source $packages; then
                        return 0
                    fi
                else
                    log_warn "Yay not available, skipping yay_source strategy"
                fi
                ;;
            *)
                log_warn "Unknown installation method: $method"
                ;;
        esac
    done
    
    return 1
}

# Category installation functions
install_fonts() {
    log_info "Installing fonts for work environment"
    
    local packages="ttf-firacode-nerd otf-opendyslexic-nerd otf-geist-mono-nerd ttf-fira-sans"
    local strategy="pacman,yay_bin,yay_source"  # Default strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install fonts" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: pacman -S $packages"
    fi
    
    log_success "Fonts installed successfully"
}

install_terminal_essentials() {
    log_info "Installing terminal essentials for work environment"
    
    local packages="zoxide fzf tlrc fd ripgrep broot bat eza xh jaq rsync"
    local strategy="pacman,yay_bin,yay_source"  # From source strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install terminal essentials" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: yay -S $packages"
    fi
    
    log_success "Terminal essentials installed successfully"
}

install_terminal_utils() {
    log_info "Installing terminal utilities for work environment"
    
    local packages="fastfetch usage nvitop btop"
    local strategy="pacman,yay_bin,yay_source"  # From source strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install terminal utilities" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: yay -S $packages"
    fi
    
    log_success "Terminal utilities installed successfully"
}

install_terminal_presentation() {
    log_info "Installing terminal presentation tools for work environment"
    
    local packages="vhs"
    local strategy="pacman,yay_bin,yay_source"  # From source strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install terminal presentation tools" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: yay -S $packages"
    fi
    
    log_success "Terminal presentation tools installed successfully"
}

install_languages() {
    log_info "Installing programming languages for work environment"
    
    local packages="go go-tools python rust"
    local strategy="pacman,yay_bin,yay_source"  # From source strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install programming languages" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: pacman -S $packages"
    fi
    
    log_success "Programming languages installed successfully"
}

install_package_managers() {
    log_info "Installing package managers for work environment"
    
    local packages="uv cargo mise"
    local strategy="pacman,yay_bin,yay_source"  # From source strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install package managers" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: yay -S $packages"
    fi
    
    log_success "Package managers installed successfully"
}

install_development_tools() {
    log_info "Installing development tools for work environment"
    
    local packages="docker docker-compose code"
    local strategy="pacman,yay_bin"  # Binary strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install development tools" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: pacman -S $packages"
    fi
    
    log_success "Development tools installed successfully"
}

install_development_clis() {
    log_info "Installing development CLI tools for work environment"
    
    local packages="aws-cli-v2 git-delta mergiraf jujutsu"
    local strategy="pacman,yay_bin,yay_source"  # From source strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install development CLI tools" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: yay -S $packages"
    fi
    
    log_success "Development CLI tools installed successfully"
}

install_system_software() {
    log_info "Installing system software for work environment"
    
    local packages="appimagelauncher snapd"
    local strategy="pacman,yay_bin"  # Default strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install system software" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: pacman -S $packages"
    fi
    
    log_success "System software installed successfully"
}

install_general_software() {
    log_info "Installing general software for work environment"
    
    local packages="firefox chromium spotify nextcloud-client qbittorrent slack-desktop"
    local strategy="pacman,yay_bin"  # Binary strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install general software" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: yay -S $packages"
    fi
    
    log_success "General software installed successfully"
}

install_ai_tools() {
    log_info "Installing AI tools for work environment"
    
    local packages="ollama vllm"
    local strategy="pacman,yay_bin,yay_source"  # From source strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install AI tools" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: yay -S $packages"
    fi
    
    log_success "AI tools installed successfully"
}

install_printing_scanning() {
    log_info "Installing printing and scanning software for work environment"
    
    local packages="cups cups-pdf system-config-printer sane sane-airscan skanpage"
    local strategy="pacman,yay_bin"  # Default strategy
    
    if ! install_with_strategy "$strategy" $packages; then
        error_exit "Failed to install printing/scanning software" $EXIT_PACKAGE_INSTALL_FAILED $CATEGORY_PACKAGE "Try running: pacman -S $packages"
    fi
    
    log_success "Printing and scanning software installed successfully"
}

# Remove conflicting packages
remove_conflicting_packages() {
    local conflicting_packages="tldr"  # From packages.yaml delete.arch
    
    if [ -n "$conflicting_packages" ]; then
        log_info "Removing conflicting packages: $conflicting_packages"
        log_dry_run "remove" "$conflicting_packages"
        
        if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
            if yay -R --noconfirm $conflicting_packages 2>/dev/null; then
                log_success "Conflicting packages removed"
            else
                log_info "No conflicting packages found (this is normal)"
            fi
        fi
    fi
}

# Validation function
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate required commands
    require_commands "${REQUIRED_COMMANDS[@]}"
    
    # Validate OS and destination
    require_os "linux-arch"
    require_destination "work"
    
    # Check if yay is available (warn if not)
    if ! command -v yay >/dev/null 2>&1; then
        log_warn "Yay AUR helper not available - some packages may not be installable"
        log_warn "Install yay for full package management capabilities"
    fi
    
    log_debug "Environment validation passed"
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: $CHEZMOI_OS_ID, Destination: $CHEZMOI_DESTINATION"
    
    validate_environment
    
    # Remove conflicting packages first
    remove_conflicting_packages
    
    # Parse enabled package categories
    IFS=',' read -ra CATEGORIES <<< "$CHEZMOI_PACKAGES"
    
    log_info "Processing $(echo "${CATEGORIES[@]}" | wc -w) package categories for work destination"
    
    for category in "${CATEGORIES[@]}"; do
        case "$category" in
            "fonts") install_fonts ;;
            "terminal_essentials") install_terminal_essentials ;;
            "terminal_utils") install_terminal_utils ;;
            "terminal_presentation") install_terminal_presentation ;;
            "languages") install_languages ;;
            "package_managers") install_package_managers ;;
            "development_tools") install_development_tools ;;
            "development_clis") install_development_clis ;;
            "system_software") install_system_software ;;
            "general_software") install_general_software ;;
            "ai_tools") install_ai_tools ;;
            "printing_scanning") install_printing_scanning ;;
            *) log_warn "Unknown package category: $category" ;;
        esac
    done
    
    log_success "$SCRIPT_PURPOSE completed successfully"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
