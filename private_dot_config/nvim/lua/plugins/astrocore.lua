---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    options = {
      opt = {
        relativenumber = true,
        number = true,
        wrap = false,
        signcolumn = "yes",
        scrolloff = 8,       -- keep 8 lines visible around cursor
        sidescrolloff = 8,   -- same for horizontal scroll
        splitright = true,   -- new vertical splits open to the right
        splitbelow = true,   -- new horizontal splits open below
        undofile = true,     -- persist undo history across sessions
        undolevels = 10000,  -- large undo history (VS Code-like)
      },
    },
  },
}
