# Zsh Configuration - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/zsh/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Shell config**: See `../shell/CLAUDE.md` for POSIX layer + Zephyr framework
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Zsh-specific config (interactive shell, plugins, functions)
- **Plugin manager**: antidote (system package: `zsh-antidote`)
- **Framework**: Zephyr (via antidote) - configured in `dot_zstyles`
- **Prompt**: Starship (via `axieax/zsh-starship` antidote plugin)
- **POSIX layer**: Delegates to `~/.config/shell/{env,interactive,login}`

## File Structure

| File | Target | Purpose |
|------|--------|---------|
| `dot_zshenv` | `~/.config/zsh/.zshenv` | Bootstraps POSIX env (sources `shell/env`) |
| `dot_zshrc` | `~/.config/zsh/.zshrc` | Interactive shell (antidote, zshrc.d) |
| `dot_zlogin` | `~/.config/zsh/.zlogin` | Login shell (sources `shell/login`) |
| `dot_zlogout` | `~/.config/zsh/.zlogout` | Logout cleanup (sources `shell/logout`) |
| `dot_zstyles` | `~/.config/zsh/.zstyles` | Zephyr + antidote plugin config |
| `dot_zsh_plugins.txt` | `~/.config/zsh/.zsh_plugins.txt` | antidote plugin list |
| `dot_zshrc.d/*.zsh` | `~/.config/zsh/.zshrc.d/` | Auto-sourced snippets |
| `dot_zfunctions/` | `~/.config/zsh/.zfunctions/` | Autoloaded Zsh functions |
| `dot_zcompletions/` | `~/.config/zsh/.zcompletions/` | Custom completions (`_*`) |

## Plugin System (antidote)

**Source**: `/usr/share/zsh-antidote/antidote.zsh` (Arch package)

**Load flow** (in `dot_zshrc`):
1. Source antidote
2. `antidote load` (uses cached `.zsh_plugins.zsh`)
3. Falls back: bundles from `dot_zsh_plugins.txt` if cache missing
4. Graceful offline handling (skips with warning)

**Plugin categories** (`dot_zsh_plugins.txt`):
- Zephyr framework: color, completion, directory, editor, environment, history, utility, zfunctions
- Completions: fzf-tab, zsh-completions, eza, fzf, zoxide, yazi-zoxide
- PVMs: uv, mise
- Fish-like: autosuggestions, history-substring-search, fast-syntax-highlighting

**Adding plugins**: Edit `dot_zsh_plugins.txt`, then run `antidote bundle <.zsh_plugins.txt >.zsh_plugins.zsh`

## Zshrc.d Snippets

Auto-sourced in `dot_zshrc` (alphabetical order, ignores `~*` files):

| File | Purpose |
|------|---------|
| `aliases.zsh` | Tool aliases (xh, fd, eza, jaq, pnpm, etc.) |
| `chezmoi-aliases.zsh` | Chezmoi shortcuts (cmapply, cmedit, cmadd, etc.) |
| `dot-expansion-fix.zsh` | Compatibility shim for Zephyr dot-expansion ZLE widget |
| `twiggit.zsh` | twiggit `cd` subcommand wrapper (requires shell function for directory change) |

**Adding snippets**: Drop `*.zsh` file in `dot_zshrc.d/` — auto-sourced next shell.

## Zsh Functions (`dot_zfunctions/`)

Autoloaded via Zephyr `zfunctions` plugin:

| Function | Purpose |
|----------|---------|
| `br` | broot wrapper (executes shell commands produced by broot) |
| `commands` | List all custom CLI tools with descriptions |
| `debug-zsh-startup` | Startup time profiling utility |
| `theme` | Wrapper for `theme-switcher` with tab completion |
| `theme-list` | Display available themes with current indicator |

## Custom Completions (`dot_zcompletions/`)

| File | Completes |
|------|-----------|
| `_twiggit` | twiggit subcommands (cobra-generated) |

**Adding completions**: Drop `_commandname` file (fpath completion format).

## Key Quirks

**dot-expansion**: Zephyr's `editor` plugin `dot-expansion` feature requires a ZLE widget named `expand-dot-to-parent-directory-path`. The shim in `dot-expansion-fix.zsh` bridges this.

**twiggit cd**: Shell `cd` cannot be done by child processes — twiggit's `cd` subcommand prints a path, and the wrapper captures + executes it.

**Antidote offline**: If plugins aren't cached and network is unavailable, shell starts without plugins (warns, doesn't crash).

**Debug startup**: `ZSH_DEBUGRC=1 zsh` profiles with `zprof`. Or call `debug-zsh-startup` function.

## Integration Points

- **POSIX shell**: `shell/env`, `shell/interactive`, `shell/login` (ZDOTDIR delegation)
- **Zephyr PATH**: `dot_zstyles` prepath adds all `~/.local/lib/scripts/` categories
- **Theme system**: `theme` / `theme-list` functions wrap `theme-switcher` script
- **Script library**: PATH includes all 10 script categories (directly executable)
- **Starship prompt**: Configured via `~/.config/starship.toml` (theme symlink)
