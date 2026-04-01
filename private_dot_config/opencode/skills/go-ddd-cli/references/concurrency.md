# Concurrency Reference

See also: `dependency-injection.md` for `sync.Once` lazy initialization patterns in service containers.

## Policy

Most CLI commands are sequential and don't need concurrency. Add it only when
latency from sequential I/O operations is user-perceptible (>500ms for multiple
independent calls).

**Architectural rules:**

| Layer          | Concurrency allowed? | Rationale                           |
| -------------- | -------------------- | ----------------------------------- |
| Domain         | Never                | Pure computation, must be testable  |
| Service        | Yes — owns decisions | Knows which calls are independent   |
| Infrastructure | Never (per adapter)  | Individual adapters are synchronous |
| Presenter      | Contained only       | bubbletea has its own event loop    |
| CLI            | Never directly       | Delegates to services               |

Services decide when to parallelize. Infrastructure provides synchronous
building blocks. The service composes them concurrently when appropriate.

## When to Add Concurrency

Add concurrency when:

- A service method makes 2+ independent I/O calls that could run in parallel
- A command processes N items where each requires an independent I/O call
- Total sequential latency exceeds ~500ms and parallel execution would help

Do not add concurrency for:

- Sequential dependencies (call B depends on result of call A)
- Single I/O operations
- CPU-bound domain computation
- <5 items to process (overhead exceeds benefit)

## Primitives

### `errgroup` (Stage 3 default)

Scoped goroutine group with shared context and first-error cancellation. Part
of `golang.org/x/sync` (official Go team project, stdlib-adjacent).

**Use for**: 2-5 independent I/O calls in one service method.

```go
func (s *service) GetDetail(ctx context.Context, path string) (*domain.Project, error) {
    g, ctx := errgroup.WithContext(ctx)

    var info *domain.RepositoryInfo
    var items []domain.ItemInfo

    g.Go(func() error {
        var err error
        info, err = s.inspector.GetInfo(ctx, path)
        return err
    })

    g.Go(func() error {
        var err error
        items, err = s.reader.List(ctx, path)
        return err
    })

    if err := g.Wait(); err != nil {
        return nil, err
    }

    return domain.NewProject(info, items), nil
}
```

**Caveat**: results are captured via closure variables. Be careful with pointer
aliasing — each goroutine must write to its own variable.

### `sourcegraph/conc` (Stage 4)

Structured concurrency with generics. Type-safe result collection and panic
recovery.

**Use for**: fan-out patterns processing N items concurrently with typed results.

```go
func (s *service) ListAll(ctx context.Context, paths []string) ([]*domain.Project, error) {
    pool := pool.NewWithResults[*domain.Project]().
        WithContext(ctx).
        WithMaxGoroutines(4)

    for _, path := range paths {
        path := path // capture
        pool.Go(func() (*domain.Project, error) {
            return s.GetDetail(ctx, path)
        })
    }

    return pool.Wait()
}
```

**Advantages over errgroup:**

- Type-safe result collection (no closure variables)
- Panic recovery (errgroup lets panics crash the process)
- Configurable pool size (`WithMaxGoroutines`)
- Cleaner API for fan-out patterns

### `lo/parallel` (lop)

Parallel map/filter over collections. Simplest option for "apply function to
every item concurrently."

```go
import (
    lop "github.com/samber/lo/parallel"
)

results := lop.Map(paths, func(path string, _ int) *domain.Detail {
    detail, err := s.GetDetail(ctx, path)
    if err != nil {
        s.logger.Debug("failed to get detail", "path", path, "err", err)
        return nil
    }
    return detail
})

// Filter out nil results
results = lo.Compact(results)
```

**Limitation**: no built-in error propagation. Errors must be handled inside
the callback. Use `errgroup` or `conc` when error handling matters.

## Context and Cancellation

All concurrent operations must respect context cancellation:

```go
g, ctx := errgroup.WithContext(ctx)
// If any goroutine fails, ctx is cancelled, others stop early
```

When using `conc`:

```go
pool := pool.New().WithContext(ctx)
// Context cancellation propagates to all goroutines
```

If the user presses ctrl-c, `signal.NotifyContext` (set up in `main.go`)
cancels the root context, which propagates to all concurrent operations.

## Testing Concurrent Code

### Race Detector

Always run concurrent tests with `-race`:

```bash
go test -race -tags concurrent ./test/concurrent/...
```

### Concurrent Test Structure

```go
//go:build concurrent

func TestConcurrentOperations(t *testing.T) {
    env := helpers.NewTestEnvironment(t)

    svc := createTestService(t, env)

    g, ctx := errgroup.WithContext(context.Background())

    // Run multiple operations concurrently
    for i := 0; i < 10; i++ {
        name := fmt.Sprintf("item-%d", i)
        g.Go(func() error {
            _, err := svc.Create(ctx, &domain.CreateRequest{
                Name: mustName(name),
            })
            return err
        })
    }

    require.NoError(t, g.Wait())
}
```

### Testing That Services Handle Context Cancellation

```go
func TestCreateRespectsContextCancellation(t *testing.T) {
    ctx, cancel := context.WithCancel(context.Background())
    cancel() // cancel immediately

    mock := &mockItemReader{}
    svc := service.NewCreator(mock, domain.DefaultConfig(), slog.Default())

    _, err := svc.Create(ctx, &domain.CreateRequest{
        Name: mustName("feature/test"),
    })

    require.Error(t, err)
    assert.True(t, errors.Is(err, context.Canceled))
}
```

## Stage Progression

| Concern        | Stage 1-2                    | Stage 3                      | Stage 4                    |
| -------------- | ---------------------------- | ---------------------------- | -------------------------- |
| Concurrency    | None                         | `errgroup` where needed      | `conc` for fan-out         |
| Max goroutines | —                            | Unbounded (small N)          | Configurable pool size     |
| Race testing   | `go test -race` on all tests | Dedicated `test/concurrent/` | Full suite                 |
| Parallel map   | —                            | —                            | `lop.Map` for simple cases |

## Anti-Patterns

| Anti-Pattern                           | Fix                                                |
| -------------------------------------- | -------------------------------------------------- |
| Goroutines in domain layer             | Domain is pure, never concurrent                   |
| Infrastructure spawning goroutines     | Adapters are synchronous; service owns concurrency |
| Goroutines in commands                 | Delegate to services                               |
| No context propagation in goroutines   | Always pass ctx from errgroup/conc                 |
| Ignoring errors in parallel operations | Use errgroup or conc, not bare goroutines          |
| No race detector in CI                 | Run `go test -race` in CI pipeline                 |
| Unbounded goroutines on user input     | Use `WithMaxGoroutines` for N > 10                 |
