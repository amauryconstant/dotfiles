#!/usr/bin/env sh

# Script: session-restore.sh
# Purpose: Restore Hyprland session using enriched data with proper launch commands
# Requirements: Arch Linux, hyprctl, jaq

SESSION_DIR="$HOME/.local/state/dotfiles"
SINGLE_INSTANCE_FILE="$HOME/.config/dotfiles/session-single-instance-apps.conf"

# Default slot name
SLOT="${1:-default}"

# Configurable timing (via environment variables)
# Users can set in ~/.zshrc or per-command:
#   export DOTFILES_SESSION_LAUNCH_DELAY=0.5
#   export DOTFILES_SESSION_SETTLE_DELAY=5
LAUNCH_DELAY="${DOTFILES_SESSION_LAUNCH_DELAY:-0.2}"
SETTLE_DELAY="${DOTFILES_SESSION_SETTLE_DELAY:-3}"

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

    # Extract base command - handle Flatpak and standard commands
    if echo "$launch_cmd" | grep -q "^flatpak run"; then
        # Flatpak: "flatpak run com.spotify.Client" → extract "spotify" (penultimate segment)
        base_cmd=$(echo "$launch_cmd" | awk '{print $NF}' | awk -F'.' '{
            # com.spotify.Client → spotify
            if (NF > 1) print $(NF-1)
            else print $NF
        }' | tr '[:upper:]' '[:lower:]')
    else
        # Standard: "ghostty --arg value" → extract "ghostty" (first word only)
        base_cmd=$(echo "$launch_cmd" | awk '{print $1}' | xargs basename | tr '[:upper:]' '[:lower:]')
    fi

    # Check if in single-instance list (case-insensitive)
    echo "$single_instance_apps" | grep -qi "^${base_cmd}$"
}

# Validate workspace exists, fallback to current workspace
validate_workspace() {
    workspace_id="$1"

    # Check if workspace exists in current Hyprland session
    if hyprctl workspaces -j 2>/dev/null | jaq -e --arg id "$workspace_id" '.[] | select(.id == ($id | tonumber))' >/dev/null 2>&1; then
        echo "$workspace_id"
    else
        # Workspace doesn't exist, use current workspace
        hyprctl activeworkspace -j 2>/dev/null | jaq -r '.id' || echo "1"
    fi
}

# Launch application with proper command
launch_app() {
    class="$1"
    launch_cmd="$2"
    workspace_id="$3"
    cwd="$4"

    # CWD validation - fallback to HOME if directory doesn't exist
    if [ -n "$cwd" ] && [ ! -d "$cwd" ]; then
        cwd="$HOME"
    fi

    # For terminal apps with CWD, append --working-directory if supported
    if [ -n "$cwd" ]; then
        case "$class" in
            "com.mitchellh.ghostty"|"ghostty")
                # Ghostty: Launch in correct directory using --working-directory
                hyprctl dispatch exec "[workspace $workspace_id silent] ghostty --working-directory='$cwd'" 2>&1 | grep -q "error" && return 1
                return 0
                ;;
            "kitty")
                # Kitty: Launch with --directory
                hyprctl dispatch exec "[workspace $workspace_id silent] kitty --directory='$cwd'" 2>&1 | grep -q "error" && return 1
                return 0
                ;;
            "alacritty")
                # Alacritty: Launch with --working-directory
                hyprctl dispatch exec "[workspace $workspace_id silent] alacritty --working-directory '$cwd'" 2>&1 | grep -q "error" && return 1
                return 0
                ;;
        esac
    fi

    # Standard app launch
    hyprctl dispatch exec "[workspace $workspace_id silent] $launch_cmd" 2>&1 | grep -q "error" && return 1
    return 0
}

# Main restore logic
restore_session() {
    notify-send "Session Manager" "Restoring session from slot: $SLOT\n(${SETTLE_DELAY}s settle time)" -t 2000

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

    # Count windows before restore
    initial_count=$(hyprctl clients -j 2>/dev/null | jaq '. | length' || echo "0")
    expected_count=0

    # Launch each app
    while IFS='|' read -r launch_cmd workspace_id cwd; do
        expected_count=$((expected_count + 1))

        # Validate workspace exists
        workspace_id=$(validate_workspace "$workspace_id")

        # Derive class from launch command for CWD handling (use first word for standard commands)
        class=$(echo "$launch_cmd" | awk '{print $1}' | xargs basename)

        launch_app "$class" "$launch_cmd" "$workspace_id" "$cwd"

        # Small delay to avoid overwhelming the compositor
        sleep "$LAUNCH_DELAY"
    done < "$temp_apps"

    rm -f "$temp_apps" "$temp_seen"

    # Wait for windows to appear and settle
    sleep "$SETTLE_DELAY"

    # Count windows after restore and calculate restored count
    final_count=$(hyprctl clients -j 2>/dev/null | jaq '. | length' || echo "0")
    restored_count=$((final_count - initial_count))

    # Smart notification based on results
    if [ "$restored_count" -eq "$expected_count" ]; then
        notify-send "Session Manager" "✅ Restored session from slot: $SLOT ($restored_count windows)" -t 3000
    elif [ "$restored_count" -gt 0 ]; then
        notify-send "Session Manager" "⚠️ Partial restore: $restored_count/$expected_count windows\nSome apps may have failed" -u normal -t 5000
    else
        notify-send "Session Manager" "❌ Restore failed\nNo windows launched" -u critical -t 5000
    fi
}

restore_session
