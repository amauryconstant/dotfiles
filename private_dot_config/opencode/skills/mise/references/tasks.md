# mise Tasks Reference

## Task Discovery

mise finds and runs tasks from two sources: TOML configuration and file-based scripts. Both can coexist.

### TOML Tasks

Defined in `mise.toml` under `[tasks]`:

```toml
[tasks.build]
run = "cargo build"
```

Invoke: `mise run build`

### File-Based Tasks

Place executable scripts in these directories (mise auto-discovers them):

```text
mise-tasks/          ← Primary location
.mise-tasks/
mise/tasks/
.mise/tasks/
.config/mise/tasks/
```

Examples:

- `mise-tasks/build` → `mise run build`
- `mise-tasks/test/unit` → `mise run test:unit`
- `mise-tasks/deploy/prod` → `mise run deploy:prod`

Script must be executable:

```sh
chmod +x mise-tasks/build
```

### Task Precedence

TOML tasks take precedence over file-based tasks with the same name.

```text
mise-tasks/build           ← File-based
[tasks.build]              ← TOML (wins if both exist)
```

### When to Use Each

| Type       | When to Use                          | Example                                         |
| ---------- | ------------------------------------ | ----------------------------------------------- |
| TOML       | Simple tasks, settings, dependencies | `run = "npm test"`                              |
| File-based | Complex logic, cross-language        | Shell script with Python subprocess             |
| Both       | Organize tasks by domain             | TOML for core, file-based for complex subdomain |

---

## Domain Separation (Namespacing)

Organize related tasks by domain using directories.

### Directory Structure

```text
mise-tasks/
├── build               ← Task: mise run build
├── test/
│   ├── unit            ← Task: mise run test:unit
│   └── integration     ← Task: mise run test:integration
└── deploy/
    ├── staging         ← Task: mise run deploy:staging
    └── prod            ← Task: mise run deploy:prod
```

Colon (`:`) separates namespace from task name:

- `mise run test:unit` — run `mise-tasks/test/unit`
- `mise run deploy:prod` — run `mise-tasks/deploy/prod`

### TOML Domain Syntax

In `mise.toml`, use dots or nested tables for domains:

```toml
# Flat syntax (preferred for simple cases)
[tasks.test:unit]
run = "pytest tests/unit/"

[tasks.test:integration]
run = "pytest tests/integration/"

# Or nested syntax
[tasks.test]
# Not a real task; just for organization

[tasks."test:unit"]
run = "pytest tests/unit/"
```

### When to Use Domains

**Use domains when:**

- Tasks are related (e.g., multiple test types)
- Project has multiple concerns (frontend:build, backend:build)
- Large number of tasks

**Flat (no domains) when:**

- Simple projects with few tasks
- Each task is independent

### Listing Namespaced Tasks

```sh
mise tasks                  # All tasks
mise tasks test             # Only test:* tasks
mise tasks test:unit        # Just test:unit (if multiple levels)
```

---

## TOML Task Options

```toml
[tasks.mytask]
description = "Human-readable description"
alias = "mt"              # Short alias: `mise run mt`
run = "cargo build"       # Command string or array (sequential, stops on failure)
run = ["npm test", "pytest"]

# Platform-specific override
run_windows = "cargo test --features windows"

dir = "{{config_root}}/subdir"  # Working dir; "{{cwd}}" = user's cwd
shell = "bash -c"               # Override shell (default: sh)
env = { PORT = "3000", DEBUG = "1" }  # Task-specific env vars

# Dependencies
depends = ["lint", "test"]      # Run before; run in parallel if possible
depends_post = ["cleanup"]      # Run after (even on failure)
wait_for = ["lint"]             # Parallel dependencies to wait on

# Caching (skip if inputs unchanged and outputs exist)
sources = ["src/**/*.rs", "Cargo.toml"]
outputs = ["target/debug/mycli"]

# Safety
confirm = "Deploy to production?"  # Prompt before running

# External script (local or remote)
file = "scripts/build.sh"
file = "https://example.com/build.sh"
file = "git::https://github.com/org/repo.git//script?ref=v1.0.0"
```

## Shebang / Non-shell Interpreters

```toml
[tasks.mypytask]
run = '''
#!/usr/bin/env python3
for i in range(10):
    print(i)
'''
```

## Argument Parsing (usage spec)

```toml
[tasks.test]
usage = '''
arg "<file>" help="Test file" default="all"
flag "--format <fmt>" help="Output format" default="text"
flag "-v --verbose" help="Verbose output"
'''
run = "pytest ${usage_file?} --format ${usage_fmt?}"
```

Arguments injected as `usage_<name>` env vars.

## File-Based Tasks

Place executable scripts in any of:

- `mise-tasks/`
- `.mise-tasks/`
- `mise/tasks/`
- `.mise/tasks/`
- `.config/mise/tasks/`

Subdirectory → namespaced task: `mise-tasks/test/integration` → `mise run test:integration`

Script must be executable (`chmod +x`):

```bash
#!/usr/bin/env bash
#MISE description="Build the CLI"
#MISE alias="b"
#MISE sources=["src/**/*.rs"]
#MISE outputs=["target/debug/mycli"]
#MISE env={RUST_BACKTRACE = "1"}
#MISE depends=["lint"]
#MISE tools={rust = "1.78"}

cargo build
```

If a formatter breaks `#MISE`, use `# [MISE]` form instead.

## Automatic Task Env Vars

| Variable            | Value                            |
| ------------------- | -------------------------------- |
| `MISE_ORIGINAL_CWD` | Where the task was invoked       |
| `MISE_CONFIG_ROOT`  | Directory containing `mise.toml` |
| `MISE_PROJECT_ROOT` | Project root                     |
| `MISE_TASK_NAME`    | Current task name                |
| `MISE_TASK_DIR`     | Directory of the task script     |
| `MISE_TASK_FILE`    | Full path to the task script     |

## Task Environment

### Full mise Environment Available

Tasks run with the complete mise environment:

- All configured tools (`[tools]`) installed and on PATH
- All environment variables (`[env]`) set
- Both TOML and file-based env vars merged
- Task-specific env vars override global ones

### Environment Variable Resolution

```toml
[env]
DATABASE_URL = "postgres://localhost/mydb"
DEBUG = "false"

[tasks.dev]
env = { DEBUG = "true" }    # Task-specific override
run = "node server.js"      # DEBUG=true for this task only
```

When task runs:

- Global `[env]` variables available
- Task `env = {}` overrides global values
- Auto-variables (`MISE_*`) always available

### Task-Only Variables

Variables from `[env]` that include `tools = true` are only available in tasks:

```toml
[env]
NODE_VERSION = { value = "{{ tools.node.version }}", tools = true }

[tasks.check]
run = "echo Node version: $NODE_VERSION"  # Only in tasks
```

---

## Running Tasks

```sh
mise run build                 # Run task
mise run test -- --verbose     # Pass args after --
mise watch build               # Re-run on source file changes
mise run test:unit             # Namespaced task
mise tasks                      # List all available tasks
mise tasks | grep deploy       # Filter by name
```

---

## Advanced Task Examples

### Multi-Step Task (Sequential)

```toml
[tasks.release]
description = "Build and publish"
run = [
  "npm run build",
  "npm test",
  "npm publish"
]
# Stops on first failure
```

### Task with Dependencies

```toml
[tasks.test]
depends = ["build"]            # Run build first
run = "npm test"

[tasks.ci]
depends = ["test", "lint"]     # Run both, potentially parallel
run = "echo CI passed"
```

### Parallel Tasks with Wait

```toml
[tasks.dev]
run = """
npm run dev &
python manage.py runserver &
wait
"""
# Or with depends:

[tasks.start:frontend]
run = "npm run dev"

[tasks.start:backend]
run = "python manage.py runserver"

[tasks.dev]
depends = ["start:frontend", "start:backend"]
run = "echo Servers started"
```

### Platform-Specific Task

```toml
[tasks.build]
description = "Build for current platform"
run = "npm run build"
run_windows = "npm run build:windows"
run_macos = "npm run build:macos"
```

### Task with Confirmation Prompt

```toml
[tasks.deploy]
description = "Deploy to production"
confirm = "Are you sure you want to deploy? This cannot be undone."
depends = ["test"]
run = "./scripts/deploy.sh"
```

### Task with Cross-Language Steps

```toml
[tasks.full-test]
description = "Test Node and Python"
run = [
  "npm test",
  "pytest tests/"
]

# Or separately:
[tasks.test:js]
run = "npm test"

[tasks.test:py]
run = "pytest tests/"

[tasks.test:all]
depends = ["test:js", "test:py"]
run = "echo All tests passed"
```

### Task Using External Script

```toml
[tasks.build]
description = "Build using external script"
file = "scripts/build.sh"     # Local script

[tasks.deploy]
description = "Deploy from GitHub"
file = "git::https://github.com/org/repo.git//deploy.sh?ref=v1.0.0"

[tasks.setup]
description = "Setup from URL"
file = "https://example.com/setup.sh"
```

**Script with metadata** (scripts/build.sh):

```bash
#!/usr/bin/env bash
#MISE description="Build the project"
#MISE sources=["src/**/*", "Cargo.toml"]
#MISE outputs=["target/release/app"]
#MISE env={RUST_BACKTRACE = "1"}

cargo build --release
```

### Task with Argument Parsing

```toml
[tasks.test]
description = "Run tests"
usage = '''
arg "<file>" help="Test file" default="all"
flag "--watch" help="Watch mode"
flag "--coverage" help="Generate coverage"
'''
run = "pytest ${usage_file} ${usage_watch:+--watch} ${usage_coverage:+--cov}"
```

Invoke:

```sh
mise run test                      # Run all tests
mise run test tests/unit.py        # Specific file
mise run test -- --watch           # Watch mode
mise run test tests/unit.py -- --watch --coverage
```

### Watch Mode Task

```toml
[tasks.dev]
description = "Watch and rebuild"
sources = ["src/**/*.rs"]
run = "cargo watch -x run"

# Or use mise watch:
# mise watch dev
```

### Task with Lazy Environment

```toml
[env]
# Regular var (always expanded)
SIMPLE = "value"

# Lazy (only if used in task)
LAZY = { value = "{{ tools.node.version }}", tools = true }

[tasks.check]
run = "echo $LAZY"  # Only evaluated when task runs
```

---

## Troubleshooting Tasks

**Task not found:**

```sh
# List all available
mise tasks

# Check file location
ls mise-tasks/
ls -la mise-tasks/mytask  # Must be executable
```

**Task fails silently:**

```sh
# Run with debug output
MISE_LOG_LEVEL=debug mise run mytask

# Run underlying command directly
bash scripts/build.sh
```

**Dependencies not running:**

```toml
# Ensure syntax is correct
depends = ["task1", "task2"]  # Array
depends = "task1"             # Single task
```

**Environment vars not set:**

```sh
# Check what's available
mise env
mise run mytask -- env | grep MYVAR
```

**Argument parsing issues:**

```toml
# Verify syntax
usage = '''
arg "<file>"
flag "--verbose"
'''
run = "echo ${usage_file} ${usage_verbose}"
# Must use ${usage_<name>} format
```
