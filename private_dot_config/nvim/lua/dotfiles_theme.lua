-- dotfiles_theme.lua
-- Reads ~/.config/themes/current symlink and maps to nvim colorscheme.
-- Used by astroui.lua at startup and by theme-apply-neovim via RPC.

local M = {}

local THEME_MAP = {
  ["catppuccin-latte"] = { colorscheme = "catppuccin-latte" },
  ["catppuccin-mocha"] = { colorscheme = "catppuccin-mocha" },
  ["rose-pine-dawn"]   = { colorscheme = "rose-pine-dawn" },
  ["rose-pine-moon"]   = { colorscheme = "rose-pine-moon" },
  ["gruvbox-light"]    = { colorscheme = "gruvbox", background = "light" },
  ["gruvbox-dark"]     = { colorscheme = "gruvbox", background = "dark" },
  ["solarized-light"]  = { colorscheme = "solarized", background = "light" },
  ["solarized-dark"]   = { colorscheme = "solarized", background = "dark" },
}

function M.get()
  local link = vim.fn.expand "~/.config/themes/current"
  local resolved = vim.fn.resolve(link)
  local theme_name = vim.fn.fnamemodify(resolved, ":t")
  return THEME_MAP[theme_name] or { colorscheme = "astrodark" }
end

function M.reload()
  local config = M.get()
  if config.background then
    vim.o.background = config.background
  end
  vim.cmd("colorscheme " .. config.colorscheme)
end

return M
