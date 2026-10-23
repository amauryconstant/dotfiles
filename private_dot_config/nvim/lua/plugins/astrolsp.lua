---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    servers = { "qmlls" }, -- not Mason-managed: Qt ships it
    config = {
      -- Absolute Qt6 path: the Qt5 tools on $PATH are a trap (.claude/rules/quickshell-qml.md)
      qmlls = { cmd = { "/usr/lib/qt6/bin/qmlls" } },
    },
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
