---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = function(_, opts)
    local theme = require("dotfiles_theme").get()
    if theme.background then
      vim.o.background = theme.background
    end
    opts.colorscheme = theme.colorscheme
    return opts
  end,
}
