#!/usr/bin/env sh

# Script: theme-switcher.sh
# Purpose: Switch between system themes
# Requirements: Arch Linux, wofi

# Theme switcher menu
if command -v wofi >/dev/null 2>&1; then
    THEME=$(echo "󰔎 Oksolar Dark\n󰔜 Oksolar Light\n󰖩 Tokyo Night\n󰗚 Gruvbox\n󰅜 Dracula\n󰔓 Nord" | wofi --dmenu --prompt "Select Theme")
    
    case "$THEME" in
        "󰔎 Oksolar Dark")
            # Apply oksolar dark theme
            notify "󰏘 Theme" "Applied Oksolar Dark"
            ;;
        "󰔜 Oksolar Light")
            # Apply oksolar light theme
            notify "󰏘 Theme" "Applied Oksolar Light"
            ;;
        "󰖩 Tokyo Night")
            # Apply tokyo night theme
            notify "󰏘 Theme" "Applied Tokyo Night"
            ;;
        "󰗚 Gruvbox")
            # Apply gruvbox theme
            notify "󰏘 Theme" "Applied Gruvbox"
            ;;
        "󰅜 Dracula")
            # Apply dracula theme
            notify "󰏘 Theme" "Applied Dracula"
            ;;
        "󰔓 Nord")
            # Apply nord theme
            notify "󰏘 Theme" "Applied Nord"
            ;;
    esac
else
    notify "󰏘 Theme" "wofi not available for theme switching"
fi