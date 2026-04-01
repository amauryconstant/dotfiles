# Dependency Injection Reference

See also: `configuration.md` for config loading that feeds into DI wiring.

## Principle: Manual Constructor Injection by Default

Go CLIs use **manual DI** at Stage 1-3. Wire everything explicitly in `main.go`.
At Stage 4, consider `samber/do` when the ServiceContainer becomes unwieldy.

## The Composition Root

All wiring happens in `main.go`. This is the **only place** that knows about
concrete implementations.

```go
// main.go — the ONLY file that imports infrastructure packages
package main

import (
    "myapp/cmd"
    "myapp/internal/infrastructure/config"
    "myapp/internal/infrastructure/tool"
    "myapp/internal/infrastructure/shell"
    "myapp/internal/presenter"
    "myapp/internal/service"
)

func main() {
    defer recoverPanic()

    // Two distinct observability channels:
    // - debug: structured logging (slog), controlled by MYAPP_DEBUG env / --debug flag
    // - verbose: user-facing progress output, controlled by -v flag
    debug := os.Getenv("MYAPP_DEBUG") != ""

    // 1. Infrastructure layer (bottom-up, leaves first)
    configManager := config.NewManager()
    cfg, err := configManager.Load()
    if err != nil { handleFatal(err) }

    logLevel := slog.LevelWarn
    if debug {
        logLevel = slog.LevelDebug
    }
    logger := slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: logLevel}))
    executor := shell.NewCommandExecutor(cfg.Timeout)
    toolClient := tool.NewClient(executor)

    // 2. Service layer (depends on infrastructure)
    creator := service.NewCreator(toolClient, cfg, logger)
    lister := service.NewLister(toolClient, cfg, logger)

    // 3. Presenter layer
    styles := presenter.NewStyles()
    formatter := presenter.NewFormatter(cfg.OutputFormat, styles)
    errFormatter := presenter.NewErrorFormatter(styles)

    // 4. CLI layer (depends on services + presenter)
    // VerboseOutput is created per-command from the -v flag
    container := &cmd.ServiceContainer{
        Creator: creator,
        Lister:  lister,
    }
    rootCmd := cmd.NewRootCommand(&cmd.CommandConfig{
        Config:         cfg,
        Services:       container,
        Presenter:      formatter,
        ErrorFormatter: errFormatter,
        Debug:          debug,
    })

    if err := rootCmd.Execute(); err != nil {
        errFormatter.Format(os.Stderr, err)
        os.Exit(int(cmd.GetExitCodeForError(err)))
    }
}
```

**Key properties:**

- Dependency order is explicit and readable (infra → service → presenter → CLI)
- If it compiles, the wiring is correct (no runtime DI failures)
- `main.go` is the documentation of your dependency graph

## The Service Container

A typed struct that holds all services. Passed to every command via
`CommandConfig`.

```go
// cmd/container.go
type ServiceContainer struct {
    Creator application.Creator
    Lister  application.Lister
    Pruner  application.Pruner
}
```

## CommandConfig: Thread Through Commands

```go
// cmd/command_config.go
type CommandConfig struct {
    Config         *domain.Config
    Services       *ServiceContainer
    Presenter      *presenter.Formatter
    ErrorFormatter *presenter.ErrorFormatter
    Verbose        *presenter.VerboseOutput
}

func NewCreateCommand(cfg *CommandConfig) *cobra.Command {
    return &cobra.Command{
        Use: "create <name>",
        RunE: func(cmd *cobra.Command, args []string) error {
            return executeCreate(cmd, args, cfg)
        },
    }
}
```

## Interface Placement

**Define interfaces where they are consumed, not where they are implemented.**

```go
// application/interfaces.go — consumed by service/
type ItemReader interface {
    List(ctx context.Context, path string) ([]domain.ItemInfo, error)
    Exists(ctx context.Context, path, name string) (bool, error)
}

// infrastructure/tool/client.go — implements the interface
type client struct {
    executor shell.CommandExecutor
}
```

The `service/` package imports `application.ItemReader` (the interface).
The `infrastructure/tool/` package imports nothing from `service/`.
`main.go` connects them.

### Interface Segregation at Scale

At Stage 3+, split large interfaces by consumer need — not by implementation
strategy.

```go
// Instead of one 14-method ToolClient:
type ItemReader interface {
    List(ctx context.Context, path string) ([]domain.ItemInfo, error)
    Exists(ctx context.Context, path, name string) (bool, error)
}

type ItemWriter interface {
    Create(ctx context.Context, path, name, source string) error
    Delete(ctx context.Context, path, name string, force bool) error
}

type RepositoryInspector interface {
    GetInfo(ctx context.Context, path string) (*domain.RepositoryInfo, error)
    Validate(path string) error
}
```

Services depend on the small interface they need. Infrastructure implements
all of them. Mocks are smaller and more focused.

## Constructor Patterns

### Simple Constructor

```go
func NewCreator(reader application.ItemReader, cfg *domain.Config, logger *slog.Logger) *creatorService {
    return &creatorService{reader: reader, config: cfg, logger: logger}
}
```

### Constructor with Validation

```go
func NewCreator(reader application.ItemReader, cfg *domain.Config, logger *slog.Logger) (*creatorService, error) {
    if reader == nil {
        return nil, errors.New("item reader is required")
    }
    return &creatorService{reader: reader, config: cfg, logger: logger}, nil
}
```

### Functional Options (for complex construction)

Use sparingly — only when a constructor has >4 optional parameters.

```go
type Option func(*client)

func WithTimeout(d time.Duration) Option {
    return func(c *client) { c.timeout = d }
}

func NewClient(executor shell.Executor, opts ...Option) *client {
    c := &client{
        executor: executor,
        timeout:  30 * time.Second,
    }
    for _, opt := range opts {
        opt(c)
    }
    return c
}
```

## DI Evolution Across Stages

### Stage 1-2: Manual Wiring

All wiring in `main.go`. ServiceContainer is a flat struct. Every service
is constructed eagerly at startup. This is correct for <8 services.

### Stage 3: Lazy Initialization

When some services are expensive and only needed by specific commands, use
`sync.Once` for lazy construction:

```go
type ServiceContainer struct {
    cfg    *domain.Config
    reader application.ItemReader
    logger *slog.Logger

    creatorOnce sync.Once
    creator     application.Creator

    prunerOnce sync.Once
    pruner     application.Pruner
}

func (c *ServiceContainer) Creator() application.Creator {
    c.creatorOnce.Do(func() {
        c.creator = service.NewCreator(c.reader, c.cfg, c.logger)
    })
    return c.creator
}

func (c *ServiceContainer) Pruner() application.Pruner {
    c.prunerOnce.Do(func() {
        c.pruner = service.NewPruner(c.reader, c.cfg, c.logger)
    })
    return c.pruner
}
```

Commands access services via methods instead of fields:
`cfg.Services.Creator()` instead of `cfg.Services.Creator`.

### Stage 4: `samber/do` Container

When the ServiceContainer exceeds 8+ services, has conditional construction
logic, or needs scoped containers per command group, consider `samber/do`:

```go
func main() {
    defer recoverPanic()

    injector := do.New()

    // Infrastructure
    do.Provide(injector, config.NewManager)
    do.Provide(injector, func(i do.Injector) (*domain.Config, error) {
        mgr := do.MustInvoke[*config.Manager](i)
        return mgr.Load()
    })
    do.Provide(injector, shell.NewCommandExecutor)
    do.Provide(injector, tool.NewClient)

    // Services (lazy — constructed on first invocation)
    do.Provide(injector, service.NewCreator)
    do.Provide(injector, service.NewLister)
    do.Provide(injector, service.NewPruner)

    // Presenter
    do.Provide(injector, presenter.NewStyles)
    do.Provide(injector, presenter.NewFormatter)

    rootCmd := cmd.NewRootCommand(injector)
    if err := rootCmd.Execute(); err != nil {
        errFmt := do.MustInvoke[*presenter.ErrorFormatter](injector)
        errFmt.Format(os.Stderr, err)
        os.Exit(int(cmd.GetExitCodeForError(err)))
    }
}
```

**`samber/do` advantages at scale:**

- Lazy invocation — services constructed only when needed
- Scoped containers — child scopes per command group with different config
- Circular dependency detection at runtime
- Zero reflection (generics-based)
- Zero transitive dependencies

**When NOT to use `samber/do`:**

- <8 services — manual wiring is clearer
- No conditional construction — all services always needed
- Team unfamiliar with DI containers

## Testing with DI

Manual DI makes testing trivial — pass different implementations.

```go
func TestCreateService(t *testing.T) {
    mock := &mockItemReader{
        items: []domain.ItemInfo{{Name: "existing"}},
    }
    svc := service.NewCreator(mock, domain.DefaultConfig(), slog.Default())

    result, err := svc.Create(context.Background(), &domain.CreateRequest{
        Name: mustBranchName("feature/test"),
    })

    require.NoError(t, err)
    assert.Equal(t, "feature/test", result.Name)
}
```

## Composite Clients

When routing to different implementations based on the operation:

```go
type compositeClient struct {
    reader application.ItemReader
    writer application.ItemWriter
}

func NewCompositeClient(reader application.ItemReader, writer application.ItemWriter) *compositeClient {
    return &compositeClient{reader: reader, writer: writer}
}
```

## Anti-Patterns

| Anti-Pattern                         | Problem                         | Fix                                 |
| ------------------------------------ | ------------------------------- | ----------------------------------- |
| Global singletons                    | Untestable, hidden dependencies | Constructor injection               |
| `init()` functions that wire deps    | Side effects at import time     | Explicit wiring in `main()`         |
| Interfaces in implementation package | Reversed dependency             | Define where consumed               |
| Giant constructor with 10+ params    | Hard to understand and maintain | Group related deps, functional opts |
| DI framework at Stage 1-2            | Unnecessary complexity          | Manual wiring                       |
| Service creating its own infra       | Hidden dependency, untestable   | Inject from outside                 |
| Infrastructure types in interfaces   | Layer leak                      | Return domain types only            |
