-- mise_files.lua
-- Recognises mise config files (cookbook patterns + this repo's chezmoi source tree).
-- Used by the `is-mise?` treesitter predicate (polish.lua) and the otter activation (plugins/user.lua).

local M = {}

local PATTERNS = {
  "/%.?mise/config%.toml$",
  "/%.?mise/config%.local%.toml$",
  "/%.?mise/config%.[^/]+%.toml$",
  "/%.?mise/conf%.d/[^/]+%.toml$",
  "/%.config/mise/mise%.toml$",
  "/%.config/mise/mise%.local%.toml$",
  -- chezmoi source: private_dot_config/mise/{config.toml,conf.d/*.toml}
  "/private_dot_config/mise/config%.toml$",
  "/private_dot_config/mise/conf%.d/[^/]+%.toml$",
}

---@param path string
---@return boolean
function M.is_mise(path)
  path = vim.fs.normalize(path)
  if vim.fn.fnamemodify(path, ":t"):match "^%.?mise.*%.toml$" then return true end
  for _, pattern in ipairs(PATTERNS) do
    if path:match(pattern) then return true end
  end
  return false
end

return M
