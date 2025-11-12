# Shell Configuration - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/shell/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Layered POSIX shell + Zsh Zephyr framework
- **Shells**: Zsh (primary), Bash (POSIX foundation)
- **Files**: POSIX shell (env, login, interactive) + Zsh (zstyles, plugins)
- **Pattern**: Progressive enhancement (POSIX → Zsh → Zephyr)

## Layered Architecture

**File purposes**:

| File | Purpose | Source timing | POSIX? |
|------|---------|---------------|--------|
| `env` | Environment variables (minimal, XDG sourcing) | Login shells | ✅ Yes |
| `env_functions` | Environment setup functions | Sourced by env | ✅ Yes |
| `login.tmpl` | Login shell config (reduced, most → Zephyr) | Login shells | ✅ Yes |
| `interactive` | Interactive shell config | Interactive shells | ✅ Yes |
| `logout` | Cleanup on logout | Logout | ✅ Yes |

**Load order**:
1. `env` → Sets up XDG, sources env_functions
2. `login.tmpl` → Minimal PATH additions (most → Zephyr)
3. `interactive` → Aliases, prompt, interactive features

## File Details

### env (4 lines)

**Purpose**: Minimal environment setup, XDG sourcing

**Pattern**:
```sh
# XDG Base Directory minimal setup
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Source environment functions
. "$XDG_CONFIG_HOME/shell/env_functions"
```

**Why minimal**: Most environment setup moved to Zephyr (zstyles)

### env_functions

**Purpose**: Helper functions for environment setup

**Functions**: (details from file)

### login.tmpl (16 lines)

**Purpose**: Login shell configuration (59% reduction from original 39 lines)

**What remains**:
- Minimal PATH additions (critical paths only)
- Shell-specific sourcing

**What moved to Zephyr**:
- XDG Base Directory variables
- Default applications (EDITOR, VISUAL, BROWSER)
- Custom PATH (SCRIPTS_DIR, UI_LIB)
- Umask setting

**Template variables**:
```go
{{ .globals.xdg.config_home }}
{{ .globals.applications.terminal }}
```

### interactive

**Purpose**: Interactive shell features

**Content**:
- Aliases (ls → eza, cat → bat, etc.)
- Prompt configuration (if not using Starship)
- Interactive-only features

**POSIX compliance**: Uses portable syntax

### logout

**Purpose**: Cleanup on logout

**Content**:
- Clear sensitive variables
- Cleanup temporary files
- History management

## POSIX Patterns

**Portable syntax**:
```sh
# POSIX-compliant variable check
[ -n "$VAR" ] && command

# POSIX-compliant sourcing
[ -f "$file" ] && . "$file"

# POSIX-compliant string manipulation
var="${var#prefix}"   # Remove prefix
var="${var%suffix}"   # Remove suffix
```

**Avoid**:
❌ `[[` (bashism)
❌ `source` (use `.` instead)
❌ `=~` regex (use case/grep instead)
❌ Arrays (not POSIX)

## Migration to Zephyr

**Before** (shell/login, 39 lines):
- XDG variables defined inline
- PATH additions manual
- EDITOR/VISUAL/BROWSER set directly
- SCRIPTS_DIR/UI_LIB exported

**After** (shell/login, 16 lines + Zephyr):
- Minimal critical PATH only
- Everything else → `.zstyles`
- Zephyr handles deduplication
- Better plugin integration

**Before** (shell/env, 23 lines):
- Complex XDG setup
- Multiple sourcing logic

**After** (shell/env, 4 lines):
- Minimal XDG for bootstrapping
- Functions moved to env_functions

## Zsh Configuration (Zephyr Framework)

**Purpose**: Modern Zsh environment management via zstyle config
**Location**: `../zsh/dot_zstyles`

### Core Plugins (10)

| Plugin | Purpose |
|--------|---------|
| `color` | Color support utilities |
| `completion` | Enhanced completion (compstyle: zephyr, caching) |
| `compstyle` | Completion styling |
| `confd` | Config directory support |
| `directory` | Directory navigation helpers |
| `editor` | Editor integration (prepend-sudo, magic-enter, dot-expansion) |
| `environment` | Env var management (XDG, PATH, EDITOR/VISUAL/BROWSER) |
| `history` | History management |
| `utility` | General utilities |
| `zfunctions` | Function autoloading |

### Key Features

**Editor Enhancements**:
- `Ctrl+S`: Prepend sudo
- Magic Enter: Empty → `ls`, directory → `cd`
- Dot expansion: `..` → `../`, `...` → `../../`

**Environment Management** (migrated from shell/login):
```zsh
zstyle ':zephyr:plugin:environment' use-xdg-basedirs yes
zstyle ':zephyr:plugin:environment' EDITOR 'nvim'
zstyle ':zephyr:plugin:environment' VISUAL 'code'
zstyle ':zephyr:plugin:environment' BROWSER 'firefox'
zstyle ':zephyr:plugin:environment' prepath ~/.local/bin
zstyle ':zephyr:plugin:environment' 'SCRIPTS_DIR' "$HOME/.local/lib/scripts"
zstyle ':zephyr:plugin:environment' 'UI_LIB' "$HOME/.local/lib/scripts/core/gum-ui.sh"
```

**Additional Plugins**:
- Prompt: `axieax/zsh-starship`
- Completions: fzf-tab, zsh-completions, eza, fzf, zoxide
- Fish-like: autosuggestions, history-substring-search, fast-syntax-highlighting

### Migration Benefits

**From shell/login** (59% reduction):
- Environment variables → `.zstyles`
- PATH additions → Zephyr (auto-deduplication)
- XDG variables → Zephyr management

**From shell/env** (83% reduction):
- Complex setup → Minimal bootstrap
- Functions → `env_functions`

## Integration Points

- **Zsh**: `../zsh/dot_zshrc.tmpl` sources POSIX shell files
- **Bash**: `~/.bashrc` sources POSIX shell files
- **Zephyr**: `../zsh/dot_zstyles` (environment plugin)
- **XDG**: Defines base directories for all configs
- **Starship**: `~/.config/starship.toml` (prompt)
- **Script library**: `~/.local/lib/scripts/` (SCRIPTS_DIR, UI_LIB)
