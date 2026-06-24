-- hyprsplit: independent workspaces (1-10) per monitor — Lua library
local hs = require("hyprsplit")
hs.config({ num_workspaces = 10, persistent_workspaces = false })
