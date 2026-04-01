# Error Handling Reference

See also: `domain-modeling.md` for domain type patterns (error types are domain types).

## Standardized Error Types

Error types are aligned 1:1 with exit codes. Six types cover all CLI error
scenarios. If two errors produce the same exit code and the same formatting
template, they are the same type with a distinguishing field.

### The DomainError Interface

All domain errors implement a common interface. This enables single-dispatch
error handling without `errors.As` chains.

```go
type DomainError interface {
    error
    Unwrap() error
    ExitCode() int
    ErrorSuggestions() []string
}
```

### Base Error Embedding

Reduce boilerplate by embedding a base type. Concrete error types only define
their unique fields and constructor.

```go
type baseError struct {
    message     string
    kind        ErrorKind
    cause       error
    suggestions []string
    exitCode    int
}

func (e *baseError) Error() string            { return e.message }
func (e *baseError) Unwrap() error            { return e.cause }
func (e *baseError) ExitCode() int            { return e.exitCode }
func (e *baseError) ErrorSuggestions() []string { return e.suggestions }
func (e *baseError) WithSuggestions(s ...string) { e.suggestions = s }
```

### ErrorKind Sub-Classification

A single enum shared across all error types. Drives formatting and suggestions
without multiplying types.

```go
type ErrorKind int

const (
    KindGeneral    ErrorKind = iota
    KindNotFound             // resource/tool doesn't exist
    KindTimeout              // operation exceeded deadline
    KindPermission           // access denied
    KindConflict             // resource already exists or state conflict
)
```

### The Six Error Types

**OperationError** — exit code 1. Business logic or general failure.

```go
type OperationError struct {
    baseError
    Operation string
    Component string
}

func NewOperationError(operation, message string, cause error) *OperationError {
    return &OperationError{
        baseError: baseError{message: message, cause: cause, exitCode: 1},
        Operation: operation,
    }
}
```

**UsageError** — exit code 2. Bad flags or arguments. Cobra handles this
automatically for flag parsing; define this type for commands that need to
report argument-level validation errors.

```go
type UsageError struct {
    baseError
    Command string
}

func NewUsageError(command, message string) *UsageError {
    return &UsageError{
        baseError: baseError{message: message, exitCode: 2},
        Command:   command,
    }
}
```

**ConfigError** — exit code 3. Configuration problems.

```go
type ConfigError struct {
    baseError
    Path string
}

func NewConfigError(path, message string, cause error) *ConfigError {
    return &ConfigError{
        baseError: baseError{message: message, cause: cause, exitCode: 3},
        Path:      path,
    }
}
```

**ExternalError** — exit code 4. External tool, API, or network failure.

```go
type ExternalError struct {
    baseError
    Tool      string
    Operation string
}

func NewExternalError(tool, operation, message string, cause error) *ExternalError {
    return &ExternalError{
        baseError: baseError{message: message, cause: cause, exitCode: 4},
        Tool:      tool,
        Operation: operation,
    }
}
```

**ValidationError** — exit code 5. Domain input validation.

```go
type ValidationError struct {
    baseError
    Field string
    Value string
}

func NewValidationError(field, value, message string) *ValidationError {
    return &ValidationError{
        baseError: baseError{message: message, exitCode: 5},
        Field:     field,
        Value:     value,
    }
}
```

**NotFoundError** — exit code 6. Resource doesn't exist.

```go
type NotFoundError struct {
    baseError
    Entity string
    Name   string
}

func NewNotFoundError(entity, name string) *NotFoundError {
    return &NotFoundError{
        baseError: baseError{
            message:  fmt.Sprintf("%s %q not found", entity, name),
            exitCode: 6,
        },
        Entity: entity,
        Name:   name,
    }
}
```

## Exit Code Constants

```go
type ExitCode int

const (
    ExitSuccess    ExitCode = 0
    ExitError      ExitCode = 1 // General / operation error
    ExitUsage      ExitCode = 2 // Bad flags/args (Cobra handles this)
    ExitConfig     ExitCode = 3 // Config error
    ExitExternal   ExitCode = 4 // External tool failure
    ExitValidation ExitCode = 5 // Input validation
    ExitNotFound   ExitCode = 6 // Resource not found
)
```

## Error Handler

Single-dispatch via the `DomainError` interface. No `errors.As` chain needed
for exit code mapping.

```go
func GetExitCodeForError(err error) ExitCode {
    if err == nil {
        return ExitSuccess
    }
    var domErr DomainError
    if errors.As(err, &domErr) {
        return ExitCode(domErr.ExitCode())
    }
    return ExitError
}
```

## Wrapping Policy

Three rules govern error propagation across layers:

**1. Infrastructure wraps once.** This is the single point where raw external
errors become typed domain errors.

```go
// infrastructure/tool/client.go
func (c *client) ListItems(ctx context.Context, path string) ([]domain.ItemInfo, error) {
    output, err := c.executor.Run(ctx, "tool", "list")
    if err != nil {
        return nil, &domain.ExternalError{
            baseError: baseError{
                message: "failed to list items",
                kind:    classifyError(err),
                cause:   err,
            },
            Tool:      "tool",
            Operation: "list",
        }
    }
    // parse output into domain types...
}
```

**2. Services translate, not wrap.** If infrastructure returns a typed error
and the service adds no new semantic meaning, pass it through unchanged. Only
create a new error when the meaning changes:

```go
func (s *service) Create(ctx context.Context, req *domain.CreateRequest) (*domain.CreateResult, error) {
    exists, err := s.reader.Exists(ctx, req.Name)
    if err != nil {
        return nil, err // pass through — no new meaning to add
    }
    if exists {
        // translate — "exists" in infrastructure becomes "conflict" in domain
        return nil, domain.NewOperationError("create",
            fmt.Sprintf("%s already exists", req.Name), nil)
    }
    // ...
}
```

**3. Commands never wrap.** The command returns the error as-is. The error
handler and formatter in the presenter layer handle exit codes and display.

```go
RunE: func(cmd *cobra.Command, args []string) error {
    result, err := cfg.Services.Creator.Create(cmd.Context(), req)
    if err != nil {
        return err // no wrapping, no fmt.Errorf
    }
    cfg.Presenter.FormatResult(cmd.OutOrStdout(), result)
    return nil
},
```

## Infrastructure Error Classification

A shared helper in the infrastructure layer maps raw errors to `ErrorKind`.

```go
func classifyError(err error) domain.ErrorKind {
    if errors.Is(err, exec.ErrNotFound) {
        return domain.KindNotFound
    }
    if errors.Is(err, context.DeadlineExceeded) {
        return domain.KindTimeout
    }
    if errors.Is(err, os.ErrPermission) {
        return domain.KindPermission
    }
    return domain.KindGeneral
}
```

## Error Formatting

Error formatting lives in the presenter layer (`presenter/error_formatter.go`).
The formatter uses the `DomainError` interface for common behavior and
`errors.As` for type-specific field access.

```go
type ErrorFormatter struct {
    styles *Styles
}

func (f *ErrorFormatter) Format(w io.Writer, err error) {
    var domErr domain.DomainError
    if !errors.As(err, &domErr) {
        fmt.Fprintf(w, "Error: %s\n", err.Error())
        return
    }

    // Type-specific formatting
    var extErr *domain.ExternalError
    if errors.As(err, &extErr) {
        f.formatExternal(w, extErr)
        return
    }
    // ... other type-specific formatters

    // Fallback: generic domain error
    f.formatGeneric(w, domErr)
}

func (f *ErrorFormatter) formatExternal(w io.Writer, err *domain.ExternalError) {
    fmt.Fprintf(w, "%s %s failed: %s\n",
        f.styles.Error.Render(err.Tool),
        err.Operation,
        err.Error())

    for _, s := range f.suggestionsForKind(err.Tool, err.Kind()) {
        fmt.Fprintf(w, "  %s %s\n", f.styles.Dim.Render("→"), s)
    }
}
```

### Kind-Driven Suggestions

```go
func (f *ErrorFormatter) suggestionsForKind(tool string, kind domain.ErrorKind) []string {
    switch kind {
    case domain.KindNotFound:
        return []string{fmt.Sprintf("install %s or check your PATH", tool)}
    case domain.KindTimeout:
        return []string{"increase timeout in config", "check network connectivity"}
    case domain.KindPermission:
        return []string{"check file permissions"}
    default:
        return nil
    }
}
```

## Panic Recovery

Top-level recovery in `main.go`. Stack trace only in debug mode.

```go
func recoverPanic() {
    if r := recover(); r != nil {
        fmt.Fprintf(os.Stderr, "Fatal: unexpected error: %v\n", r)
        if os.Getenv("MYAPP_DEBUG") != "" {
            fmt.Fprintf(os.Stderr, "\nStack trace:\n%s\n", debug.Stack())
        } else {
            fmt.Fprintf(os.Stderr, "Set MYAPP_DEBUG=1 for stack trace\n")
        }
        os.Exit(1)
    }
}
```

## Stage Progression

| Concern             | Stage 1-2                                    | Stage 3                              | Stage 4                            |
| ------------------- | -------------------------------------------- | ------------------------------------ | ---------------------------------- |
| Error types         | 6 types inline                               | 6 types with `baseError`             | Shared module across projects      |
| ErrorKind           | `KindGeneral`, `KindNotFound`, `KindTimeout` | Add `KindPermission`, `KindConflict` | Full kind × tool suggestion matrix |
| Formatting          | Simple `err.Error()` output                  | Presenter with strategy              | Kind-driven suggestions            |
| `DomainError` iface | Optional                                     | Required                             | Required                           |
| `classifyError`     | Inline in adapters                           | Shared infra helper                  | Shared infra helper                |

## Anti-Patterns

| Anti-Pattern                      | Fix                                                            |
| --------------------------------- | -------------------------------------------------------------- |
| One error type per service        | One type per exit code, use fields to distinguish              |
| `log.Fatal()` in library code     | Return errors; only `main` calls `os.Exit()`                   |
| `panic()` for expected errors     | Return typed domain errors                                     |
| `fmt.Errorf` wrapping in commands | Return the error unchanged                                     |
| Service wrapping typed errors     | Pass through or translate, never re-wrap                       |
| String matching on error messages | Use `errors.As()` with typed errors or `DomainError` interface |
| `err.Error()` in user output      | Use ErrorFormatter in presenter layer                          |
| Exit codes in domain layer        | Domain defines types; exit codes on `DomainError`              |
