#!/usr/bin/env bash

# Tailscale Network Management Tool
# Purpose: Interactive Tailscale VPN management with exit node support
# Requirements: Arch Linux, tailscale, gum (UI library)

# Source the UI library
if [ -f "$UI_LIB" ]; then
    # shellcheck source=/dev/null
    . "$UI_LIB"
else
    echo "Error: UI library not found at $UI_LIB" >&2
    exit 1
fi

show_help() {
    ui_title "Tailscale Management Tool - Usage"
    ui_spacer
    ui_info "Usage: ts [command] [options]"
    ui_spacer
    ui_info "Commands:"
    ui_info "  connect [exit-node]  - Connect to Tailscale (optionally via exit node)"
    ui_info "  disconnect           - Disconnect from Tailscale network"
    ui_info "  status               - Show connection status and peer information"
    ui_info "  --help, -h           - Show this help message"
    ui_spacer
    ui_info "Examples:"
    ui_info "  ts connect                  # Connect without exit node"
    ui_info "  ts connect my-exit-node     # Connect via specific exit node"
    ui_info "  ts status                   # Show current status"
    ui_info "  ts                          # Interactive menu"
}

check_tailscale_installed() {
    if ! command -v tailscale >/dev/null 2>&1; then
        ui_error "Tailscale is not installed"
        ui_info "Install with: sudo pacman -S tailscale"
        return 1
    fi
    return 0
}

check_daemon_running() {
    if ! systemctl is-active tailscaled >/dev/null 2>&1; then
        ui_warning "Tailscale daemon is not running"
        ui_info "Starting Tailscale daemon..."
        if sudo systemctl start tailscaled; then
            ui_success "Tailscale daemon started"
            sleep 2
            return 0
        else
            ui_error "Failed to start Tailscale daemon"
            return 1
        fi
    fi
    return 0
}

ts_connect() {
    check_tailscale_installed || return 1
    check_daemon_running || return 1

    # Check if already connected
    if tailscale status >/dev/null 2>&1; then
        ui_success "Already connected to Tailscale"
        ts_status
        return 0
    fi

    local exit_node="$1"

    if [ -z "$exit_node" ]; then
        ui_title "🚀 Connecting to Tailscale..."
        if ui_spin_interactive "Establishing connection..." "tailscale up"; then
            ui_success "Successfully connected to Tailscale"
            sleep 1
            ts_status
        else
            ui_error "Failed to connect to Tailscale"
            ui_info "Please check your authentication and network connection"
            return 1
        fi
    else
        ui_title "🌐 Connecting to Tailscale via exit node: $exit_node"
        if ui_spin_interactive "Establishing connection..." "tailscale up --exit-node=\"$exit_node\""; then
            ui_success "Successfully connected to Tailscale"
            sleep 1
            ts_status
        else
            ui_error "Failed to connect to Tailscale"
            ui_info "Please verify the exit node name and try again"
            return 1
        fi
    fi
}

ts_disconnect() {
    check_tailscale_installed || return 1

    # Check if connected
    if ! tailscale status >/dev/null 2>&1; then
        ui_info "Not connected to Tailscale"
        return 0
    fi

    ui_title "🔌 Disconnecting from Tailscale..."

    if ui_spin_interactive "Disconnecting..." "tailscale down"; then
        ui_success "Successfully disconnected from Tailscale"

        # Verify disconnection
        sleep 1
        if ! tailscale status >/dev/null 2>&1; then
            ui_success "Confirmed: No longer connected to Tailscale network"
        else
            ui_warning "Disconnection may not have completed properly"
        fi
    else
        ui_error "Failed to disconnect from Tailscale"
        return 1
    fi
}

ts_status() {
    check_tailscale_installed || return 1

    if ! systemctl is-active tailscaled >/dev/null 2>&1; then
        ui_error "Tailscale daemon is not running"
        ui_info "Run: sudo systemctl start tailscaled"
        return 1
    fi

    ui_title "🔍 Tailscale Status"

    # Show basic status
    if tailscale status >/dev/null 2>&1; then
        ui_success "Connected to Tailscale network"
        ui_spacer

        # Show current IP
        local current_ip
        current_ip=$(tailscale ip -4 2>/dev/null || echo "N/A")
        ui_info "📍 Tailscale IPv4: $current_ip"

        # Show peer count
        local peer_count
        peer_count=$(tailscale status 2>/dev/null | grep -c "^[0-9]" || echo "0")
        ui_info "👥 Active peers: $peer_count"

        # Show exit node if used
        local exit_node
        exit_node=$(tailscale status 2>/dev/null | grep "exit node" | head -1 | awk '{print $1}' || echo "")
        if [ -n "$exit_node" ]; then
            ui_info "🌐 Exit node: $exit_node"
        fi

        ui_spacer
        ui_subtitle "📋 Peer Details:"
        tailscale status 2>/dev/null || ui_warning "No peers available"
    else
        ui_error "Not connected to Tailscale network"
        ui_info "Run: ts connect"
    fi
}

ts_interactive() {
    check_tailscale_installed || return 1

    ui_title "🔐 Tailscale Network Management"

    local action
    action=$(ui_choose "Select an action:" \
        "🚀 Connect to Tailscale" \
        "🌐 Connect with Exit Node" \
        "🔌 Disconnect from Tailscale" \
        "🔍 Show Status" \
        "🚪 Exit")

    case "$action" in
        "🚀 Connect to Tailscale")
            ts_connect
            ;;
        "🌐 Connect with Exit Node")
            local exit_node
            exit_node=$(ui_input "Enter exit node hostname:")
            if [ -n "$exit_node" ]; then
                ts_connect "$exit_node"
            else
                ui_warning "No exit node specified, connecting normally"
                ts_connect
            fi
            ;;
        "🔌 Disconnect from Tailscale")
            ts_disconnect
            ;;
        "🔍 Show Status")
            ts_status
            ;;
        "🚪 Exit"|"")
            ui_info "Goodbye! 👋"
            return 0
            ;;
        *)
            ui_error "Unknown action"
            return 1
            ;;
    esac
}

# Main entry point
main() {
    # Handle help flags
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_help
        return 0
    fi

    # Handle subcommands
    if [[ $# -gt 0 ]]; then
        local command="$1"
        shift

        case "$command" in
            "connect")
                ts_connect "$@"
                ;;
            "disconnect")
                ts_disconnect
                ;;
            "status")
                ts_status
                ;;
            *)
                ui_error "Unknown command: $command"
                show_help
                return 1
                ;;
        esac
    else
        # No arguments - interactive mode
        ts_interactive
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
