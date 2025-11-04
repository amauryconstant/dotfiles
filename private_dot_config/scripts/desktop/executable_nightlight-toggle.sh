#!/usr/bin/env sh

# Script: nightlight-toggle.sh
# Purpose: Toggle blue light filter using hyprsunset
# Requirements: Arch Linux, hyprsunset, hyprctl
# Adapted from: Omarchy's omarchy-toggle-nightlight

# Check if hyprsunset is running
if pgrep -x hyprsunset >/dev/null; then
    # Get current temperature
    temp=$(pgrep -a hyprsunset | grep -oP '\-t \K\d+')

    if [ "$temp" = "4000" ] || [ -z "$temp" ]; then
        # Currently warm (nightlight on) or default -> Turn off (6000K is neutral)
        pkill hyprsunset
        hyprsunset -t 6000 &
        notify-send "🌞 Nightlight" "Blue light filter disabled" -t 2000
    else
        # Currently neutral -> Turn on (4000K warm)
        pkill hyprsunset
        hyprsunset -t 4000 &
        notify-send "🌙 Nightlight" "Blue light filter enabled" -t 2000
    fi
else
    # hyprsunset not running -> Start with warm temperature
    hyprsunset -t 4000 &
    notify-send "🌙 Nightlight" "Blue light filter enabled" -t 2000
fi

# Optional: Restart waybar if it has nightlight module
# Uncomment if you add nightlight indicator to waybar
# pkill -SIGUSR2 waybar
