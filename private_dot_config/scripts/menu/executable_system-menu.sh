#!/usr/bin/env sh

# Script: system-menu.sh
# Purpose: Main menu entry point (Omarchy-inspired hierarchical menu)
# Requirements: Arch Linux, wofi
# Adapted from: Omarchy's omarchy-menu

# Source helpers
. ~/.config/scripts/menu/menu-helpers.sh

# Main menu options (10 categories) - Using Material Design icons from glyphnames.json
MAIN_OPTIONS="󰀻 Apps|󰗚 Learn|󰈿 Trigger|󰏘 Style|󰒓 Setup|󰏓 Install|󰩺 Remove|󰚰 Update|󰋼 About|󰐥 System"

CHOICE=$(show_menu "Main Menu" "$MAIN_OPTIONS")

case "$CHOICE" in
    "󰀻 Apps")
        # Launch application launcher
        wofi --show drun
        ;;
    "󰗚 Learn")
        ~/.config/scripts/menu/menu-learn.sh
        ;;
    "󰈿 Trigger")
        ~/.config/scripts/menu/menu-trigger.sh
        ;;
    "󰏘 Style")
        ~/.config/scripts/menu/menu-style.sh
        ;;
    "󰒓 Setup")
        ~/.config/scripts/menu/menu-setup.sh
        ;;
    "󰏓 Install")
        ~/.config/scripts/menu/menu-install.sh
        ;;
    "󰩺 Remove")
        ~/.config/scripts/menu/menu-remove.sh
        ;;
    "󰚰 Update")
        ~/.config/scripts/menu/menu-update.sh
        ;;
    "󰋼 About")
        ~/.config/scripts/menu/menu-about.sh
        ;;
    "󰐥 System")
        ~/.config/scripts/menu/menu-system.sh
        ;;
esac
