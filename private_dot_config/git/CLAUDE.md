# Git Configuration

**Location**: `private_dot_config/git/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

## Files

- `config.tmpl` → `~/.config/git/config`. Sections: `core`, `user`, `alias`, `delta`, `fetch`, `init`, `interactive`, `log`, `merge`, `push`, `pull`.
  - Identity uses **`.workEmail`** + `.fullname` (this is the default-identity machine; per-repo overrides handle personal work).
  - `[delta]` is configured here and **inherited by jj** via git config — see `jj/CLAUDE.md`.
  - `[merge "mergiraf"]` registers the syntax-aware merge driver for source-code files (`.go`/`.rs`/`.yaml`/…), wired through the deployed `~/.gitattributes` (`dot_gitattributes`).
- `dot_gitattributes` → `~/.gitattributes`: global mergiraf rules for source files.

## Template merge driver (chezmoi `.tmpl` files)

This repo's own `*.tmpl` files use a separate `chezmoi-template` merge driver so merges don't render `{{ .var }}` into literal values. It is **not** defined in `config.tmpl` — it's registered into the chezmoi source repo's local git config by `.chezmoiscripts/run_once_after_001_configure_developer_tools.sh.tmpl`, and matched via the repo-root `.gitattributes` rule `*.tmpl merge=chezmoi-template`.

**See `.scripts/CLAUDE.md`** for the driver algorithm, args, and the mergiraf-vs-chezmoi-template distinction.

## Merge conflict workflow

```bash
chezmoi status              # "M" marks a file with merge conflicts
chezmoi merge <file>        # resolve one (opens merge tool)
chezmoi merge-all           # resolve all
```

`.age` files are `binary` in `.gitattributes` — never auto-merged; resolve encrypted files manually per the root CLAUDE.md safety protocol.
