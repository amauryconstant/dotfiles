#!/usr/bin/env sh

# Script: launch-or-focus.sh
# Purpose: Focus existing window or launch application (single-instance behavior)
# Requirements: Arch Linux, hyprctl, jaq
# Adapted from: Omarchy's omarchy-launch-or-focus

# Usage: launch-or-focus.sh [pattern] [launch-command]
# Example: launch-or-focus.sh dolphin
# Example: launch-or-focus.sh btop "ghostty -e btop"

WINDOW_PATTERN="$1"
LAUNCH_COMMAND="${2:-$WINDOW_PATTERN}"

if [ -z "$WINDOW_PATTERN" ]; then
    echo "Error: Usage: launch-or-focus.sh [pattern] [launch-command]" >&2
    exit 1
fi

# Query all windows and find matching class or title
# Uses case-insensitive regex matching with word boundaries
WINDOW_ADDRESS=$(hyprctl clients -j | jaq -r \
    --arg pattern "$WINDOW_PATTERN" \
    '.[] | select(
        (.class | test("\\b" + $pattern + "\\b"; "i")) or
        (.title | test("\\b" + $pattern + "\\b"; "i"))
    ) | .address' | head -n1)

if [ -n "$WINDOW_ADDRESS" ]; then
    # Window exists - focus it
    hyprctl dispatch focuswindow "address:$WINDOW_ADDRESS"
else
    # Window doesn't exist - launch application with proper detachment
    setsid -f $LAUNCH_COMMAND >/dev/null 2>&1
fi
