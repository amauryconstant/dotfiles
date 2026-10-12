-- ============================================================================
-- OAuth sign-in popups: float, size to half the monitor, centre -- once.
-- ============================================================================
-- Replaces the hyprwhenthen handler. Three guards, each fixing a failure of it:
--   * apply once  -- hl.dsp.window.float is a TOGGLE and a title event fires on
--     every retitle, so a flow that matched twice (password, then 2FA) floated
--     the popup and then tiled it again.
--   * age         -- a popup is retitled within seconds of mapping.
--   * opener      -- a popup shares its opener's pid and maps after it. A sign-in
--     TAB retitles the whole browser window (the title is the active tab's), and
--     a browser cold-started onto a sign-in page has no older sibling, so
--     neither is ever treated as a popup and the main window is left alone.
-- ============================================================================

local POPUP_WINDOW_S = 10

-- Lowercase, matched as plain substrings (no pattern escaping, multibyte-safe).
local TITLES = {
	"sign in - google accounts",
	"sign in to your account", -- Microsoft
	"sign in to github",
}

-- address -> { t = first-seen time, seq = first-seen order }. A window that
-- predates this module (a config reload) has t = 0, so it always reads as old.
local seen = {}
local handled = {}
local seq = 0

local function track(w, t)
	local s = seen[w.address]
	if not s then
		seq = seq + 1
		s = { t = t or os.time(), seq = seq }
		seen[w.address] = s
	end
	return s
end

for _, w in ipairs(hl.get_windows({ mapped = true })) do
	track(w, 0)
end

local function is_sign_in(title)
	local t = title:lower()
	for _, p in ipairs(TITLES) do
		if t:find(p, 1, true) then
			return true
		end
	end
	return false
end

local function has_older_sibling(w, s)
	for _, o in ipairs(hl.get_windows({ mapped = true })) do
		local os_ = seen[o.address]
		if o.address ~= w.address and o.pid == w.pid and (not os_ or os_.seq < s.seq) then
			return true
		end
	end
	return false
end

-- hyprctl-style monitor .width/.height are the MODE's physical axes; window
-- geometry is logical. Divide by scale, and swap the axes for an odd transform.
local function half_monitor(m)
	local w, h = m.width, m.height
	if m.transform % 2 == 1 then
		w, h = h, w
	end
	return math.floor(w / m.scale / 2), math.floor(h / m.scale / 2)
end

local function consider(w)
	-- window.title can fire before the window has an address or a monitor; window.open follows.
	if not (w and w.address and w.monitor) then
		return
	end
	if handled[w.address] or w.floating or not is_sign_in(w.title or "") then
		return
	end
	local s = track(w)
	if os.time() - s.t > POPUP_WINDOW_S or not has_older_sibling(w, s) then
		return
	end
	handled[w.address] = true

	local sel = "address:" .. w.address
	local x, y = half_monitor(w.monitor)
	hl.dispatch(hl.dsp.window.float({ action = "enable", window = sel }))
	hl.dispatch(hl.dsp.window.resize({ x = x, y = y, window = sel }))
	hl.dispatch(hl.dsp.focus({ window = sel }))
	hl.dispatch(hl.dsp.window.center({}))
end

hl.on("window.open_early", function(w)
	if w and w.address then
		track(w)
	end
end)
hl.on("window.open", consider)
hl.on("window.title", consider)

local function forget(w)
	if not (w and w.address) then
		return
	end
	seen[w.address] = nil
	handled[w.address] = nil
end
hl.on("window.close", forget)
hl.on("window.destroy", forget)
