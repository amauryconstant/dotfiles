#!/usr/bin/env sh

# Script: launch-or-focus.sh
# Purpose: Focus existing window or launch application (single-instance behavior)
# Requirements: Arch Linux, hyprctl, jaq
# Adapted from: Omarchy's omarchy-launch-or-focus

# Source UI library
if [ -n "$UI_LIB" ] && [ -f "$UI_LIB" ]; then
    . "$UI_LIB"
elif [ -f "$HOME/.local/lib/scripts/core/gum-ui.sh" ]; then
    . "$HOME/.local/lib/scripts/core/gum-ui.sh"
else
    echo "Error: UI library not found" >&2
    exit 1
fi

# Usage: launch-or-focus.sh [pattern] [launch-command]
# Example: launch-or-focus.sh dolphin
# Example: launch-or-focus.sh btop "ghostty -e btop"

WINDOW_PATTERN="$1"
LAUNCH_COMMAND="${2:-$WINDOW_PATTERN}"

if [ -z "$WINDOW_PATTERN" ]; then
    ui_error "Usage: launch-or-focus.sh [pattern] [launch-command]"
    exit 1
fi

# Query all windows and find matching class or title
# Uses case-insensitive regex matching on both fields
WINDOW_ADDRESS=$(hyprctl clients -j | jaq -r \
    --arg pattern "$WINDOW_PATTERN" \
    '.[] | select(
        (.class | test($pattern; "i")) or
        (.title | test($pattern; "i"))
    ) | .address' | head -n1)

if [ -n "$WINDOW_ADDRESS" ]; then
    # Window exists - focus it
    hyprctl dispatch focuswindow "address:$WINDOW_ADDRESS"
else
    # Window doesn't exist - launch application
    $LAUNCH_COMMAND &
fi
