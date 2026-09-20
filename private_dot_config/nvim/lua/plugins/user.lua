---@type LazySpec
return {
  -- Inline image rendering via the Kitty graphics protocol, which Ghostty
  -- implements. Sixel is not an option: Ghostty will never support it.
  {
    "3rd/image.nvim",
    lazy = false,
    opts = {
      backend = "kitty",
      integrations = {},
      max_width_window_percentage = 50,
      window_overlap_clear_enabled = true,
    },
  },
  -- Mermaid diagram inline rendering in markdown code blocks
  {
    "3rd/diagram.nvim",
    ft = { "markdown" },
    dependencies = { "3rd/image.nvim" },
    config = function()
      require("diagram").setup({
        integrations = {
          require("diagram.integrations.markdown"),
        },
        renderer_options = {
          mermaid = {
            scale = 1,
          },
        },
      })
    end,
  },
  {
    "NeogitOrg/neogit",
    opts = {
      integrations = { diffview = true },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
        },
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = { hidden = true },
        },
      },
    },
  },
  -- aerial: layout only — auto-open logic is in polish.lua (files > 100 lines)
  {
    "stevearc/aerial.nvim",
    opts = {
      open_automatic = false,
      layout = { default_direction = "right" },
    },
  },
  -- mise version manager integration (ensures go/python/node from mise are available)
  {
    "https://plugins.ejri.dev/mise.nvim",
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
