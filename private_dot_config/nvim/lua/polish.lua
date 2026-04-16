-- Post-load customizations

-- Lazydocker float (<leader>td)
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
