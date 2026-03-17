require("lazy").setup({
  {
    "AstroNvim/AstroNvim",
    version = "^4",
    import = "astronvim.plugins",
  },
  { import = "community" },
  { import = "plugins" },
}, {
  install = { colorscheme = { "astrodark", "habamax" } },
  ui = { backdrop = 100 },
})
