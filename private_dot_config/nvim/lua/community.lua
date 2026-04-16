---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  -- Language packs
  { import = "astrocommunity.pack.go" },
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.bash" },    -- covers sh + bash
  { import = "astrocommunity.pack.yaml" },
  { import = "astrocommunity.pack.json" },
  { import = "astrocommunity.pack.chezmoi" }, -- .tmpl support + toml (included by chezmoi pack)
  -- Diagnostics
  { import = "astrocommunity.diagnostics.trouble-nvim" },
  -- Markdown rendering (visual headers, bold/italic, tables, code blocks)
  { import = "astrocommunity.markdown-and-latex.render-markdown-nvim" },
  -- Git UI (VS Code Source Control panel equivalent)
  { import = "astrocommunity.git.neogit" },
  -- Debugger UI (nvim-dap-ui was replaced by nvim-dap-view in astrocommunity)
  { import = "astrocommunity.debugging.nvim-dap-view" },
}
