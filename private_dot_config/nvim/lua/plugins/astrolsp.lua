---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    formatting = {
      format_on_save = {
        enabled = true,
        allow_filetypes = {
          "go",
          "python",
          "typescript",
          "typescriptreact",
          "javascript",
          "javascriptreact",
          "lua",
          "sh",
          "bash",
          "yaml",
          "json",
          "toml",
        },
      },
    },
  },
}
