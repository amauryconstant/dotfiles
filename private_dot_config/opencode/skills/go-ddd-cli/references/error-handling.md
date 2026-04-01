# Error Handling Reference

## Three-Tier Error Architecture

```text
Domain Layer          CLI Layer                 CLI Layer
(define errors)  →    (categorize + exit code)  →  (format for user)
domain/errors.go      cmd/error_handler.go      cmd/error_formatter.go
```

## Tier 1: Domain Error Types

Each error type carries context. Use the builder pattern for optional fields.

```go
// Base pattern: typed error with context
type ValidationError struct {
    Field       string
    Value       string
    Message     string
    Suggestions []string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed for %s: %s", e.Field, e.Message)
}

// Constructor
func NewValidationError(field, value, message string) *ValidationError {
    return &ValidationError{Field: field, Value: value, Message: message}
}

// Builder for optional fields
func (e *ValidationError) WithSuggestions(s ...string) *ValidationError {
    e.Suggestions = s
    return e
}
```

### Standard Error Types for CLIs

| Error Type        | When to Use                             | Exit Code |
| ----------------- | --------------------------------------- | --------- |
| `ValidationError` | Invalid user input, bad flags           | 5         |
| `ConfigError`     | Config file missing, invalid, malformed | 3         |
| `NotFoundError`   | Resource doesn't exist                  | 6         |
| `OperationError`  | Business operation failed               | 1         |
| `ExternalError`   | External tool/API failed (git, API)     | 4         |
| `FileError`       | File I/O problems                       | 1         |
| `ConflictError`   | Resource already exists, state conflict | 1         |

```go
// ExternalError for tool/API failures
type ExternalError struct {
    Tool      string   // "git", "docker", etc.
    Operation string   // "clone", "push", etc.
    Message   string
    Cause     error
    Suggestions []string
}

func (e *ExternalError) Error() string {
    return fmt.Sprintf("%s %s failed: %s", e.Tool, e.Operation, e.Message)
}

func (e *ExternalError) Unwrap() error { return e.Cause }

// NotFoundError
type NotFoundError struct {
    Entity string // "project", "branch", "worktree"
    Name   string
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s %q not found", e.Entity, e.Name)
}
```

## Tier 2: Error Categorization & Exit Codes

In `cmd/error_handler.go`. Maps domain errors to exit codes using `errors.As`.

```go
type ExitCode int

const (
    ExitSuccess    ExitCode = 0
    ExitError      ExitCode = 1 // General error
    ExitUsage      ExitCode = 2 // Bad flags/args (Cobra handles this)
    ExitConfig     ExitCode = 3 // Config error
    ExitExternal   ExitCode = 4 // External tool failure
    ExitValidation ExitCode = 5 // Input validation
    ExitNotFound   ExitCode = 6 // Resource not found
)

func GetExitCodeForError(err error) ExitCode {
    if err == nil {
        return ExitSuccess
    }
    var valErr *domain.ValidationError
    if errors.As(err, &valErr) {
        return ExitValidation
    }
    var cfgErr *domain.ConfigError
    if errors.As(err, &cfgErr) {
        return ExitConfig
    }
    var extErr *domain.ExternalError
    if errors.As(err, &extErr) {
        return ExitExternal
    }
    var nfErr *domain.NotFoundError
    if errors.As(err, &nfErr) {
        return ExitNotFound
    }
    return ExitError
}
```

### Top-Level Error Handler

Called from `main.go` when `rootCmd.Execute()` returns an error:

```go
func HandleCLIError(cmd *cobra.Command, err error) ExitCode {
    // Cobra already printed usage errors
    if isCobraUsageError(err) {
        return ExitUsage
    }

    // Format and print
    formatted := globalConfig.ErrorFormatter.Format(err)
    fmt.Fprintln(cmd.ErrOrStderr(), formatted)

    return GetExitCodeForError(err)
}
```

## Tier 3: Error Formatting

Strategy pattern — register formatters per error type. Produces user-friendly
output with actionable suggestions.

```go
type ErrorFormatter struct {
    formatters []errorFormatEntry
    quiet      bool
}

type errorFormatEntry struct {
    match  func(error) bool
    format func(error) string
}

func NewErrorFormatter() *ErrorFormatter {
    f := &ErrorFormatter{}
    f.Register(
        func(err error) bool { var e *domain.ValidationError; return errors.As(err, &e) },
        formatValidationError,
    )
    f.Register(
        func(err error) bool { var e *domain.NotFoundError; return errors.As(err, &e) },
        formatNotFoundError,
    )
    // ... more formatters
    return f
}

func (f *ErrorFormatter) Format(err error) string {
    for _, entry := range f.formatters {
        if entry.match(err) {
            return entry.format(err)
        }
    }
    return fmt.Sprintf("Error: %s", err.Error())
}

// Example formatter
func formatValidationError(err error) string {
    var valErr *domain.ValidationError
    errors.As(err, &valErr)

    msg := fmt.Sprintf("Error: %s\n", valErr.Message)
    if valErr.Field != "" {
        msg += fmt.Sprintf("  Field: %s\n", valErr.Field)
    }
    if len(valErr.Suggestions) > 0 {
        msg += "\nSuggestions:\n"
        for _, s := range valErr.Suggestions {
            msg += fmt.Sprintf("  - %s\n", s)
        }
    }
    return msg
}
```

## Error Wrapping Rules

1. **Wrap with `%w`** when the caller should be able to inspect the original error.
2. **Wrap with `%s`** (or create a new error) when you want to hide internals.
3. **Add context** at each layer boundary (service → infrastructure).
4. **Don't double-wrap**: if the error already has good context, pass it through.

```go
// In service layer — add context about the operation
func (s *creatorService) Create(ctx context.Context, req *CreateRequest) (*CreateResult, error) {
    branches, err := s.git.ListBranches(ctx, req.Project)
    if err != nil {
        return nil, fmt.Errorf("listing branches for project %q: %w", req.Project, err)
    }
    // ...
}

// In infrastructure — wrap external errors with domain types
func (c *gitClient) ListBranches(ctx context.Context, repo string) ([]string, error) {
    output, err := c.executor.Run(ctx, "git", "branch", "--list")
    if err != nil {
        return nil, &domain.ExternalError{
            Tool: "git", Operation: "list-branches",
            Message: "failed to list branches",
            Cause: err,
        }
    }
    // ...
}
```

## Panic Recovery

Top-level recovery in `main.go`. Show stack trace only in debug mode.

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

func main() {
    defer recoverPanic()
    // ...
}
```

## Common Anti-Patterns

| Anti-Pattern                      | Fix                                                |
| --------------------------------- | -------------------------------------------------- |
| `log.Fatal()` in library code     | Return errors; only `main` calls `os.Exit()`       |
| `panic()` for expected errors     | Return typed domain errors                         |
| `err.Error()` in user output      | Use ErrorFormatter for friendly messages           |
| Exit codes in domain layer        | Domain defines error types; CLI maps to exit codes |
| Swallowing errors with `_ =`      | Handle or propagate every error                    |
| String matching on error messages | Use `errors.As()` with typed errors                |
| Wrapping then re-wrapping         | Wrap once at the boundary, pass through otherwise  |
