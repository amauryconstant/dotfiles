#!/usr/bin/env sh

# Script: session-restore.sh
# Purpose: Restore Hyprland session using enriched data with proper launch commands
# Requirements: Arch Linux, hyprctl, jaq

SESSION_DIR="$HOME/.local/state/dotfiles"
SINGLE_INSTANCE_FILE="$HOME/.config/dotfiles/session-single-instance-apps.conf"

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

# Load single-instance apps (one per line)
load_single_instance_apps() {
    if [ -f "$SINGLE_INSTANCE_FILE" ]; then
        grep -v '^#' "$SINGLE_INSTANCE_FILE" | grep -v '^$'
    else
        # Default single-instance apps
        printf "firefox\nchromium\nbrave\ncode\ncode-oss\nvscodium\n"
    fi
}

# Check if app should launch only once
is_single_instance_app() {
    launch_cmd="$1"
    single_instance_apps="$2"

    # Extract base command (handle "flatpak run ..." format)
    base_cmd=$(echo "$launch_cmd" | awk '{print $NF}' | xargs basename)

    # Check if in single-instance list (case-insensitive)
    echo "$single_instance_apps" | grep -qi "^${base_cmd}$"
}

# Launch application with proper command
launch_app() {
    class="$1"
    launch_cmd="$2"
    workspace_id="$3"
    cwd="$4"

    # For terminal apps with CWD, append --working-directory if supported
    if [ -n "$cwd" ]; then
        case "$class" in
            "com.mitchellh.ghostty"|"ghostty")
                # Ghostty: Launch in correct directory using --working-directory
                hyprctl dispatch exec "[workspace $workspace_id silent] ghostty --working-directory=\"$cwd\"" >/dev/null 2>&1
                return
                ;;
            "kitty")
                # Kitty: Launch with --directory
                hyprctl dispatch exec "[workspace $workspace_id silent] kitty --directory=\"$cwd\"" >/dev/null 2>&1
                return
                ;;
            "alacritty")
                # Alacritty: Launch with --working-directory
                hyprctl dispatch exec "[workspace $workspace_id silent] alacritty --working-directory \"$cwd\"" >/dev/null 2>&1
                return
                ;;
        esac
    fi

    # Standard app launch
    hyprctl dispatch exec "[workspace $workspace_id silent] $launch_cmd" >/dev/null 2>&1
}

# Main restore logic
restore_session() {
    notify-send "Session Manager" "Restoring Hyprland session from slot: $SLOT..." -t 2000

    # Read enrichment file
    session_data=$(cat "$enrichment_file")

    # Load single-instance app list
    single_instance_apps=$(load_single_instance_apps)

    # Build launch list with smart grouping
    temp_apps=$(mktemp)
    temp_seen=$(mktemp)

    echo "$session_data" | jaq -r '
        .clients[] |
        "\(.launchCommand)|\(.workspace.id)|\(.cwd // "")"
    ' | while IFS='|' read -r launch_cmd workspace_id cwd; do
        # Check if single-instance app
        if is_single_instance_app "$launch_cmd" "$single_instance_apps"; then
            # Single-instance: Check if already added
            if ! grep -q "^${launch_cmd}|" "$temp_seen"; then
                echo "$launch_cmd|$workspace_id|$cwd" >> "$temp_apps"
                echo "$launch_cmd|" >> "$temp_seen"
            fi
        else
            # Multi-instance: Add every occurrence
            echo "$launch_cmd|$workspace_id|$cwd" >> "$temp_apps"
        fi
    done

    # Launch each app
    while IFS='|' read -r launch_cmd workspace_id cwd; do
        # Derive class from launch command for CWD handling
        class=$(echo "$launch_cmd" | awk '{print $NF}' | xargs basename)

        launch_app "$class" "$launch_cmd" "$workspace_id" "$cwd"

        # Small delay to avoid overwhelming the compositor
        sleep 0.2
    done < "$temp_apps"

    rm -f "$temp_apps" "$temp_seen"

    # Wait for windows to appear and settle
    sleep 3

    window_count=$(echo "$session_data" | jaq -r '.clients | length')
    notify-send "Session Manager" "✅ Restored session from slot: $SLOT ($window_count windows)" -t 3000
}

restore_session
