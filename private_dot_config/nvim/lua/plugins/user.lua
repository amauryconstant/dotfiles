---@type LazySpec
return {
  -- Auto-open Neo-tree file explorer on startup
  {
    "nvim-neo-tree/neo-tree.nvim",
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          vim.defer_fn(function() vim.cmd "Neotree show" end, 0)
        end,
      })
    end,
  },
  -- Pin to master branch: AstroNvim v4 uses nvim-treesitter.configs which was removed in the main branch rewrite
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
  },
  -- Disable aerial treesitter backend for markdown.
  -- aerial.nvim uses iter_matches with { all = false }, but nvim 0.12.1 changed
  -- iter_matches to always return captures as lists, breaking node:type() calls.
  -- Remove this override once aerial.nvim releases a fix for nvim 0.12+ compatibility.
  -- Tracked at: https://github.com/stevearc/aerial.nvim/issues
  {
    "stevearc/aerial.nvim",
    opts = {
      ignore = { filetypes = { "markdown" } },
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
