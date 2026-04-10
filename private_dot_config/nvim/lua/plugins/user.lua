---@type LazySpec
return {
  -- Open aerial symbol outline as a right sidebar automatically
  {
    "stevearc/aerial.nvim",
    opts = {
      open_automatic = true,
      layout = { default_direction = "right" },
    },
  },
  -- mise version manager integration (ensures go/python/node from mise are available)
  {
    "https://tangled.org/ejri.dev/mise.nvim",
    lazy = false,
    opts = {},
  },
  -- Colorschemes (direct plugins, avoids AstroCommunity module loading issues)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    opts = {},
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    opts = {},
  },
  -- Gruvbox (not in AstroCommunity)
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    opts = {},
  },
  -- Solarized (not in AstroCommunity)
  {
    "maxmx03/solarized.nvim",
    lazy = true,
    opts = {},
  },
}
