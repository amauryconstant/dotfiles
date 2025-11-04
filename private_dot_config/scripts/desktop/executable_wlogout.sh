#!/usr/bin/env bash

# ============================================================================
# Wlogout Launch Script
# ============================================================================
# Launches wlogout with custom layout and styling
# Implements toggle behavior to prevent multiple instances
# Based on best practices from hyprland-investigator analysis
#
# FEATURES:
# - Toggle behavior: Launch if not running, kill if already running
# - Process management with pidof check
# - Custom layout (6 actions: lock, logout, suspend, hibernate, reboot, shutdown)
# - Optimized spacing and responsive margins
# - Layer-shell protocol for proper Wayland integration
#
# USAGE:
# - Run directly: ~/.config/scripts/wlogout.sh
# - Hyprland keybind: Super+Shift+Q
# ============================================================================

LAYOUT="$HOME/.config/wlogout/layout"
STYLE="$HOME/.config/wlogout/style.css"

# Toggle wlogout: Launch if not running, kill if already running
if [[ ! $(pidof wlogout) ]]; then
    wlogout \
        --protocol layer-shell \
        --layout "${LAYOUT}" \
        --css "${STYLE}" \
        --buttons-per-row 3 \
        --column-spacing 50 \
        --row-spacing 50 \
        --margin-top 300 \
        --margin-bottom 300 \
        --margin-left 300 \
        --margin-right 300
else
    pkill wlogout
fi
