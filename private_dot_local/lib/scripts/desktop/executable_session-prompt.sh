#!/usr/bin/env sh

# Script: session-prompt.sh
# Purpose: Prompt user to restore saved Hyprland session
# Requirements: Arch Linux, wofi, notify-send, jaq

SESSION_FILE="$HOME/.local/state/dotfiles/hyprland-session.json"

# Check if session file exists
if [ ! -f "$SESSION_FILE" ]; then
    # No saved session - exit silently
    exit 0
fi

# Check if session is recent (within last 24 hours)
current_time=$(date +%s)
file_time=$(stat -c %Y "$SESSION_FILE")
session_age=$((current_time - file_time))
max_age=$((24 * 60 * 60))  # 24 hours in seconds

if [ "$session_age" -gt "$max_age" ]; then
    # Session too old - don't prompt
    exit 0
fi

# Get session metadata
window_count=$(jaq -r '.windows | length' "$SESSION_FILE")
timestamp=$(jaq -r '.metadata.timestamp' "$SESSION_FILE")

# Format timestamp for display
formatted_time=$(date -d "$timestamp" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "recent")

# Show wofi dialog for selection
choice=$(printf "Restore session ($window_count windows)\nSkip" | wofi \
    --dmenu \
    --prompt "Session from $formatted_time" \
    --width 400 \
    --height 150)

if [ "$choice" = "Restore session ($window_count windows)" ]; then
    # User chose to restore - launch in background
    "$HOME/.local/lib/scripts/desktop/session-restore.sh" &
fi
