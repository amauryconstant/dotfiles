#!/usr/bin/env sh

# Script: session-restore.sh
# Purpose: Restore Hyprland session using hyprdrover with CWD restoration
# Requirements: Arch Linux, hyprdrover, hyprctl, jaq

SESSION_DIR="$HOME/.local/state/dotfiles"
POLL_INTERVAL=0.5   # Seconds between polls

# Default slot name
SLOT="${1:-default}"

# Validate slot name
if ! echo "$SLOT" | grep -qE '^[a-zA-Z0-9_-]+$'; then
    notify-send "Session Manager" "❌ Invalid slot name: $SLOT" -u critical -t 3000
    exit 1
fi

# Check if enrichment file exists
enrichment_file="$SESSION_DIR/hyprland-session-$SLOT.json"

if [ ! -f "$enrichment_file" ]; then
    notify-send "Session Manager" "No saved session found for slot: $SLOT" -u critical -t 3000
    exit 1
fi

# Wait for window to appear by class
wait_for_window() {
    _expected_class="$1"
    expected_address="$2"
    timeout="$3"

    start_time=$(date +%s)

    while true; do
        # Check if window with this address exists
        if hyprctl clients -j | jaq -e --arg addr "$expected_address" \
            '.[] | select(.address == $addr)' >/dev/null 2>&1; then
            echo "$expected_address"
            return 0
        fi

        # Check timeout
        elapsed=$(( $(date +%s) - start_time ))
        if [ "$elapsed" -ge "$timeout" ]; then
            return 1  # Timeout
        fi

        sleep "$POLL_INTERVAL"
    done
}

# Restore CWD for terminal windows
restore_terminal_cwds() {
    # Extract CWD enrichment data
    jaq -r '.clients[] | select(.cwd) | @json' "$enrichment_file" | while IFS= read -r window_json; do
        address=$(echo "$window_json" | jaq -r '.address')
        _cwd=$(echo "$window_json" | jaq -r '.cwd')
        class=$(echo "$window_json" | jaq -r '.class')

        # Wait for terminal window to appear
        if wait_for_window "$class" "$address" 10; then
            # Get window PID
            pid=$(hyprctl clients -j | jaq -r --arg addr "$address" \
                '.[] | select(.address == $addr) | .pid')

            if [ -n "$pid" ] && [ "$pid" != "null" ]; then
                # Try to find shell child process
                shell_pid=$(pgrep -P "$pid" 2>/dev/null | head -n 1)

                if [ -n "$shell_pid" ]; then
                    # Send cd command to shell (using hyprctl dispatch exec)
                    # This is a workaround - may not work for all terminals
                    # Alternative: Use terminal-specific commands

                    # For now, we'll just log this as it requires terminal-specific implementation
                    # TODO: Implement terminal-specific CWD restoration
                    continue
                fi
            fi
        fi
    done
}

# Main restore logic
restore_session() {
    notify-send "Session Manager" "Restoring Hyprland session from slot: $SLOT..." -t 2000

    # Phase 1: Use hyprdrover to restore core session (launches apps, positions windows)
    if ! hyprdrover --load "$SLOT" >/dev/null 2>&1; then
        notify-send "Session Manager" "❌ Failed to restore session with hyprdrover" -u critical -t 5000
        exit 1
    fi

    # Phase 2: Wait a moment for windows to appear
    sleep 2

    # Phase 3: Restore terminal CWDs (currently limited - requires terminal-specific impl)
    # restore_terminal_cwds

    # Note: CWD restoration is complex and requires per-terminal implementation.
    # For now, hyprdrover handles the core restoration.
    # Future enhancement: Add terminal-specific CWD restoration logic.

    window_count=$(jaq -r '.clients | length' "$enrichment_file")
    notify-send "Session Manager" "✅ Restored session from slot: $SLOT ($window_count windows)" -t 3000
}

restore_session
