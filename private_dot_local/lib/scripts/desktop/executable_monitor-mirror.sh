#!/usr/bin/env sh

# Script: monitor-mirror.sh
# Purpose: Mirror displays
# Requirements: Arch Linux

# Mirror all displays
if command -v wlr-randr >/dev/null 2>&1; then
    # Simple mirroring to first output
    PRIMARY_OUTPUT=$(wlr-randr | grep -E "^\w+" | head -1 | cut -d: -f1)
    if [ -n "$PRIMARY_OUTPUT" ]; then
        wlr-randr --output "$PRIMARY_OUTPUT" --on
        notify "󰍹 Displays" "Display mirroring enabled"
    fi
else
    notify "󰍹 Displays" "wlr-randr not available for display management"
fi