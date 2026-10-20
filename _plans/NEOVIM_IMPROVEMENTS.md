# Neovim Improvements Backlog

Remaining suggestions from the VS Code → Neovim migration review.
Items 1 (Neogit), 2 (nvim-dap UI), 5 (LuaSnip), 10 (editor options) already implemented; 7 (toggleterm) is moot, see below.
Reviewed 2026-10-20: nothing else started. Config is AstroNvim `^6`, whose picker is **snacks** (`lua/plugins/user.lua`), not Telescope.

---

## 3. Custom Keybindings — VS Code Muscle Memory (Priority: High)

Add VS Code-familiar shortcuts in `lua/plugins/astrocore.lua` under `opts.mappings`:

```lua
mappings = {
  n = {
    ["<C-p>"]   = { function() Snacks.picker.files() end, desc = "Find files" },
    ["<C-S-f>"] = { function() Snacks.picker.grep() end,  desc = "Find in files" },
    ["<leader>|"] = { "<cmd>vsplit<cr>",              desc = "Vertical split" },
    ["<leader>-"] = { "<cmd>split<cr>",               desc = "Horizontal split" },
  },
}
```

Note: `<Leader>gg` for Neogit is added automatically by the neogit community pack.

---

## 4. Session Management — Workspace Persistence (Priority: Medium)

VS Code remembers open files per workspace. Add resession.nvim:

**In `lua/community.lua`:**
```lua
{ import = "astrocommunity.utility.resession-nvim" },
```

Saves/restores buffers, splits, and cursor position per project directory.

---

## 6. AI Coding Assistant (Priority: Medium)

Choose one:

**Option A — GitHub Copilot (requires subscription):**
```lua
{ import = "astrocommunity.completion.copilot-lua-cmp" },
```

**Option B — Supermaven (free tier, very fast):**
```lua
{ import = "astrocommunity.completion.supermaven-nvim" },
```

**Option C — Avante (Claude/GPT chat panel, VS Code Copilot Chat equivalent):**
```lua
{ import = "astrocommunity.editing-support.avante-nvim" },
```

---

## 7. Terminal Integration — Integrated Terminal ✅ MOOT

`toggleterm.nvim` already ships with AstroNvim core (present in the lazy plugin dir; `lua/plugins/astrocore.lua` already works around its buffer names), so the community import below is unnecessary. Original note: VS Code has `Ctrl+\`` for integrated terminal. Add toggleterm:

**In `lua/community.lua`:**
```lua
{ import = "astrocommunity.terminal-integration.toggleterm-nvim" },
```

Gives `<C-\>` to toggle floating/split terminal. Replaces the single lazydocker binding.
Also enables named terminals (e.g., one per project).

---

## 8. Multi-cursor / Multi-edit (Priority: Low)

**Learn first**: `cgn` + `.` is the Vim-native approach — change the word under search,
then `.` repeats across matches. Faster than VS Code's Ctrl+D once learned.

If you still want multi-cursor plugin:
```lua
{ import = "astrocommunity.editing-support.vim-visual-multi" },
```

---

## 9. Format-on-save for Additional Filetypes (Priority: Low) ✅ DONE

Already handled — lua, sh, yaml, json added to `astrolsp.lua` allow_filetypes.
