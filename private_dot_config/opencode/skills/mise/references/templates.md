# mise Project Templates

Copy-paste starting configurations for common project types.

## Node.js Backend

```toml
[tools]
node = "22"
"npm:typescript" = "latest"
"npm:prettier" = "latest"
"npm:eslint" = "latest"

[env]
NODE_ENV = "development"
_.path = ["./node_modules/.bin"]

[settings]
jobs = 4

[tasks.dev]
description = "Start development server"
run = "node src/server.js"
env = { NODE_ENV = "development" }

[tasks.build]
description = "Build project"
sources = ["src/**/*.ts", "tsconfig.json"]
outputs = ["dist/"]
run = "tsc"

[tasks.test]
description = "Run tests"
depends = ["build"]
run = "npm test"

[tasks.lint]
description = "Lint code"
run = "eslint src/ && prettier --check src/"

[tasks.format]
description = "Format code"
run = "prettier --write src/"
```

---

## Python Project

```toml
[tools]
python = "3.12"
"pipx:poetry" = "latest"
"pipx:black" = "latest"
"pipx:ruff" = "latest"

[env]
PYTHONUNBUFFERED = "1"
_.path = ["./venv/bin"]

[settings.python]
uv_venv_auto = true    # Auto-create venvs

[tasks.dev]
description = "Start development server"
run = "python -m app.main"

[tasks.test]
description = "Run tests"
run = "pytest tests/"

[tasks.lint]
description = "Lint code"
run = "ruff check ."

[tasks.format]
description = "Format code"
run = "black ."

[tasks.build]
description = "Build distribution"
depends = ["test"]
run = "poetry build"
```

---

## Node.js + Python (Full-Stack)

```toml
[tools]
node = "22"
python = "3.12"
"npm:typescript" = "latest"
"npm:prettier" = "latest"
"pipx:poetry" = "latest"
"pipx:black" = "latest"

[env]
NODE_ENV = "development"
DATABASE_URL = { required = true }
_.file = ".env.local"
_.path = ["./backend/venv/bin", "./frontend/node_modules/.bin"]

[settings]
jobs = 4

[settings.python]
uv_venv_auto = true

[tasks.dev]
description = "Start dev servers (frontend + backend)"
run = """
  npm run dev --prefix frontend &
  python backend/manage.py runserver
"""

[tasks.test]
description = "Run all tests"
run = ["npm test --prefix frontend", "pytest backend/tests/"]

[tasks.build]
description = "Build frontend and backend"
run = ["npm run build --prefix frontend", "poetry build"]
depends = ["test"]

[tasks.lint]
description = "Lint frontend and backend"
run = ["npm run lint --prefix frontend", "ruff check backend/"]

[tasks.format]
description = "Format code"
run = ["prettier --write frontend/", "black backend/"]
```

---

## Monorepo Setup

```toml
# Root mise.toml — shared across all packages
[tools]
node = "22"
python = "3.12"
"npm:typescript" = "latest"
"npm:turbo" = "latest"    # or pnpm workspaces

[env]
# Extend PATH with each package's bin
_.path = [
  "./node_modules/.bin",
  "./packages/*/node_modules/.bin"
]

[settings]
experimental_monorepo_root = true    # Enable monorepo features

[tasks.build]
description = "Build all packages"
run = "turbo run build"

[tasks.test]
description = "Test all packages"
run = "turbo run test"

[tasks.dev]
description = "Dev mode for all packages"
run = "turbo run dev --parallel"

[tasks.lint]
description = "Lint all packages"
run = "turbo run lint"
```

**Each subdirectory (e.g., `packages/api/mise.toml`):**

```toml
[tools]
node = "22"
"npm:prettier" = "latest"

[tasks.dev]
description = "Start API dev server"
run = "node src/server.js"
```

---

## CI/CD Pipeline (GitHub Actions)

```toml
[tools]
node = "22"
python = "3.12"
"github:cli/cli" = "latest"

[env]
CI = "true"
NODE_ENV = "production"

[settings]
# Shims work better in CI environments
# (no dynamic switching needed)

[tasks.ci]
description = "Run full CI pipeline"
run = ["npm ci", "npm run build", "npm test"]

[tasks.deploy]
confirm = "Deploy to production?"
depends = ["ci"]
run = """
  npm run build
  gh deployment create --auto-merge
"""

[tasks.check]
description = "Pre-commit checks"
run = ["npm run lint", "npm test", "npm run type-check"]
```

**GitHub Actions workflow:**

```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: curl https://mise.jdx.dev/install.sh | sh
      - run: eval "$(mise activate bash --shims)" && mise install
      - run: eval "$(mise activate bash --shims)" && mise run ci
```

---

## Rust Project

```toml
[tools]
rust = "1.78"
"cargo:just" = "latest"
"cargo:cargo-edit" = "latest"

[env]
RUST_BACKTRACE = "1"
CARGO_TERM_COLOR = "always"

[tasks.dev]
description = "Run in development"
run = "cargo run"

[tasks.build]
description = "Build release"
sources = ["src/**/*.rs", "Cargo.toml"]
outputs = ["target/release/"]
run = "cargo build --release"

[tasks.test]
description = "Test suite"
run = "cargo test"

[tasks.bench]
description = "Run benchmarks"
run = "cargo bench"

[tasks.fmt]
description = "Format code"
run = "cargo fmt"

[tasks.lint]
description = "Lint with clippy"
run = "cargo clippy -- -D warnings"
```

---

## Go Project

```toml
[tools]
go = "1.22"
"github:golangci/golangci-lint" = "latest"

[env]
GO111MODULE = "on"
GOFLAGS = "-v"

[tasks.dev]
description = "Run server in dev mode"
run = "go run ./cmd/server"

[tasks.build]
description = "Build binary"
sources = ["*.go", "cmd/**/*.go"]
outputs = ["bin/app"]
run = "go build -o bin/app ./cmd/server"

[tasks.test]
description = "Run tests"
run = "go test ./..."

[tasks.test:unit]
description = "Unit tests only"
run = "go test -short ./..."

[tasks.test:integration]
description = "Integration tests"
run = "go test -run Integration ./..."

[tasks.lint]
description = "Lint code"
run = "golangci-lint run"

[tasks.coverage]
description = "Test coverage"
run = "go test -cover ./..."
```

---

## Multi-Language Library

```toml
# Publish to npm, PyPI, and GitHub simultaneously
[tools]
node = "22"
python = "3.12"
ruby = "3.2"
go = "1.22"
"npm:typescript" = "latest"
"pipx:twine" = "latest"
"github:cli/cli" = "latest"

[env]
PROJECT_VERSION = "0.1.0"

[tasks.build]
description = "Build all language bindings"
run = [
  "npm run build",
  "python setup.py build",
  "go build -o ./build/app"
]

[tasks.test]
description = "Test all implementations"
run = [
  "npm test",
  "pytest tests/",
  "go test ./..."
]

[tasks.publish]
confirm = "Publish v{{ env.PROJECT_VERSION }}?"
depends = ["test"]
run = [
  "npm publish",
  "twine upload dist/*",
  "gh release create v{{ env.PROJECT_VERSION }}"
]
```

---

## Minimal Setup

```toml
# Bare minimum for a simple project
[tools]
node = "22"

[tasks.dev]
run = "npm run dev"

[tasks.test]
run = "npm test"
```

---

## Using These Templates

1. **Copy the template** matching your project type
2. **Paste into `mise.toml`** in your project root
3. **Run `mise install`** to install tools
4. **Add to git:** `git add mise.toml`
5. **Test:** `mise run dev` or specific task

**Customize:**

- Change tool versions to match your needs
- Add/remove tasks as needed
- Extend `[env]` section for your variables
- Add `depends` to link tasks
- Use `sources`/`outputs` for caching

---

## Tips

- Keep templates simple; add complexity as needed
- Use `depends` to chain related tasks
- Set `sources` and `outputs` for caching
- Use `[env]` for shared constants
- Leverage `_.path`, `_.file`, `_.source` for environment setup
- See `references/tasks.md` for advanced task options
