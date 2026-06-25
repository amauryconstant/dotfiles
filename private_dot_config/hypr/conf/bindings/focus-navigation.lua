-- ============================================================================
-- Focus Navigation
-- ============================================================================
-- Navigate between windows and move windows within workspace.
-- Arrow keys and vim-style (h/j/k/l). movefocus → hl.dsp.focus({ direction }),
-- movewindow → hl.dsp.window.move({ direction }).
-- ============================================================================

-- Move focus with arrow keys: Super + Arrows
o.bind("SUPER + left",  "Focus left",  hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + right", "Focus right", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + up",    "Focus up",    hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + down",  "Focus down",  hl.dsp.focus({ direction = "d" }))

-- Move focus with vim keys: Super + H/J/K/L
o.bind("SUPER + h", "Focus left (vim)",  hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + j", "Focus down (vim)",  hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + k", "Focus up (vim)",    hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + l", "Focus right (vim)", hl.dsp.focus({ direction = "r" }))

-- Move windows with arrow keys: Super + Shift + Arrows
o.bind("SUPER + SHIFT + left",  "Move window left",  hl.dsp.window.move({ direction = "l" }))
o.bind("SUPER + SHIFT + right", "Move window right", hl.dsp.window.move({ direction = "r" }))
o.bind("SUPER + SHIFT + up",    "Move window up",    hl.dsp.window.move({ direction = "u" }))
o.bind("SUPER + SHIFT + down",  "Move window down",  hl.dsp.window.move({ direction = "d" }))

-- Cycle grouped (tabbed) windows: Super + Ctrl + H/L
o.bind("SUPER + CTRL + h", "Previous in group", hl.dsp.group.prev())
o.bind("SUPER + CTRL + l", "Next in group",     hl.dsp.group.next())
