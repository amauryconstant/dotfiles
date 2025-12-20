#!/usr/bin/env bash

# System Maintenance Tool
# Purpose: Non-interactive system maintenance for automation
# Requirements: Arch Linux, pacman, paru (optional)

# Source UI library
if [ -n "$UI_LIB" ] && [ -f "$UI_LIB" ]; then
    # shellcheck source=/dev/null
    . "$UI_LIB"
elif [ -f "$HOME/.local/lib/scripts/core/gum-ui.sh" ]; then
    . "$HOME/.local/lib/scripts/core/gum-ui.sh"
else
    echo "Error: UI library not found" >&2
    exit 1
fi

# Non-interactive system maintenance
# Usage: system-maintenance [--update|--cleanup|--help]
system-maintenance() {
    case "$1" in
        --help|-h)
            ui_info "Usage: system-maintenance [--update|--cleanup|--help]"
            ui_info "Simple system maintenance for automation"
            echo ""
            ui_info "Options:"
            ui_info "  --update     Update all packages (pacman -Syu)"
            ui_info "  --cleanup    Clean package cache and orphaned packages"
            ui_info "  --help, -h   Show this help message"
            echo ""
            ui_info "Without options, shows available maintenance tasks"
            return 0
            ;;
        --update)
            # Call pre-maintenance hook
            if [ -f "$HOME/.local/lib/scripts/core/hook-runner.sh" ]; then
                "$HOME/.local/lib/scripts/core/hook-runner.sh" pre-maintenance 2>/dev/null || true
            fi

            ui_title "SYSTEM UPDATE"
            if command -v pacman >/dev/null 2>&1; then
                ui_step "Updating packages..."
                if sudo pacman -Syu --noconfirm; then
                    ui_success "System update completed"

                    # Call post-maintenance hook
                    if [ -f "$HOME/.local/lib/scripts/core/hook-runner.sh" ]; then
                        "$HOME/.local/lib/scripts/core/hook-runner.sh" post-maintenance "success" 2>/dev/null || true
                    fi
                    return 0
                else
                    ui_error "System update failed"

                    # Call post-maintenance hook with failure status
                    if [ -f "$HOME/.local/lib/scripts/core/hook-runner.sh" ]; then
                        "$HOME/.local/lib/scripts/core/hook-runner.sh" post-maintenance "failure" 2>/dev/null || true
                    fi
                    return 1
                fi
            else
                ui_error "pacman not available"
                return 1
            fi
            ;;
        --cleanup)
            # Call pre-maintenance hook
            if [ -f "$HOME/.local/lib/scripts/core/hook-runner.sh" ]; then
                "$HOME/.local/lib/scripts/core/hook-runner.sh" pre-maintenance 2>/dev/null || true
            fi

            ui_title "SYSTEM CLEANUP"

            # Clean package cache
            if command -v pacman >/dev/null 2>&1; then
                ui_step "Cleaning package cache..."
                sudo pacman -Sc --noconfirm >/dev/null 2>&1
            fi

            # Remove orphaned packages
            if command -v pacman >/dev/null 2>&1; then
                orphans=$(pacman -Qtdq 2>/dev/null)
                if [ -n "$orphans" ]; then
                    orphan_count=$(echo "$orphans" | wc -l)
                    ui_step "Removing $orphan_count orphaned package(s)..."
                    echo "$orphans" | sudo pacman -Rns - --noconfirm >/dev/null 2>&1 || true
                    ui_success "Orphaned packages removed"
                else
                    ui_success "No orphaned packages found"
                fi
            fi

            # Clean paru cache if available
            if command -v paru >/dev/null 2>&1; then
                ui_step "Cleaning AUR cache..."
                paru -Sc --noconfirm >/dev/null 2>&1 || true
            fi

            ui_success "System cleanup completed"

            # Call post-maintenance hook
            if [ -f "$HOME/.local/lib/scripts/core/hook-runner.sh" ]; then
                "$HOME/.local/lib/scripts/core/hook-runner.sh" post-maintenance "success" 2>/dev/null || true
            fi
            return 0
            ;;
        "")
            ui_title "SYSTEM MAINTENANCE"
            ui_info "Available maintenance options:"
            ui_info "  --update     Update all packages"
            ui_info "  --cleanup    Clean caches and orphaned packages"
            ui_info "  --help       Show detailed help"
            echo ""
            ui_info "Usage: system-maintenance [option]"
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
    system-maintenance "$@"
fi