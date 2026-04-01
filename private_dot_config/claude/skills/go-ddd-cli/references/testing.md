# Testing Reference

## Testing Pyramid for Go CLIs

```
        ╱╲
       ╱E2E╲         Few — full binary, slow, high confidence
      ╱──────╲
     ╱  CLI   ╲      Command tests with captured output
    ╱──────────╲
   ╱  Service   ╲    Mock infrastructure, test orchestration
  ╱──────────────╲
 ╱    Domain      ╲   Many — pure logic, fast, no mocks
╱──────────────────╲
```

## Domain Tests: Table-Driven, No Mocks

Domain has zero deps, so tests are pure and fast.

```go
func TestValidateBranchName(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        wantErr bool
        errType any
    }{
        {"valid branch", "feature/login", false, nil},
        {"empty string", "", true, &ValidationError{}},
        {"double dots", "feature..test", true, &ValidationError{}},
        {"protected branch", "main", true, &ValidationError{}},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            _, err := NewBranchName(tt.input)
            if tt.wantErr {
                require.Error(t, err)
                if tt.errType != nil {
                    require.ErrorAs(t, err, &tt.errType)
                }
            } else {
                require.NoError(t, err)
            }
        })
    }
}
```

### Validation Pipeline Tests

```go
func TestValidationPipeline(t *testing.T) {
    pipeline := NewPipeline(
        validateNotEmpty,
        validateNoSpecialChars,
    )

    t.Run("all pass", func(t *testing.T) {
        err := pipeline.Validate("feature-login")
        require.NoError(t, err)
    })

    t.Run("collects all errors", func(t *testing.T) {
        err := pipeline.Validate("")
        require.Error(t, err)
        // errors.Join produces joined errors
    })
}
```

## Service Tests: Hand-Written Mocks

Mock infrastructure interfaces to test orchestration logic in isolation.

```go
// Hand-written mock — simple, explicit, no codegen
type mockGitClient struct {
    branches     []string
    branchesErr  error
    createCalled bool
    createReq    *domain.CreateRequest
    createErr    error
}

func (m *mockGitClient) ListBranches(ctx context.Context, repo string) ([]string, error) {
    return m.branches, m.branchesErr
}

func (m *mockGitClient) CreateWorktree(ctx context.Context, req *domain.CreateRequest) error {
    m.createCalled = true
    m.createReq = req
    return m.createErr
}

// Test
func TestWorktreeService_Create(t *testing.T) {
    mock := &mockGitClient{branches: []string{"main"}}
    svc := service.NewWorktreeService(mock, domain.DefaultConfig())

    result, err := svc.Create(context.Background(), &domain.CreateRequest{
        Project:    "myproject",
        BranchName: "feature/test",
    })

    require.NoError(t, err)
    assert.True(t, mock.createCalled)
    assert.Equal(t, "feature/test", mock.createReq.BranchName)
    assert.Equal(t, "feature/test", result.BranchName)
}
```

### When to Use `testify/mock` vs Hand-Written

| Hand-Written Mocks       | `testify/mock`             |
| ------------------------ | -------------------------- |
| Interface has <5 methods | Interface has many methods |
| Simple return values     | Complex call expectations  |
| Most CLI scenarios       | Rarely needed for CLIs     |

**Prefer hand-written mocks for CLIs.** Interfaces are typically small.

## CLI Command Tests

Test Cobra commands by constructing them with test config and capturing output.

```go
func TestCreateCommand(t *testing.T) {
    // Set up mock services
    mock := &mockGitClient{branches: []string{"main"}}
    svc := service.NewWorktreeService(mock, domain.DefaultConfig())

    cfg := &cmd.CommandConfig{
        Config: domain.DefaultConfig(),
        Services: &cmd.ServiceContainer{
            Worktree: svc,
        },
        ErrorFormatter: cmd.NewErrorFormatter(),
    }

    // Build and execute command
    root := cmd.NewRootCommand(cfg)
    buf := new(bytes.Buffer)
    root.SetOut(buf)
    root.SetErr(buf)
    root.SetArgs([]string{"create", "feature/test"})

    err := root.Execute()
    require.NoError(t, err)
    assert.Contains(t, buf.String(), "Created")
}

func TestCreateCommand_InvalidArgs(t *testing.T) {
    cfg := &cmd.CommandConfig{
        Config:         domain.DefaultConfig(),
        Services:       &cmd.ServiceContainer{},
        ErrorFormatter: cmd.NewErrorFormatter(),
    }

    root := cmd.NewRootCommand(cfg)
    root.SetArgs([]string{"create"}) // missing required arg

    err := root.Execute()
    require.Error(t, err)
}
```

## E2E Tests: Full Binary

Build the binary and test it as users would. Two approaches:

### Approach 1: Ginkgo + gexec

```go
//go:build e2e

package e2e

import (
    "os/exec"
    "testing"

    . "github.com/onsi/ginkgo/v2"
    . "github.com/onsi/gomega"
    "github.com/onsi/gomega/gexec"
)

var binaryPath string

var _ = BeforeSuite(func() {
    var err error
    binaryPath, err = gexec.Build("myapp")
    Expect(err).NotTo(HaveOccurred())
})

var _ = AfterSuite(func() {
    gexec.CleanupBuildArtifacts()
})

var _ = Describe("create command", func() {
    It("creates a worktree successfully", func() {
        cmd := exec.Command(binaryPath, "create", "feature/test")
        session, err := gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
        Expect(err).NotTo(HaveOccurred())
        Eventually(session).Should(gexec.Exit(0))
        Expect(session.Out).To(gbytes.Say("Created"))
    })

    It("exits 5 for invalid branch name", func() {
        cmd := exec.Command(binaryPath, "create", "")
        session, err := gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
        Expect(err).NotTo(HaveOccurred())
        Eventually(session).Should(gexec.Exit(5))
    })
})
```

### Approach 2: testscript (Roger Peppe)

Write `.txtar` files that describe CLI interactions declaratively:

```
# test_create.txtar

# Setup
exec git init myrepo
cd myrepo

# Test: create worktree
exec myapp create feature/test
stdout 'Created worktree'

# Test: invalid input
! exec myapp create ''
stderr 'validation failed'
```

```go
//go:build e2e

func TestCLI(t *testing.T) {
    testscript.Run(t, testscript.Params{
        Dir: "testdata",
        Setup: func(env *testscript.Env) error {
            // Build binary and add to PATH
            return nil
        },
    })
}
```

**When to use which:**

- **testscript**: simpler, declarative, great for input/output verification
- **Ginkgo + gexec**: better for complex setup/teardown, parallel execution

## Test Fixtures

### Directory Structure

```
test/
  fixtures/
    configs/           # Test config files
      valid.toml
      invalid.toml
    documents/         # Input documents
      simple.yaml
      complex.yaml
  golden/              # Expected output files
    create_output.txt
    list_output.txt
```

### Golden File Testing

Compare output against a known-good reference file:

```go
func TestFormatOutput(t *testing.T) {
    result := formatCreateResult(&domain.CreateResult{
        Path:       "/tmp/worktree",
        BranchName: "feature/test",
    })

    golden := filepath.Join("testdata", "golden", "create_output.txt")
    if *update {
        os.WriteFile(golden, []byte(result), 0644)
    }

    expected, err := os.ReadFile(golden)
    require.NoError(t, err)
    assert.Equal(t, string(expected), result)
}
```

### Test Helper Patterns

```go
// test/helpers/cli_helper.go
type CLIHelper struct {
    binaryPath string
    workDir    string
}

func NewCLIHelper(t *testing.T, binaryPath string) *CLIHelper {
    t.Helper()
    return &CLIHelper{
        binaryPath: binaryPath,
        workDir:    t.TempDir(),
    }
}

func (h *CLIHelper) Run(args ...string) (stdout, stderr string, exitCode int) {
    cmd := exec.Command(h.binaryPath, args...)
    cmd.Dir = h.workDir
    var outBuf, errBuf bytes.Buffer
    cmd.Stdout = &outBuf
    cmd.Stderr = &errBuf
    err := cmd.Run()
    exitCode = 0
    if exitErr, ok := err.(*exec.ExitError); ok {
        exitCode = exitErr.ExitCode()
    }
    return outBuf.String(), errBuf.String(), exitCode
}
```

## Contract Tests

Validate that interfaces are correctly implemented:

```go
// cmd/contract_test.go
func TestServiceContainerSatisfiesInterfaces(t *testing.T) {
    container := cmd.NewServiceContainer()

    // Verify all interfaces are satisfied at compile time
    var _ application.WorktreeService = container.Worktree
    var _ application.ProjectService = container.Project
    var _ application.ContextService = container.Context
}
```

## Build Tags

```go
//go:build e2e        // E2E tests (slow, need binary)
//go:build integration // Integration tests (need external services)
// No tag              // Unit tests (fast, no external deps)
```

Run:

```bash
go test ./...                           # Unit tests only
go test -tags e2e ./test/e2e/...       # E2E tests
go test -tags integration ./...        # Integration tests
go test -tags "e2e integration" ./...  # All tests
```

## Test Anti-Patterns

| Anti-Pattern                | Fix                                     |
| --------------------------- | --------------------------------------- |
| Mocking domain types        | Domain has no deps — test directly      |
| Testing private methods     | Test through public API                 |
| One giant test function     | Table-driven subtests                   |
| Shared mutable test state   | `t.TempDir()`, fresh mocks per test     |
| Testing Cobra internals     | Test your `execute*` functions directly |
| Skipping error path tests   | Test every exit code / error type       |
| Mock every interface method | Only mock what the test needs           |
