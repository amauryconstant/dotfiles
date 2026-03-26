---
name: mise
description: >
  Use and configure mise (mise.jdx.dev) — a polyglot tool version manager, task
  runner, and environment variable manager. Trigger for: pinning tool versions
  (node, python, ruby, go, rust, java…), writing or editing mise.toml,
  configuring project environments, creating or running tasks, setting up shell
  integration, troubleshooting "command not found" or version conflicts, migrating
  from nvm/pyenv/rbenv/asdf, or any question about mise commands or configuration.
  Also trigger when user says "pin a version", "add a runtime", "create a task",
  or "mise install not working".
---

# mise Skill

mise (mise-en-place) manages tool versions, environment variables, and tasks per
project directory. Config lives in `mise.toml`; settings cascade from global
(`~/.config/mise/config.toml`) → project → subdirectories.

## Quick Command Reference

```sh
# Tool management
mise use node@22          # Pin version in current project's mise.toml
mise use --global node@22 # Set global default
mise install              # Install all pinned tools (reads mise.toml)
mise ls                   # List installed tools and active versions
mise current              # Show active versions in cwd
mise upgrade node         # Upgrade to latest matching constraint
mise exec python@3 -- python script.py  # Run at specific version without pinning

# Discovery
mise ls-remote node       # List available remote versions
mise latest node          # Show latest available version
mise doctor               # Diagnose issues (start here for any problem)

# Environment
mise env                  # Show env vars mise would set
mise env --json           # JSON format
mise which node           # Show path of active binary
mise set KEY=value        # Add env var to mise.toml
mise unset KEY            # Remove env var

# Tasks
mise run build            # Run a task
mise run test -- --verbose # Pass extra args after --
mise watch build          # Re-run task on file changes
mise tasks                # List available tasks
```

## mise.toml — Core Structure

```toml
min_version = "2024.11.1"   # Enforce minimum mise version

[tools]
node = "22"                 # Latest 22.x
python = "3.12"
go = "latest"
rust = "1.78"

# Multiple versions (dict syntax)
node = [
  {version = "22"},
  {version = "latest"},
]

# With postinstall hook
"npm:playwright" = {version = "latest", postinstall = "playwright install"}

# Tool backends
"npm:typescript" = "latest"       # npm global
"pipx:black" = "latest"           # Python CLI via pipx
"cargo:ripgrep" = "latest"        # Rust crate
"github:owner/repo" = "latest"    # GitHub release binary
"gitlab:owner/repo" = "latest"    # GitLab release binary
"aqua:cli/cli" = "latest"         # Aqua ecosystem

[env]
NODE_ENV = "development"
DATABASE_URL = { required = true }                  # Error if unset
SECRET_TOKEN = { value = "abc", redact = true }     # Hidden in logs

# Directives — see references/env.md for full syntax
_.file = ".env"                    # Load dotenv file
_.path = ["./bin", "./node_modules/.bin"]  # Extend PATH
_.source = "./scripts/env.sh"     # Source a shell script

[settings]
jobs = 4                           # Parallel install threads
experimental = true                # Enable experimental features
idiomatic_version_file_enable_tools = ["node", "python"]  # Read .nvmrc, .python-version etc.

[tasks.build]
description = "Build the project"
alias = "b"
sources = ["src/**/*"]            # Skip if inputs unchanged
outputs = ["dist/"]
run = "npm run build"

[tasks.test]
description = "Run all tests"
depends = ["build"]
env = { CI = "true" }
run = ["npm test", "pytest tests/"]

[tasks.deploy]
confirm = "Deploy to production?"  # Prompt user before running
depends = ["test"]
file = "scripts/deploy.sh"         # External script or URL
```

## Common Workflows

### Add a tool to a project

```sh
cd /path/to/project
mise use node@22     # Writes [tools] entry to mise.toml
mise install         # Install it
```

### Set global defaults

```sh
mise use --global python@3.12
# Writes to ~/.config/mise/config.toml
```

### Troubleshoot version conflicts

```sh
mise doctor          # Check for issues
mise current         # See what's active here
mise env             # See env vars being set
mise ls              # See all installed versions
mise where node      # Show install path for a tool
```

### Install all tools for a freshly cloned project

```sh
mise install         # Reads mise.toml, installs everything
```

### Migrate from asdf / nvm / pyenv

mise reads `.tool-versions` (asdf), `.nvmrc`, `.python-version` etc. automatically
when `idiomatic_version_file_enable_tools` is set. To fully migrate:

```sh
mise install        # Installs from existing version files
mise use <tool>@<version>  # Optionally write to mise.toml
```

## Shell Integration

| Mode | Command | Use case |
|------|---------|----------|
| **activate** | `eval "$(mise activate zsh)"` | Interactive shells — dynamic version switching |
| **shims** | `eval "$(mise activate bash --shims)"` | Non-interactive / GUI / CI — static PATH |

Add to your shell rc (`~/.zshrc`, `~/.bashrc`):
```sh
eval "$(mise activate zsh)"   # or bash, fish, etc.
```

For GUI apps launched outside the terminal (e.g., from a desktop environment):
```sh
eval "$(mise activate bash --shims)"  # in ~/.profile or a session env file
```

## Config File Locations

mise searches from cwd up through parents; closer files take precedence:

1. `mise.local.toml` — local overrides (git-ignore this)
2. `mise.toml`
3. `mise/config.toml` or `.mise/config.toml`
4. `.config/mise.toml` or `.config/mise/config.toml`
5. `~/.config/mise/config.toml` — global user config

JSON Schema for editor autocompletion:
```
https://mise.jdx.dev/schema/mise.json
```

## Idiomatic Version Files

Enable per-language reading of tool-native version files:

```toml
[settings]
idiomatic_version_file_enable_tools = ["node", "python", "ruby", "go", "java"]
```

| Language | Supported files |
|----------|----------------|
| Node | `.nvmrc`, `.node-version`, `package.json` engines |
| Python | `.python-version`, `.python-versions` |
| Ruby | `.ruby-version`, `Gemfile` |
| Go | `.go-version` |
| Java | `.java-version`, `.sdkmanrc` |

## Env Variables (mise itself)

| Variable | Purpose |
|----------|---------|
| `MISE_DATA_DIR` | Where tools are installed |
| `MISE_GLOBAL_CONFIG_FILE` | Override global config path |
| `MISE_<TOOL>_VERSION` | Override a tool version (e.g., `MISE_NODE_VERSION=20`) |
| `MISE_LOG_LEVEL` | Verbosity: `trace`, `debug`, `info`, `warn`, `error` |
| `MISE_QUIET=1` | Suppress non-error output |
| `MISE_RAW=1` | Pass plugin stdout/stderr directly (for interactive prompts) |
| `MISE_CEILING_PATHS` | Stop directory traversal at these paths |

## Troubleshooting Installation

Check if mise is installed and properly activated:

```sh
./scripts/check_mise.sh
```

This script verifies:
- `mise` is in PATH
- Correct version is installed
- Shell integration is activated
- Provides installation instructions if needed

## Tips

- `mise doctor` is the first command to run for any issue
- Tasks run with the full mise environment (all tools and env vars on PATH)
- `mise.local.toml` is for machine-local overrides — git-ignore it
- Tasks support `depends`, `sources`, `outputs` for smart caching
- File-based tasks: place executable scripts in `mise-tasks/` or `.mise/tasks/`
- See `references/env.md` for advanced `[env]` directives (_.file, _.path, templating)
- See `references/tasks.md` for full task options (args, shebang, file-based tasks)
