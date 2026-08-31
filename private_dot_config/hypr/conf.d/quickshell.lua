-- ============================================================================
-- Quickshell Shell (bar + OSDs)
-- ============================================================================
-- Deployed only when features.quickshell_shell.enabled is true — the gate is
-- in .chezmoiignore, since a .lua drop-in cannot carry template actions and
-- .chezmoidata files cannot be templates.
--
-- Mutually exclusive with conf.d/waybar.lua: this bar floats (40 tall, inset
-- 8, reserving 56) and Waybar's 30px full-bleed bar cannot stack with it. That
-- exclusivity is what lets both drop-ins claim SUPER+B.
-- Roadmap: _plans/QUICKSHELL_SHELL.md
-- ============================================================================

o.exec_on_start("quickshell -c dotfiles")

-- Goes through the script, not a raw `ipc call`: IPC only reaches a RUNNING
-- instance, so a direct binding silently did nothing whenever the bar was
-- down -- and `quickshell ipc` exits 0 even then, so nothing reported it.
o.bind("SUPER + B", "Toggle status bar", "~/.local/lib/scripts/desktop/quickshell-toggle")

-- Phase 5 surfaces on SPARE keys, deliberately. SUPER+D still opens Wofi and
-- SUPER+SHIFT+Q still opens wlogout; both keep working, and the swap happens
-- only once these are better than what they replace. Wofi is not removable
-- regardless -- it serves cliphist and every --dmenu caller.
o.bind(
	"SUPER + SHIFT + D",
	"Application launcher (Quickshell)",
	"~/.local/lib/scripts/desktop/quickshell-toggle launcher"
)
o.bind("SUPER + ALT + Q", "Power menu (Quickshell)", "~/.local/lib/scripts/desktop/quickshell-toggle power")
