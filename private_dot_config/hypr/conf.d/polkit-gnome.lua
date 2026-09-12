-- ============================================================================
-- Polkit Authentication Agent (fallback)
-- ============================================================================
-- Deployed only when features.quickshell_polkit.enabled is FALSE -- the gate is
-- in .chezmoiignore, since a .lua drop-in cannot carry template actions and
-- .chezmoidata files cannot be templates.
--
-- A session may have exactly ONE polkit agent, so this and the Quickshell
-- agent (quickshell/dotfiles/polkit/PolkitDialog.qml, itself behind
-- Config.polkitOwned) are mutually exclusive. That exclusivity is why this
-- lives in conf.d rather than in the shared conf/autostart, which both
-- branches load: the drop-in is the only place the choice can be expressed.
--
-- polkit-gnome (stable) over hyprpolkitagent (Qt platform plugin crashes).
-- ============================================================================

o.exec_on_start("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
