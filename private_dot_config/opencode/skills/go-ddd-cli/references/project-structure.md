# Project Structure Reference

## Package Naming

Follow Go conventions, not Java/C# conventions:

- **Short, lowercase, single-word** names: `domain`, `service`, `config`, `git`
- **No stuttering**: `git.Client` not `git.GitClient`
- **Organize by dependency**, not by pattern: `postgres.UserRepo` not `repository.UserRepo`
- **`internal/`** for packages that must not be imported by other modules

## When to Extract a Package

Extract when you have:

- **5+ types** that share a clear concern
- **An interface boundary** you want to enforce (e.g., domain isolation)
- **A distinct external dependency** (e.g., go-git, koanf)
- **Test isolation needs** (heavy infra tests separate from pure logic tests)

Do NOT extract for:

- Fewer than 3 related types
- "It might grow later"
- Matching a layer diagram before you have the code

## Standard Directory Layout

```
myapp/
  main.go                    # Composition root (ONLY wiring, no logic)
  go.mod
  go.sum

  cmd/                       # CLI layer — Cobra command definitions
    root.go                  # NewRootCommand(), global flags, subcommand registration
    container.go             # ServiceContainer struct + NewServiceContainer()
    command_config.go        # CommandConfig passed to all commands
    error_handler.go         # CategorizeError(), GetExitCodeForError()
    error_formatter.go       # ErrorFormatter with strategy pattern
    verbose.go               # Verbosity management
    suggestions.go           # Carapace shell completion actions
    completion.go            # Shell completion generation command
    version.go               # Version command
    <command>.go             # One file per command or command group
    <command>_test.go        # Command-level tests
    contract_test.go         # Interface contract validation tests

  internal/
    application/             # Port interfaces (consumed by service/, implemented by infrastructure/)
      interfaces.go          # All service + infrastructure interfaces
      requests.go            # Request DTOs (optional, can live in domain/)
      results.go             # Result DTOs (optional, can live in domain/)

    domain/                  # Pure business logic — ZERO external deps
      types.go               # Entities, value objects
      errors.go              # Typed error hierarchy
      validation.go          # Validation pipeline, validators
      result.go              # Result[T] functional error type
      config.go              # Configuration model (strongly typed)
      doc.go                 # Package doc explaining zero-dep constraint
      *_test.go              # Table-driven unit tests

    service/                 # Application services — orchestrate domain + infra
      <service>.go           # One file per service
      <service>_test.go      # Tests with mock infrastructure

    infrastructure/          # Concrete implementations of application interfaces
      git/                   # Git operations
        client.go            # Implements application.GitClient
        go_git.go            # go-git specific implementation
        cli.go               # CLI fallback implementation
        composite.go         # Composite routing (read → go-git, write → CLI)
      config/                # Configuration loading
        manager.go           # Implements application.ConfigManager
      shell/                 # External command execution
        executor.go          # CommandExecutor implementation
      hooks/                 # Hook/plugin execution
        runner.go            # HookRunner implementation

    version/                 # Build version info
      version.go

  test/                      # Test support
    e2e/                     # End-to-end tests (build tag: e2e)
      helpers/               # CLI execution helpers
      fixtures/              # Test data files
      *_test.go
    fixtures/                # Shared test fixtures
    golden/                  # Golden file outputs
    mocks/                   # Shared mock implementations (if needed)

  contrib/                   # Optional: shell plugins, completion scripts
```

## File Sizing Guidelines

| Symptom                       | Action                                              |
| ----------------------------- | --------------------------------------------------- |
| File >500 lines               | Consider splitting by sub-concern                   |
| Package >10 files             | Consider extracting a sub-package                   |
| `cmd/root.go` >200 lines      | Extract command registration to per-command files   |
| Single `domain.go` >300 lines | Split into `types.go`, `errors.go`, `validation.go` |
| Test file >500 lines          | Split by test concern or use subtests               |

## Package Dependency Rules

```
cmd/ ──────────► application/ (interfaces)
  │                  ▲
  │                  │ implements
  ▼                  │
service/ ────► infrastructure/
  │
  ▼
domain/ ◄────── (everyone reads domain, domain reads nothing)
```

**Enforcing the rules:**

```yaml
# .golangci.yml
linters:
  enable:
    - depguard

linters-settings:
  depguard:
    rules:
      domain-isolation:
        files:
          - "**/domain/**"
        deny:
          - pkg: "github.com/*"
            desc: "domain must not import external packages"
          - pkg: "myapp/internal/infrastructure/*"
            desc: "domain must not import infrastructure"
          - pkg: "myapp/internal/service/*"
            desc: "domain must not import service"
```

## cmd/ Organization Patterns

### One File Per Command

```
cmd/
  root.go          # Root command + global flags
  create.go        # create command
  delete.go        # delete command
  list.go          # list command
```

### Grouped Subcommands

```
cmd/
  root.go
  worktree.go          # worktree command group (create, delete, list)
  worktree_create.go   # worktree create
  worktree_delete.go   # worktree delete
  worktree_list.go     # worktree list
  config.go            # config command group
  config_init.go
  config_validate.go
```

### Command Constructor Pattern

Every command file exports a constructor, never a global:

```go
// cmd/create.go
func NewCreateCommand(cfg *CommandConfig) *cobra.Command {
    cmd := &cobra.Command{
        Use:   "create <name>",
        Short: "Create a new resource",
        RunE: func(cmd *cobra.Command, args []string) error {
            return executeCreate(cmd, args, cfg)
        },
    }
    cmd.Flags().StringP("source", "s", "main", "Source branch")
    return cmd
}

// cmd/root.go
func NewRootCommand(cfg *CommandConfig) *cobra.Command {
    root := &cobra.Command{Use: "myapp"}
    root.AddCommand(
        NewCreateCommand(cfg),
        NewDeleteCommand(cfg),
        NewListCommand(cfg),
    )
    return root
}
```

## Configuration File Convention

```
$XDG_CONFIG_HOME/myapp/config.toml    # Primary
~/.config/myapp/config.toml           # Fallback
```

Use koanf or viper for multi-source config (file → env → flags).

## Build & Version

```go
// internal/version/version.go
var (
    Version   = "dev"
    Commit    = "unknown"
    BuildDate = "unknown"
)

// Set via ldflags:
// go build -ldflags "-X myapp/internal/version.Version=1.0.0 -X ..."
```

## Makefile / Task Runner

Prefer `mise` tasks or a `Makefile` with standard targets:

```makefile
.PHONY: build test lint e2e

build:
	go build -o bin/myapp .

test:
	go test ./...

lint:
	golangci-lint run

e2e:
	go test -tags e2e ./test/e2e/...
```
