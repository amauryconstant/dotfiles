-- ============================================================================
-- Waybar - Status bar (workspaces, system info, tray icons)
-- ============================================================================
-- Deployed only when features.quickshell_shell.enabled is FALSE -- the gate is
-- in .chezmoiignore, since a .lua drop-in cannot carry template actions and
-- .chezmoidata files cannot be templates.
--
-- Mutually exclusive with conf.d/quickshell.lua: the Quickshell bar floats
-- (40 tall, inset 4, reserving 44) and Waybar's 30px full-bleed bar cannot
-- stack with it. That exclusivity is what lets both drop-ins claim SUPER+B.
--
-- Location: ~/.config/waybar/config and ~/.config/waybar/style.css
-- Roadmap: _plans/archive/QUICKSHELL_SHELL.md
-- ============================================================================

o.exec_on_start("waybar")

o.bind("SUPER + B", "Toggle status bar", "~/.local/lib/scripts/desktop/waybar-toggle")
