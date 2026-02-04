#!/usr/bin/env sh

# Script: menu-helpers.sh
# Purpose: Shared utilities for menu system
# Requirements: Arch Linux, wofi

# Show menu with Wofi dmenu mode
# Usage: show_menu "Prompt text" "option1|option2|option3"
show_menu() {
    prompt="$1"
    options="$2"

    # Convert pipe-separated options to newline-separated
    echo "$options" | tr '|' '\n' | wofi --dmenu \
        --prompt "$prompt" \
        --width 295 \
        --height 600 \
        --cache-file /dev/null
}

# Show confirmation dialog
# Usage: confirm "Question text"
# Returns: 0 if Yes, 1 if No/Cancel
confirm() {
    question="$1"
    result=$(echo "Yes|No" | tr '|' '\n' | wofi --dmenu \
        --prompt "$question" \
        --width 295 \
        --height 150 \
        --cache-file /dev/null)

    [ "$result" = "Yes" ]
}

# Send notification
# Usage: notify "Title" "Message" [timeout_ms]
notify() {
    title="$1"
    message="$2"
    timeout="${3:-3000}"

    notify-send "$title" "$message" -t "$timeout"
}
