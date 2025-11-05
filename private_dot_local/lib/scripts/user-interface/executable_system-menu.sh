#!/usr/bin/env sh

# Script: system-menu.sh
# Purpose: Main menu entry point (Omarchy-inspired hierarchical menu)
# Requirements: Arch Linux, wofi
# Adapted from: Omarchy's omarchy-menu

# Source helpers
. ~/.local/lib/scripts/user-interface/menu-helpers.sh

# Main menu options (10 categories) - Using Material Design icons from glyphnames.json
MAIN_OPTIONS="󰀻 Apps|󰗚 Learn|󰈿 Trigger|󰏘 Style|󰒓 Setup|󰏓 Install|󰩺 Remove|󰚰 Update|󰋼 About|󰐥 System"

CHOICE=$(show_menu "Main Menu" "$MAIN_OPTIONS")

case "$CHOICE" in
    "󰀻 Apps")
        # Launch application launcher
        wofi --show drun
        ;;
    "󰗚 Learn")
        ~/.local/lib/scripts/user-interface/menu-learn.sh
        ;;
    "󰈿 Trigger")
        ~/.local/lib/scripts/user-interface/menu-trigger.sh
        ;;
    "󰏘 Style")
        ~/.local/lib/scripts/user-interface/menu-style.sh
        ;;
    "󰒓 Setup")
        ~/.local/lib/scripts/user-interface/menu-setup.sh
        ;;
    "󰏓 Install")
        ~/.local/lib/scripts/user-interface/menu-install.sh
        ;;
    "󰩺 Remove")
        ~/.local/lib/scripts/user-interface/menu-remove.sh
        ;;
    "󰚰 Update")
        ~/.local/lib/scripts/user-interface/menu-update.sh
        ;;
    "󰋼 About")
        ~/.local/lib/scripts/user-interface/menu-about.sh
        ;;
    "󰐥 System")
        ~/.local/lib/scripts/user-interface/menu-system.sh
        ;;
esac
