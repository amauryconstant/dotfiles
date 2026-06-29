# Shell Configuration (POSIX layer)

**Location**: `private_dot_config/shell/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Scope**: POSIX `sh` files shared by **both** zsh and bash. Zsh-specific config (antidote, Zephyr, zstyles) lives in `../zsh/` — see `zsh/CLAUDE.md`.

## Files & load model

| File | Target | Role |
|------|--------|------|
| `env` | `~/.config/shell/env` | Bootstrap. Exports `ENV` (→ `interactive`), `BASH_ENV` (→ `~/.config/bash/env`), `SCRIPTS_DIR`, `UI_LIB`, `CLAUDE_CONFIG_DIR`, `umask 0077`. |
| `login.tmpl` | `~/.config/shell/login` | All persistent env: XDG dirs, PATH (prepends `local_bin`/`local_sbin` with dedup guard), `EDITOR`/`VISUAL`/`BROWSER`, toolchain homes (`CARGO_HOME`, `GOPATH`, `NPM_CONFIG_*`), `__GL_SHADER_DISK_CACHE_PATH`, `PROJECTS`/`WORKTREES`. |
| `interactive` | `~/.config/shell/interactive` | Interactive-only: `mesg n`, color env (`CLICOLOR`, `COLORTERM`). Pointed to by `$ENV`. |
| `logout` | `~/.config/shell/logout` | `clear_console` at `SHLVL=1` for privacy. |

**Key points (non-obvious):**
- `login.tmpl` is the single env source — every value comes from `.globals.*` (`.chezmoidata/globals.yaml`), so change paths/apps/XDG there, not inline. It is **not** delegated to Zephyr; zsh layers Zephyr's `environment` plugin on top but the POSIX baseline lives here so bash/sh get the same env.
- `UI_LIB` is exported but **lazy-loaded on demand**, not sourced at startup (keeps shell init fast). See `private_dot_local/lib/scripts/CLAUDE.md`.
- `env` chains the shells together via `$ENV`/`$BASH_ENV`; don't move those exports.

## Constraint

These four files must stay POSIX `sh` (sourced by bash too): no `[[`, no arrays, `.` not `source`. `login.tmpl` is the only template — validate with `chezmoi execute-template < login.tmpl`.

## Integration

Sourced by `../zsh/dot_zshrc` and `~/.bashrc`. Consumers: `SCRIPTS_DIR`/`UI_LIB` → `~/.local/lib/scripts/`; XDG dirs → all configs.
