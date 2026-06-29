# Jujutsu Configuration

**Location**: `private_dot_config/jj/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**File**: `config.toml.tmpl` → `~/.config/jj/config.toml` (templated, not themed)

## Delta inheritance (key design decision)

Delta is **not** configured in jj config. jj sets `ui.pager = "delta"` and `ui.diff-formatter = ":git"`; delta then reads `~/.config/git/config` `[delta]` automatically, so git and jj share one source of truth for navigate/side-by-side/colors. Edit delta behavior in `../git/config.tmpl`, never here. `diff-formatter = ":git"` is required for delta to parse jj's diffs.

## Identity & aliases

- `[user]` uses `.fullname` + **`.workEmail`** (same default identity as git — see `../git/CLAUDE.md`).
- Aliases mirror git muscle-memory: `st` (status), `l` (`log -r "ancestors(@)"`), `sync` (`git fetch --all-remotes`).

## Cross-references

- `../git/config.tmpl` — delta settings source of truth, identity vars
- `../../.chezmoi.yaml.tmpl` — `.fullname`, `.workEmail`
- `../../.chezmoidata/packages.yaml` — `jujutsu`, `git-delta` install
- Upstream config docs: https://docs.jj-vcs.dev/latest/config/
