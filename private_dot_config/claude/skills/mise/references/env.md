# mise [env] Reference

## Directives (`_.*`)

### Load a dotenv file

```toml
[env]
_.file = ".env"
_.file = [".env", ".env.local"]
_.file = [
  ".env.json",
  { path = ".secrets.yaml", redact = true },
  { path = ".env.prod", tools = true }  # Evaluated after tools are activated
]
```

### Extend PATH

```toml
[env]
_.path = "./bin"
_.path = ["~/.local/bin", "{{config_root}}/node_modules/.bin"]
```

### Source a shell script

```toml
[env]
_.source = "./scripts/base.sh"
_.source = [
  "./scripts/base.sh",
  { path = ".secrets.sh", redact = true, tools = true }
]
```

### Multiple directives of the same type

Use array-of-tables syntax:

```toml
[[env]]
_.source = "./script_1.sh"
[[env]]
_.source = "./script_2.sh"
```

## Templating in [env]

Uses Tera template syntax (`{{ }}`):

```toml
[env]
LD_LIBRARY_PATH = "/some/path:{{env.LD_LIBRARY_PATH}}"
MY_VAR = "{{config_root}}/lib"
TOOL_VER = { value = "{{ tools.node.version }}", tools = true }
```

Enable `$VAR` shell-style expansion:

```toml
[settings]
env_shell_expand = true

[env]
LD_LIBRARY_PATH = "$MY_LIB:$LD_LIBRARY_PATH"  # Supports ${VAR:-default}
```

## Required and Redacted Variables

```toml
[env]
API_KEY = { required = true }                         # Error if missing
API_KEY = { required = "Get key at example.com" }    # Custom message
SECRET = { value = "abc", redact = true }             # Shown as [redacted]
redactions = ["SECRET_*", "*_TOKEN", "PASSWORD"]      # Pattern-based redaction
```

View redacted values explicitly:

```sh
mise env --redacted
mise env --redacted --values
```

## Merge Behavior

Across multiple config files (closer directory wins):
- `[tools]` — additive, closer overrides
- `[env]` — additive, closer overrides
- `[settings]` — additive, closer overrides
- `[tasks]` — per-task replacement (no merging)
