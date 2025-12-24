#!/usr/bin/env sh

# Script: session-restore.sh
# Purpose: Restore Hyprland session from saved JSON
# Requirements: Arch Linux, hyprctl, jaq

SESSION_FILE="$HOME/.local/state/dotfiles/hyprland-session.json"
RESTORE_TIMEOUT=30  # Max seconds to wait for window appearance
POLL_INTERVAL=0.5   # Seconds between polls

# Check if session file exists
if [ ! -f "$SESSION_FILE" ]; then
    notify-send "Session Manager" "No saved session found" -u critical -t 3000
    exit 1
fi

# Validate monitor configuration
validate_monitors() {
    saved_monitors=$(jaq -r '.metadata.monitor_count' "$SESSION_FILE")
    current_monitors=$(hyprctl monitors -j | jaq 'length')

    if [ "$saved_monitors" -ne "$current_monitors" ]; then
        notify-send "Session Manager" "⚠️  Monitor config changed (saved: $saved_monitors, current: $current_monitors)" -t 5000
        return 1
    fi
    return 0
}

# Wait for window to appear
wait_for_window() {
    expected_class="$1"
    instance_number="$2"
    timeout="$3"

    start_time=$(date +%s)

    while true; do
        # Query windows matching class
        matching=$(hyprctl clients -j | jaq -r --arg class "$expected_class" \
            '[.[] | select(.class == $class)]')

        current_count=$(echo "$matching" | jaq 'length')

        # Wait until we have at least instance_number windows
        if [ "$current_count" -ge "$instance_number" ]; then
            # Return address of Nth instance (0-indexed in jaq)
            address=$(echo "$matching" | jaq -r --argjson idx "$((instance_number - 1))" '.[$idx].address')
            echo "$address"
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

# Launch application
launch_app() {
    command="$1"
    cwd="$2"

    # Check if command exists
    base_cmd=$(echo "$command" | awk '{print $1}')
    if ! command -v "$base_cmd" >/dev/null 2>&1; then
        return 1
    fi

    if [ "$cwd" != "null" ] && [ -d "$cwd" ]; then
        # Terminal with CWD - change directory before launch
        (cd "$cwd" && setsid -f $command >/dev/null 2>&1) &
    else
        # Regular app
        setsid -f $command >/dev/null 2>&1 &
    fi

    return 0
}

# Position window
position_window() {
    address="$1"
    workspace="$2"
    x="$3"
    y="$4"
    width="$5"
    height="$6"
    floating="$7"

    # Verify window still exists
    if ! hyprctl clients -j | jaq -e --arg addr "$address" '.[] | select(.address == $addr)' >/dev/null 2>&1; then
        return 1
    fi

    # Build batch command for atomic operations
    batch_cmd=""

    # Move to workspace (silently - creates workspace if needed)
    batch_cmd="${batch_cmd}dispatch movetoworkspacesilent $workspace,address:$address;"

    # Set floating state if needed
    if [ "$floating" = "true" ]; then
        batch_cmd="${batch_cmd}dispatch togglefloating address:$address;"
        # Position and resize floating windows
        batch_cmd="${batch_cmd}dispatch movewindowpixel exact $x $y,address:$address;"
        batch_cmd="${batch_cmd}dispatch resizewindowpixel exact $width $height,address:$address;"
    fi

    # Execute atomically
    hyprctl --batch "$batch_cmd" >/dev/null 2>&1
    return 0
}

# Main restore logic
restore_session() {
    notify-send "Session Manager" "Restoring Hyprland session..." -t 2000

    # Validate monitors
    validate_monitors  # Non-blocking, just warns

    # Count total windows
    window_count=$(jaq -r '.windows | length' "$SESSION_FILE")

    # Phase 1: Launch all applications
    notify-send "Session Manager" "Launching $window_count applications..." -t 2000

    jaq -r '.windows[] | @json' "$SESSION_FILE" | while IFS= read -r window_json; do
        class=$(echo "$window_json" | jaq -r '.class')
        command=$(echo "$window_json" | jaq -r '.launchCommand')
        cwd=$(echo "$window_json" | jaq -r '.cwd')

        # Launch app
        if ! launch_app "$command" "$cwd"; then
            notify-send "Session Manager" "⚠️  Failed to launch: $class" -u low -t 1000
        fi

        # Small delay between launches
        sleep 0.2
    done

    # Phase 2 & 3: Wait for windows and position them
    notify-send "Session Manager" "Positioning windows..." -t 2000

    success_count=0
    failure_count=0

    # Group windows by class to track instances
    temp_file=$(mktemp)
    jaq -r '.windows[] | @json' "$SESSION_FILE" > "$temp_file"

    while IFS= read -r window_json; do
        class=$(echo "$window_json" | jaq -r '.class')
        workspace=$(echo "$window_json" | jaq -r '.workspace.id // .workspace')
        x=$(echo "$window_json" | jaq -r '.x')
        y=$(echo "$window_json" | jaq -r '.y')
        width=$(echo "$window_json" | jaq -r '.width')
        height=$(echo "$window_json" | jaq -r '.height')
        floating=$(echo "$window_json" | jaq -r '.floating')
        instance_num=$(echo "$window_json" | jaq -r '.instanceNumber')

        # Wait for window to appear
        if address=$(wait_for_window "$class" "$instance_num" "$RESTORE_TIMEOUT"); then
            # Window appeared - position it
            if position_window "$address" "$workspace" "$x" "$y" "$width" "$height" "$floating"; then
                success_count=$((success_count + 1))
            else
                failure_count=$((failure_count + 1))
            fi
        else
            # Timeout - window didn't appear
            failure_count=$((failure_count + 1))
        fi
    done < "$temp_file"

    rm -f "$temp_file"

    # Summary notification
    if [ "$failure_count" -eq 0 ]; then
        notify-send "Session Manager" "✅ Restored $success_count windows" -t 3000
    else
        notify-send "Session Manager" "⚠️  Restored $success_count/$window_count windows ($failure_count failed)" -u normal -t 5000
    fi
}

restore_session
