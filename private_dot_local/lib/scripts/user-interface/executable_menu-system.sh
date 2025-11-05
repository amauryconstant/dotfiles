#!/usr/bin/env sh

# Script: menu-system.sh
# Purpose: System menu (Power/session controls)
# Requirements: Arch Linux, wofi

# Source helpers
. ~/.local/lib/scripts/user-interface/menu-helpers.sh

# Menu options - Using Material Design icons from glyphnames.json
OPTIONS="󰁍 Back|󰌾 Lock|󰤄 Suspend|󰜉 Restart|󰐥 Shutdown"

CHOICE=$(show_menu "System" "$OPTIONS")

case "$CHOICE" in
    "󰁍 Back")
        ~/.local/lib/scripts/user-interface/system-menu.sh
        ;;
    "󰌾 Lock")
        hyprlock
        ;;
    "󰤄 Suspend")
        if confirm "Suspend system?"; then
            systemctl suspend
        fi
        ;;
    "󰜉 Restart")
        if confirm "Restart system?\nAll unsaved work will be lost."; then
            systemctl reboot
        fi
        ;;
    "󰐥 Shutdown")
        if confirm "Shutdown system?\nAll unsaved work will be lost."; then
            systemctl poweroff
        fi
        ;;
esac
