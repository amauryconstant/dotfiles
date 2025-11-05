#!/usr/bin/env sh

# Script: waybar-toggle.sh
# Purpose: Toggle waybar visibility for distraction-free mode
# Requirements: Arch Linux, waybar, pkill
# Adapted from: Omarchy's omarchy-toggle-waybar

# Check if waybar is running
if pgrep -x waybar >/dev/null; then
    # Waybar is running -> Kill it (hide)
    pkill waybar
    notify-send "📊 Waybar" "Status bar hidden" -t 2000
else
    # Waybar not running -> Start it (show)
    waybar &
    notify-send "📊 Waybar" "Status bar shown" -t 2000
fi
