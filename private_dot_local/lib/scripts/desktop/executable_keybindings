#!/usr/bin/env sh
# ============================================================================
# Hyprland Dynamic Keybinding Cheatsheet
# ============================================================================
# Displays all active Hyprland keybindings by querying hyprctl in real-time.
# Automatically categorizes by dispatcher type and formats for easy reading.
#
# Dependencies: hyprctl, jaq (jq-compatible), wofi, awk
# Usage: Run directly or bind to a key (e.g., Super + /)
# ============================================================================

# Wofi configuration
WOFI_WIDTH=1200
WOFI_HEIGHT=800
WOFI_STYLE="$HOME/.config/wofi/keybinds.css"

# ============================================================================
# Modifier Bitmask Decoder
# ============================================================================
# Hyprctl returns modmask as a bitmask: 64=SUPER, 8=ALT, 4=CTRL, 1=SHIFT
# This function converts the numeric value to human-readable modifier strings
decode_modmask() {
    local mask=$1
    local mods=""

    # Check each bit and build modifier string
    if [ $((mask & 64)) -ne 0 ]; then
        mods="SUPER"
    fi
    if [ $((mask & 8)) -ne 0 ]; then
        [ -n "$mods" ] && mods="$mods "
        mods="${mods}ALT"
    fi
    if [ $((mask & 4)) -ne 0 ]; then
        [ -n "$mods" ] && mods="$mods "
        mods="${mods}CTRL"
    fi
    if [ $((mask & 1)) -ne 0 ]; then
        [ -n "$mods" ] && mods="$mods "
        mods="${mods}SHIFT"
    fi

    # Return empty string if no modifiers
    echo "$mods"
}

# ============================================================================
# Key Symbol Mapping
# ============================================================================
# Convert special keys to readable names or Nerd Font icons
map_key_symbol() {
    local key="$1"

    # Media keys → Icons
    case "$key" in
        "XF86AudioRaiseVolume") echo "󰝝" ;;
        "XF86AudioLowerVolume") echo "󰝞" ;;
        "XF86AudioMute") echo "󰓄" ;;
        "XF86AudioPlay") echo "󰐊" ;;
        "XF86AudioPause") echo "󰏤" ;;
        "XF86AudioNext") echo "󰒭" ;;
        "XF86AudioPrev") echo "󰒮" ;;
        "XF86MonBrightnessUp") echo "󰃠" ;;
        "XF86MonBrightnessDown") echo "󰃞" ;;

        # Arrow keys → Icons
        "left") echo "" ;;
        "right") echo "" ;;
        "up") echo "" ;;
        "down") echo "" ;;

        # Mouse buttons
        "mouse:272") echo "󰍽 Left" ;;
        "mouse:273") echo "󰍽 Right" ;;
        "mouse_down") echo "󰍽 Wheel↓" ;;
        "mouse_up") echo "󰍽 Wheel↑" ;;

        # Special keys
        "Return") echo "Enter" ;;
        "Print") echo "PrtSc" ;;
        "slash") echo "/" ;;

        # Default: Return as-is (capitalize first letter)
        *) echo "$key" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}' ;;
    esac
}

# ============================================================================
# Category Mapping
# ============================================================================
# Maps Hyprland dispatcher names to user-friendly categories
get_category() {
    local dispatcher="$1"

    case "$dispatcher" in
        "exec") echo "Execute Commands" ;;
        "workspace") echo "Navigate Workspaces" ;;
        "movetoworkspace"|"movetoworkspacesilent") echo "Move Windows" ;;
        "movefocus") echo "Focus Navigation" ;;
        "movewindow"|"resizewindow") echo "Window Movement" ;;
        "killactive"|"togglefloating"|"pseudo"|"togglesplit") echo "Window Management" ;;
        "fullscreen") echo "Toggle Functions" ;;
        "togglespecialworkspace"|"movetoworkspace") echo "Special Workspaces" ;;
        "exit") echo "System Control" ;;
        *) echo "Other Bindings" ;;
    esac
}

# ============================================================================
# Generate User-Friendly Description
# ============================================================================
# Creates a readable description from dispatcher and arguments
get_description() {
    local dispatcher="$1"
    local arg="$2"

    case "$dispatcher" in
        "exec")
            # Clean up common exec commands
            case "$arg" in
                *"ghostty"*) echo "Terminal" ;;
                *"wofi"*) echo "Application launcher" ;;
                *"dolphin"*) echo "File manager" ;;
                *"cliphist"*) echo "Clipboard history" ;;
                *"grim"*"slurp"*) echo "Screenshot (region)" ;;
                *"grim"*) echo "Screenshot (full)" ;;
                *"pamixer -i"*) echo "Volume up" ;;
                *"pamixer -d"*) echo "Volume down" ;;
                *"pamixer -t"*) echo "Toggle mute" ;;
                *"brightnessctl"*"+") echo "Brightness up" ;;
                *"brightnessctl"*"-") echo "Brightness down" ;;
                *"playerctl play-pause"*) echo "Play/Pause" ;;
                *"playerctl next"*) echo "Next track" ;;
                *"playerctl previous"*) echo "Previous track" ;;
                *"hyprlock"*) echo "Lock screen" ;;
                *"wlogout"*) echo "Power menu" ;;
                *) echo "Run: $(echo "$arg" | cut -d' ' -f1)" ;;
            esac
            ;;
        "workspace")
            [ "$arg" = "e+1" ] && echo "Next workspace" && return
            [ "$arg" = "e-1" ] && echo "Previous workspace" && return
            echo "Switch to workspace $arg"
            ;;
        "movetoworkspace"|"movetoworkspacesilent")
            echo "Move to workspace $arg"
            ;;
        "movefocus")
            case "$arg" in
                "l") echo "Focus left" ;;
                "r") echo "Focus right" ;;
                "u") echo "Focus up" ;;
                "d") echo "Focus down" ;;
                *) echo "Focus $arg" ;;
            esac
            ;;
        "killactive") echo "Close window" ;;
        "togglefloating") echo "Toggle floating" ;;
        "fullscreen") echo "Toggle fullscreen" ;;
        "pseudo") echo "Toggle pseudotile" ;;
        "togglesplit") echo "Toggle split direction" ;;
        "togglespecialworkspace") echo "Toggle scratchpad" ;;
        "exit") echo "Exit Hyprland" ;;
        "movewindow") echo "Move window $arg" ;;
        "resizewindow") echo "Resize window (drag)" ;;
        *) echo "$dispatcher $arg" ;;
    esac
}

# ============================================================================
# Main Processing Pipeline
# ============================================================================

# Query Hyprland for all active keybindings (JSON format)
bindings_json=$(hyprctl binds -j)

# Check if hyprctl succeeded
if [ -z "$bindings_json" ] || [ "$bindings_json" = "[]" ]; then
    echo "Error: Unable to fetch keybindings from hyprctl"
    exit 1
fi

# Process JSON with jaq: Extract and format each binding
# Output format: category|modmask|key|dispatcher|arg
processed=$(echo "$bindings_json" | jaq -r '.[] |
    select(.submap == "" or .submap == "default") |
    "\(.modmask)|\(.key)|\(.dispatcher)|\(.arg)"' 2>/dev/null)

if [ -z "$processed" ]; then
    echo "Error: Failed to process keybindings with jaq"
    exit 1
fi

# Transform into categorized, formatted output
output=""
while IFS='|' read -r modmask key dispatcher arg; do
    # Skip empty or invalid entries
    [ -z "$dispatcher" ] && continue

    # Decode modifiers
    mods=$(decode_modmask "$modmask")

    # Map key to symbol
    key_symbol=$(map_key_symbol "$key")

    # Get category
    category=$(get_category "$dispatcher")

    # Get description
    description=$(get_description "$dispatcher" "$arg")

    # Build keybinding string
    if [ -n "$mods" ]; then
        keybind="$mods + $key_symbol"
    else
        keybind="$key_symbol"
    fi

    # Append to output with delimiter
    output="${output}${category}§§${keybind}§§${description}\n"
done << EOF
$processed
EOF

# Sort and group by category using awk
formatted=$(echo -e "$output" | awk -F '§§' '
BEGIN {
    print "󰌌 Keybindings\t\t\t\t\t\t\t󱧣 Description"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
{
    category = $1
    keybind = $2
    description = $3

    # Store bindings by category
    if (!(category in seen)) {
        categories[++cat_count] = category
        seen[category] = 1
    }
    binds[category] = binds[category] sprintf("%-35s  →  %s\n", keybind, description)
}
END {
    # Print each category with its bindings
    for (i = 1; i <= cat_count; i++) {
        cat = categories[i]
        print "\n" cat ":"
        print "─────────────────────────────────────────────────────────────────────────────────"
        printf "%s", binds[cat]
    }
}
')

# Display in wofi
echo "$formatted" | wofi \
    --dmenu \
    --insensitive \
    --prompt "Keybindings" \
    --width "$WOFI_WIDTH" \
    --height "$WOFI_HEIGHT" \
    --style "$WOFI_STYLE" \
    --no-actions \
    > /dev/null

exit 0
