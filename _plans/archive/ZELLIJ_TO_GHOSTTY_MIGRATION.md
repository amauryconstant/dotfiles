# Zellij → Ghostty Migration (Deferred Steps)

**Status**: ✅ COMPLETE — Phase 4 executed 2026-09-21. **Archived**: 2026-09-21.

Zellij is gone: config, layouts, themes, completions, `zdl`/`zj`, the
`zellij-sessionizer` launcher and the package itself. `Super+O` now opens
`ghostty-sessionizer`; splits are native Ghostty, the secondary pane lives in
Neovim.

**Phase 3 was dropped, not done.** `smart-splits.nvim` turned out to be
unnecessary — AstroNvim already maps `<C-H/J/K/L>` to `<C-w>hjkl`, and Ghostty
splits navigate on `ctrl+alt+arrows`, so the two keysets never collide.
`zellij-nav.nvim` was deleted and nothing replaced it. Revisit only if
nvim-edge → Ghostty-split crossing is wanted.

**🚨 Still open — the session-persistence gap.** This plan's own "What is lost at
cutover" correction below stands, and the cutover did **not** resolve it. There
is now no session persistence on Linux at all: a closed window kills whatever ran
in it, including unattended coding agents. Accepted knowingly; the replacement is
an open question tracked in `_research/TERMINAL_AGENT_RUNTIME.md` (herdr, or a
remote host) and reopened in `_plans/OMARCHY.md`.

---

Backlog for finishing the zellij → native-Ghostty migration. **Gated: do not
execute until the user is certain they want to drop zellij.** The coexistence
trial (Phase 1–2) is already live; this doc holds the destructive Phase 3–4 that
were intentionally deferred.

Working preference driving the gating: keep the old tool functional until committed
(coexistence over replace-and-delete).

> **2026-09-13**: the original rationale file
> (`~/.config/claude/plans/lauch-a-subagent-tasked-mellow-seal.md`) **no longer exists**.
> The reasoning that survives is what this document states plus
> `_research/TERMINAL_AGENT_RUNTIME.md`, which re-derives the whole-layer decision
> against the agent workload. Read that before executing Phase 4.

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
  It also supports **herdr** (`multiplexer_integration = 'herdr'`), so this swap is
  no-regret under every option in `_research/TERMINAL_AGENT_RUNTIME.md`. Detection is
  by `$TERM_PROGRAM`; pin the value explicitly if nesting confuses it.
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

- ~~Live detach/reattach — unused (workflow rebuilds from scratch).~~
  🚨 **Corrected 2026-09-13: this was false.** `zellij a <session>` was in regular use.
  It also became load-bearing after this plan was written: coding agents run unattended
  across projects, and for a process you walked away from, "rebuild from scratch" is
  data loss rather than a neutral default. Ghostty cannot replace it —
  `window-save-state` is macOS-only, so the Phase 4 end state has **no** session
  persistence on Linux at all. This is not a reason to keep zellij (see below), but it
  is no longer an accepted loss without a replacement for the agent case.
  Evidence: `_research/TERMINAL_AGENT_RUNTIME.md` Part 2.
- chpwd auto session-switching — cosmetic.
- Zellij status/tab bar — Ghostty has a native tab bar only.
- Declarative KDL layouts — replaced by nvim toggleterm + ad-hoc Ghostty splits.
  The old `monitoring.kdl` (btop + journalctl + shell) becomes an ad-hoc Ghostty
  split arrangement, or btop via Ghostty's `quick-terminal` dropdown.

## The agent layer is a separate question (2026-09-13)

Phase 4 removes zellij. It does **not** answer where coding agents live, and that
question was not in scope when this plan was written.

`_research/TERMINAL_AGENT_RUNTIME.md` examines Herdr (v0.9.0, Apache-2.0) as an
agent-layer candidate at source level. Summary as it bears on this plan:

- **It does not compete with Ghostty.** Herdr runs inside a terminal emulator, and
  vendors `libghostty-vt` as its VT engine — so panes inside it parse exactly as
  Ghostty does, and the Kitty graphics protocol works (unlike inside zellij).
- **It does not change Phase 4.** If adopted it would be scoped to agent panes only;
  interactive work stays on Ghostty splits + nvim exactly as planned here.
- **It does not rescue the persistence loss corrected above.** This laptop suspends,
  and agents die with it regardless of multiplexer. Only idle-inhibit discipline or a
  remote host answers that.
- **What it does answer** is the measured pain: agent state is currently discovered by
  cycling Ghostty tabs by hand.

**Ordering, if Herdr is adopted**: Herdr first, Phase 4 after. Zellij costs nothing
sitting idle, and this plan's own principle is coexistence over replace-and-delete.

---

## Cutover verification

1. `chezmoi diff` → `chezmoi apply`; `hyprctl reload`; restart Ghostty.
2. `Super+O` now opens the Ghostty launcher; `zj`/`zdl`/`zellij-sessionizer` gone.
3. `command -v zellij` empty after package prune (`package-manager sync --prune`).
4. nvim: `<c-hjkl>` navigates splits (smart-splits); `image.nvim` renders via kitty.
5. `theme switch <name>` runs clean (no zellij hook).
6. `rg -i zellij` in the repo returns nothing unintended.
