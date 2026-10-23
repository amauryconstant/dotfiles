-- Post-load customizations (loaded by init.lua)

-- `(#is-mise?)` in after/queries/toml/injections.scm: restrict the run-command
-- injection to mise config files. Registered first: a TOML buffer parsed before
-- this errors with "No handler for is-mise?".
vim.treesitter.query.add_predicate("is-mise?", function(_, _, bufnr)
  return require("mise_files").is_mise(vim.api.nvim_buf_get_name(tonumber(bufnr) or 0))
end, { force = true, all = false })

-- Enable built-in undotree (Neovim 0.12+)
-- <Leader>uu is AstroNvim's "Toggle URL highlight"
vim.cmd "packadd! nvim.undotree"
vim.keymap.set("n", "<Leader>uU", "<Cmd>Undotree<CR>", { desc = "Undo tree" })

if vim.fn.executable "lazydocker" == 1 then
  vim.keymap.set("n", "<Leader>td", function()
    require("astrocore").toggle_term_cmd { cmd = "lazydocker", direction = "float" }
  end, { desc = "ToggleTerm lazydocker", silent = true })
end

-- Auto-open Aerial symbol outline for files > 100 lines
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    if vim.bo[args.buf].buftype == "" and vim.fn.line "$" > 100 then
      require("aerial").open { focus = false }
    end
  end,
})
