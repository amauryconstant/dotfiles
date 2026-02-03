#!/usr/bin/env sh

# Script: screenrecord.sh
# Purpose: GPU-accelerated screen recording with audio support
# Requirements: Arch Linux, gpu-screen-recorder, slurp, jaq
# Adapted from: Omarchy's omarchy-cmd-screenrecord

# Parse arguments
WITH_AUDIO=false
for arg in "$@"; do
    case "$arg" in
        --with-audio)
            WITH_AUDIO=true
            ;;
    esac
done

# PID file to track recording state
PID_FILE="/tmp/screenrecord_$USER.pid"

# Check if already recording
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    # Stop recording
    recording_pid=$(cat "$PID_FILE")
    kill "$recording_pid"
    rm -f "$PID_FILE"

    # Signal waybar to update (if configured)
    pkill -RTMIN+8 waybar 2>/dev/null

    notify-send "🎬 Screen Recording" "Recording stopped and saved" -t 3000
    exit 0
fi

# Get monitor information
monitors=$(hyprctl monitors -j)

# If more than one monitor, let user select with slurp
if [ "$(echo "$monitors" | jaq 'length')" -gt 1 ]; then
    # Let user select region or full output
    selection=$(slurp -f "%o %x,%y %wx%h" 2>/dev/null)

    if [ -z "$selection" ]; then
        notify-send "🎬 Screen Recording" "Recording cancelled" -t 2000
        exit 1
    fi

    # Parse slurp output: output x,y widthxheight
    output=$(echo "$selection" | cut -d' ' -f1)
    geometry=$(echo "$selection" | cut -d' ' -f3)
else
    # Single monitor - record full output
    output=$(echo "$monitors" | jaq -r '.[0].name')
    geometry=""
fi

# Determine output filename with timestamp
output_dir="${HOME}/Videos"
mkdir -p "$output_dir"
output_file="${output_dir}/screenrecord-$(date +%Y%m%d-%H%M%S).mp4"

# Build gpu-screen-recorder command
cmd="gpu-screen-recorder -w $output"

# Add audio if requested
if [ "$WITH_AUDIO" = true ]; then
    # Get default audio sink (output)
    default_sink=$(pactl get-default-sink)
    # Get default audio source (input/microphone)
    default_source=$(pactl get-default-source)

    # Add both system audio and microphone
    cmd="$cmd -a $default_sink -a $default_source"
fi

# Add output file
cmd="$cmd -o $output_file"

# Start recording in background
eval "$cmd" &
recording_pid=$!

# Save PID
echo "$recording_pid" > "$PID_FILE"

# Signal waybar to show recording indicator (if configured)
pkill -RTMIN+8 waybar 2>/dev/null

# Notify user
if [ "$WITH_AUDIO" = true ]; then
    notify-send "🎬 Screen Recording" "Recording started with audio\nPress Super+R to stop" -t 3000
else
    notify-send "🎬 Screen Recording" "Recording started\nPress Super+R to stop" -t 3000
fi
