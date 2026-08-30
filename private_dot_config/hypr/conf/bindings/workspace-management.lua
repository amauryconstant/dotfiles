-- ============================================================================
-- Per-Monitor Workspace Navigation (hyprsplit + native monitor dispatchers)
-- ============================================================================
-- Each monitor has its own independent workspaces 1-10 (hyprsplit).
-- Workspace switching/movement → hs.dsp.*  (split:workspace family).
-- Monitor focus/move           → hl.dsp.*  (native focusmonitor family).
-- REQUIRES: hyprsplit Lua library (require("hyprsplit")).
-- ============================================================================

local hs = require("hyprsplit")

-- Workspace switching + window movement (1-10; key 0 → workspace 10)
for i = 1, 10 do
	local key = i % 10
	o.bind("SUPER + " .. key, "Switch to workspace " .. i, hs.dsp.focus({ workspace = i }))
	o.bind("SUPER + SHIFT + " .. key, "Move to workspace " .. i, hs.dsp.window.move({ workspace = i, follow = false }))
end

-- Workspace cycling
o.bind("SUPER + Tab", "Next workspace", hs.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + SHIFT + Tab", "Previous workspace", hs.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + mouse_down", "Next workspace (wheel)", hs.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + mouse_up", "Previous workspace (wheel)", hs.dsp.focus({ workspace = "e-1" }))

-- Empty workspace
o.bind("SUPER + ALT + Tab", "Empty workspace", hs.dsp.focus({ workspace = "empty" }))

-- Monitor focus (native dispatcher — short direction form)
o.bind("SUPER + ALT + left", "Focus monitor left", hl.dsp.focus({ monitor = "l" }))
o.bind("SUPER + ALT + right", "Focus monitor right", hl.dsp.focus({ monitor = "r" }))
o.bind("SUPER + ALT + up", "Focus monitor up", hl.dsp.focus({ monitor = "u" }))
o.bind("SUPER + ALT + down", "Focus monitor down", hl.dsp.focus({ monitor = "d" }))

-- Swap / grab (hyprsplit)
o.bind("SUPER + ALT + s", "Swap workspaces", hs.dsp.workspace.swap_monitors({ monitor1 = "current", monitor2 = "+1" }))
o.bind("SUPER + ALT + g", "Grab rogue windows", hs.dsp.grab_rogue_windows())

-- Native dispatcher, not hyprsplit: hs.dsp.window.move({ workspace = "+1" }) routes
-- through hyprsplit's get_workspace_string, which clamps +1 to the monitor's own
-- 1-10 range — same-monitor move, never crossing monitors.
-- ⚠️ VERIFY at cutover: the { monitor = "+1" } argument cannot be checked statically
-- (the 0.56.2 stub types every dispatcher as `fun(...)`). Needs a two-monitor test.
o.bind("SUPER + ALT + m", "Move to other monitor", hl.dsp.window.move({ monitor = "+1" }))

-- Cross-monitor workspace move (native dispatcher)
o.bind("SUPER + SHIFT + ALT + left", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + SHIFT + ALT + right", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
