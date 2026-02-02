#!/usr/bin/env sh

# Script: system-menu.sh
# Purpose: Main menu entry point - called by Super+Space keybinding
#          Displays 10 categories, routes to submenus
# Requirements: Arch Linux, wofi
# Adapted from: Omarchy's omarchy-menu
# Note: Do not confuse with menu-system.sh (power management submenu)

# Source helpers
. "$SCRIPTS_DIR/user-interface/menu-helpers.sh"

# Main menu options (9 categories) - Using Material Design icons
MAIN_OPTIONS="󰀻 Apps|󰗚 Learn|󰈿 Trigger|󰏘 Style|󰒓 Setup|󰏓 Install|󰚰 Update|󰋼 About|󰐥 System"

CHOICE=$(show_menu "Main Menu" "$MAIN_OPTIONS")

case "$CHOICE" in
    "󰀻 Apps")
        # Launch application launcher
        wofi --show drun
        ;;
    "󰗚 Learn")
        "$SCRIPTS_DIR/user-interface/menu-learn.sh"
        ;;
    "󰈿 Trigger")
        "$SCRIPTS_DIR/user-interface/menu-trigger.sh"
        ;;
    "󰏘 Style")
        "$SCRIPTS_DIR/user-interface/menu-style.sh"
        ;;
    "󰒓 Setup")
        "$SCRIPTS_DIR/user-interface/menu-setup.sh"
        ;;
    "󰏓 Install")
        "$SCRIPTS_DIR/user-interface/menu-install.sh"
        ;;
    # "󰩺 Remove")
    #     "$SCRIPTS_DIR/user-interface/menu-remove.sh"
    #     ;;
    "󰚰 Update")
        "$SCRIPTS_DIR/user-interface/menu-update.sh"
        ;;
    "󰋼 About")
        "$SCRIPTS_DIR/user-interface/menu-about.sh"
        ;;
    "󰐥 System")
        "$SCRIPTS_DIR/user-interface/menu-system.sh"
        ;;
esac
