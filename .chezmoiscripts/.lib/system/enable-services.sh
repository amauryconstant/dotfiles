#!/bin/bash
# enable-services.sh
# Purpose: Enable system services based on destination configuration
# Dependencies: systemctl
# Environment: CHEZMOI_OS_ID, CHEZMOI_DESTINATION, CHEZMOI_SERVICES
# OS Support: linux (all distributions with systemd)
# Destination: work/leisure/test (different services per destination)

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../utils/logging-lib.sh"
source "$SCRIPT_DIR/../utils/error-handler.sh"

# Script configuration
readonly SCRIPT_PURPOSE="Enable system services based on destination configuration"
readonly REQUIRED_COMMANDS=("systemctl")
readonly REQUIRED_ENV_VARS=("CHEZMOI_OS_ID" "CHEZMOI_DESTINATION")

# Validation functions
validate_environment() {
    log_debug "Validating environment for $SCRIPT_PURPOSE"
    
    # Validate required commands
    require_commands "${REQUIRED_COMMANDS[@]}"
    
    # Validate required environment variables
    require_env_vars "${REQUIRED_ENV_VARS[@]}"
    
    # Validate OS supports systemd
    if ! systemctl --version >/dev/null 2>&1; then
        error_exit "systemd is not available on this system" 21 "SYSTEM" "This script requires systemd"
    fi
    
    log_debug "Environment validation passed"
}

# Check if service exists
service_exists() {
    local service="$1"
    systemctl list-unit-files "$service" >/dev/null 2>&1
}

# Check if service is enabled
is_service_enabled() {
    local service="$1"
    systemctl is-enabled "$service" >/dev/null 2>&1
}

# Check if service is active
is_service_active() {
    local service="$1"
    systemctl is-active "$service" >/dev/null 2>&1
}

# Enable and start a service
enable_service() {
    local service="$1"
    local description="$2"
    
    log_info "Configuring service: $description"
    
    # Check if service exists
    if ! service_exists "$service"; then
        log_warn "Service $service does not exist, skipping"
        return 0
    fi
    
    # Check if already enabled
    if is_service_enabled "$service"; then
        log_info "Service $service is already enabled"
    else
        log_dry_run "enable" "service $service"
        
        if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
            if sudo systemctl enable "$service"; then
                log_success "Service $service enabled successfully"
            else
                log_warn "Failed to enable service $service (non-critical)"
                return 0
            fi
        fi
    fi
    
    # Check if already running
    if is_service_active "$service"; then
        log_info "Service $service is already running"
    else
        log_dry_run "start" "service $service"
        
        if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
            if sudo systemctl start "$service"; then
                log_success "Service $service started successfully"
            else
                log_warn "Failed to start service $service (non-critical)"
            fi
        fi
    fi
}

# Enable Docker service (work destination)
enable_docker_service() {
    log_info "Enabling Docker service for development work"
    
    enable_service "docker.service" "Docker container runtime"
    
    # Add user to docker group if service exists
    if service_exists "docker.service" && [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if ! groups | grep -q docker; then
            log_info "Adding user to docker group..."
            if sudo usermod -aG docker "$USER"; then
                log_success "User added to docker group (logout/login required)"
            else
                log_warn "Failed to add user to docker group"
            fi
        else
            log_info "User already in docker group"
        fi
    fi
}

# Enable Snap services (leisure destination with system_software)
enable_snap_services() {
    log_info "Enabling Snap services for system software support"
    
    enable_service "snapd.socket" "Snap daemon socket"
    enable_service "snapd.apparmor.service" "Snap AppArmor service"
    
    # Create snap symlink if needed
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        if [ ! -e "/snap" ] && [ -d "/var/.lib/snapd/snap" ]; then
            log_info "Creating /snap symlink..."
            if sudo ln -sf /var/.lib/snapd/snap /snap; then
                log_success "Snap symlink created"
            else
                log_warn "Failed to create snap symlink"
            fi
        fi
    fi
}

# Enable Bluetooth service (all destinations)
enable_bluetooth_service() {
    log_info "Enabling Bluetooth service for wireless connectivity"
    
    enable_service "bluetooth.service" "Bluetooth wireless connectivity"
}

# Enable CUPS printing service (all destinations)
enable_cups_service() {
    log_info "Enabling CUPS printing service"
    
    enable_service "cups.service" "CUPS printing system"
}

# Enable NetworkManager service (all destinations)
enable_networkmanager_service() {
    log_info "Enabling NetworkManager service"
    
    enable_service "NetworkManager.service" "Network connection management"
}

# Parse and enable services based on configuration
process_services() {
    log_info "Processing services for destination: $CHEZMOI_DESTINATION"
    
    # Always enable basic system services
    enable_bluetooth_service
    enable_cups_service
    enable_networkmanager_service
    
    # Parse services from environment variable if provided
    if [ -n "${CHEZMOI_SERVICES:-}" ]; then
        log_info "Processing configured services: $CHEZMOI_SERVICES"
        
        IFS=',' read -ra SERVICES <<< "$CHEZMOI_SERVICES"
        
        for service in "${SERVICES[@]}"; do
            case "$service" in
                "docker")
                    enable_docker_service
                    ;;
                "snap")
                    enable_snap_services
                    ;;
                *)
                    log_warn "Unknown service configuration: $service"
                    ;;
            esac
        done
    else
        # Fallback: enable services based on destination
        case "$CHEZMOI_DESTINATION" in
            "work")
                enable_docker_service
                ;;
            "leisure")
                enable_snap_services
                ;;
            "test")
                # Test destination: minimal services
                log_info "Test destination: only basic services enabled"
                ;;
            *)
                log_warn "Unknown destination: $CHEZMOI_DESTINATION"
                ;;
        esac
    fi
}

# Verify service status
verify_services() {
    log_info "Verifying service status"
    
    if [ "${CHEZMOI_DRY_RUN:-false}" != "true" ]; then
        local services_to_check=("bluetooth.service" "cups.service" "NetworkManager.service")
        
        # Add destination-specific services
        case "$CHEZMOI_DESTINATION" in
            "work")
                services_to_check+=("docker.service")
                ;;
            "leisure")
                services_to_check+=("snapd.socket" "snapd.apparmor.service")
                ;;
        esac
        
        local failed_services=()
        
        for service in "${services_to_check[@]}"; do
            if service_exists "$service"; then
                if is_service_enabled "$service" && is_service_active "$service"; then
                    log_success "Service $service is enabled and running"
                else
                    failed_services+=("$service")
                fi
            fi
        done
        
        if [ ${#failed_services[@]} -eq 0 ]; then
            log_success "All expected services are enabled and running"
        else
            log_warn "Some services are not properly configured: ${failed_services[*]}"
        fi
    else
        log_info "Dry-run: Would verify service status for destination $CHEZMOI_DESTINATION"
    fi
}

# Main execution
main() {
    log_info "Starting: $SCRIPT_PURPOSE"
    log_debug "OS: $CHEZMOI_OS_ID"
    log_debug "Destination: $CHEZMOI_DESTINATION"
    log_debug "Services: ${CHEZMOI_SERVICES:-auto-detect}"
    
    validate_environment
    
    process_services
    
    verify_services
    
    log_success "$SCRIPT_PURPOSE completed successfully"
    
    # Service summary
    echo ""
    echo "=== Service Configuration Summary ==="
    echo "Destination: $CHEZMOI_DESTINATION"
    echo "✓ Basic system services enabled (Bluetooth, CUPS, NetworkManager)"
    
    case "$CHEZMOI_DESTINATION" in
        "work")
            echo "✓ Development services enabled (Docker)"
            ;;
        "leisure")
            echo "✓ System software services enabled (Snap)"
            ;;
        "test")
            echo "✓ Minimal service configuration"
            ;;
    esac
    
    echo ""
    echo "=== Next Steps ==="
    echo "1. Logout/login if user groups were modified"
    echo "2. Check service status: systemctl status <service-name>"
    echo "3. Restart services if needed: sudo systemctl restart <service-name>"
    echo ""
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
