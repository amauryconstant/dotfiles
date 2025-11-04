#!/usr/bin/env sh

# Script: menu-trigger.sh
# Purpose: Trigger menu (Capture/Share/Toggle quick actions)
# Requirements: Arch Linux, wofi

# Source helpers
. ~/.config/scripts/menu/menu-helpers.sh

# Main trigger menu - Using Material Design icons from glyphnames.json
MAIN_OPTIONS="󰁍 Back|󰄀 Capture|󰒖 Share|󰔡 Toggle"
CHOICE=$(show_menu "Trigger" "$MAIN_OPTIONS")

case "$CHOICE" in
    "󰁍 Back")
        ~/.config/scripts/menu/system-menu.sh
        ;;
    "󰄀 Capture")
        # Capture submenu
        CAPTURE_OPTIONS="󰁍 Back|󰹑 Screenshot (Smart)|󰩭 Screenshot (Region)|󰖲 Screenshot (Window)|󰍹 Screenshot (Fullscreen)|󰨸 Screenshot → Clipboard|󰻂 Screen Record|󰕾 Screen Record + Audio|󰴱 Color Picker"
        CAPTURE_CHOICE=$(show_menu "Capture" "$CAPTURE_OPTIONS")

        case "$CAPTURE_CHOICE" in
            "󰁍 Back")
                ~/.config/scripts/menu/menu-trigger.sh
                ;;
            "󰹑 Screenshot (Smart)")
                ~/.config/scripts/media/screenshot.sh smart
                ;;
            "󰩭 Screenshot (Region)")
                ~/.config/scripts/media/screenshot.sh region
                ;;
            "󰖲 Screenshot (Window)")
                ~/.config/scripts/media/screenshot.sh windows
                ;;
            "󰍹 Screenshot (Fullscreen)")
                ~/.config/scripts/media/screenshot.sh fullscreen
                ;;
            "󰨸 Screenshot → Clipboard")
                ~/.config/scripts/media/screenshot.sh smart clipboard
                ;;
            "󰻂 Screen Record")
                ~/.config/scripts/desktop/screenrecord.sh
                ;;
            "󰕾 Screen Record + Audio")
                ~/.config/scripts/desktop/screenrecord.sh --with-audio
                ;;
            "󰴱 Color Picker")
                pkill hyprpicker || hyprpicker -a
                ;;
        esac
        ;;
    "󰒖 Share")
        # Share submenu (placeholder for future file sharing)
        SHARE_OPTIONS="󰁍 Back|󰈔 Share File|󰨸 Share Clipboard"
        SHARE_CHOICE=$(show_menu "Share" "$SHARE_OPTIONS")

        case "$SHARE_CHOICE" in
            "󰁍 Back")
                ~/.config/scripts/menu/menu-trigger.sh
                ;;
            "󰈔 Share File")
                notify "󰒖 Share" "File sharing not yet implemented"
                ;;
            "󰨸 Share Clipboard")
                notify "󰒖 Share" "Clipboard sharing not yet implemented"
                ;;
        esac
        ;;
    "󰔡 Toggle")
        # Toggle submenu
        TOGGLE_OPTIONS="󰁍 Back|󰛨 Nightlight|󰌾 Idle Lock|󰘯 Waybar|󰝘 Workspace Gaps"
        TOGGLE_CHOICE=$(show_menu "Toggle" "$TOGGLE_OPTIONS")

        case "$TOGGLE_CHOICE" in
            "󰁍 Back")
                ~/.config/scripts/menu/menu-trigger.sh
                ;;
            "󰛨 Nightlight")
                ~/.config/scripts/desktop/nightlight-toggle.sh
                ;;
            "󰌾 Idle Lock")
                ~/.config/scripts/desktop/idle-toggle.sh
                ;;
            "󰘯 Waybar")
                ~/.config/scripts/desktop/waybar-toggle.sh
                ;;
            "󰝘 Workspace Gaps")
                ~/.config/scripts/desktop/workspace-gaps-toggle.sh
                ;;
        esac
        ;;
esac
