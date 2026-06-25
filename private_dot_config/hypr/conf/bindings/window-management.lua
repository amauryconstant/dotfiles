-- ============================================================================
-- Window Management
-- ============================================================================
-- Basic window operations: close, toggle modes, special workspaces.
-- ============================================================================

-- Close window: Super + Q
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- Toggle floating: Super + V
o.bind("SUPER + V", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))

-- Toggle fullscreen: Super + F
o.bind("SUPER + F", "Toggle fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Toggle scratchpad (hidden "magic" special workspace): Super + S
o.bind("SUPER + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("magic"))

-- Picture-in-picture mode: Super + Shift + P (float, resize, center, pin, raise)
o.bind("SUPER + SHIFT + P", "Picture-in-picture mode", "~/.local/lib/scripts/desktop/window-pop")

-- Move to scratchpad: Super + Shift + S
o.bind("SUPER + SHIFT + S", "Move to scratchpad", hl.dsp.window.move({ workspace = "special:magic" }))
