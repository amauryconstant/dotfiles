#!/usr/bin/env sh

# Script: utilities-menu.sh
# Purpose: Quick access to system utilities
# Requirements: Arch Linux, wofi

# Source helpers
. ~/.local/lib/scripts/user-interface/menu-helpers.sh

# Menu options
OPTIONS="󰁍 Back|󰕾 Audio (PulseAudio)|󰖩 Network (WiFi)|󰂯 Bluetooth|󰍹 Displays|󰌑 Edit Keybindings|󰖳 Input Devices"

CHOICE=$(show_menu "Utilities" "$OPTIONS")

case "$CHOICE" in
    "󰁍 Back")
        ~/.local/lib/scripts/user-interface/system-menu.sh
        ;;
    "󰕾 Audio (PulseAudio)")
        pavucontrol &
        ;;
    "󰖩 Network (WiFi)")
        {{ .globals.applications.terminal }} -e nmtui
        ;;
    "󰂯 Bluetooth")
        blueman-manager &
        ;;
    "󰍹 Displays")
        if command -v wdisplays >/dev/null 2>&1; then
            wdisplays &
        elif command -v nwg-displays >/dev/null 2>&1; then
            nwg-displays &
        else
            notify "󰍹 Displays" "No display configuration tool found\nInstall wdisplays or nwg-displays"
        fi
        ;;
    "󰌑 Edit Keybindings")
        {{ .globals.applications.terminal }} -e $EDITOR ~/.config/hypr/conf/bindings.conf
        ;;
    "󰖳 Input Devices")
        {{ .globals.applications.terminal }} -e $EDITOR ~/.config/hypr/conf/input.conf
        ;;
esac