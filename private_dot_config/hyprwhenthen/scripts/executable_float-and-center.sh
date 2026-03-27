#!/usr/bin/env sh
ADDRESS="0x$1"
hyprctl dispatch togglefloating "address:$ADDRESS" 2>/dev/null || exit 0
hyprctl dispatch resizewindowpixel exact 50% 50%,"address:$ADDRESS" 2>/dev/null || exit 0
hyprctl dispatch focuswindow "address:$ADDRESS" 2>/dev/null || exit 0
hyprctl dispatch centerwindow 2>/dev/null || exit 0
