#!/usr/bin/env sh

# Script: monitor-switch.sh
# Purpose: Cycle through monitor configurations
# Requirements: Arch Linux, wofi

# Simple monitor configuration switcher
if command -v wdisplays >/dev/null 2>&1; then
    wdisplays &
elif command -v nwg-displays >/dev/null 2>&1; then
    nwg-displays &
else
    notify "󰍹 Displays" "No display configuration tool found\nInstall wdisplays or nwg-displays"
fi