-- ============================================================================
-- General Settings (structural only)
-- ============================================================================
-- Window layout, gaps, and borders. Border COLORS are set by the theme
-- override module (~/.config/themes/current/hyprland.lua), loaded after this.
-- Documentation: https://wiki.hypr.land/Configuring/Variables/#general
-- ============================================================================

hl.config({
	general = {
		-- Gaps ------------------------------------------------------------
		gaps_in = 4, -- Space between windows (px)
		gaps_out = 8, -- Space between windows and screen edges (px)

		-- Borders ---------------------------------------------------------
		border_size = 2, -- Thickness of window borders (px; 0 disables)
		-- col.active_border / col.inactive_border come from the theme module.

		-- Layout ----------------------------------------------------------
		layout = "dwindle", -- "dwindle" (binary tree) or "master"

		-- Allow tearing: reduced latency in fullscreen games (experimental)
		allow_tearing = false,
		-- resize_on_border = false,
		-- extend_border_grab_area = 15,
		-- hover_icon_on_border = true,
	},

	-- Dwindle layout (binary tree tiling) ---------------------------------
	-- https://wiki.hypr.land/Configuring/Dwindle-Layout/
	dwindle = {
		preserve_split = true, -- Remember split direction when moving windows
		-- split_width_multiplier = 1.0,
		-- use_active_for_splits  = true,
		-- default_split_ratio    = 1.0,
	},
})
