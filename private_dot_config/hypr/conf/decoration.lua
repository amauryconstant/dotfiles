-- ============================================================================
-- Decoration Settings
-- ============================================================================
-- Visual effects: blur, shadows, rounded corners.
-- Documentation: https://wiki.hypr.land/Configuring/Variables/#decoration
--
-- PERFORMANCE NOTE: Blur and shadows have GPU cost. If experiencing issues,
-- disable blur (blur.enabled = false), reduce passes, or disable shadows.
-- ============================================================================

hl.config({
	decoration = {
		rounding = 8, -- Corner radius (px); 0 = sharp corners

		blur = {
			enabled = true,
			size = 5, -- Blur radius (px); recommended 3-8
			passes = 2, -- Iterations; 1-2 perf, 3-4 quality
			vibrancy = 0.1696, -- Color intensity through blur (0.0-1.0)
			-- noise = 0.0117, contrast = 0.8916, brightness = 0.8172,
			-- xray = false, ignore_opacity = false,
		},

		shadow = {
			enabled = true,
			range = 4, -- How far shadow extends (px)
			render_power = 3, -- Fade curve (1 linear .. 4 sharp)
			color = "rgba(1a1a1aee)", -- #1a1a1a @ 93% opacity
			-- color_inactive = "rgba(1a1a1a55)",
			-- offset = { 0, 0 }, scale = 1.0,
		},

		-- Dimming (uncomment to enable)
		-- dim_inactive = false, dim_strength = 0.05, dim_around = 0.4,

		-- Opacity (uncomment to set defaults)
		-- active_opacity = 1.0, inactive_opacity = 1.0, fullscreen_opacity = 1.0,
	},
})
