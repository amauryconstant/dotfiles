---@type LazySpec
return {
  -- Inline image rendering via the Kitty graphics protocol, which Ghostty
  -- implements. Sixel is not an option: Ghostty will never support it.
  -- Loaded on demand: diagram.nvim (markdown) is its only consumer.
  {
    "3rd/image.nvim",
    lazy = true,
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
  -- LSP for code embedded in other buffers: mise `run` strings (toml) and markdown fences.
  -- Diagnostics are off: TOML escapes (`\\(`) and doc fragments give false shellcheck errors.
  -- Needs the injection queries in after/queries/ and an LSP per embedded language.
  {
    "jmbuhr/otter.nvim",
    ft = { "toml", "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "toml", "markdown" },
        group = vim.api.nvim_create_augroup("OtterEmbedded", {}),
        callback = function(args)
          if args.match == "toml" and not require("mise_files").is_mise(args.file) then return end
          require("otter").activate(nil, true, false)
        end,
      })
    end,
  },
  -- diffview.nvim is unmaintained upstream (last push 2024-08); same module and
  -- commands, so the astrocommunity spec and Neogit's integration keep working.
  {
    "sindrets/diffview.nvim",
    url = "https://github.com/dlyongemallo/diffview-plus.nvim",
  },
  -- Mise/system tools ahead of Mason's: in this repo `mise run lint` and
  -- format-on-save then use the same pinned stylua/shellcheck/shfmt.
  {
    "mason-org/mason.nvim",
    opts = { PATH = "append" },
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
