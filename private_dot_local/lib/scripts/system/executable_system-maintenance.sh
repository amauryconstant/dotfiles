#!/usr/bin/env bash

# System Maintenance Tool
# Purpose: Non-interactive system maintenance for automation
# Requirements: Arch Linux, pacman, yay (optional)

# Non-interactive system maintenance
# Usage: system-maintenance [--update|--cleanup|--help]
system-maintenance() {
    case "$1" in
        --help|-h)
            printf "Usage: system-maintenance [--update|--cleanup|--help]\n"
            printf "Simple system maintenance for automation\n"
            printf "\n"
            printf "Options:\n"
            printf "  --update     Update all packages (pacman -Syu)\n"
            printf "  --cleanup    Clean package cache and orphaned packages\n"
            printf "  --help, -h   Show this help message\n"
            printf "\n"
            printf "Without options, shows available maintenance tasks\n"
            return 0
            ;;
        --update)
            printf "\033[1;34m=== SYSTEM UPDATE ===\033[0m\n"
            if command -v pacman >/dev/null 2>&1; then
                printf "\033[0;36mUpdating packages...\033[0m\n"
                if sudo pacman -Syu --noconfirm; then
                    printf "\033[0;32m✓ System update completed\033[0m\n"
                    return 0
                else
                    printf "\033[0;31m✗ System update failed\033[0m\n" >&2
                    return 1
                fi
            else
                printf "\033[0;31mError: pacman not available\033[0m\n" >&2
                return 1
            fi
            ;;
        --cleanup)
            printf "\033[1;34m=== SYSTEM CLEANUP ===\033[0m\n"
            
            # Clean package cache
            if command -v pacman >/dev/null 2>&1; then
                printf "\033[0;36mCleaning package cache...\033[0m\n"
                sudo pacman -Sc --noconfirm >/dev/null 2>&1
            fi
            
            # Remove orphaned packages
            if command -v pacman >/dev/null 2>&1; then
                orphans=$(pacman -Qtdq 2>/dev/null)
                if [ -n "$orphans" ]; then
                    orphan_count=$(echo "$orphans" | wc -l)
                    printf "\033[0;36mRemoving %d orphaned package(s)...\033[0m\n" "$orphan_count"
                    echo "$orphans" | sudo pacman -Rns - --noconfirm >/dev/null 2>&1 || true
                    printf "\033[0;32m✓ Orphaned packages removed\033[0m\n"
                else
                    printf "\033[0;32m✓ No orphaned packages found\033[0m\n"
                fi
            fi
            
            # Clean yay cache if available
            if command -v yay >/dev/null 2>&1; then
                printf "\033[0;36mCleaning AUR cache...\033[0m\n"
                yay -Sc --noconfirm >/dev/null 2>&1 || true
            fi
            
            printf "\033[0;32m✓ System cleanup completed\033[0m\n"
            return 0
            ;;
        "")
            printf "\033[1;34m=== SYSTEM MAINTENANCE ===\033[0m\n"
            printf "Available maintenance options:\n"
            printf "  --update     Update all packages\n"
            printf "  --cleanup    Clean caches and orphaned packages\n"
            printf "  --help       Show detailed help\n"
            printf "\n"
            printf "Usage: system-maintenance [option]\n"
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
    system-maintenance "$@"
fi