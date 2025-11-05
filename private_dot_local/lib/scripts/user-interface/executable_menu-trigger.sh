#!/usr/bin/env sh

# Script: menu-trigger.sh
# Purpose: Trigger menu (Capture/Share/Toggle quick actions)
# Requirements: Arch Linux, wofi

# Source helpers
. ~/.local/lib/scripts/user-interface/menu-helpers.sh

# Main trigger menu - Using Material Design icons from glyphnames.json
MAIN_OPTIONS="󰁍 Back|󰄀 Capture|󰒖 Share|󰔡 Toggle"
CHOICE=$(show_menu "Trigger" "$MAIN_OPTIONS")

case "$CHOICE" in
    "󰁍 Back")
        ~/.local/lib/scripts/user-interface/system-menu.sh
        ;;
    "󰄀 Capture")
        # Capture submenu
        CAPTURE_OPTIONS="󰁍 Back|󰹑 Screenshot (Smart)|󰩭 Screenshot (Region)|󰖲 Screenshot (Window)|󰍹 Screenshot (Fullscreen)|󰨸 Screenshot → Clipboard|󰻂 Screen Record|󰕾 Screen Record + Audio|󰴱 Color Picker"
        CAPTURE_CHOICE=$(show_menu "Capture" "$CAPTURE_OPTIONS")

        case "$CAPTURE_CHOICE" in
            "󰁍 Back")
                ~/.local/lib/scripts/user-interface/menu-trigger.sh
                ;;
            "󰹑 Screenshot (Smart)")
                ~/.local/lib/scripts/media/screenshot.sh smart
                ;;
            "󰩭 Screenshot (Region)")
                ~/.local/lib/scripts/media/screenshot.sh region
                ;;
            "󰖲 Screenshot (Window)")
                ~/.local/lib/scripts/media/screenshot.sh windows
                ;;
            "󰍹 Screenshot (Fullscreen)")
                ~/.local/lib/scripts/media/screenshot.sh fullscreen
                ;;
            "󰨸 Screenshot → Clipboard")
                ~/.local/lib/scripts/media/screenshot.sh smart clipboard
                ;;
            "󰻂 Screen Record")
                ~/.local/lib/scripts/desktop/screenrecord.sh
                ;;
            "󰕾 Screen Record + Audio")
                ~/.local/lib/scripts/desktop/screenrecord.sh --with-audio
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
                ~/.local/lib/scripts/user-interface/menu-trigger.sh
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
                ~/.local/lib/scripts/user-interface/menu-trigger.sh
                ;;
            "󰛨 Nightlight")
                ~/.local/lib/scripts/desktop/nightlight-toggle.sh
                ;;
            "󰌾 Idle Lock")
                ~/.local/lib/scripts/desktop/idle-toggle.sh
                ;;
            "󰘯 Waybar")
                ~/.local/lib/scripts/desktop/waybar-toggle.sh
                ;;
            "󰝘 Workspace Gaps")
                ~/.local/lib/scripts/desktop/workspace-gaps-toggle.sh
                ;;
        esac
        ;;
esac
