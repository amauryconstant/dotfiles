#!/usr/bin/env sh

# Script: window-pop.sh
# Purpose: Float, resize, pin window for picture-in-picture mode
# Requirements: Arch Linux, hyprland, jq

# Get active window address
addr="address:$(hyprctl activewindow -j | jq -r .address)"

# Get monitor dimensions
monitor_info=$(hyprctl activeworkspace -j)
monitor_width=$(echo "$monitor_info" | jq -r '.monitor.width')
monitor_height=$(echo "$monitor_info" | jq -r '.monitor.height')

# Calculate 30% size
width=$((monitor_width * 30 / 100))
height=$((monitor_height * 30 / 100))

# Apply transformations atomically
hyprctl --batch "\
  dispatch togglefloating $addr;\
  dispatch resizeactive exact $width $height;\
  dispatch centerwindow;\
  dispatch pin;\
  dispatch alterzorder top;\
  dispatch tagwindow +pop"
