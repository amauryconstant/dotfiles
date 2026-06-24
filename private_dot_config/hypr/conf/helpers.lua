-- Ergonomic helper layer for the Hyprland Lua config (global `o`).
o = o or {}

-- o.bind(keys, description, dispatcher, options)
-- dispatcher: a hl.dsp.* value, OR a plain string (→ hl.dsp.exec_cmd).
function o.bind(keys, description, dispatcher, options)
  local opts = options or {}
  if description then opts.description = description end
  if type(dispatcher) == "string" then dispatcher = hl.dsp.exec_cmd(dispatcher) end
  hl.bind(keys, dispatcher, opts)
end

-- o.window(match, rules): string match → match.class; table match → merged into rules.match.
function o.window(match, rules)
  rules.match = rules.match or {}
  if type(match) == "string" then
    rules.match.class = match
  else
    for k, v in pairs(match) do rules.match[k] = v end
  end
  hl.window_rule(rules)
end

function o.exec_on_start(command)
  hl.on("hyprland.start", function() hl.exec_cmd(command) end)
end
