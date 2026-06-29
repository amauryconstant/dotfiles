-- ============================================================================
-- Window Resizing
-- ============================================================================
-- Resize active window with Super + Ctrl + Arrows. Mouse binds for move/resize.
-- resizeactive, X Y → hl.dsp.window.resize({ x, y, relative = true }).
-- ============================================================================

-- Resize windows: Super + Ctrl + Arrows
o.bind("SUPER + CTRL + left", "Shrink width", hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
o.bind("SUPER + CTRL + right", "Expand width", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))
o.bind("SUPER + CTRL + up", "Shrink height", hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
o.bind("SUPER + CTRL + down", "Expand height", hl.dsp.window.resize({ x = 0, y = 20, relative = true }))

-- Mouse bindings for window operations
o.bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })
