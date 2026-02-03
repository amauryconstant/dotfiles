#!/usr/bin/env sh

# Script: screenshot.sh
# Purpose: Advanced screenshot capture with Satty annotation editor
# Requirements: Arch Linux, grim, slurp, satty, wayfreeze
# Adapted from: Omarchy's omarchy-cmd-screenshot

# Parse arguments
MODE="${1:-smart}"      # smart, region, windows, fullscreen
OUTPUT="${2:-slurp}"    # slurp (editor) or clipboard (direct)

# Output directory (respects XDG)
OUTPUT_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"
mkdir -p "$OUTPUT_DIR"

# Generate timestamp filename
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
OUTPUT_FILE="$OUTPUT_DIR/screenshot-$TIMESTAMP.png"

# Freeze screen for clean capture (prevents visual changes during selection)
if command -v wayfreeze >/dev/null 2>&1; then
    wayfreeze &
    WAYFREEZE_PID=$!
    sleep 0.1  # Wait for freeze to activate
fi

# Select region based on mode
case "$MODE" in
    region)
        # Free-form region selection
        GEOMETRY=$(slurp 2>/dev/null)
        ;;
    windows)
        # Snap to window boundaries
        GEOMETRY=$(slurp -r 2>/dev/null)
        ;;
    fullscreen)
        # Active monitor only (no selection needed)
        GEOMETRY=""
        ;;
    smart|*)
        # Smart mode: area selection with auto-snap
        GEOMETRY=$(slurp 2>/dev/null)

        # Configurable threshold (default 20px)
        SMART_THRESHOLD="${SMART_THRESHOLD:-20}"

        # If selection is tiny, assume accidental click
        # Snap to containing window or monitor instead
        if [ -n "$GEOMETRY" ]; then
            WIDTH=$(echo "$GEOMETRY" | cut -d'x' -f1 | cut -d' ' -f2)
            HEIGHT=$(echo "$GEOMETRY" | cut -d'x' -f2 | cut -d'+' -f1)

            if [ "$WIDTH" -lt "$SMART_THRESHOLD" ] || [ "$HEIGHT" -lt "$SMART_THRESHOLD" ]; then
                # Get mouse position
                MOUSE_POS=$(slurp -p 2>/dev/null)

                # Find window at that position (focused window prioritized)
                GEOMETRY=$(hyprctl -j clients | jaq -r \
                    --arg pos "$MOUSE_POS" \
                    '[.[] | select(.at[0] <= ($pos | split(",")[0] | tonumber) and
                                   .at[1] <= ($pos | split(",")[1] | tonumber) and
                                   (.at[0] + .size[0]) >= ($pos | split(",")[0] | tonumber) and
                                   (.at[1] + .size[1]) >= ($pos | split(",")[1] | tonumber))] |
                     sort_by(if .focus then 0 else 1 end) |
                     .[0] |
                     "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')

                # If no window found, fall back to monitor bounds
                if [ -z "$GEOMETRY" ]; then
                    GEOMETRY=$(hyprctl monitors -j | jaq -r \
                        --arg pos "$MOUSE_POS" \
                        '.[] | select(.x <= ($pos | split(",")[0] | tonumber) and
                                      .y <= ($pos | split(",")[1] | tonumber) and
                                      (.x + .width) >= ($pos | split(",")[0] | tonumber) and
                                      (.y + .height) >= ($pos | split(",")[1] | tonumber)) |
                         "\(.x),\(.y) \(.width)x\(.height)"' | head -n1)
                fi
            fi
        fi
        ;;
esac

# Kill wayfreeze
if [ -n "$WAYFREEZE_PID" ]; then
    kill "$WAYFREEZE_PID" 2>/dev/null
fi

# Check if user cancelled selection
if [ -z "$GEOMETRY" ] && [ "$MODE" != "fullscreen" ]; then
    notify-send "Screenshot" "Cancelled" -t 2000
    exit 1
fi

# Capture screenshot
if [ -n "$GEOMETRY" ]; then
    grim -g "$GEOMETRY" "$OUTPUT_FILE"
else
    grim "$OUTPUT_FILE"
fi

# Check if capture succeeded
if [ ! -f "$OUTPUT_FILE" ]; then
    notify-send "Screenshot" "Failed to capture" -t 2000
    exit 1
fi

# Process based on output mode
case "$OUTPUT" in
    clipboard)
        # Direct to clipboard (bypass editor)
        wl-copy < "$OUTPUT_FILE"
        notify-send "📸 Screenshot" "Copied to clipboard" -t 2000
        # Keep file for 5 seconds then delete (allows paste)
        (sleep 5 && rm -f "$OUTPUT_FILE") &
        ;;
    slurp|*)
        # Open Satty editor
        if command -v satty >/dev/null 2>&1; then
            satty --filename "$OUTPUT_FILE" \
                  --output-filename "$OUTPUT_FILE" \
                  --save-after-copy \
                  --early-exit
        else
            # Fallback: just copy to clipboard
            wl-copy < "$OUTPUT_FILE"
            notify-send "📸 Screenshot" "Saved to $OUTPUT_FILE\n(Satty not installed - copied to clipboard)" -t 3000
        fi
        ;;
esac
