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
-- Roadmap: _plans/archive/QUICKSHELL_SHELL.md
-- ============================================================================

o.exec_on_start("quickshell -c dotfiles")

-- Goes through the script, not a raw `ipc call`: IPC only reaches a RUNNING
-- instance, so a direct binding silently did nothing whenever the bar was
-- down -- and `quickshell ipc` exits 0 even then, so nothing reported it.
o.bind("SUPER + B", "Toggle status bar", "~/.local/lib/scripts/desktop/quickshell-toggle")

-- Phase 5 now owns the PRIMARY keys. The Wofi SUPER+D in
-- conf/bindings/applications.lua.tmpl and the wlogout SUPER+SHIFT+Q in
-- conf/bindings/system-control.lua.tmpl are gated off on the same
-- features.quickshell_shell flag -- duplicate binds STACK in Hyprland, so the
-- old ones must be gated off rather than shadowed.
-- Wofi is not removable regardless: it serves cliphist and every --dmenu caller.
o.bind("SUPER + D", "Application launcher", "~/.local/lib/scripts/desktop/quickshell-toggle launcher")
o.bind("SUPER + SHIFT + Q", "Power menu", "~/.local/lib/scripts/desktop/quickshell-toggle power")

-- Clipboard history, taken from `cliphist list | wofi --dmenu | cliphist decode
-- | wl-copy`. SUPER+SHIFT+C has no successor: deletion is Shift+Delete inside
-- the surface, where the entry being deleted is the one on screen.
-- cliphist keeps the store and media/clipboard-store keeps filtering it; only
-- the picker moved.
o.bind("SUPER + C", "Clipboard history", "~/.local/lib/scripts/desktop/quickshell-toggle clipboard")

-- Popovers (design page Shell-06-Popovers). ONE submap rather than seven
-- top-level keys: the SUPER space is crowded, and a popover is a place you go
-- rather than a thing you toggle mid-flow.
--
-- 🚨 The submap is what makes these popovers KEYBOARD-mode: opened this way a
-- popover takes a Hyprland focus grab, puts a cursor on its first row and draws
-- a focus ring. A pointer click on the same widget opens the same surface with
-- no grab and no ring -- see quickshell/dotfiles/bar/BarPopover.qml.
o.bind("SUPER + P", "Popovers", hl.dsp.submap("popovers"))

hl.define_submap("popovers", function()
	local function popover(key, id)
		hl.bind(key, hl.dsp.exec_cmd("~/.local/lib/scripts/desktop/quickshell-toggle popover " .. id))
		hl.bind(key, hl.dsp.submap("reset"))
	end

	popover("A", "audio")
	popover("N", "network")
	popover("B", "bluetooth")
	popover("C", "calendar")
	popover("M", "media")
	popover("E", "meters")
	popover("W", "power")

	hl.bind("ESCAPE", hl.dsp.submap("reset"))
end)

-- Toast open/close effect. Layer surfaces are animated by the compositor, not
-- by Quickshell, so this is the only place it can be changed. The popup window
-- sets its own WlrLayershell.namespace for exactly this reason -- matching
-- `quickshell` would drag the bar, OSD, dock and launcher along with it.
--
-- The direction is explicit: a bare "slide" lets Hyprland pick the nearest
-- edge, and for a top-right anchor that is the TOP one, so the toasts flew
-- upwards. Other values of `animation`: "popin 80%", "fade", or no_anim = true.
hl.layer_rule({ match = { namespace = "quickshell-notifications" }, animation = "slide right" })
