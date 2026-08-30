-- hyprsplit: independent workspaces (1-10) per monitor — Lua library
-- Source: https://github.com/cryeprecision/hyprsplit (fork, tracks Hyprland
-- internals closer than upstream shezdy/hyprsplit — see
-- _guides/HYPRSPLIT_PLUGIN_FORK_DECISION.md).
-- Cloned to ~/.config/hypr/hyprsplit by run_once_before_008; resolved via the
-- package.path entry in hyprland.lua. Replaces the hyprpm C++ plugin at cutover.
local hs = require("hyprsplit")
hs.config({ num_workspaces = 10, persistent_workspaces = false })
