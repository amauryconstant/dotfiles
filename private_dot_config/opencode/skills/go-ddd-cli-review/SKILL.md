---
name: go-ddd-cli-review
description: >
  Review and align Go CLI code against DDD-lite architecture principles.
  Trigger for: reviewing Go CLI code, checking architecture alignment,
  auditing layer boundaries, PR reviews of Go CLIs, refactoring Go CLI
  structure, or aligning an existing Go project to DDD-lite patterns.
  Also trigger when user says "review this Go code", "check architecture",
  "is this structured right", "align to DDD", "audit layers", or
  "refactor to clean architecture" in the context of a Go CLI.
---

# DDD-Lite Review for Go CLIs

Use this skill to evaluate Go CLI code against DDD-lite architectural
principles. Produces actionable findings with severity and refactoring guidance.

## Review Process

1. **Map the current structure** — identify layers (or lack thereof)
2. **Check dependency direction** — violations are the highest-severity findings
3. **Evaluate domain purity** — external deps in domain are critical issues
4. **Assess error handling** — typed errors, exit codes, user-facing messages
5. **Check DI pattern** — composition root, interface placement
6. **Evaluate test coverage** — per layer, test strategy appropriateness

## Architecture Checklist

### Layer Existence & Separation

| Check                                     | Pass                              | Fail                                       |
| ----------------------------------------- | --------------------------------- | ------------------------------------------ |
| CLI layer is thin (parse → call → format) | Commands delegate to services     | Business logic in Cobra `RunE`             |
| Domain layer exists                       | Separate `domain/` or `domain.go` | Types scattered across packages            |
| Domain has zero external deps             | Only `stdlib` imports             | Imports `go-git`, `viper`, etc.            |
| Infrastructure behind interfaces          | Accessed via interfaces           | Direct calls to `exec.Command` in services |
| Services orchestrate, don't implement     | Coordinate domain + infra         | Service contains git/file logic            |

### Dependency Direction

```
VALID:                          INVALID:
cmd/ → service/ → domain/      domain/ → infrastructure/
cmd/ → application/            service/ → cmd/
infrastructure/ → domain/      domain/ → service/
service/ → application/        infrastructure/ → cmd/
```

**How to check:**

```bash
# Find imports in domain/ — should only be stdlib
grep -r '"' internal/domain/ | grep -v '_test.go' | grep -v 'import' | grep '/'

# Find reverse dependencies
grep -rn 'internal/infrastructure' internal/domain/
grep -rn 'internal/service' internal/domain/
grep -rn 'cmd/' internal/service/
```

### Domain Quality

| Check                           | Good                            | Smell                            |
| ------------------------------- | ------------------------------- | -------------------------------- |
| Types have behavior             | `order.Cancel()`                | `order.Status = "cancelled"`     |
| Always-valid construction       | `NewBranchName()` returns error | Public fields, no constructor    |
| Value objects where appropriate | `ProjectPath` with validation   | Raw `string` passed everywhere   |
| Self-validating requests        | `req.Validate()`                | Validation scattered in services |
| Typed errors                    | `*ValidationError`              | `fmt.Errorf("invalid: %s")`      |
| Domain config model             | `domain.Config` with behavior   | Raw `viper.Get()` calls          |

### Error Handling

| Check                    | Good                                 | Smell                            |
| ------------------------ | ------------------------------------ | -------------------------------- |
| Typed domain errors      | `*ValidationError`, `*NotFoundError` | `errors.New("...")` everywhere   |
| Error wrapping with `%w` | `fmt.Errorf("context: %w", err)`     | `fmt.Errorf("context: %s", err)` |
| Exit code mapping        | `errors.As()` → exit code in `cmd/`  | `os.Exit(1)` in service code     |
| User-facing formatting   | `ErrorFormatter` strategy            | `err.Error()` printed directly   |
| Suggestions in errors    | `Suggestions: []string{...}`         | Bare error messages              |
| Panic recovery           | `defer recoverPanic()` in main       | No recovery, raw stack traces    |

### Dependency Injection

| Check                     | Good                            | Smell                                  |
| ------------------------- | ------------------------------- | -------------------------------------- |
| Composition root          | All wiring in `main.go`         | Wiring scattered across packages       |
| Constructor injection     | `NewService(gitClient, config)` | `service.gitClient = git.New()` inside |
| Interfaces where consumed | `application/interfaces.go`     | Interface next to implementation       |
| ServiceContainer          | Typed struct with all services  | Global variables for services          |
| No init() side effects    | Clean `init()` or none          | `init()` creates clients, opens files  |

### Testing

| Check                       | Good                         | Smell                           |
| --------------------------- | ---------------------------- | ------------------------------- |
| Domain tested without mocks | Table-driven, pure functions | Mock framework for domain tests |
| Services tested with mocks  | Hand-written mock infra      | No service tests, only E2E      |
| E2E tests exist             | Full binary tests            | Only unit tests                 |
| Error paths tested          | Each exit code has a test    | Only happy path                 |
| Test isolation              | `t.TempDir()`, fresh mocks   | Shared state between tests      |

## Severity Levels

### Critical — Fix before merging

- Domain imports external packages
- Business logic in Cobra commands
- Service creates its own infrastructure (hidden dependency)
- `os.Exit()` called outside `main.go`
- `log.Fatal()` in library code
- Dependency cycle between layers

### High — Fix soon

- No typed errors (only `fmt.Errorf`)
- No exit code mapping (always exits 1)
- Infrastructure called directly from CLI (bypassing services)
- Global mutable state for dependencies
- `init()` functions with side effects

### Medium — Address during refactoring

- Domain types are anemic (data-only structs)
- Missing value objects for validated data
- No validation pipeline (scattered validation)
- Error messages not user-friendly
- No error formatter/categorizer
- Tests only cover happy path

### Low — Nice to have

- No `doc.go` explaining domain constraints
- No depguard enforcement of layer boundaries
- Could use Result[T] for cleaner error chains
- Missing shell completion (carapace)
- No golden file tests for output formatting

## Refactoring Priority Order

When aligning an existing project, follow this order:

### Phase 1: Dependency Direction (highest impact)

1. Extract domain types to `domain/` package
2. Remove external deps from domain
3. Define interfaces in `application/` (or alongside service types)
4. Move infrastructure behind interfaces

### Phase 2: Error Handling (user-visible improvement)

5. Create typed domain errors
6. Add exit code mapping in `cmd/`
7. Add error formatter for user-friendly messages
8. Add suggestions to error types

### Phase 3: Composition Root (testability)

9. Move all wiring to `main.go`
10. Create ServiceContainer
11. Use constructor injection everywhere
12. Remove global state and `init()` side effects

### Phase 4: Domain Richness (long-term quality)

13. Add behavior to domain types
14. Add validation pipelines
15. Create value objects for validated data
16. Add always-valid construction

### Phase 5: Testing (confidence)

17. Add domain unit tests (table-driven)
18. Add service tests with mock infrastructure
19. Add E2E tests (testscript or Ginkgo)
20. Add contract tests for interface compliance

## Common Refactoring Patterns

### Extract Domain Type

Before:

```go
// In service/creator.go
func (s *service) Create(name string, source string) error {
    if name == "" { return fmt.Errorf("name required") }
    if strings.Contains(name, "..") { return fmt.Errorf("invalid name") }
    // ...
}
```

After:

```go
// In domain/types.go
type BranchName struct { value string }
func NewBranchName(raw string) (BranchName, error) {
    if raw == "" { return BranchName{}, NewValidationError("branch", raw, "required") }
    if strings.Contains(raw, "..") { return BranchName{}, NewValidationError("branch", raw, "invalid") }
    return BranchName{value: raw}, nil
}

// In service/creator.go
func (s *service) Create(req *domain.CreateRequest) error {
    // BranchName already validated at construction
}
```

### Extract Infrastructure Interface

Before:

```go
// In service/syncer.go
func (s *service) Sync() error {
    out, err := exec.Command("git", "fetch", "--all").Output()
    // ...
}
```

After:

```go
// In application/interfaces.go
type GitClient interface {
    FetchAll(ctx context.Context) error
}

// In infrastructure/git/client.go
func (c *client) FetchAll(ctx context.Context) error {
    _, err := c.executor.Run(ctx, "git", "fetch", "--all")
    return err
}

// In service/syncer.go
func (s *service) Sync(ctx context.Context) error {
    return s.git.FetchAll(ctx)
}
```

### Thin Out a Cobra Command

Before:

```go
RunE: func(cmd *cobra.Command, args []string) error {
    name := args[0]
    if name == "" { return fmt.Errorf("name required") }
    config, err := viper.ReadConfig()
    // 50 more lines of logic...
    fmt.Println("Done!")
    return nil
},
```

After:

```go
RunE: func(cmd *cobra.Command, args []string) error {
    req := &domain.CreateRequest{Name: args[0]}
    result, err := cfg.Services.Creator.Create(cmd.Context(), req)
    if err != nil { return err }
    formatCreateResult(cmd.OutOrStdout(), result)
    return nil
},
```

## Quick Assessment Template

When reviewing a Go CLI, produce a summary in this format:

```
## Architecture Assessment: <project>

**Current State**: <flat / partially layered / well-layered>
**Maturity**: <stage 1 / 2 / 3> (per project structure progression)

### Layer Health
- Domain:         <missing / anemic / rich>
- Application:    <missing / interfaces only / with DTOs>
- Service:        <missing / partial / complete>
- Infrastructure: <inline / partial extraction / fully abstracted>
- CLI:            <thin / moderate / fat>

### Critical Issues
1. ...

### High Priority
1. ...

### Recommended Phase
Start with Phase <N>: <name>

### Estimated Effort
<small / medium / large> refactoring
```
