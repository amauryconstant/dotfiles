#!/usr/bin/env sh

# Script: waybar-style.sh
# Purpose: Configure Waybar styling
# Requirements: Arch Linux, wofi

# Waybar style configuration menu
if command -v wofi >/dev/null 2>&1; then
    STYLE=$(echo "󰍹 Default\n󰖩 Dark\n󰔜 Light\n󰥔 Minimal\n󰔓 Compact" | wofi --dmenu --prompt "Waybar Style")
    
    case "$STYLE" in
        "󰍹 Default")
            # Reload default style
            killall -SIGUSR2 waybar
            notify "󰘯 Waybar" "Applied default style"
            ;;
        "󰖩 Dark")
            # Apply dark theme (placeholder)
            killall -SIGUSR2 waybar
            notify "󰘯 Waybar" "Applied dark style"
            ;;
        "󰔜 Light")
            # Apply light theme (placeholder)
            killall -SIGUSR2 waybar
            notify "󰘯 Waybar" "Applied light style"
            ;;
        "󰥔 Minimal")
            # Apply minimal theme (placeholder)
            killall -SIGUSR2 waybar
            notify "󰘯 Waybar" "Applied minimal style"
            ;;
        "󰔓 Compact")
            # Apply compact theme (placeholder)
            killall -SIGUSR2 waybar
            notify "󰘯 Waybar" "Applied compact style"
            ;;
    esac
else
    notify "󰘯 Waybar" "wofi not available for style configuration"
fi