---
name: go-ddd-cli
description: >
  Architecture reference for building Go CLI applications with DDD-lite patterns.
  Trigger for: scaffolding new Go CLIs, adding commands/features to existing ones,
  structuring Go CLI code, choosing where to put logic, designing domain types,
  wiring dependencies, or any question about Go CLI architecture.
  Also trigger when user says "new Go CLI", "add a command", "where should this go",
  "structure this project", "scaffold", or references DDD/clean/hexagonal architecture
  in the context of a Go CLI.
---

# DDD-Lite Architecture for Go CLIs

A pragmatic subset of Domain-Driven Design adapted for command-line tools. Uses
tactical DDD patterns (domain types with behavior, repository interfaces, layered
architecture) without strategic overhead (bounded contexts, event storming).

## The Four Layers

```
┌─────────────────────────────────────────────────┐
│  CLI Layer (cmd/)                                │
│  Cobra commands, flag parsing, output formatting │
│  THIN: parse input → call service → format output│
└──────────────────────┬──────────────────────────┘
                       │ depends on
┌──────────────────────▼──────────────────────────┐
│  Application Layer (application/ or service/)    │
│  Use cases, orchestration, service interfaces    │
│  One service per logical concern                 │
└──────────────────────┬──────────────────────────┘
                       │ depends on
┌──────────────────────▼──────────────────────────┐
│  Domain Layer (domain/)                          │
│  Pure business types, validation, errors         │
│  ZERO external dependencies (stdlib only)        │
└──────────────────────┬──────────────────────────┘
                       │ implemented by
┌──────────────────────▼──────────────────────────┐
│  Infrastructure Layer (infrastructure/)           │
│  Git clients, filesystem, config, APIs, shell    │
│  Implements interfaces defined in application/   │
└─────────────────────────────────────────────────┘
```

**The dependency rule**: each layer depends only on the layers below it. Domain
depends on nothing. Infrastructure implements interfaces from application.

## CLI-Specific Adaptations

| Web Service Concept | CLI Equivalent                            |
| ------------------- | ----------------------------------------- |
| HTTP/gRPC handler   | Cobra command (`RunE` function)           |
| Request DTO         | Flags + args → domain request struct      |
| Response DTO        | Domain result → formatted terminal output |
| Middleware          | Cobra `PersistentPreRunE` / hooks         |
| HTTP status codes   | Exit codes (0-6+)                         |
| Logger              | Verbosity-controlled stderr output        |

## Layer Responsibilities

### CLI Layer (`cmd/`)

- Parse flags and arguments into domain request types
- Call application services
- Format results for terminal output (tables, JSON, plain)
- Map errors to exit codes and user-facing messages
- Handle verbosity/quiet mode

**Must NOT contain**: business logic, direct infrastructure calls, validation beyond
flag parsing.

```go
func executeCreate(cmd *cobra.Command, args []string, cfg *CommandConfig) error {
    req := &domain.CreateRequest{Name: args[0], Source: flagSource}
    result, err := cfg.Services.Creator.Create(cmd.Context(), req)
    if err != nil {
        return err // error handler maps to exit code
    }
    formatResult(cmd.OutOrStdout(), result)
    return nil
}
```

### Application Layer (`application/` + `service/`)

Two sub-packages with distinct roles:

**`application/`** — Interface contracts only (ports):

```go
type Creator interface {
    Create(ctx context.Context, req *domain.CreateRequest) (*domain.CreateResult, error)
}
type GitClient interface {
    CloneRepo(ctx context.Context, url string, path string) error
    ListBranches(ctx context.Context, repo string) ([]string, error)
}
```

**`service/`** — Implementations that orchestrate domain + infrastructure:

```go
type creatorService struct {
    git    application.GitClient
    config *domain.Config
}
func (s *creatorService) Create(ctx context.Context, req *domain.CreateRequest) (*domain.CreateResult, error) {
    if err := req.Validate(); err != nil { return nil, err }
    // orchestrate infrastructure calls using domain rules
}
```

**When to split**: if you have <3 services, a single `service/` package with
interfaces at the top is fine. Split `application/` out when interfaces are shared
across packages or you want to enforce the boundary via linting.

### Domain Layer (`domain/`)

**The most important layer.** Contains:

- **Types with behavior** (not just data structs)
- **Validation** (always-valid construction)
- **Error types** (typed, with context and suggestions)
- **Value objects** (immutable, equality by value)
- **Request/Result DTOs** for service boundaries
- **Configuration models** (strongly typed)

**Must have ZERO external dependencies** (enforce via `depguard` or code review).

See: `references/domain-modeling.md` for patterns.

### Infrastructure Layer (`infrastructure/`)

Concrete implementations of application interfaces. Organized by external dependency:

```
infrastructure/
  git/           # Git operations (go-git, CLI fallback)
  config/        # Config file loading (koanf, viper)
  filesystem/    # File operations
  shell/         # External command execution
  api/           # HTTP API clients
```

Each sub-package implements one or more application interfaces.

## Project Structure Progression

**Start flat, extract when painful.** Don't pre-create packages for 2 types.

### Stage 1: Simple CLI (<5 commands, single concern)

```
myapp/
  main.go           # Composition root + Run()
  cmd/
    root.go          # Command tree
    create.go        # Commands (thin)
  domain.go          # Types, errors, validation (single file)
  service.go         # Business logic
  git.go             # Infrastructure adapter
```

### Stage 2: Growing CLI (5-15 commands, multiple concerns)

```
myapp/
  main.go
  cmd/
    root.go
    container.go       # DI container
    error_handler.go   # Error → exit code mapping
    create.go
    delete.go
    list.go
  internal/
    domain/
      types.go
      errors.go
      validation.go
    service/
      creator.go       # Interfaces + implementation together
      lister.go
    infrastructure/
      git/
      config/
```

### Stage 3: Mature CLI (15+ commands, complex domain)

```
myapp/
  main.go
  cmd/
    root.go
    container.go
    command_config.go
    error_handler.go
    error_formatter.go
    suggestions.go       # Shell completion
    create.go
    delete.go
    list.go
    ...
  internal/
    application/         # Interfaces only (ports)
      interfaces.go
    domain/              # Pure business logic
      types.go
      errors.go
      validation.go
      config.go
      result.go          # Result[T] type
    service/             # Use case implementations
      creator.go
      lister.go
      pruner.go
    infrastructure/
      git/
      config/
      shell/
      hooks/
  test/
    e2e/
    fixtures/
    golden/
    mocks/
```

See: `references/project-structure.md` for detailed guidance.

## Composition Root (main.go)

All dependency wiring happens in `main.go`. Manual constructor injection — no
DI frameworks.

```go
func main() {
    defer recoverPanic()

    // Infrastructure (bottom-up)
    configManager := config.NewManager()
    cfg, err := configManager.Load()
    handleFatal(err)

    executor := shell.NewCommandExecutor(cfg.Timeout)
    gitClient := git.NewClient(executor)

    // Services (depend on infrastructure)
    creator := service.NewCreator(gitClient, cfg)
    lister := service.NewLister(gitClient, cfg)

    // CLI (depends on services)
    container := &cmd.ServiceContainer{
        Creator: creator,
        Lister:  lister,
    }
    rootCmd := cmd.NewRootCommand(&cmd.CommandConfig{
        Config:   cfg,
        Services: container,
    })

    if err := rootCmd.Execute(); err != nil {
        os.Exit(int(cmd.GetExitCodeForError(err)))
    }
}
```

See: `references/dependency-injection.md` for patterns.

## Error Handling Strategy

Three-tier approach:

1. **Domain errors** — typed, carry context and suggestions, no exit codes
2. **Error categorization** — `cmd/error_handler.go` maps error types to exit codes
3. **Error formatting** — `cmd/error_formatter.go` renders user-friendly messages

```go
// Domain: define the error
type ValidationError struct {
    Field, Value, Message string
    Suggestions           []string
}

// CLI: map to exit code
func GetExitCodeForError(err error) ExitCode {
    var valErr *domain.ValidationError
    if errors.As(err, &valErr) { return ExitCodeValidation }
    return ExitCodeError
}
```

See: `references/error-handling.md` for full patterns.

## Testing Strategy

| Layer   | Strategy                               | Tools                                |
| ------- | -------------------------------------- | ------------------------------------ |
| Domain  | Table-driven unit tests, no mocks      | `testing`, `testify`                 |
| Service | Interface mocks for infrastructure     | Hand-written mocks or `testify/mock` |
| CLI     | Command execution with captured output | `cobra` test helpers                 |
| E2E     | Full binary execution                  | `testscript`, Ginkgo + `gexec`       |

See: `references/testing.md` for patterns.

## Key Principles

1. **Domain types have behavior, not just data.** `order.Cancel()` not `order.Status = "cancelled"`.
2. **Always-valid construction.** Validate in constructors/factories. If it exists, it's valid.
3. **Define interfaces where consumed, not where implemented.** The `application/` package owns the interfaces; `infrastructure/` implements them.
4. **Start flat, extract when painful.** Don't create 10 packages for 5 types.
5. **Manual DI in main.go.** No Wire, no Fx. Explicit is better than magic.
6. **Domain has zero external deps.** Enforce this. It's the most valuable constraint.
7. **Cobra commands are thin.** Parse → call service → format. That's it.
8. **Errors are a first-class domain concept.** Type them, give them context, make them actionable.

## Common Libraries

| Concern          | Recommended         | Alternative    |
| ---------------- | ------------------- | -------------- |
| CLI framework    | `cobra`             | `urfave/cli`   |
| Shell completion | `carapace`          | Cobra built-in |
| Config           | `koanf`             | `viper`        |
| Config format    | TOML                | YAML           |
| YAML             | `gopkg.in/yaml.v3`  | —              |
| Template funcs   | `sprig`             | —              |
| Testing          | `testify`           | `gotest.tools` |
| BDD testing      | `ginkgo` + `gomega` | —              |
| CLI E2E          | `testscript`        | Ginkgo `gexec` |
| Linting          | `golangci-lint`     | —              |
| Arch linting     | `depguard`          | `go-cleanarch` |
