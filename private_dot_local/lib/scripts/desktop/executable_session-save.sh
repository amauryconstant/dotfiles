#!/usr/bin/env sh

# Script: session-save.sh
# Purpose: Save current Hyprland session state to JSON
# Requirements: Arch Linux, hyprctl, jaq

SESSION_FILE="$HOME/.local/state/dotfiles/hyprland-session.json"
SESSION_DIR="$(dirname "$SESSION_FILE")"
DENYLIST_FILE="$HOME/.config/dotfiles/session-denylist.conf"

# Ensure state directory exists
mkdir -p "$SESSION_DIR"

# Load denylist (one class per line)
load_denylist() {
    if [ -f "$DENYLIST_FILE" ]; then
        grep -v '^#' "$DENYLIST_FILE" | grep -v '^$'
    else
        # Default denylist (ephemeral/UI elements)
        printf "wofi\nwlogout\ndunst\nwaybar\nhyprpicker\n"
    fi
}

# Map window class to launch command
map_class_to_command() {
    class="$1"
    pid="$2"

    # Try reading /proc/PID/cmdline for actual launch command
    if [ -f "/proc/$pid/cmdline" ]; then
        cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" | sed 's/[[:space:]]*$//')
        if [ -n "$cmdline" ]; then
            printf "%s" "$cmdline"
            return
        fi
    fi

    # Fallback: Heuristic mapping (class → command)
    case "$class" in
        firefox|Firefox) printf "firefox" ;;
        code|Code) printf "code" ;;
        ghostty|Ghostty) printf "ghostty" ;;
        kitty|Kitty) printf "kitty" ;;
        alacritty|Alacritty) printf "alacritify" ;;
        foot|Foot) printf "foot" ;;
        wezterm|WezTerm) printf "wezterm" ;;
        thunar|Thunar) printf "thunar" ;;
        dolphin|Dolphin) printf "dolphin" ;;
        discord|Discord) printf "discord" ;;
        spotify|Spotify) printf "spotify" ;;
        obsidian|Obsidian) printf "obsidian" ;;
        slack|Slack) printf "slack" ;;
        *)
            # Fallback: use class as command (lowercase)
            printf "%s" "$class" | tr '[:upper:]' '[:lower:]'
            ;;
    esac
}

# Extract terminal CWD from PID
get_terminal_cwd() {
    pid="$1"
    class="$2"

    # Only for terminal apps
    case "$class" in
        ghostty|kitty|alacritty|foot|wezterm|Ghostty|Kitty|Alacritty|Foot|WezTerm)
            # Find shell child process
            shell_pid=$(pgrep -P "$pid" 2>/dev/null | head -n 1)
            [ -z "$shell_pid" ] && shell_pid="$pid"

            # Read CWD from /proc
            if [ -d "/proc/$shell_pid" ]; then
                cwd=$(readlink "/proc/$shell_pid/cwd" 2>/dev/null)
                if [ -d "$cwd" ]; then
                    printf "%s" "$cwd"
                    return
                fi
            fi
            ;;
    esac

    printf "null"
}

# Main save logic
save_session() {
    notify-send "Session Manager" "Saving Hyprland session..." -t 2000

    # Query monitors
    monitors_json=$(hyprctl monitors -j)

    # Query all windows
    windows_json=$(hyprctl clients -j)

    # Get denylist as JSON array
    denylist_json=$(load_denylist | jaq -R -s 'split("\n") | map(select(length > 0))')

    # Create temp file for enriched windows
    temp_windows=$(mktemp)

    # Process each window and enrich with command/cwd
    echo "$windows_json" | jaq -c '.[]' | while IFS= read -r window; do
        class=$(echo "$window" | jaq -r '.class')
        pid=$(echo "$window" | jaq -r '.pid')

        # Check if denylisted
        is_denied=$(echo "$denylist_json" | jaq -e --arg class "$class" 'index($class)' >/dev/null 2>&1 && echo "yes" || echo "no")

        if [ "$is_denied" = "yes" ]; then
            continue
        fi

        # Get launch command and CWD
        launch_command=$(map_class_to_command "$class" "$pid")
        cwd=$(get_terminal_cwd "$pid" "$class")

        # Add launch command and CWD to window object
        enriched_window=$(echo "$window" | jaq \
            --arg cmd "$launch_command" \
            --arg cwd "$cwd" \
            '. + {launchCommand: $cmd, cwd: $cwd}')

        echo "$enriched_window" >> "$temp_windows"
    done

    # Read enriched windows and add instance numbers
    if [ -s "$temp_windows" ]; then
        filtered_windows=$(jaq -s '
            group_by(.class) |
            map(to_entries | map(.value + {instanceNumber: (.key + 1)})) |
            flatten
        ' "$temp_windows")
    else
        filtered_windows="[]"
    fi

    rm -f "$temp_windows"

    # Build metadata
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    hypr_version=$(hyprctl version | head -1 | awk '{print $2}' 2>/dev/null || echo "unknown")
    monitor_count=$(echo "$monitors_json" | jaq 'length')
    workspace_count=$(hyprctl workspaces -j | jaq 'length')

    # Build final JSON
    session_json=$(jaq -n \
        --arg timestamp "$timestamp" \
        --arg version "$hypr_version" \
        --argjson monitors "$monitors_json" \
        --argjson windows "$filtered_windows" \
        --argjson monitor_count "$monitor_count" \
        --argjson workspace_count "$workspace_count" \
        '{
            metadata: {
                timestamp: $timestamp,
                hyprland_version: $version,
                monitor_count: $monitor_count,
                workspace_count: $workspace_count
            },
            monitors: $monitors,
            windows: $windows
        }')

    # Write session file
    echo "$session_json" > "$SESSION_FILE"

    window_count=$(echo "$session_json" | jaq '.windows | length')
    notify-send "Session Manager" "✅ Saved $window_count windows to session" -t 3000
}

save_session
