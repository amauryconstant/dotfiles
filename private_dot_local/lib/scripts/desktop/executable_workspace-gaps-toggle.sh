#!/usr/bin/env sh

# Script: workspace-gaps-toggle.sh
# Purpose: Toggle gaps and borders for current workspace (presentation/immersive mode)
# Requirements: Arch Linux, hyprctl, jaq
# Adapted from: Omarchy's omarchy-hyprland-workspace-toggle-gaps

# Get current workspace ID
workspace_id=$(hyprctl activeworkspace -j | jaq -r '.id')

# Get current gap settings for this workspace
current_gaps_in=$(hyprctl getoption general:gaps_in -j | jaq -r '.int')
current_gaps_out=$(hyprctl getoption general:gaps_out -j | jaq -r '.int')
current_border=$(hyprctl getoption general:border_size -j | jaq -r '.int')

# Toggle logic: if any gaps or borders exist, remove them; otherwise restore
if [ "$current_gaps_in" -gt 0 ] || [ "$current_gaps_out" -gt 0 ] || [ "$current_border" -gt 0 ]; then
    # Immersive mode: No gaps, no borders
    hyprctl keyword workspace "$workspace_id,gapsout:0"
    hyprctl keyword workspace "$workspace_id,gapsin:0"
    hyprctl keyword workspace "$workspace_id,bordersize:0"
    notify-send "Workspace $workspace_id" "Immersive mode enabled" -t 2000
else
    # Normal mode: Restore default gaps and borders
    hyprctl keyword workspace "$workspace_id,gapsout:5"
    hyprctl keyword workspace "$workspace_id,gapsin:10"
    hyprctl keyword workspace "$workspace_id,bordersize:2"
    notify-send "Workspace $workspace_id" "Normal mode restored" -t 2000
fi
