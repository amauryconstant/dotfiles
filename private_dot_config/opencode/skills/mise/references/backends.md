# mise Tool Backends Reference

Tool backends allow installing tools from different sources. Each has its own syntax and options.

## Core Backend (Built-in Tools)

The default for languages like node, python, ruby, go, rust, java, etc.

```toml
[tools]
node = "22"
python = "3.12"
go = "latest"
rust = "1.78"
```

**Built-in tools** have pre-built plugins in mise. Full list: <https://mise.jdx.dev/lang/>

---

## npm — Node Package Manager

Install global npm packages as tools.

**Syntax:**

```toml
[tools]
"npm:package-name" = "version"
"npm:@org/package-name" = "version"
```

**Examples:**

```toml
[tools]
"npm:typescript" = "latest"
"npm:@types/node" = "^20"
"npm:prettier" = "3.0.0"
"npm:@anthropic-ai/claude-code" = "latest"
"npm:@angular/cli" = "17"
"npm:create-react-app" = "5.0.1"
```

**With postinstall hook** (e.g., for playwright):

```toml
[tools]
"npm:playwright" = {version = "latest", postinstall = "playwright install"}
```

**Install globally:**

```sh
mise use npm:typescript
```

**Use:**

```sh
prettier --write src/
```

---

## pipx — Python Package Manager

Install Python CLI tools via pipx (isolated venvs).

**Syntax:**

```toml
[tools]
"pipx:package-name" = "version"
"pipx:user/repo" = "latest"   # GitHub format
```

**Examples:**

```toml
[tools]
"pipx:black" = "latest"
"pipx:ruff" = "0.1.0"
"pipx:httpie" = "latest"
"pipx:pipenv" = "latest"
"pipx:poetry" = "1.7.0"
"pipx:claude-monitor" = "latest"
```

**GitHub format** (installs from git):

```toml
[tools]
"pipx:oraios/serena" = "latest"
```

**Install:**

```sh
mise use pipx:black
```

**Use:**

```sh
black .
```

---

## cargo — Rust Package Manager

Install Rust crates as binary tools.

**Syntax:**

```toml
[tools]
"cargo:crate-name" = "version"
```

**Examples:**

```toml
[tools]
"cargo:ripgrep" = "latest"
"cargo:fd-find" = "latest"
"cargo:bat" = "0.24"
"cargo:exa" = "latest"
"cargo:just" = "1.14"
"cargo:tokio-console" = "0.1"
```

**Install:**

```sh
mise use cargo:ripgrep
```

**Use:**

```sh
rg "pattern" src/
```

---

## github — GitHub Release Binaries

Install binary tools from GitHub releases.

**Syntax:**

```toml
[tools]
"github:owner/repo" = "version"
"github:owner/repo@asset-pattern" = "version"
```

**Examples:**

```toml
[tools]
"github:BurntSushi/ripgrep" = "latest"
"github:cli/cli" = "2.45.0"
"github:golang-migrate/migrate" = "latest"
"github:junegunn/fzf" = "0.50.0"
"github:sharkdp/fd" = "latest"
```

**With asset filter** (if repo has multiple binaries):

```toml
[tools]
"github:owner/repo@binary-name" = "latest"
```

**Install:**

```sh
mise use github:cli/cli
```

**Use:**

```sh
gh repo list
```

---

## gitlab — GitLab Release Binaries

Install binary tools from GitLab releases.

**Syntax:**

```toml
[tools]
"gitlab:owner/repo" = "version"
```

**Examples:**

```toml
[tools]
"gitlab:company/internal-tool" = "latest"
"gitlab:amoconst/twiggit" = "latest"
```

**Install:**

```sh
mise use gitlab:owner/repo
```

---

## aqua — Aqua Registry

Install tools from the Aqua ecosystem (registry of Go tools).

**Syntax:**

```toml
[tools]
"aqua:registry/name" = "version"
```

**Examples:**

```toml
[tools]
"aqua:cli/cli" = "latest"
"aqua:google/protobuf" = "latest"
```

**Install:**

```sh
mise use aqua:cli/cli
```

---

## Custom Backends via Plugins

Create custom backends by writing plugins. See mise documentation for plugin development.

---

## Version Specifier Syntax

All backends support version specifiers:

| Specifier           | Meaning                  | Example                             |
| ------------------- | ------------------------ | ----------------------------------- |
| `"latest"`          | Latest available version | `"npm:typescript" = "latest"`       |
| `"22"`              | Latest 22.x              | `node = "22"`                       |
| `"1.78"`            | Exact version            | `rust = "1.78"`                     |
| `"^1.0"`            | Caret range (semver)     | `"npm:jest" = "^29.0"`              |
| `"~1.0"`            | Tilde range (semver)     | `"npm:lodash" = "~4.17"`            |
| `"ref:master"`      | Git ref (if supported)   | `go = "ref:master"`                 |
| `"prefix:1.20"`     | Any matching prefix      | `python = "prefix:3.1"`             |
| `"path:/usr/local"` | Use local binary         | `node = "path:/usr/local/bin/node"` |

---

## Backend-Specific Settings

### npm settings

```toml
[settings.npm]
bun = true              # Use bun as npm backend instead of npm/yarn/pnpm
```

### Node settings

```toml
[settings]
node.compile = 1        # Build from source
node.corepack = true    # Enable corepack shim (pnpm, yarn native)
node.flavor = "musl"    # musl/glibc variant
```

### Python settings

```toml
[settings.python]
uv_venv_auto = true     # Auto-create venvs with uv
```

---

## Choosing a Backend

| Tool Type          | Backend | When to Use                                               |
| ------------------ | ------- | --------------------------------------------------------- |
| Node global CLI    | npm     | You need a Node-based tool (prettier, typescript, eslint) |
| Python CLI         | pipx    | Self-contained Python tools (black, ruff, poetry)         |
| Rust binary        | cargo   | Fast native tools (ripgrep, fd, bat)                      |
| Any binary release | github  | Tools published on GitHub releases                        |
| GitLab tools       | gitlab  | Internal or GitLab-hosted tools                           |
| Go ecosystem       | aqua    | Go-based tools and registries                             |

---

## Common Patterns

### Full-stack JavaScript/Node

```toml
[tools]
node = "22"
"npm:typescript" = "latest"
"npm:prettier" = "latest"
"npm:eslint" = "latest"
"npm:@angular/cli" = "latest"
```

### Python data science

```toml
[tools]
python = "3.12"
"pipx:poetry" = "latest"
"pipx:black" = "latest"
"pipx:ruff" = "latest"
"pipx:jupyter" = "latest"
```

### DevOps / infrastructure

```toml
[tools]
"github:cli/cli" = "latest"
"github:golang-migrate/migrate" = "latest"
"gitlab:company/internal-tool" = "latest"
"cargo:just" = "latest"
"npm:aws-cli" = "latest"
```

### Mixed runtimes with CLI tools

```toml
[tools]
node = "22"
python = "3.12"
go = "latest"
"npm:typescript" = "latest"
"pipx:black" = "latest"
"cargo:ripgrep" = "latest"
"github:sharkdp/fd" = "latest"
```

---

## Troubleshooting Backends

**Tool not found after install:**

```sh
mise which npm:prettier        # Check install path
mise ls | grep prettier        # Verify it's listed
mise install npm:prettier      # Force reinstall
```

**Version not available:**

```sh
mise ls-remote npm:prettier    # List available versions
```

**Permission issues:**

```sh
# Some backends need write permissions to install location
export MISE_DATA_DIR=~/my_tools
mkdir -p $MISE_DATA_DIR
mise install npm:prettier
```

**Slow installation:**

```sh
# Check network
mise ls-remote npm:prettier

# Increase timeout
export MISE_HTTP_TIMEOUT=60
mise install npm:prettier
```
