-- ============================================================================
-- System Control
-- ============================================================================
-- System-level operations: lock, power, help, menus.
-- ============================================================================

o.bind("SUPER + L", "Lock screen", "hyprlock")
o.bind("SUPER + SHIFT + Q", "Power menu", "~/.local/lib/scripts/desktop/wlogout")
o.bind("SUPER + Space", "Main system menu", "~/.local/lib/scripts/user-interface/system-menu")
o.bind("SUPER + SHIFT + N", "Notification center", "swaync-client --toggle-panel")
o.bind("SUPER + slash", "Keybinding help", "~/.local/lib/scripts/desktop/keybindings")
