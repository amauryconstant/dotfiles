-- ============================================================================
-- System Control
-- ============================================================================
-- System-level operations: lock, power, help, menus.
-- ============================================================================

o.bind("SUPER + L", "Lock screen", "~/.local/lib/scripts/desktop/immediate-lock")
o.bind("SUPER + Space", "Main system menu", "~/.local/lib/scripts/user-interface/system-menu")
o.bind("SUPER + SHIFT + N", "Notification center", "~/.local/lib/scripts/desktop/quickshell-toggle notifications")
-- The shell draws a document, which is what surface 9 asks for; with the shell
-- down quickshell-toggle falls back to the script's own picker.
o.bind("SUPER + slash", "Keybinding help", "~/.local/lib/scripts/desktop/quickshell-toggle keybindings")
