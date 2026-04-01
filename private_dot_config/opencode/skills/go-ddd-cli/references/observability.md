# Observability Reference

## Two Output Channels

CLIs have two distinct observability channels. Do not conflate them.

| Channel            | Purpose                 | Audience  | Destination | Control                 |
| ------------------ | ----------------------- | --------- | ----------- | ----------------------- |
| Structured logging | Operational diagnostics | Developer | Stderr      | `MYAPP_DEBUG`/`--debug` |
| Verbose output     | Progress disclosure     | User      | Stderr      | `-v`/`--verbose`        |

**Structured logging** answers "what did the program do internally?" — function
calls, timings, HTTP requests, decision paths. Useful for bug reports and
troubleshooting.

**Verbose output** answers "what is the program doing right now?" — progress
messages, summaries, contextual info. Part of the UI.

See `references/presenter.md` for the VerboseOutput implementation.

## Structured Logging with slog

Use `log/slog` (stdlib, Go 1.21+). Create the handler in `main.go`, inject
`*slog.Logger` into services via constructor.

### Logger Creation

```go
// main.go
func newLogger(debug bool) *slog.Logger {
    level := slog.LevelWarn
    if debug {
        level = slog.LevelDebug
    }

    handler := slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{
        Level: level,
    })
    return slog.New(handler)
}
```

The debug flag comes from `MYAPP_DEBUG=1` environment variable or `--debug`
flag. It is separate from `-v`/`--verbose` (which controls user-facing output).

### Service Injection

```go
type creatorService struct {
    reader application.ItemReader
    config *domain.Config
    logger *slog.Logger
}

func NewCreator(reader application.ItemReader, cfg *domain.Config, logger *slog.Logger) *creatorService {
    return &creatorService{
        reader: reader,
        config: cfg,
        logger: logger,
    }
}

func (s *creatorService) Create(ctx context.Context, req *domain.CreateRequest) (*domain.CreateResult, error) {
    start := time.Now()
    s.logger.Debug("creating item",
        "name", req.Name.String(),
        "source", req.Source)

    // ... operation ...

    s.logger.Debug("item created",
        "path", result.Path,
        "duration", time.Since(start))

    return result, nil
}
```

### Where Each Layer Logs

| Layer          | Logging behavior                                     |
| -------------- | ---------------------------------------------------- |
| Domain         | Never logs. Returns errors/results.                  |
| Service        | Debug-level: operation start/end, decisions, timings |
| Infrastructure | Debug-level: external calls, responses, retries      |
| Presenter      | Never logs. Outputs to terminal.                     |
| CLI            | Never logs directly. Delegates to presenter/service. |

## Context Propagation

### Context Creation

The CLI layer creates the context with cancellation support:

```go
// main.go
func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer cancel()

    // ... wiring ...

    rootCmd := cmd.NewRootCommand(cfg)
    rootCmd.SetContext(ctx)

    if err := rootCmd.Execute(); err != nil {
        // ...
    }
}
```

### Context Policy

| Rule                                  | Implementation                           |
| ------------------------------------- | ---------------------------------------- |
| CLI creates context                   | `signal.NotifyContext` in `main.go`      |
| Services pass context through         | Every service method takes `ctx`         |
| Infrastructure respects cancellation  | All I/O operations use `ctx`             |
| Domain never touches context          | Pure computation, no ctx parameter       |
| Per-operation timeouts set by service | `context.WithTimeout` in service methods |
| Nothing goes in context values        | Use constructor params, not `ctx.Value`  |

### Timeout Propagation

Timeouts are set at the service layer for specific operations, using config
values:

```go
func (s *service) Create(ctx context.Context, req *CreateRequest) (*CreateResult, error) {
    // Apply operation-specific timeout from config
    ctx, cancel := context.WithTimeout(ctx, s.config.Timeout)
    defer cancel()

    return s.writer.Create(ctx, req.Name, req.Source)
}
```

Infrastructure respects the context deadline:

```go
func (c *client) Create(ctx context.Context, name, source string) error {
    cmd := exec.CommandContext(ctx, "tool", "create", name, "--from", source)
    output, err := cmd.CombinedOutput()
    if ctx.Err() == context.DeadlineExceeded {
        return &domain.ExternalError{
            baseError: baseError{message: "operation timed out", kind: domain.KindTimeout},
            Tool: "tool", Operation: "create",
        }
    }
    // ...
}
```

### Signal Handling

`signal.NotifyContext` in `main.go` handles ctrl-c gracefully. When the
context is cancelled, infrastructure calls fail with `context.Canceled`, and
the error propagates up cleanly.

No special signal handling is needed in services or infrastructure — they just
check `ctx.Err()` or let their I/O calls fail naturally.

## Stage Progression

| Concern        | Stage 1-2              | Stage 3                | Stage 4               |
| -------------- | ---------------------- | ---------------------- | --------------------- |
| Logging        | None or `fmt.Fprintf`  | `slog` injected        | `slog` with groups    |
| Debug control  | `MYAPP_DEBUG` env      | + `--debug` flag       | Leveled (debug/trace) |
| Verbose output | Basic `fmt.Fprintf`    | `VerboseOutput`        | Styled, injected      |
| Context        | `context.Background()` | `signal.NotifyContext` | + per-op timeouts     |
| Cancellation   | None                   | Ctrl-c via context     | Graceful cleanup      |

## Anti-Patterns

| Anti-Pattern                      | Fix                                       |
| --------------------------------- | ----------------------------------------- |
| `fmt.Println` for diagnostics     | Use `slog` at debug level                 |
| Logger as global variable         | Inject via constructor                    |
| Logging in domain layer           | Return errors/results, let caller log     |
| Context values for configuration  | Use constructor parameters                |
| No cancellation support           | `signal.NotifyContext` in `main.go`       |
| Mixing verbose output and logging | Separate channels, separate control flags |
| `log.Fatal` in services           | Return errors, let `main.go` exit         |
