#!/usr/bin/env sh

# Script: workspace-gaps-reset.sh
# Purpose: Reset workspace gaps to default
# Requirements: Arch Linux, Hyprland

# Reset gaps to default values
hyprctl keyword general:gaps_in 5
hyprctl keyword general:gaps_out 20
notify "󰝘 Workspace Gaps" "Reset to default values"