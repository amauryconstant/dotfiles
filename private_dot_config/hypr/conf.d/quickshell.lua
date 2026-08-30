-- ============================================================================
-- Quickshell Shell (bar + OSDs)
-- ============================================================================
-- Deployed only when features.quickshell_shell.enabled is true — the gate is
-- in .chezmoiignore, since a .lua drop-in cannot carry template actions and
-- .chezmoidata files cannot be templates.
--
-- Coexists with Waybar during A/B: both anchor top and stack via layer-shell
-- exclusive zones. Roadmap: _plans/QUICKSHELL_SHELL.md
-- ============================================================================

o.exec_on_start("quickshell -c dotfiles")

-- SUPER+B stays on waybar-toggle while both bars run, so either can be hidden
-- independently for an A/B look. At Phase 6 the Waybar binding goes and this
-- one can move to SUPER+B.
o.bind("SUPER + SHIFT + B", "Toggle Quickshell bar", "quickshell -c dotfiles ipc call bar toggle")
