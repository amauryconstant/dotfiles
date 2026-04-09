---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  -- Language packs
  { import = "astrocommunity.pack.go" },
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.pack.typescript" },
  -- Diagnostics
  { import = "astrocommunity.diagnostics.trouble-nvim" },
  -- Markdown rendering (visual headers, bold/italic, tables, code blocks)
  { import = "astrocommunity.markdown-and-latex.render-markdown-nvim" },
  -- Git UI (VS Code Source Control panel equivalent)
  { import = "astrocommunity.git.neogit" },
  -- Debugger UI (VS Code debug panel equivalent — works with Go/Python DAP from language packs)
  { import = "astrocommunity.debugging.nvim-dap-ui" },
  -- VS Code-style snippet collection (friendly-snippets via LuaSnip)
  { import = "astrocommunity.snippet.luasnip" },
}
