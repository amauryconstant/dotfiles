# Dev Environment Improvements Backlog

Ideas surfaced from a broad dev-tooling audit (nvim, shell, terminal, git/jj,
mise). Done: zsh antidote block simplified (see `private_dot_config/zsh/dot_zshrc`
— dropped the manual bundle/warn reimplementation, `antidote load` handles it).

Neovim-specific items live in `NEOVIM_IMPROVEMENTS.md`.

---

## 1. Atuin shell history (Priority: High)

Replace `zsh-users/zsh-history-substring-search` with [Atuin](https://atuin.sh):
full-text searchable history, per-directory/context filtering, stats, optional
end-to-end-encrypted sync across machines.

**Why**: Biggest single ergonomic win found. Current setup is plain history +
fzf; Atuin is a categorical upgrade in recall.

**Sketch**:
- Add `atuin` to `.chezmoidata/packages.yaml` (Arch pkg `atuin`).
- Swap the history-substring-search line in `dot_zsh_plugins.txt`, or wire
  `atuin init zsh` via a `dot_zshrc.d/atuin.zsh` snippet.
- Decide keybind behavior: Atuin rebinds Up/`Ctrl-r` by default — preserve
  existing muscle memory (`--disable-up-arrow` if Up should stay native).
- Sync is optional and off by default; revisit only if multi-device history
  is wanted (privacy: self-hosted server vs atuin.sh).

**Open question**: keep fzf history widget alongside Atuin, or let Atuin own
`Ctrl-r` entirely.

---

## 2. Deepen jj (jujutsu) workflow (Priority: Medium, larger commitment)

`jj/config.toml.tmpl` is minimal — only `st`, `l`, `sync` aliases. jj is
adopted but underused next to the rich git worktree aliases + twiggit.

**Why**: jj's ergonomics (anonymous branches, first-class undo, revsets) are
wasted without aliases/workflow built out. Worth a focused session to either
commit to jj as primary or consciously keep git primary.

**Sketch**:
- Revset aliases (e.g. `wip`, `ready`, mine-only views).
- Workflow helper aliases (squash/split flows, `tug`-style move-bookmark).
- Confirm delta integration parity with git config.
- Decide primacy: if jj stays secondary, scope this down to "comfortable for
  occasional use" rather than full migration.

**Decision needed first**: jj-primary vs git-primary. Drives how much to build.

---

## 3. Neovim backlog (see NEOVIM_IMPROVEMENTS.md)

Pending items from the VS Code → Neovim migration, still open:
- Session persistence (`resession.nvim`) — lose buffer/split layout per project.
- VS Code keybindings (`<C-p>`, `<C-S-f>`, split leaders).
- `toggleterm` integrated terminal.
- AI assistant — **open question whether wanted at all** given heavy Claude Code
  use; inline completion (Supermaven/Copilot) is the only non-redundant piece,
  a chat panel (Avante) duplicates Claude Code.

Could be knocked out as a single batch.
