# mise Config File Loading & Precedence

## Config File Search Order

mise searches upward from the current directory, checking for config files in this order:

```
Current directory / project root
├── 1. mise.local.toml          ← Local overrides (git-ignore this)
├── 2. mise.toml                ← Project config
├── 3. mise/config.toml         ← or .mise/config.toml
├── 4. .config/mise.toml        ← or .config/mise/config.toml
└── (continue upward to parent directories)

Home directory
└── 5. ~/.config/mise/config.toml     ← Global config

System-wide
└── 6. /etc/mise/config.toml          ← System config
```

**Key points:**
- Search continues upward until a config is found
- Closer (more specific) directories override parent directories
- `mise.local.toml` is always checked first in each directory (if present)
- All matching files in `~/.config/mise/conf.d/` are loaded (alphabetical)

## Config Precedence Example

```
Project structure:
~/work/myapp/
├── mise.toml              ← Closest to cwd
├── .mise/
│   └── config.toml        ← Would be checked if mise.toml missing
└── (parent: ~/work/)
    └── mise.toml          ← Only used if ~/work/myapp/ has no config

Result: ~/work/myapp/mise.toml wins
```

## Section Merge Behavior

When multiple config files are loaded (from parent directories or `conf.d/`), sections merge differently:

| Section | Behavior | Example |
|---------|----------|---------|
| `[tools]` | **Additive** — closer files add/override | Parent: `node=20`, Child: `node=22` → Child wins |
| `[env]` | **Additive** — closer files add/override | Parent: `FOO=a`, Child: `FOO=b` → Child wins |
| `[settings]` | **Additive** — closer files add/override | Parent: `jobs=4`, Child: `jobs=8` → Child wins |
| `[tasks]` | **Replace per task** — no merging | Parent: `[tasks.build]`, Child: `[tasks.build]` → Child's version used |

**Example:**

```toml
# Parent: ~/work/mise.toml
[tools]
node = "20"
python = "3.11"

[tasks.ci]
run = "npm test"

# Child: ~/work/myapp/mise.toml
[tools]
node = "22"        # Overrides parent's 20
ruby = "3.0"       # Adds to parent's tools

[tasks.ci]
run = "npm test && pytest"  # Replaces parent's task entirely
```

**Result after merging:**
```toml
[tools]
node = "22"        ← from child (override)
python = "3.11"    ← from parent (inherited)
ruby = "3.0"       ← from child (addition)

[tasks.ci]
run = "npm test && pytest"  ← from child (replace)
```

## Local Overrides (`mise.local.toml`)

`mise.local.toml` takes highest priority in the current directory:

```toml
# mise.toml (checked into git)
[tools]
node = "22"
python = "3.12"

# mise.local.toml (git-ignored, machine-specific)
[tools]
node = "20"        ← Overrides for this machine
python = "3.11"
```

**Use case:** Developer-specific versions, machine-specific paths, secrets

**Git setup:**
```bash
echo "mise.local.toml" >> .gitignore
```

## Config File Precedence via CLI

Set config file location with environment variable:

```sh
# Use specific config file
MISE_GLOBAL_CONFIG_FILE=~/.mise/config.toml mise ls

# Use a temporary config for one command
MISE_GLOBAL_CONFIG_FILE=/tmp/test.toml mise install
```

## Version Enforcement

Require minimum mise version in config:

```toml
min_version = "2024.11.1"
```

Mise will error if installed version is older. Soft warning + hard error:

```toml
min_version = { soft = "2024.9.0", hard = "2024.11.1" }
# soft: warning if older
# hard: error if older
```

## Trusted Config Paths

By default, mise auto-loads configs. For security, restrict loading:

```toml
[settings]
trusted_config_paths = [
  "/home/user/projects",
  "/opt/shared"
]
```

Only configs in these paths (and parents) are auto-loaded. Others require explicit trust:

```sh
mise trust /path/to/config
mise untrust /path/to/config
```

## Config File Examples

### Project with subdirectories

```
myapp/
├── mise.toml                     ← Shared config
├── backend/
│   └── mise.toml                 ← Backend-specific, inherits from root
└── frontend/
    └── mise.toml                 ← Frontend-specific, inherits from root
```

Each backend/frontend config inherits from root and adds/overrides as needed.

### Monorepo setup

```
monorepo/
├── mise.toml                     ← Global tools + shared tasks
├── packages/
│   ├── server/
│   │   └── mise.toml             ← Server-specific tools/tasks
│   └── client/
│       └── mise.toml             ← Client-specific tools/tasks
└── ~/.config/mise/config.toml    ← User's global defaults
```

## Debugging Config Loading

See which config files are being loaded:

```sh
mise doctor        # Shows loaded config path
mise config        # Lists config in use
```

Verbose output:

```sh
MISE_LOG_LEVEL=debug mise install
```

## Config File Best Practices

1. **Use `mise.toml` for shared configs** — check into git
2. **Use `mise.local.toml` for machine-specific** — git-ignore
3. **Use global `~/.config/mise/config.toml` for user defaults** — applies everywhere
4. **Lean on section merging** — parent + child configs work together
5. **Document min_version** if you use experimental features
6. **Use subdirectory configs** in monorepos for isolation
