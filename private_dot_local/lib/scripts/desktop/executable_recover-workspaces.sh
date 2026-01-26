#!/usr/bin/env sh
# Script: executable_recover-workspaces.sh
# Purpose: Manually recover rogue windows from disconnected monitors
# Requirements: Hyprland, hyprsplit plugin

set -euo pipefail

# Recover all rogue windows to current workspace
# Uses hyprsplit dispatcher to grab windows from disconnected monitors
hyprctl dispatch split:grabroguewindows 2>/dev/null || true

logger -t hyprsplit-recovery "Rogue windows recovered to active workspace"
