#!/usr/bin/env sh

# Script: system-settings.sh
# Purpose: Launch system settings applications
# Requirements: Arch Linux

# Launch system settings
if command -v gnome-control-center >/dev/null 2>&1; then
    gnome-control-center &
elif command -v systemsettings5 >/dev/null 2>&1; then
    systemsettings5 &
elif command -v xfce4-settings-manager >/dev/null 2>&1; then
    xfce4-settings-manager &
else
    notify-send "󰒓 Settings" "No system settings application found"
fi