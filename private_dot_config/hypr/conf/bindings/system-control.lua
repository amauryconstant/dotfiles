-- ============================================================================
-- System Control
-- ============================================================================
-- System-level operations: lock, power, help, menus.
-- ============================================================================

o.bind("SUPER + L", "Lock screen", "~/.local/lib/scripts/desktop/immediate-lock")
-- The launcher's `>` mode: capture and maintenance actions.
o.bind("SUPER + Space", "Actions", "~/.local/lib/scripts/desktop/quickshell-toggle launcher actions")
o.bind("SUPER + SHIFT + N", "Notification center", "~/.local/lib/scripts/desktop/quickshell-toggle notifications")
o.bind("SUPER + slash", "Keybinding help", "~/.local/lib/scripts/desktop/quickshell-toggle keybindings")
