# Project Structure Reference

## Package Naming

Follow Go conventions:

- **Short, lowercase, single-word** names: `domain`, `service`, `config`
- **No stuttering**: `tool.Client` not `tool.ToolClient`
- **Organize by dependency**, not by pattern
- **`internal/`** for all non-cmd packages at Stage 2+

## The `internal/` Boundary

Always use `internal/` at Stage 2+. It signals architectural intent, prevents
accidental exposure during library extraction, and helps AI coding agents
understand boundaries. The cost is zero — one directory level, no runtime or
build impact.

- **Stage 1**: not used. A flat CLI with `domain.go` at the root doesn't need it.
- **Stage 2-4**: always. All packages under `internal/`.

## When to Extract a Package

Extract when you have:

- **5+ types** that share a clear concern
- **An interface boundary** you want to enforce
- **A distinct external dependency** (e.g., a specific library or tool)
- **Test isolation needs** (heavy I/O tests separate from pure logic tests)

Do NOT extract for:

- Fewer than 3 related types
- "It might grow later"
- Matching a layer diagram before you have the code

## Standard Directory Layout (Stage 3-4)

```text
myapp/
  main.go                    # Composition root (ONLY wiring, no logic)
  go.mod
  go.sum

  cmd/                       # CLI layer — Cobra command definitions
    root.go                  # NewRootCommand(), global flags, subcommand registration
    container.go             # ServiceContainer struct
    command_config.go        # CommandConfig passed to all commands
    completion.go            # Shell completion generation command
    version.go               # Version command
    <command>.go             # One file per command or command group
    <command>_test.go        # Command-level tests

  internal/
    application/             # Port interfaces (consumed by service/)
      interfaces.go          # All service + infrastructure interfaces

    domain/                  # Pure business logic — curated deps only
      types.go               # Entities, value objects, aggregates
      errors.go              # Standardized error types + DomainError interface
      validation.go          # ValidationPipeline, validators
      config.go              # Configuration model (strongly typed, no tags at Stage 4)
      rules.go               # Domain services (pure business rule functions)
      specs.go               # Specification predicates for filtering
      doc.go                 # Package doc explaining dependency policy

    presenter/               # All terminal output concerns
      formatter.go           # Multi-format output (table, JSON, plain)
      error_formatter.go     # Error presentation with suggestions
      verbose.go             # Verbosity-controlled progress output
      styles.go              # Centralized lipgloss style definitions
      interactive.go         # Confirmations, selections (huh/bubbletea)

    service/                 # Application services — orchestrate domain + infra
      <service>.go           # One file per service
      <service>_test.go      # Tests with mock infrastructure

    infrastructure/          # Concrete implementations of application interfaces
      tool/                  # External tool operations
        client.go            # Implements application interfaces
        reader.go            # Read-path implementation
        writer.go            # Write-path implementation
        composite.go         # Routes reads/writes to different backends
        classify.go          # classifyError helper
      config/                # Configuration loading
        manager.go           # Implements application.ConfigManager
        raw_types.go         # Stage 4: serialization tags, maps to domain.Config
      shell/                 # External command execution
        executor.go          # CommandExecutor implementation
      hooks/                 # Hook/plugin execution
        runner.go            # HookRunner implementation

    version/                 # Build version info (cross-cutting utility)
      version.go

  tests/                      # E2E, integration, concurrent tests (unit tests in *_test.go files)
    e2e/                     # End-to-end tests (build tag: e2e)
      fixtures/
      *_test.go
    integration/             # Component integration tests (real I/O, no binary)
      *_test.go
    concurrent/              # Race detector validation
      *_test.go
    fixtures/                # Shared test fixtures
    golden/                  # Golden file outputs, organized by concern
      errors/
      list/
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

```text
cmd/ ──────────► internal/presenter/ ──────► internal/domain/
  │                                            ▲
  │                                            │
  ▼                                            │
internal/service/ ──► internal/application/ ──► internal/domain/
   │                         ▲
   │                         │ implements
   ▼                         │
internal/infrastructure/ ─────────────────► internal/domain/
```

**Key rules:**

- `cmd/` depends on `internal/presenter/`, `internal/service/` (via `internal/application/`), and `internal/domain/`
- `internal/presenter/` depends on `internal/domain/` (for type-specific formatting)
- `internal/service/` depends on `internal/application/` (interfaces) and `internal/domain/`
- `internal/infrastructure/` depends on `internal/domain/` and implements `internal/application/` interfaces
- `internal/domain/` depends on nothing (stdlib + curated allowlist only)
- `version/` is cross-cutting — any layer may import it

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
        allow:
          - $gostd
          - github.com/samber/lo
          - github.com/samber/mo
          # depguard v2: allow takes precedence over deny, so lo/mo are
          # permitted despite the broad github.com/* deny below.
        deny:
          - pkg: "github.com/*"
            desc: "domain allows only stdlib and curated libs (lo, mo)"
          - pkg: "myapp/internal/infrastructure/*"
            desc: "domain must not import infrastructure"
          - pkg: "myapp/internal/service/*"
            desc: "domain must not import service"
          - pkg: "myapp/internal/presenter/*"
            desc: "domain must not import presenter"
```

## cmd/ Organization Patterns

### One File Per Command

```text
cmd/
  root.go          # Root command + global flags
  create.go
  delete.go
  list.go
```

### Grouped Subcommands

```text
cmd/
  root.go
  item.go              # item command group
  item_create.go
  item_delete.go
  item_list.go
  config.go            # config command group
  config_init.go
  config_validate.go
```

### Command Constructor Pattern

Every command file exports a constructor, never a global:

```go
func NewCreateCommand(cfg *CommandConfig) *cobra.Command {
    cmd := &cobra.Command{
        Use:   "create <n>",
        Short: "Create a new resource",
        RunE: func(cmd *cobra.Command, args []string) error {
            return executeCreate(cmd, args, cfg)
        },
    }
    cmd.Flags().StringP("source", "s", "main", "Source branch")
    return cmd
}

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

```text
$XDG_CONFIG_HOME/myapp/config.toml    # Primary
~/.config/myapp/config.toml           # Fallback
```

See `references/configuration.md` for the full loading pipeline.

## Build & Version

```go
// internal/version/version.go
var (
    Version   = "dev"
    Commit    = "unknown"
    BuildDate = "unknown"
)

// Set via ldflags:
// go build -ldflags "-X myapp/internal/version.Version=1.0.0 ..."
```

`version/` sits outside the four-layer model as cross-cutting build metadata.

## Release & Distribution

Use `goreleaser` for cross-compilation, checksums, packaging (homebrew, deb,
rpm, Docker), and changelog generation. This is a Stage 2+ concern.

## Task Runner

Prefer `mise` tasks or a `Makefile` with standard targets:

```makefile
.PHONY: build test lint e2e

build:
 go build -o bin/myapp .

test:
 go test -race ./...

lint:
 golangci-lint run

integration:
 go test -tags integration ./test/integration/...

e2e:
 go test -tags e2e ./test/e2e/...
```
