-- ============================================================================
-- Animation Settings
-- ============================================================================
-- Animation curves and timing for window movements and effects.
-- Documentation: https://wiki.hypr.land/Configuring/Animations/
--
-- Curves: hl.curve(name, { type = "bezier", points = { {x1,y1}, {x2,y2} } })
-- Anims : hl.animation({ leaf = ..., enabled = ..., speed = N, bezier = ..., style = ... })
--         speed = duration in deciseconds (5 = 0.5s). Use bezier= (or spring=), never curve=.
-- ============================================================================

-- Enable all animations (set enabled = false for maximum performance)
hl.config({ animations = { enabled = true } })

-- Bezier curves ---------------------------------------------------------------
-- myBezier: smooth ease-out with slight overshoot (elastic feel)
hl.curve("myBezier",     { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 },   { 0.32, 1 } } })

-- Animation definitions -------------------------------------------------------
hl.animation({ leaf = "windows",          enabled = true, speed = 5, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 5, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",           enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "borderangle",      enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "fade",             enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })
