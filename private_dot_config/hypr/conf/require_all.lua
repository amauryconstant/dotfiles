-- Directory loader + optional-require helper for the Hyprland Lua config.
local M = {}

local function shell_quote(p)
	return "'" .. p:gsub("'", "'\\''") .. "'"
end

-- require() every *.lua in dir (sorted). module_prefix = nil when dir is on package.path.
-- opts.reload drops any cached copy first, so `hyprctl reload` picks up edits.
function M.files(dir, module_prefix, opts)
	local h =
		io.popen("find " .. shell_quote(dir) .. " -maxdepth 1 -type f -name '*.lua' -printf '%f\\n' 2>/dev/null | sort")
	if not h then
		return
	end
	for filename in h:lines() do
		local mod = filename:gsub("%.lua$", "")
		if module_prefix then
			mod = module_prefix .. "." .. mod
		end
		if opts and opts.reload then
			package.loaded[mod] = nil
		end
		require(mod)
	end
	h:close()
end

-- require(module) only if its file exists (avoids hard error on optional files).
function M.if_exists(path, module, opts)
	local f = io.open(path, "r")
	if f then
		f:close()
		if opts and opts.reload then
			package.loaded[module] = nil
		end
		require(module)
	end
end

return M
