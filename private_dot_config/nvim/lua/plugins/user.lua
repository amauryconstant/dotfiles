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
