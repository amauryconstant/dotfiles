#!/bin/bash
# setup-network-printer.sh
# Purpose: Install and configure Samsung M2070 Series network printer and scanner
# Dependencies: cups, sane-airscan, system-config-printer
# Environment: CHEZMOI_OS_ID
# OS Support: linux (Arch and Fedora)
# Destination: all (work/leisure/test)

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Install and configure Samsung M2070 Series network printer and scanner"
readonly REQUIRED_COMMANDS=("systemctl")
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID")

# Printer configuration
readonly PRINTER_NAME="Samsung_M2070_Series"
readonly PRINTER_IP="192.168.1.40"
readonly PRINTER_MODEL="Samsung M2070 Series"
readonly PRINTER_DESCRIPTION="Samsung M2070 Series Network Printer"

# Validation functions
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required commands
    require_commands "${REQUIRED_COMMANDS[@]}"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate OS support
    case "$CHEZMOI_OS_ID" in
        "linux-arch"|"linux-fedora")
            log_debug "OS $CHEZMOI_OS_ID is supported"
            ;;
        *)
            error_exit "Unsupported OS: $CHEZMOI_OS_ID" 3 "ENVIRONMENT" "This script supports linux-arch and linux-fedora"
            ;;
    esac
    
    log_debug "Environment validation passed"
}

# Check if package is installed (distribution-agnostic)
is_package_installed() {
    local package="$1"
    
    case "$CHEZMOI_OS_ID" in
        "linux-arch")
            pacman -Qi "$package" >/dev/null 2>&1 || yay -Qi "$package" >/dev/null 2>&1
            ;;
        "linux-fedora")
            rpm -q "$package" >/dev/null 2>&1 || (command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q "$package")
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if service is enabled and running
is_service_active() {
    local service="$1"
    systemctl is-active --quiet "$service" 2>/dev/null
}

is_service_enabled() {
    local service="$1"
    systemctl is-enabled --quiet "$service" 2>/dev/null
}

# Check if printer is already configured
is_printer_configured() {
    command -v lpstat >/dev/null 2>&1 && lpstat -p "$PRINTER_NAME" >/dev/null 2>&1
}

# Check if user is in required groups
is_user_in_group() {
    local group="$1"
    groups | grep -q "\b$group\b"
}

# Add user to group if not already a member
add_user_to_group() {
    local group="$1"
    if ! is_user_in_group "$group"; then
        log_info "Adding user to $group group..."
        log_dry_run "add" "user to $group group"
        
        if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
            if sudo usermod -a -G "$group" "$USER"; then
                log_success "User added to $group group (requires logout/login to take effect)"
            else
                log_warn "Failed to add user to $group group"
            fi
        fi
    else
        log_info "User already in $group group"
    fi
}

# Detect printer URI using lpinfo
detect_printer_uri() {
    # Try different protocols
    local uris=(
        "ipp://$PRINTER_IP/ipp/print"
        "http://$PRINTER_IP:631/ipp/print"
        "socket://$PRINTER_IP:9100"
        "lpd://$PRINTER_IP/queue"
    )
    
    if command -v lpinfo >/dev/null 2>&1; then
        for uri in "${uris[@]}"; do
            if lpinfo -v 2>/dev/null | grep -q "$uri"; then
                echo "$uri"
                return 0
            fi
        done
    fi
    
    # Fallback to socket protocol
    echo "socket://$PRINTER_IP:9100"
}

# Configure printer
configure_printer() {
    log_info "Configuring Samsung M2070 Series printer..."
    
    if is_printer_configured; then
        log_info "Printer '$PRINTER_NAME' is already configured"
        return 0
    fi
    
    if ! command -v lpadmin >/dev/null 2>&1; then
        log_warn "lpadmin not available, skipping printer configuration"
        return 0
    fi
    
    log_dry_run "configure" "printer $PRINTER_NAME at $PRINTER_IP"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Detect printer URI
        log_info "Detecting printer URI..."
        local printer_uri
        printer_uri=$(detect_printer_uri)
        log_info "Using printer URI: $printer_uri"
        
        # Choose driver based on connection type
        local driver_option
        if [[ "$printer_uri" == ipp://* ]] || [[ "$printer_uri" == http://* ]]; then
            log_info "Using IPP Everywhere driver for IPP/HTTP connection..."
            driver_option="-m everywhere"
        else
            log_info "Using generic PostScript driver for socket/LPD connection..."
            driver_option="-m drv:///sample.drv/generic.ppd"
        fi
        
        # Add printer using lpadmin
        log_info "Adding printer with appropriate driver..."
        if sudo lpadmin -p "$PRINTER_NAME" \
            -v "$printer_uri" \
            $driver_option \
            -D "$PRINTER_DESCRIPTION" \
            -L "Network Printer at $PRINTER_IP" \
            -E; then
            
            # Set as default printer
            sudo lpadmin -d "$PRINTER_NAME"
            
            # Accept jobs
            sudo cupsenable "$PRINTER_NAME"
            sudo cupsaccept "$PRINTER_NAME"
            
            log_success "Printer configured successfully"
        else
            log_warn "Failed to configure printer (non-critical)"
        fi
    fi
}

# Configure scanner
configure_scanner() {
    log_info "Configuring network scanner..."
    
    # Check if sane-airscan is installed
    if ! is_package_installed "sane-airscan"; then
        log_warn "sane-airscan is not installed. Scanner configuration skipped."
        return 1
    fi
    
    log_dry_run "configure" "scanner for $PRINTER_IP"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Create sane-airscan configuration if it doesn't exist
        local airscan_conf="/etc/sane.d/airscan.conf"
        if [ ! -f "$airscan_conf" ]; then
            log_info "Creating sane-airscan configuration..."
            sudo tee "$airscan_conf" > /dev/null << EOF
# Samsung M2070 Series Scanner Configuration
[devices]
"Samsung M2070" = http://$PRINTER_IP/eSCL/, WSD

[options]
discovery = enable
model = Samsung M2070
EOF
            log_success "Scanner configuration created"
        else
            log_info "Scanner configuration already exists"
        fi
        
        # Test scanner detection
        log_info "Testing scanner detection..."
        if command -v scanimage >/dev/null 2>&1 && scanimage -L | grep -q "$PRINTER_IP" 2>/dev/null; then
            log_success "Scanner detected successfully"
        else
            log_info "Scanner not immediately detected (may need service restart)"
        fi
    fi
}

# Verify required packages
verify_packages() {
    log_info "Verifying required packages are installed..."
    
    local required_packages
    case "$CHEZMOI_OS_ID" in
        "linux-arch")
            required_packages=("cups" "sane-airscan" "sane" "system-config-printer")
            ;;
        "linux-fedora")
            required_packages=("cups" "sane-airscan" "sane-backends" "system-config-printer")
            ;;
        *)
            log_warn "Unknown OS for package verification"
            return 0
            ;;
    esac
    
    local missing_packages=()
    for package in "${required_packages[@]}"; do
        if ! is_package_installed "$package"; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        log_warn "Missing required packages: ${missing_packages[*]}"
        log_warn "Please install missing packages before running printer setup"
        return 1
    fi
    
    log_success "All required packages are installed"
    return 0
}

# Configure CUPS service
configure_cups() {
    log_info "Configuring CUPS service..."
    
    log_dry_run "configure" "CUPS printing service"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if ! is_service_enabled "cups.service"; then
            log_info "Enabling CUPS service..."
            sudo systemctl enable cups.service
        fi
        
        if ! is_service_active "cups.service"; then
            log_info "Starting CUPS service..."
            sudo systemctl start cups.service
        fi
        
        log_success "CUPS service is running"
    fi
}

# Configure user permissions
configure_permissions() {
    log_info "Configuring user permissions..."
    
    add_user_to_group "lp"
    add_user_to_group "scanner"
}

# Test configuration
test_configuration() {
    log_info "Testing printer and scanner configuration..."
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        # Test printer
        if command -v lpstat >/dev/null 2>&1 && lpstat -p "$PRINTER_NAME" >/dev/null 2>&1; then
            log_success "Printer configuration verified"
        else
            log_warn "Printer configuration could not be verified"
        fi
        
        # Test scanner (basic check)
        if command -v scanimage >/dev/null 2>&1; then
            log_success "Scanner tools available"
        else
            log_warn "Scanner tools not available"
        fi
    else
        log_info "Dry-run: Would test printer and scanner configuration"
    fi
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: $CHEZMOI_OS_ID"
    log_debug "Printer IP: $PRINTER_IP"
    
    validate_environment
    
    # Step 1: Verify required packages
    if ! verify_packages; then
        log_warn "Required packages missing, skipping printer setup"
        return 0
    fi
    
    # Step 2: Configure CUPS service
    configure_cups
    
    # Step 3: Configure user permissions
    configure_permissions
    
    # Step 4: Configure printer
    configure_printer
    
    # Step 5: Configure scanner
    configure_scanner
    
    # Step 6: Test configuration
    test_configuration
    
    log_success "$SCRIPT_PURPOSE completed successfully"
    
    # Print summary
    echo ""
    echo "=== Printer Setup Summary ==="
    echo "Printer Name: $PRINTER_NAME"
    echo "Printer IP: $PRINTER_IP"
    echo "Printer URI: $(detect_printer_uri)"
    echo ""
    echo "=== Next Steps ==="
    echo "1. Log out and log back in for group permissions to take effect"
    echo "2. Test printing: echo 'Test page' | lp -d $PRINTER_NAME"
    echo "3. Test scanning with skanpage (KDE) or simple-scan"
    echo "4. Access printer settings: http://localhost:631"
    echo ""
    echo "=== Troubleshooting ==="
    echo "- Check printer status: lpstat -p $PRINTER_NAME"
    echo "- Check scanner: scanimage -L"
    echo "- CUPS web interface: http://localhost:631"
    echo "- Restart CUPS: sudo systemctl restart cups.service"
    echo ""
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
