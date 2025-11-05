#!/usr/bin/env sh

# Script: idle-toggle.sh
# Purpose: Toggle automatic screen locking (presentation mode)
# Requirements: Arch Linux, hypridle
# Adapted from: Omarchy's omarchy-toggle-idle

# Check if hypridle is running
if pgrep -x hypridle >/dev/null; then
    # hypridle is running -> Kill it (disable auto-lock)
    pkill hypridle
    notify-send "⏸️ Idle Lock" "Auto-lock disabled (presentation mode)" -t 2000
else
    # hypridle not running -> Start it (enable auto-lock)
    hypridle &
    notify-send "▶️ Idle Lock" "Auto-lock enabled" -t 2000
fi
