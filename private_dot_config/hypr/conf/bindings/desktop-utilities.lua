-- ============================================================================
-- Desktop Utilities
-- ============================================================================
-- System utilities and desktop enhancements.
-- ============================================================================

o.bind("SUPER + M", "Monitor switcher", "~/.local/lib/scripts/desktop/monitor-switch")
o.bind("SUPER + U", "Utilities menu", "~/.local/lib/scripts/user-interface/utilities-menu")
o.bind("SUPER + G", "Toggle gaps", "~/.local/lib/scripts/desktop/workspace-gaps-toggle")
o.bind("SUPER + A", "Audio output switcher", "~/.local/lib/scripts/desktop/audio-switch")
o.bind("SUPER + SHIFT + A", "Audio settings", "pavucontrol")
o.bind("SUPER + N", "Nightlight toggle", "~/.local/lib/scripts/desktop/nightlight-toggle")
o.bind("SUPER + B", "Toggle status bar", "~/.local/lib/scripts/desktop/waybar-toggle")
o.bind("SUPER + I", "Toggle idle lock", "~/.local/lib/scripts/desktop/idle-toggle")
o.bind("SUPER + CTRL + T", "Activity monitor (btop)", "ghostty -e btop")
o.bind("SUPER + CTRL + B", "Bluetooth manager", "blueman-manager")
o.bind("SUPER + CTRL + W", "WiFi settings", "ghostty -e nmtui")
o.bind("SUPER + CTRL + Z", "Zoom in", "zoom-cursor in")
o.bind("SUPER + CTRL + ALT + Z", "Zoom out", "zoom-cursor out")
o.bind("SUPER + CTRL + ALT + B", "Battery status", "battery-status")
