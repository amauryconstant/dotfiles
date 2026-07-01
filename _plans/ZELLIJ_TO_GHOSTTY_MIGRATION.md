# Zellij → Ghostty Migration (Deferred Steps)

Backlog for finishing the zellij → native-Ghostty migration. **Gated: do not
execute until the user is certain they want to drop zellij.** The coexistence
trial (Phase 1–2) is already live; this doc holds the destructive Phase 3–4 that
were intentionally deferred.

Full rationale + research: `~/.config/claude/plans/lauch-a-subagent-tasked-mellow-seal.md`.
Working preference driving the gating: keep the old tool functional until committed
(coexistence over replace-and-delete).

---

## Status: what's already done (coexistence trial, live)

- **Ghostty splits** confirmed fully native + enabled by default (`ctrl+shift+o`/`e`
  new split, `ctrl+alt+arrows` navigate, `super+ctrl+shift+arrows` resize,
  `ctrl+shift+enter` zoom, `split-inherit-working-directory = true`). Only addition:
  `keybind = ctrl+shift+equal=equalize_splits` in `private_dot_config/ghostty/config.tmpl`.
- **Parallel launcher** `private_dot_local/lib/scripts/terminal/executable_ghostty-sessionizer.tmpl`
  on **`Super+Shift+O`** (fzf project pick → `nvim` in-place). `Super+O` still → zellij.
- Nothing zellij-owned removed or repointed.

## Ghostty constraints that shaped this (verified against docs, Ghostty 1.3.1)

- **No CLI/config multi-pane layout at launch** (issue #2480 open) → coding layout
  lives inside Neovim (toggleterm/`snacks.terminal`), not terminal-level panes.
- **No session persistence on Linux** — `window-save-state` is macOS-only. Launcher
  rebuild is the only path (matches user's "rebuild from scratch" morning workflow).
- **Sixel will never be supported** → image.nvim must use the `kitty` backend.
- Don't steal keys from nvim: prefer `unconsumed:` / `performable:` keybind prefixes.

---

## Phase 3 — Optional nvim tweak (non-destructive, Priority: Low)

Can run during the trial *without* committing to removal, if unified `<c-hjkl>`
across nvim + Ghostty splits is wanted sooner.

File: `private_dot_config/nvim/lua/plugins/user.lua`
- Replace `swaits/zellij-nav.nvim` block (L3–16) with `mrjones2014/smart-splits.nvim`,
  keeping the same `<c-h/j/k/l>` mappings. smart-splits auto-detects the multiplexer,
  so it works with **both** zellij and Ghostty splits — safe to swap before Phase 4.
- Consider sourcing via `community.lua` (AstroCommunity) to match the repo's plugin
  convention instead of a raw spec.

**Why deferred**: current `zellij-nav.nvim` still serves in-zellij usage; no urgency.

**Leave alone until Phase 4**: the `image.nvim` `ZELLIJ ? sixel : kitty` conditional
(L17–28) — sixel still needed inside zellij while it coexists.

---

## Phase 4 — Full removal (Priority: gated — only on explicit "switch" go-ahead)

Cutover checklist. Do all together once the user commits.

**Repoint the primary binding**
- `private_dot_config/hypr/conf/bindings/applications.conf.tmpl` + `.lua.tmpl`:
  point `Super+O` at `ghostty-sessionizer`; drop the `Super+Shift+O` trial binding.

**Neovim**
- Swap `zellij-nav.nvim` → `smart-splits.nvim` (if not already done in Phase 3).
- `image.nvim`: set `backend = "kitty"` unconditionally; delete the `ZELLIJ` ternary
  and the sixel/1.4 comment (`user.lua` L17–28).

**Delete zellij surface**
- `private_dot_config/zellij/` (config.kdl, `layouts/`, `themes/`).
- 8× `private_dot_config/themes/*/zellij.kdl`.
- `private_dot_local/lib/scripts/desktop/executable_theme-apply-zellij` **and** its
  invocation block in `executable_theme-switcher.tmpl` (~L152–154).
- `private_dot_config/zsh/dot_zshrc.d/zellij-completions.zsh`.
- `private_dot_config/zsh/dot_zshrc.d/zellij-layouts.zsh.tmpl` (retires `zdl` +
  chpwd auto session-rename). Optionally leave a thin `ws` alias for the launcher.
- `private_dot_local/lib/scripts/terminal/executable_zellij-sessionizer.tmpl`.
- `alias zj='zellij'` in `dot_zshrc.d/aliases.zsh` (L30).
- `- zellij` in `.chezmoidata/packages.yaml` (~L171) → `run_onchange_before_sync_packages`
  prunes the package on next apply.

**Docs**
- Update refs in `private_dot_config/zsh/CLAUDE.md`, `private_dot_local/lib/scripts/CLAUDE.md`,
  `private_dot_local/CLAUDE.md`, `private_dot_config/CLAUDE.md`, and `_plans/OMARCHY.md`.

---

## What is lost at cutover (accepted)

- Live detach/reattach — unused (workflow rebuilds from scratch).
- chpwd auto session-switching — cosmetic.
- Zellij status/tab bar — Ghostty has a native tab bar only.
- Declarative KDL layouts — replaced by nvim toggleterm + ad-hoc Ghostty splits.
  The old `monitoring.kdl` (btop + journalctl + shell) becomes an ad-hoc Ghostty
  split arrangement, or btop via Ghostty's `quick-terminal` dropdown.

## Cutover verification

1. `chezmoi diff` → `chezmoi apply`; `hyprctl reload`; restart Ghostty.
2. `Super+O` now opens the Ghostty launcher; `zj`/`zdl`/`zellij-sessionizer` gone.
3. `command -v zellij` empty after package prune (`package-manager sync --prune`).
4. nvim: `<c-hjkl>` navigates splits (smart-splits); `image.nvim` renders via kitty.
5. `theme switch <name>` runs clean (no zellij hook).
6. `rg -i zellij` in the repo returns nothing unintended.
