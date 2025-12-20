#!/usr/bin/env sh

# Script: workspace-gaps-toggle.sh
# Purpose: Toggle gaps and borders for current workspace (presentation/immersive mode)
# Requirements: Arch Linux, hyprctl, jaq
# Adapted from: Omarchy's omarchy-hyprland-workspace-toggle-gaps

# Get current workspace ID
workspace_id=$(hyprctl activeworkspace -j | jaq -r '.id')

# Read default values from general.conf (no hardcoding)
DEFAULT_GAPS_IN=$(hyprctl getoption general:gaps_in -j | jaq -r '.int')
DEFAULT_GAPS_OUT=$(hyprctl getoption general:gaps_out -j | jaq -r '.int')
DEFAULT_BORDER=$(hyprctl getoption general:border_size -j | jaq -r '.int')

# Check if workspace has a custom rule
current_rule=$(hyprctl workspacerules -j | jaq -r \
  --arg id "$workspace_id" \
  '.[] | select(.workspaceString == $id)')

# Determine current state
if [ -n "$current_rule" ]; then
    # Workspace has a rule - check its gap settings
    gaps_out=$(echo "$current_rule" | jaq -r '.gapsOut[0] // empty')

    if [ "$gaps_out" = "0" ]; then
        # Currently immersive, restore defaults
        hyprctl keyword workspace "$workspace_id,gapsout:$DEFAULT_GAPS_OUT,gapsin:$DEFAULT_GAPS_IN,bordersize:$DEFAULT_BORDER"
        notify-send "Workspace $workspace_id" "Normal mode restored" -t 2000
    else
        # Currently normal, enable immersive
        hyprctl keyword workspace "$workspace_id,gapsout:0,gapsin:0,bordersize:0"
        notify-send "Workspace $workspace_id" "Immersive mode enabled" -t 2000
    fi
else
    # No workspace rule - check global config state
    current_gaps=$(hyprctl getoption general:gaps_out -j | jaq -r '.int')

    if [ "$current_gaps" -gt 0 ]; then
        # Currently normal, enable immersive
        hyprctl keyword workspace "$workspace_id,gapsout:0,gapsin:0,bordersize:0"
        notify-send "Workspace $workspace_id" "Immersive mode enabled" -t 2000
    else
        # Currently immersive, restore defaults
        hyprctl keyword workspace "$workspace_id,gapsout:$DEFAULT_GAPS_OUT,gapsin:$DEFAULT_GAPS_IN,bordersize:$DEFAULT_BORDER"
        notify-send "Workspace $workspace_id" "Normal mode restored" -t 2000
    fi
fi
