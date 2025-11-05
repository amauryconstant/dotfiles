#!/usr/bin/env sh

# Script: nightlight-config.sh
# Purpose: Configure nightlight/blue light filter
# Requirements: Arch Linux, wofi

# Nightlight configuration menu
if command -v wofi >/dev/null 2>&1; then
    TEMP=$(echo "6500K (Daylight)\n6000K (Cool)\n5500K (Neutral)\n5000K (Warm)\n4500K (Warmer)\n4000K (Evening)\n3500K (Night)" | wofi --dmenu --prompt "Color Temperature")
    
    case "$TEMP" in
        "6500K (Daylight)")
            hyprctl keyword decoration:col.shadow 0xee111111
            notify "󰛨 Nightlight" "Set to Daylight (6500K)"
            ;;
        "6000K (Cool)")
            hyprctl keyword decoration:col.shadow 0xee221111
            notify "󰛨 Nightlight" "Set to Cool (6000K)"
            ;;
        "5500K (Neutral)")
            hyprctl keyword decoration:col.shadow 0xee332211
            notify "󰛨 Nightlight" "Set to Neutral (5500K)"
            ;;
        "5000K (Warm)")
            hyprctl keyword decoration:col.shadow 0xee443311
            notify "󰛨 Nightlight" "Set to Warm (5000K)"
            ;;
        "4500K (Warmer)")
            hyprctl keyword decoration:col.shadow 0xee554411
            notify "󰛨 Nightlight" "Set to Warmer (4500K)"
            ;;
        "4000K (Evening)")
            hyprctl keyword decoration:col.shadow 0xee665511
            notify "󰛨 Nightlight" "Set to Evening (4000K)"
            ;;
        "3500K (Night)")
            hyprctl keyword decoration:col.shadow 0xee776611
            notify "󰛨 Nightlight" "Set to Night (3500K)"
            ;;
    esac
else
    notify "󰛨 Nightlight" "wofi not available for configuration"
fi