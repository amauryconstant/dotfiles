-- Post-load customizations

-- Enable built-in undotree (Neovim 0.12+)
vim.cmd("packadd! undotree")
vim.keymap.set("n", "<Leader>uu", vim.cmd.UndotreeToggle, { desc = "Undo tree" })

if vim.fn.executable "lazydocker" == 1 then
  vim.keymap.set("n", "<Leader>td", function()
    require("astrocore").toggle_term_cmd { cmd = "lazydocker", direction = "float" }
  end, { desc = "ToggleTerm lazydocker", silent = true })
end

-- Auto-open Aerial symbol outline for files > 100 lines
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    if vim.fn.line "$" > 100 then
      require("aerial").open { focus = false }
    end
  end,
})
