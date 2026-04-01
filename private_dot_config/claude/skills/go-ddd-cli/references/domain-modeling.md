# Domain Modeling Reference

## Core Principle

Domain types have **behavior, not just data**. A domain type enforces its own
invariants and exposes operations, not raw fields.

```go
// BAD: anemic data struct
type Order struct {
    Status string
    Items  []Item
}
// caller does: order.Status = "cancelled" — no validation

// GOOD: type with behavior
type Order struct {
    status Status    // private
    items  []Item    // private
}
func (o *Order) Cancel() error {
    if o.status == StatusShipped {
        return NewOrderError("cannot cancel shipped order")
    }
    o.status = StatusCancelled
    return nil
}
```

## Always-Valid Construction

If a type exists, it must be valid. Validate in constructors/factories.

```go
// Constructor enforces invariants
func NewBranchName(raw string) (BranchName, error) {
    if raw == "" {
        return BranchName{}, NewValidationError("branch", raw, "branch name cannot be empty")
    }
    if strings.Contains(raw, "..") {
        return BranchName{}, NewValidationError("branch", raw, "branch name cannot contain '..'")
    }
    return BranchName{value: raw}, nil
}

type BranchName struct {
    value string // private — can only be created via NewBranchName
}
func (b BranchName) String() string { return b.value }
```

## Value Objects

Immutable types compared by value, not identity. Common in CLIs for paths,
names, identifiers.

```go
// Value object: compared by value, immutable
type ProjectPath struct {
    absolute string
}

func NewProjectPath(raw string) (ProjectPath, error) {
    abs, err := filepath.Abs(raw)
    if err != nil {
        return ProjectPath{}, NewValidationError("path", raw, "invalid path")
    }
    return ProjectPath{absolute: abs}, nil
}

func (p ProjectPath) String() string     { return p.absolute }
func (p ProjectPath) Base() string       { return filepath.Base(p.absolute) }
func (p ProjectPath) Join(elem string) string { return filepath.Join(p.absolute, elem) }

// Value equality
func (p ProjectPath) Equal(other ProjectPath) bool {
    return p.absolute == other.absolute
}
```

## When to Use Value Objects vs Plain Types

| Use Case                           | Choice                           | Why                                 |
| ---------------------------------- | -------------------------------- | ----------------------------------- |
| Branch name with validation        | Value object                     | Invariants to enforce               |
| Git commit SHA                     | Value object                     | Format validation, display behavior |
| Simple boolean flag                | Plain `bool`                     | No invariants needed                |
| File path that needs normalization | Value object                     | Normalization = invariant           |
| Timeout duration                   | Plain `time.Duration`            | stdlib type is sufficient           |
| Exit code                          | Named type (`type ExitCode int`) | Adds type safety without full VO    |

**Rule of thumb**: if you find yourself validating or transforming the same value
in multiple places, it should be a value object.

## Request/Result DTOs

Use typed structs for service boundaries. Never pass raw maps or
loosely-typed args between layers.

```go
// Request: what the caller wants
type CreateWorktreeRequest struct {
    Project      string
    BranchName   BranchName    // Already validated value object
    SourceBranch string
    Options      CreateOptions
}

// Self-validating request
func (r *CreateWorktreeRequest) Validate() error {
    if r.Project == "" {
        return NewValidationError("project", "", "project is required")
    }
    return nil
}

// Result: what the service returns
type CreateWorktreeResult struct {
    Path         string
    BranchName   string
    SourceBranch string
    Created      bool
}
```

## Validation Pipeline

Composable validators for complex validation logic.

```go
// Validator function type
type ValidatorFunc[T any] func(T) error

// Pipeline composes validators
type ValidationPipeline[T any] struct {
    validators []ValidatorFunc[T]
}

func NewPipeline[T any](validators ...ValidatorFunc[T]) *ValidationPipeline[T] {
    return &ValidationPipeline[T]{validators: validators}
}

func (p *ValidationPipeline[T]) Validate(value T) error {
    var errs []error
    for _, v := range p.validators {
        if err := v(value); err != nil {
            errs = append(errs, err)
        }
    }
    return errors.Join(errs...)
}

// Usage
var branchValidation = NewPipeline(
    validateNotEmpty,
    validateNoDoubleDots,
    validateNotProtected,
)

func validateNotEmpty(name string) error {
    if name == "" {
        return NewValidationError("branch", name, "cannot be empty")
    }
    return nil
}
```

## Result[T] Type

Functional error handling for operations that may fail. Useful when you want
to chain operations without early `if err != nil` returns.

```go
type Result[T any] struct {
    value T
    err   error
}

func Ok[T any](value T) Result[T]  { return Result[T]{value: value} }
func Err[T any](err error) Result[T] { return Result[T]{err: err} }

func (r Result[T]) IsOk() bool    { return r.err == nil }
func (r Result[T]) IsErr() bool   { return r.err != nil }
func (r Result[T]) Value() T      { return r.value }
func (r Result[T]) Error() error  { return r.err }

func (r Result[T]) Unwrap() (T, error) { return r.value, r.err }

// Map transforms the value if Ok
func Map[T, U any](r Result[T], fn func(T) U) Result[U] {
    if r.IsErr() {
        return Err[U](r.err)
    }
    return Ok(fn(r.value))
}

// FlatMap chains fallible operations
func FlatMap[T, U any](r Result[T], fn func(T) Result[U]) Result[U] {
    if r.IsErr() {
        return Err[U](r.err)
    }
    return fn(r.value)
}
```

## Configuration as Domain Type

Config is part of the domain — it defines behavioral parameters, not just data.

```go
type Config struct {
    ProjectsDir    string
    DefaultBranch  string
    Git            GitConfig
    Validation     ValidationConfig
    Shell          ShellConfig
}

type GitConfig struct {
    Timeout      time.Duration
    CacheEnabled bool
    MaxCacheSize int
}

type ValidationConfig struct {
    ProtectedBranches []string
}

// Behavior on config
func (c *Config) IsProtectedBranch(name string) bool {
    for _, p := range c.Validation.ProtectedBranches {
        if p == name { return true }
    }
    return false
}

// Default factory
func DefaultConfig() *Config {
    return &Config{
        DefaultBranch: "main",
        Git: GitConfig{
            Timeout:      30 * time.Second,
            CacheEnabled: true,
            MaxCacheSize: 25,
        },
    }
}
```

## Enums (Named Constants)

Go doesn't have enums. Use typed constants with validation.

```go
type Platform string

const (
    PlatformClaudeCode Platform = "claude-code"
    PlatformOpenCode   Platform = "opencode"
)

func ParsePlatform(raw string) (Platform, error) {
    switch Platform(raw) {
    case PlatformClaudeCode, PlatformOpenCode:
        return Platform(raw), nil
    default:
        return "", NewValidationError("platform", raw,
            fmt.Sprintf("unknown platform, must be one of: %s, %s",
                PlatformClaudeCode, PlatformOpenCode))
    }
}

func (p Platform) String() string { return string(p) }
```

## Domain Package Documentation

Always include a `doc.go` that explains the zero-dependency constraint:

```go
// Package domain contains the core business types, validation rules, and
// error definitions for myapp.
//
// This package MUST have zero external dependencies. It depends only on the
// Go standard library. This constraint is enforced by depguard in CI.
//
// All types in this package enforce their own invariants through constructors
// and behavioral methods. If a domain type exists, it is valid.
package domain
```
