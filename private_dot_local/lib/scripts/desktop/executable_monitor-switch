#!/usr/bin/env sh

# Script: monitor-switch.sh
# Purpose: Cycle through monitor configurations
# Requirements: Arch Linux, wofi

# Source UI library for monitor-focused notifications
if [ -n "$UI_LIB" ] && [ -f "$UI_LIB" ]; then
    # shellcheck source=/home/amaury/.local/lib/scripts/core/gum-ui.sh
    . "$UI_LIB"
elif [ -f "$HOME/.local/lib/scripts/core/gum-ui.sh" ]; then
    . "$HOME/.local/lib/scripts/core/gum-ui.sh"
fi

# Simple monitor configuration switcher
if command -v wdisplays >/dev/null 2>&1; then
    wdisplays &
elif command -v nwg-displays >/dev/null 2>&1; then
    nwg-displays &
else
    # Use monitor-focused notification if available
    if command -v ui_notify_focused >/dev/null 2>&1; then
        ui_notify_focused "󰍹 Displays" "No display configuration tool found\nInstall wdisplays or nwg-displays"
    else
        notify-send "󰍹 Displays" "No display configuration tool found\nInstall wdisplays or nwg-displays"
    fi
fi