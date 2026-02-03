#!/usr/bin/env sh

# Script: monitor-mirror.sh
# Purpose: Mirror displays
# Requirements: Arch Linux

# Source UI library for monitor-focused notifications
if [ -n "$UI_LIB" ] && [ -f "$UI_LIB" ]; then
    # shellcheck source=/home/amaury/.local/lib/scripts/core/gum-ui.sh
    . "$UI_LIB"
elif [ -f "$HOME/.local/lib/scripts/core/gum-ui.sh" ]; then
    . "$HOME/.local/lib/scripts/core/gum-ui.sh"
fi

# Mirror all displays
if command -v wlr-randr >/dev/null 2>&1; then
    # Simple mirroring to first output
    PRIMARY_OUTPUT=$(wlr-randr | grep -E "^\w+" | head -1 | cut -d: -f1)
    if [ -n "$PRIMARY_OUTPUT" ]; then
        wlr-randr --output "$PRIMARY_OUTPUT" --on
        # Use monitor-focused notification if available
        if command -v ui_notify_focused >/dev/null 2>&1; then
            ui_notify_focused "󰍹 Displays" "Display mirroring enabled"
        else
            notify-send "󰍹 Displays" "Display mirroring enabled"
        fi
    fi
else
    # Use monitor-focused notification if available
    if command -v ui_notify_focused >/dev/null 2>&1; then
        ui_notify_focused "󰍹 Displays" "wlr-randr not available for display management"
    else
        notify-send "󰍹 Displays" "wlr-randr not available for display management"
    fi
fi