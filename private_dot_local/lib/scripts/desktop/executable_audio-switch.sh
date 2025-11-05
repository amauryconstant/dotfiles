#!/usr/bin/env sh

# Script: audio-switch.sh
# Purpose: Cycle through available audio output devices with visual feedback
# Requirements: Arch Linux, pactl (pipewire-pulse), wpctl, swayosd-client, jaq
# Adapted from: Omarchy's omarchy-cmd-audio-switch

# Get list of available sinks (audio outputs)
sinks=$(pactl -f json list sinks)

# Get current default sink
current_sink=$(pactl get-default-sink)

# Parse available sinks into array
available_sinks=$(echo "$sinks" | jaq -r '.[] | select(.state != "SUSPENDED") | .name')

# Count available sinks
sink_count=$(echo "$available_sinks" | wc -l)

# If only one sink, nothing to switch
if [ "$sink_count" -le 1 ]; then
    notify-send "Audio Output" "Only one output device available" -t 2000
    exit 0
fi

# Find current sink index in the list
current_index=0
index=0
for sink in $available_sinks; do
    if [ "$sink" = "$current_sink" ]; then
        current_index=$index
        break
    fi
    index=$((index + 1))
done

# Calculate next sink index (wrap around)
next_index=$(( (current_index + 1) % sink_count ))

# Get the next sink name
next_sink=$(echo "$available_sinks" | sed -n "$((next_index + 1))p")

# Switch to next sink
pactl set-default-sink "$next_sink"

# Move all existing streams to the new sink
pactl list short sink-inputs | while read -r stream; do
    stream_id=$(echo "$stream" | cut -f1)
    pactl move-sink-input "$stream_id" "$next_sink" 2>/dev/null
done

# Get sink description for notification
sink_info=$(pactl -f json list sinks | jaq -r ".[] | select(.name == \"$next_sink\") | .description")
if [ -z "$sink_info" ]; then
    # Fallback to wpctl if pactl doesn't have description
    sink_info=$(wpctl inspect "$next_sink" 2>/dev/null | grep "node.description" | cut -d'"' -f4)
fi
if [ -z "$sink_info" ]; then
    sink_info="$next_sink"
fi

# Get current volume for icon
volume=$(pactl get-sink-volume "$next_sink" | grep -oP '\d+(?=%)' | head -1)
is_muted=$(pactl get-sink-mute "$next_sink" | grep -q "yes" && echo "true" || echo "false")

# Determine volume icon
if [ "$is_muted" = "true" ]; then
    icon=""
elif [ "$volume" -eq 0 ]; then
    icon=""
elif [ "$volume" -lt 33 ]; then
    icon=""
elif [ "$volume" -lt 66 ]; then
    icon=""
else
    icon=""
fi

# Send OSD notification if swayosd is available
if command -v swayosd-client >/dev/null 2>&1; then
    swayosd-client --output-volume "$volume" --output-name "$sink_info"
else
    # Fallback to regular notification
    notify-send "$icon Audio Output" "$sink_info\nVolume: ${volume}%" -t 3000
fi
