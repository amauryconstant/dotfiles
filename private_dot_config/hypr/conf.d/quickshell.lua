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

-- Phase 5 now owns the PRIMARY keys. The Wofi SUPER+D in
-- conf/bindings/applications.lua.tmpl and the wlogout SUPER+SHIFT+Q in
-- conf/bindings/system-control.lua.tmpl are gated off on the same
-- features.quickshell_shell flag -- duplicate binds STACK in Hyprland, so the
-- old ones must be gated off rather than shadowed.
-- Wofi is not removable regardless: it serves cliphist and every --dmenu caller.
o.bind("SUPER + D", "Application launcher", "~/.local/lib/scripts/desktop/quickshell-toggle launcher")
o.bind("SUPER + SHIFT + Q", "Power menu", "~/.local/lib/scripts/desktop/quickshell-toggle power")
