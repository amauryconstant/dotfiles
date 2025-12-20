#!/usr/bin/env sh

# Script: state-manager.sh
# Purpose: Unified state tracking for toggle utilities
# Requirements: Arch Linux, coreutils

# State directory
STATE_DIR="$HOME/.local/state/dotfiles"

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Usage information
usage() {
    cat << EOF
Usage: state-manager <command> [args]

Commands:
    set <name>              Create state marker
    clear <pattern>         Remove state markers (glob support)
    exists <name>           Check if state exists (exit 0 if exists)
    list                    List all state markers

Examples:
    state-manager set idle-disabled
    state-manager exists idle-disabled && echo "Idle is disabled"
    state-manager clear "idle-*"
    state-manager list
EOF
}

# Main command handler
case "$1" in
    set)
        if [ -z "$2" ]; then
            echo "Error: state name required" >&2
            usage
            exit 1
        fi
        touch "$STATE_DIR/$2"
        ;;

    clear)
        if [ -z "$2" ]; then
            echo "Error: state pattern required" >&2
            usage
            exit 1
        fi
        # Use find with pattern matching for safe deletion
        find "$STATE_DIR" -maxdepth 1 -type f -name "$2" -delete
        ;;

    exists)
        if [ -z "$2" ]; then
            echo "Error: state name required" >&2
            usage
            exit 1
        fi
        [ -f "$STATE_DIR/$2" ]
        ;;

    list)
        find "$STATE_DIR" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | sort
        ;;

    *)
        echo "Error: invalid command '$1'" >&2
        usage
        exit 1
        ;;
esac
