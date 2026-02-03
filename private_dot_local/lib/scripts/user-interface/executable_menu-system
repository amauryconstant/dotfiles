#!/usr/bin/env sh

# Script: menu-system.sh
# Purpose: Power/session controls submenu
#          Lock/Suspend/Restart/Shutdown options
# Requirements: Arch Linux, wofi
# Note: Do not confuse with system-menu.sh (main entry point)

# Source helpers
. "$SCRIPTS_DIR/user-interface/menu-helpers.sh"

# Menu options - Using Material Design icons
OPTIONS="󰁍 Back|󰌾 Lock|󰤄 Suspend|󰜉 Restart|󰐥 Shutdown"

CHOICE=$(show_menu "System" "$OPTIONS")

case "$CHOICE" in
    "󰁍 Back")
        "$SCRIPTS_DIR/user-interface/system-menu.sh"
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
