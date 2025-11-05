#!/usr/bin/env sh

# Script: menu-learn.sh
# Purpose: Learn menu (Documentation and help)
# Requirements: Arch Linux, wofi

# Source helpers
. ~/.local/lib/scripts/user-interface/menu-helpers.sh

# Menu options - Using Material Design icons from glyphnames.json
OPTIONS="󰁍 Back|󰌌 Keybindings|󰗚 Hyprland Wiki|󰣇 Arch Wiki|󰈙 Chezmoi Docs|󰊤 GitHub (Dotfiles)"

CHOICE=$(show_menu "Learn" "$OPTIONS")

case "$CHOICE" in
    "󰁍 Back")
        ~/.local/lib/scripts/user-interface/system-menu.sh
        ;;
    "󰌌 Keybindings")
        ~/.local/lib/scripts/desktop/keybindings.sh
        ;;
    "󰗚 Hyprland Wiki")
        firefox "https://wiki.hyprland.org" &
        ;;
    "󰣇 Arch Wiki")
        firefox "https://wiki.archlinux.org" &
        ;;
    "󰈙 Chezmoi Docs")
        firefox "https://www.chezmoi.io/user-guide/command-overview/" &
        ;;
    "󰊤 GitHub (Dotfiles)")
        # Open your dotfiles repo (customize if needed)
        firefox "https://github.com" &
        ;;
esac
