#!/usr/bin/env sh

# Script: workspace-gaps-reset.sh
# Purpose: Reset workspace gaps to default (remove workspace-specific rule)
# Requirements: Arch Linux, Hyprland, jaq

# Get current workspace ID
workspace_id=$(hyprctl activeworkspace -j | jaq -r '.id')

# Remove workspace-specific rule (reverts to general.conf defaults)
hyprctl keyword workspace "$workspace_id,default"

notify-send "󰝘 Workspace $workspace_id" "Reset to default gaps"