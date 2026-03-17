-- Post-load customizations

-- Lazydocker float (<leader>td)
if vim.fn.executable "lazydocker" == 1 then
  vim.keymap.set("n", "<Leader>td", function()
    require("astrocore").toggle_term_cmd { cmd = "lazydocker", direction = "float" }
  end, { desc = "ToggleTerm lazydocker", silent = true })
end
