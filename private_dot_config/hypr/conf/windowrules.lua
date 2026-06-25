-- ============================================================================
-- Window Rules
-- ============================================================================
-- Per-application window behavior.
-- Documentation: https://wiki.hypr.land/Configuring/Window-Rules/
--
-- o.window(match, rules):
--   match  : string → match.class ; table → merged into match (class/title/...)
--   rules  : float=true, center=true, pin=true, stay_focused=true,
--            size = { W, H } (TABLE), opacity = "active inactive" (STRING)
-- Find window props with: hyprctl clients
-- ============================================================================

-- System dialogs (should float) ----------------------------------------------
o.window("pavucontrol",      { float = true })                       -- PulseAudio volume control
o.window("hyprpolkitagent",  { float = true })                       -- Polkit auth dialog
o.window("blueman-manager",  { float = true })                       -- Bluetooth manager
o.window("com.gabm.satty",   { float = true, stay_focused = true })  -- Screenshot annotation editor

-- AI scratchpad terminals (menu-ai: opencode, claude-code, ollama) -----------
o.window("ai-scratchpad", { float = true, center = true, size = { "55%", "65%" } })

-- Nextcloud (preserve existing workflow from KDE) ----------------------------
o.window("com.nextcloud.desktopclient.nextcloud", { float = true, size = { 800, 600 }, stay_focused = true })

-- Firefox Picture-in-Picture: float and pin to all workspaces ----------------
o.window({ title = "Picture-in-Picture" }, { float = true, pin = true })

-- File Manager (Thunar) ------------------------------------------------------
-- Main window: opacity, tiles by default
o.window("thunar", { opacity = "0.9 0.8" })
-- File operation progress dialogs: float + center
o.window({ class = "thunar", title = "(Copying|Moving|Deleting)" }, { float = true, size = { 500, 200 }, center = true })
-- File picker dialogs: float + center
o.window({ class = "thunar", title = "(Open|Save)" }, { float = true, size = { 800, 600 }, center = true })

-- LocalSend (minimum window size to avoid tiny default) ----------------------
o.window("localsend", { size = { 600, 400 } })

-- ============================================================================
-- Layer Rules (special surfaces: waybar, notifications, launchers)
-- ============================================================================
-- Wofi launcher: blur background for transparency readability
hl.layer_rule({ match = { namespace = "wofi" }, blur = true })
