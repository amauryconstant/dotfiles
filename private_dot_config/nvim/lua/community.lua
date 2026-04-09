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
}
