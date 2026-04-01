# Domain Modeling Reference

## Core Principle

Domain types have **behavior, not just data**. A domain type enforces its own
invariants and exposes operations, not raw fields.

## Aggregate Roots

An aggregate is an entity that owns child entities and controls access to them.
The aggregate root enforces invariants across the cluster and provides behavioral
methods that eliminate logic from services.

```go
type Project struct {
    name          string
    path          string
    items         []*Item
    branches      []*BranchInfo
    defaultBranch string
}

// Behavioral methods — logic lives on the aggregate, not in services
func (p *Project) ActiveItems() []*Item {
    return lo.Filter(p.Items(), func(item *Item, _ int) bool {
        return !item.IsArchived()
    })
}

func (p *Project) HasItemForBranch(branch string) bool {
    return lo.SomeBy(p.Items(), func(item *Item) bool {
        return item.Branch() == branch
    })
}

func (p *Project) CanPrune() bool {
    return len(p.ActiveItems()) > 1
}
```

### Assembly via Domain Factory

When an aggregate is built from multiple infrastructure calls, assembly logic
belongs in a domain factory — not in the service.

```go
// domain/factories.go
func NewProject(repo *RepositoryInfo, items []Item) *Project {
    return &Project{
        name:          repo.Name,
        path:          repo.Path,
        items:         toPointers(items),
        branches:      repo.Branches,
        defaultBranch: repo.DefaultBranch,
    }
}
```

The service calls infrastructure, then calls the factory:

```go
func (s *service) GetProject(ctx context.Context, path string) (*domain.Project, error) {
    repo, err := s.reader.GetRepositoryInfo(ctx, path)
    if err != nil { return nil, err }

    items, err := s.reader.ListItems(ctx, path)
    if err != nil { return nil, err }

    return domain.NewProject(repo, items), nil
}
```

### When to Use Aggregates

| Situation                                     | Use Aggregate | Use Standalone Entity |
| --------------------------------------------- | ------------- | --------------------- |
| Parent owns children, enforces rules          | Yes           | —                     |
| Multiple services query the same entity       | Yes           | —                     |
| Entity has no children, no cross-entity rules | —             | Yes                   |
| Entity is read-only lookup data               | —             | Yes                   |

## Always-Valid Construction

If a type exists, it must be valid. Validate in constructors/factories.

```go
func NewBranchName(raw string) (BranchName, error) {
    if err := branchNamePipeline.Validate(raw); err != nil {
        return BranchName{}, err
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

func (p ProjectPath) String() string           { return p.absolute }
func (p ProjectPath) Base() string             { return filepath.Base(p.absolute) }
func (p ProjectPath) Join(elem string) string  { return filepath.Join(p.absolute, elem) }
func (p ProjectPath) Equal(other ProjectPath) bool { return p.absolute == other.absolute }
```

### When to Use Value Objects vs Plain Types

| Use Case                           | Choice                           |
| ---------------------------------- | -------------------------------- |
| Name with validation rules         | Value object                     |
| Identifier with format constraints | Value object                     |
| Simple boolean flag                | Plain `bool`                     |
| Path that needs normalization      | Value object                     |
| Timeout duration                   | Plain `time.Duration`            |
| Exit code                          | Named type (`type ExitCode int`) |

**Rule of thumb**: if you validate or transform the same value in multiple
places, it should be a value object.

## Domain Services (Pure Business Rules)

Domain services are pure functions that encode business rules spanning multiple
types. They live in `domain/` (e.g., `domain/rules.go`), not in application
services.

```go
// domain/rules.go
func CanDelete(project *Project, item *Item, cfg *Config) error {
    if len(project.ActiveItems()) <= 1 {
        return NewOperationError("delete", "cannot delete the last active item", nil)
    }
    if cfg.IsProtected(item.Branch()) {
        return NewValidationError("branch", item.Branch(), "branch is protected")
    }
    return nil
}

func CanCreate(req *CreateRequest, cfg *Config) error {
    if cfg.IsProtected(req.BranchName.String()) {
        return NewValidationError("branch", req.BranchName.String(),
            "cannot create on a protected branch")
    }
    return nil
}
```

Application services call domain services before calling infrastructure:

```go
func (s *service) Delete(ctx context.Context, req *DeleteRequest) error {
    project, err := s.getProject(ctx, req.Path)
    if err != nil { return err }

    item := project.FindItem(req.Name)
    if item == nil { return NewNotFoundError("item", req.Name) }

    if err := domain.CanDelete(project, item, s.config); err != nil {
        return err
    }

    return s.writer.DeleteItem(ctx, project.Path(), req.Name, req.Force)
}
```

**Benefits**: domain rules are testable without mocks (pure functions on domain
types), services are shorter and clearly separated into "check rules" then
"execute."

### When to Use Domain Services

- Logic involves 2+ domain types (aggregate + config, entity + value object)
- Logic is reused across multiple application services
- Logic is a business rule, not orchestration

If the rule only involves one type, make it a method on that type instead.

## Specification Pattern

Composable predicates for filtering and querying domain collections. Keeps
filtering logic in the domain layer as testable, reusable functions.

```go
// domain/specs.go
type Spec[T any] func(T) bool

func ItemOnBranch(pattern string) Spec[*Item] {
    return func(item *Item) bool {
        matched, _ := filepath.Match(pattern, item.Branch())
        return matched
    }
}

func ItemIsStale(mergedBranches []string) Spec[*Item] {
    return func(item *Item) bool {
        return lo.Contains(mergedBranches, item.Branch()) && !item.IsModified()
    }
}

func ItemNotArchived() Spec[*Item] {
    return func(item *Item) bool { return !item.IsArchived() }
}
```

### Combinators

```go
func And[T any](specs ...Spec[T]) Spec[T] {
    return func(item T) bool {
        return lo.EveryBy(specs, func(s Spec[T]) bool { return s(item) })
    }
}

func Or[T any](specs ...Spec[T]) Spec[T] {
    return func(item T) bool {
        return lo.SomeBy(specs, func(s Spec[T]) bool { return s(item) })
    }
}

func Not[T any](spec Spec[T]) Spec[T] {
    return func(item T) bool { return !spec(item) }
}
```

### Usage on Aggregates

```go
func (p *Project) ItemsMatching(spec Spec[*Item]) []*Item {
    return lo.Filter(p.Items(), func(item *Item, _ int) bool {
        return spec(item)
    })
}
```

### Usage in Services

```go
func (s *service) List(ctx context.Context, req *ListRequest) ([]*domain.Item, error) {
    project, err := s.getProject(ctx, req.Path)
    if err != nil { return nil, err }

    spec := domain.And(
        domain.ItemNotArchived(),
        domain.ItemOnBranch(req.BranchPattern),
    )
    return project.ItemsMatching(spec), nil
}
```

### Stage Progression for Specifications

- **Stage 1-2**: inline filtering in services. Specs are overkill for 1-2 filter criteria.
- **Stage 3**: extract specs when filtering logic is reused across commands.
- **Stage 4**: full `Spec[T]` type with `And`/`Or`/`Not` combinators.

## Request/Result DTOs

Typed structs for service boundaries. Requests carry validated inputs. Results
carry operation outcomes.

### Request DTOs (Self-Validating)

```go
type CreateRequest struct {
    Name       BranchName  // already-validated value object
    Source     string
    Options    CreateOptions
}

func (r *CreateRequest) Validate() error {
    return createRequestPipeline.Validate(r)
}
```

All request validation lives on the request DTO. Services call `req.Validate()`
and nothing else. No service-level validation methods.

### Result DTOs (Command vs. Query)

Command methods return thin confirmations:

```go
type CreateResult struct {
    Path       string
    BranchName string
    Created    bool
}
```

Query methods return domain types or slices of domain types directly.

## Validation Pipeline

A unified validation mechanism used across value objects, request DTOs, and
configuration. Returns `error`, not `Result[bool]`.

```go
type ValidationFunc[T any] func(T) error

type ValidationPipeline[T any] struct {
    validators []ValidationFunc[T]
}

func NewPipeline[T any](validators ...ValidationFunc[T]) *ValidationPipeline[T] {
    return &ValidationPipeline[T]{validators: validators}
}

// Validate stops on first error (use for value objects and user input)
func (p *ValidationPipeline[T]) Validate(value T) error {
    for _, v := range p.validators {
        if err := v(value); err != nil {
            return err
        }
    }
    return nil
}

// ValidateAll collects all errors (use for config and complex DTOs)
func (p *ValidationPipeline[T]) ValidateAll(value T) error {
    var errs []error
    for _, v := range p.validators {
        if err := v(value); err != nil {
            errs = append(errs, err)
        }
    }
    return errors.Join(errs...)
}
```

### Value Object Validation (Fail-Fast)

```go
var branchNamePipeline = NewPipeline(
    validateNotEmpty,
    validateNoReservedNames,
    validateLeadingChars,
    validateFormat,
    validateTrailingChars,
    validateLength,
)

func validateNotEmpty(name string) error {
    if strings.TrimSpace(name) == "" {
        return NewValidationError("name", name, "cannot be empty")
    }
    return nil
}
```

### Config Validation (Collect-All)

```go
func (c *Config) Validate() error {
    return configPipeline.ValidateAll(c)
}

var configPipeline = NewPipeline(
    func(c *Config) error {
        if !filepath.IsAbs(c.ProjectsDir) {
            return NewValidationError("projects_dir", c.ProjectsDir,
                "must be absolute path").
                WithSuggestions("use a full path like /home/user/Projects")
        }
        return nil
    },
    func(c *Config) error {
        if c.DefaultBranch == "" {
            return NewValidationError("default_branch", "", "cannot be empty")
        }
        return nil
    },
)
```

### Request DTO Validation (Fail-Fast, Cross-Field)

```go
func (r *CreateRequest) Validate() error {
    return NewPipeline(
        func(r *CreateRequest) error {
            if r.Source == "" {
                return NewValidationError("source", "", "source is required")
            }
            return nil
        },
        func(r *CreateRequest) error {
            if r.Name.String() == r.Source {
                return NewValidationError("name", r.Name.String(),
                    "name and source cannot be the same")
            }
            return nil
        },
    ).Validate(r)
}
```

## Configuration as Domain Type

Config is part of the domain — it defines behavioral parameters. The domain
config type has no serialization tags and no knowledge of TOML, YAML, or koanf.

```go
type Config struct {
    ProjectsDir   string
    DefaultBranch string
    Timeout       time.Duration
    Validation    ValidationConfig
}

type ValidationConfig struct {
    ProtectedBranches []string
}

// Behavior on config
func (c *Config) IsProtected(name string) bool {
    return lo.Contains(c.Validation.ProtectedBranches, name)
}

// Default factory — returns a known-valid config
func DefaultConfig() *Config {
    return &Config{
        DefaultBranch: "main",
        Timeout:       30 * time.Second,
        Validation: ValidationConfig{
            ProtectedBranches: []string{"main", "master"},
        },
    }
}
```

At Stage 1-3, serialization tags on domain types are acceptable. At Stage 4,
infrastructure defines a raw config type with tags and maps to the tag-free
domain config. See `references/configuration.md`.

## Using `samber/mo` in the Domain

`mo.Option[T]` is useful for optional fields that have meaningful
presence/absence semantics (distinct from zero value):

```go
type Config struct {
    ProjectsDir   string
    DefaultBranch string
    CustomTimeout mo.Option[time.Duration] // absent = use default, present = override
}

func (c *Config) Timeout() time.Duration {
    return c.CustomTimeout.OrElse(30 * time.Second)
}
```

`mo.Result[T]` can replace `(T, error)` returns in domain service functions
where chaining is cleaner than sequential error checks. Use sparingly — idiomatic
Go error handling is clearer in most cases.

**Policy**: `mo` is allowed in the domain layer as a curated zero-dep
computational library. It must not be used for I/O or infrastructure concerns.

## Enums (Named Constants)

Go doesn't have enums. Use typed constants with validation.

```go
type OutputFormat string

const (
    FormatTable OutputFormat = "table"
    FormatJSON  OutputFormat = "json"
    FormatPlain OutputFormat = "plain"
)

func ParseOutputFormat(raw string) (OutputFormat, error) {
    switch OutputFormat(raw) {
    case FormatTable, FormatJSON, FormatPlain:
        return OutputFormat(raw), nil
    default:
        return "", NewValidationError("format", raw,
            fmt.Sprintf("must be one of: %s, %s, %s",
                FormatTable, FormatJSON, FormatPlain))
    }
}
```

## Domain Package Documentation

Always include a `doc.go` that explains the dependency constraint:

```go
// Package domain contains the core business types, validation rules, and
// error definitions.
//
// Dependency policy: this package depends only on the Go standard library
// and allowlisted zero-dep computational libraries (samber/lo, samber/mo).
// No I/O dependencies. Enforced by depguard in CI.
//
// All types enforce their own invariants through constructors and behavioral
// methods. If a domain type exists, it is valid.
package domain
```
