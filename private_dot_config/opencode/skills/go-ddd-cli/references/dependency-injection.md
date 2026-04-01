# Dependency Injection Reference

## Principle: Manual Constructor Injection

Go CLIs use **manual DI** — no frameworks, no containers, no magic. Wire
everything explicitly in `main.go`.

**Why not Wire/Fx?**

- Wire: code generation adds build complexity for little gain in CLIs
- Fx: designed for long-running services with lifecycle hooks — wrong fit for CLIs
- Manual DI: explicit, debuggable, no hidden behavior, easy to understand

## The Composition Root

All wiring happens in `main.go`. This is the **only place** that knows about
concrete implementations.

```go
// main.go — the ONLY file that imports infrastructure packages
package main

import (
    "myapp/cmd"
    "myapp/internal/infrastructure/config"
    "myapp/internal/infrastructure/git"
    "myapp/internal/infrastructure/shell"
    "myapp/internal/service"
)

func main() {
    defer recoverPanic()

    // 1. Infrastructure layer (bottom-up, leaves first)
    configManager := config.NewManager()
    cfg, err := configManager.Load()
    if err != nil {
        handleFatal(err)
    }

    executor := shell.NewCommandExecutor(cfg.Git.Timeout)
    gitClient := git.NewCompositeClient(
        git.NewGoGitClient(cfg.Git.CacheEnabled),
        git.NewCLIClient(executor, cfg.Git.Timeout),
    )

    // 2. Service layer (depends on infrastructure)
    worktreeService := service.NewWorktreeService(gitClient, cfg)
    projectService := service.NewProjectService(gitClient, cfg)
    contextService := service.NewContextService(gitClient, cfg)

    // 3. CLI layer (depends on services)
    container := &cmd.ServiceContainer{
        Worktree: worktreeService,
        Project:  projectService,
        Context:  contextService,
    }
    rootCmd := cmd.NewRootCommand(&cmd.CommandConfig{
        Config:         cfg,
        Services:       container,
        ErrorFormatter: cmd.NewErrorFormatter(),
    })

    if err := rootCmd.Execute(); err != nil {
        os.Exit(int(cmd.HandleCLIError(rootCmd, err)))
    }
}
```

**Key properties:**

- Dependency order is explicit and readable (infrastructure → service → CLI)
- If it compiles, the wiring is correct (no runtime DI failures)
- Easy to add or remove a dependency
- `main.go` is the documentation of your dependency graph

## The Service Container

A simple struct that holds all services. Passed to every command via
`CommandConfig`.

```go
// cmd/container.go
type ServiceContainer struct {
    Worktree application.WorktreeService
    Project  application.ProjectService
    Context  application.ContextService
}

// Factory that does the wiring (alternative to doing it in main.go)
func NewServiceContainer() *ServiceContainer {
    configManager := config.NewManager()
    cfg, _ := configManager.Load()

    executor := shell.NewCommandExecutor(cfg.Git.Timeout)
    gitClient := git.NewClient(executor)

    return &ServiceContainer{
        Worktree: service.NewWorktreeService(gitClient, cfg),
        Project:  service.NewProjectService(gitClient, cfg),
        Context:  service.NewContextService(gitClient, cfg),
    }
}
```

**Which pattern to use?**

- **Wiring in `main.go`**: when you need error handling during setup (config load
  failure, etc.) — preferred for most CLIs.
- **Factory in `container.go`**: when setup is simple and never fails, or when
  you want a clean `main.go`.

## CommandConfig: Thread Through Commands

```go
// cmd/command_config.go
type CommandConfig struct {
    Config         *domain.Config
    Services       *ServiceContainer
    ErrorFormatter *ErrorFormatter
    Verbosity      int
}

// Commands receive it via closure
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
type GitClient interface {
    ListBranches(ctx context.Context, repo string) ([]string, error)
    CreateWorktree(ctx context.Context, req *domain.CreateRequest) error
}

// infrastructure/git/client.go — implements the interface
type client struct {
    executor shell.CommandExecutor
}

func NewClient(executor shell.CommandExecutor) *client {
    return &client{executor: executor}
}

func (c *client) ListBranches(ctx context.Context, repo string) ([]string, error) {
    // implementation
}
```

The `service/` package imports `application.GitClient` (the interface).
The `infrastructure/git/` package imports nothing from `service/`.
`main.go` connects them.

## Constructor Patterns

### Simple Constructor

```go
func NewWorktreeService(git application.GitClient, cfg *domain.Config) *worktreeService {
    return &worktreeService{git: git, config: cfg}
}
```

### Constructor with Validation

```go
func NewWorktreeService(git application.GitClient, cfg *domain.Config) (*worktreeService, error) {
    if git == nil {
        return nil, errors.New("git client is required")
    }
    if cfg == nil {
        return nil, errors.New("config is required")
    }
    return &worktreeService{git: git, config: cfg}, nil
}
```

### Functional Options (for complex construction)

Use sparingly — only when a constructor has >4 optional parameters.

```go
type Option func(*gitClient)

func WithTimeout(d time.Duration) Option {
    return func(c *gitClient) { c.timeout = d }
}

func WithCache(enabled bool, size int) Option {
    return func(c *gitClient) {
        c.cacheEnabled = enabled
        c.cacheSize = size
    }
}

func NewGitClient(executor shell.Executor, opts ...Option) *gitClient {
    c := &gitClient{
        executor:     executor,
        timeout:      30 * time.Second, // defaults
        cacheEnabled: true,
        cacheSize:    25,
    }
    for _, opt := range opts {
        opt(c)
    }
    return c
}
```

## Testing with DI

Manual DI makes testing trivial — just pass different implementations.

```go
// In service tests — pass a mock
func TestCreateWorktree(t *testing.T) {
    mockGit := &mockGitClient{
        branches: []string{"main", "develop"},
    }
    svc := service.NewWorktreeService(mockGit, domain.DefaultConfig())

    result, err := svc.Create(context.Background(), &domain.CreateRequest{
        BranchName: "feature/test",
    })

    require.NoError(t, err)
    assert.Equal(t, "feature/test", result.BranchName)
}
```

## Composite Clients

When you need to route to different implementations based on the operation:

```go
// Composite routes read ops to go-git, write ops to CLI
type compositeGitClient struct {
    reader application.GitReader   // go-git (fast, deterministic)
    writer application.GitWriter   // CLI (reliable for mutations)
}

func NewCompositeClient(reader application.GitReader, writer application.GitWriter) *compositeGitClient {
    return &compositeGitClient{reader: reader, writer: writer}
}

func (c *compositeGitClient) ListBranches(ctx context.Context, repo string) ([]string, error) {
    return c.reader.ListBranches(ctx, repo)  // routed to go-git
}

func (c *compositeGitClient) CreateWorktree(ctx context.Context, req *domain.CreateRequest) error {
    return c.writer.CreateWorktree(ctx, req)  // routed to CLI
}
```

## Anti-Patterns

| Anti-Pattern                         | Problem                         | Fix                                 |
| ------------------------------------ | ------------------------------- | ----------------------------------- |
| Global singletons                    | Untestable, hidden dependencies | Constructor injection               |
| `init()` functions that wire deps    | Side effects at import time     | Explicit wiring in `main()`         |
| Interfaces in implementation package | Reversed dependency             | Define where consumed               |
| Giant constructor with 10+ params    | Hard to understand and maintain | Group related deps into sub-structs |
| DI framework for a CLI               | Unnecessary complexity          | Manual wiring                       |
| Service creating its own infra       | Hidden dependency, untestable   | Inject from outside                 |
