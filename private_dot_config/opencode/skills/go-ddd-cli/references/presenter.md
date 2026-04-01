# Presenter Reference

## Purpose

The presenter layer handles all terminal output concerns. It translates domain
results into user-facing output. It sits between the CLI layer (Cobra commands)
and the domain types.

```text
cmd/ → presenter/ → terminal
         ↑
       domain types (for formatting)
```

The presenter never calls services, never accesses infrastructure, and never
contains business logic.

## Output Formatting

### Multi-Format Output

Query commands support `--output json|table|plain`. Command (mutating)
operations always produce human-readable confirmations.

```go
type OutputFormat string

const (
    FormatTable OutputFormat = "table"
    FormatJSON  OutputFormat = "json"
    FormatPlain OutputFormat = "plain"
)

type Formatter struct {
    format OutputFormat
    styles *Styles
}

func NewFormatter(format OutputFormat, styles *Styles) *Formatter {
    return &Formatter{format: format, styles: styles}
}

func (f *Formatter) FormatList(w io.Writer, items []domain.ItemInfo) {
    switch f.format {
    case FormatJSON:
        f.formatJSON(w, items)
    case FormatTable:
        f.formatTable(w, items)
    case FormatPlain:
        f.formatPlain(w, items)
    }
}

func (f *Formatter) FormatCreateResult(w io.Writer, result *domain.CreateResult) {
    // Commands always use human-readable format
    fmt.Fprintf(w, "Created %s at %s\n",
        f.styles.Success.Render(result.Name),
        f.styles.Dim.Render(result.Path))
}
```

### TTY Detection

Default output format depends on whether stdout is a terminal:

- TTY → table (styled)
- Piped → plain (no styling, no colors)
- `--output` flag overrides in both cases

```go
func DefaultOutputFormat() OutputFormat {
    if term.IsTerminal(int(os.Stdout.Fd())) {
        return FormatTable
    }
    return FormatPlain
}
```

### Stdout vs. Stderr Discipline

- **Stdout**: data output only. Results, JSON, tables. What gets piped.
- **Stderr**: everything else. Errors, progress, verbose output, spinners, prompts.

This rule is critical for piping. `myapp list --output json | jq '.[]'` must
not have progress messages or errors mixed into the JSON stream.

## Terminal Styling

Use `lipgloss` for all styling. Define styles centrally, reference everywhere.

```go
// presenter/styles.go
type Styles struct {
    Error   lipgloss.Style
    Warning lipgloss.Style
    Success lipgloss.Style
    Dim     lipgloss.Style
    Header  lipgloss.Style
    Bold    lipgloss.Style
}

func NewStyles() *Styles {
    return &Styles{
        Error:   lipgloss.NewStyle().Foreground(lipgloss.Color("9")).Bold(true),
        Warning: lipgloss.NewStyle().Foreground(lipgloss.Color("11")),
        Success: lipgloss.NewStyle().Foreground(lipgloss.Color("10")),
        Dim:     lipgloss.NewStyle().Foreground(lipgloss.Color("8")),
        Header:  lipgloss.NewStyle().Bold(true).Underline(true),
        Bold:    lipgloss.NewStyle().Bold(true),
    }
}
```

**Standard color mapping:**

| Color  | Usage                          |
| ------ | ------------------------------ |
| Red    | Errors, destructive actions    |
| Green  | Success confirmations          |
| Yellow | Warnings, caution              |
| Dim    | Verbose output, secondary info |
| Bold   | Headers, important values      |

Lipgloss handles color degradation automatically — no-color when stdout isn't
a TTY or when `NO_COLOR` environment variable is set.

## Error Formatting

Error formatting uses the `DomainError` interface for exit code dispatch and
`errors.As` for type-specific field access. See `references/error-handling.md`
for the full error architecture.

```go
// presenter/error_formatter.go
type ErrorFormatter struct {
    styles *Styles
}

func (f *ErrorFormatter) Format(w io.Writer, err error) {
    var domErr domain.DomainError
    if !errors.As(err, &domErr) {
        fmt.Fprintf(w, "%s %s\n", f.styles.Error.Render("Error:"), err.Error())
        return
    }

    // Dispatch to type-specific formatters
    f.formatByType(w, err)

    // Append suggestions from DomainError interface
    for _, s := range domErr.ErrorSuggestions() {
        fmt.Fprintf(w, "  %s %s\n", f.styles.Dim.Render("→"), s)
    }
}
```

## Verbose Output

Verbose output is user-facing progressive disclosure — "show me more detail
about what's happening." It is distinct from structured logging (`slog`):

| Concern       | Verbose Output          | Structured Logging        |
| ------------- | ----------------------- | ------------------------- |
| Audience      | User                    | Developer / operator      |
| Destination   | Stderr (styled)         | Stderr (structured)       |
| Controlled by | `-v` / `--verbose` flag | `MYAPP_DEBUG` / `--debug` |
| Content       | Progress, summaries     | Function calls, timings   |
| Styling       | lipgloss                | None (key=value)          |

```go
// presenter/verbose.go
type VerboseOutput struct {
    enabled bool
    writer  io.Writer
    style   lipgloss.Style
}

func NewVerboseOutput(enabled bool, w io.Writer, styles *Styles) *VerboseOutput {
    return &VerboseOutput{
        enabled: enabled,
        writer:  w,
        style:   styles.Dim,
    }
}

func (v *VerboseOutput) Info(format string, args ...any) {
    if !v.enabled { return }
    msg := fmt.Sprintf(format, args...)
    fmt.Fprintln(v.writer, v.style.Render(msg))
}

func (v *VerboseOutput) Step(format string, args ...any) {
    if !v.enabled { return }
    msg := fmt.Sprintf(format, args...)
    fmt.Fprintf(v.writer, "  %s %s\n", v.style.Render("→"), msg)
}
```

### Where VerboseOutput Is Used

VerboseOutput is **command-level only** — it is owned by the Presenter layer and
passed via `CommandConfig.Verbose`. Services do **not** receive VerboseOutput.
Commands emit progress messages before/after service calls:

```go
// In a command
cfg.Verbose.Info("Discovering project...")
project, err := cfg.Services.Discoverer.Discover(ctx, path)
cfg.Verbose.Step("Found project: %s", project.Name())
```

## Interactive Prompts

Interactive prompts use `huh` (for forms) or `bubbletea` (for custom
components). All prompts live in the presenter layer.

### Architecture: Cmd Decides, Presenter Prompts

The command checks whether prompting is needed. The presenter executes the
prompt. The service receives a decided request.

```go
// cmd/delete.go
RunE: func(cmd *cobra.Command, args []string) error {
    req := &domain.DeleteRequest{Name: args[0], Force: flagForce}

    if !req.Force && term.IsTerminal(int(os.Stdin.Fd())) {
        confirmed, err := cfg.Presenter.Confirm(
            fmt.Sprintf("Delete %s?", req.Name))
        if err != nil { return err }
        if !confirmed { return nil }
    }

    result, err := cfg.Services.Deleter.Delete(cmd.Context(), req)
    if err != nil { return err }
    cfg.Presenter.FormatDeleteResult(cmd.OutOrStdout(), result)
    return nil
},
```

### Simple Confirmation

```go
// presenter/interactive.go
func (p *Formatter) Confirm(message string) (bool, error) {
    var confirmed bool
    form := huh.NewForm(
        huh.NewGroup(
            huh.NewConfirm().
                Title(message).
                Value(&confirmed),
        ),
    ).WithOutput(os.Stderr)  // prompts go to stderr

    if err := form.Run(); err != nil {
        return false, err
    }
    return confirmed, nil
}
```

### Selection from List

```go
func (p *Formatter) SelectItem(items []domain.ItemInfo) (*domain.ItemInfo, error) {
    options := lo.Map(items, func(item domain.ItemInfo, _ int) huh.Option[int] {
        return huh.NewOption(item.Name, idx)
    })

    var selected int
    form := huh.NewForm(
        huh.NewGroup(
            huh.NewSelect[int]().
                Title("Select item").
                Options(options...).
                Value(&selected),
        ),
    ).WithOutput(os.Stderr)

    if err := form.Run(); err != nil {
        return nil, err
    }
    return &items[selected], nil
}
```

### Plan/Execute for Destructive Bulk Operations

For operations that affect multiple resources, use a two-phase approach:

```go
// cmd/prune.go
RunE: func(cmd *cobra.Command, args []string) error {
    // Phase 1: plan
    plan, err := cfg.Services.Pruner.Plan(cmd.Context(), req)
    if err != nil { return err }

    if len(plan.Items) == 0 {
        cfg.Presenter.FormatMessage(cmd.OutOrStdout(), "Nothing to prune")
        return nil
    }

    // Show plan
    cfg.Presenter.FormatPrunePlan(cmd.OutOrStdout(), plan)

    // Confirm
    if !flagForce && term.IsTerminal(int(os.Stdin.Fd())) {
        confirmed, err := cfg.Presenter.Confirm(
            fmt.Sprintf("Prune %d items?", len(plan.Items)))
        if err != nil { return err }
        if !confirmed { return nil }
    }

    // Phase 2: execute
    result, err := cfg.Services.Pruner.Execute(cmd.Context(), plan)
    if err != nil { return err }
    cfg.Presenter.FormatPruneResult(cmd.OutOrStdout(), result)
    return nil
},
```

### Scriptability Rule

**Every interactive command must be fully scriptable via flags.** If a command
can prompt, it can also be run with `--force` or explicit arguments that skip
the prompt. No command requires human interaction to complete.

Test both paths: interactive (TTY) and non-interactive (piped/scripted).

## Stage Progression

| Concern          | Stage 1          | Stage 2               | Stage 3              | Stage 4                                           |
| ---------------- | ---------------- | --------------------- | -------------------- | ------------------------------------------------- |
| Styling          | `lipgloss` basic | `lipgloss` styles     | Centralized `Styles` | Theme system                                      |
| Output format    | Plain only       | `--output` flag       | Table + JSON + plain | + custom formatters                               |
| Error formatting | `err.Error()`    | In `cmd/`             | Presenter layer      | Kind-driven suggest.                              |
| Verbose output   | `fmt.Fprintf`    | Basic `VerboseOutput` | Styled, injected     | Two channels: slog (debug) + VerboseOutput (user) |
| Interactive      | —                | —                     | `huh` confirmations  | bubbletea components                              |
| TTY detection    | —                | Basic                 | Format default       | Full degradation                                  |

## File Organization

```text
presenter/
  formatter.go        # Multi-format output (table, JSON, plain)
  error_formatter.go  # Error presentation with suggestions
  verbose.go          # VerboseOutput service
  styles.go           # Centralized lipgloss style definitions
  interactive.go      # Confirmations, selections (Stage 3+)
  interactive/        # bubbletea components (Stage 4)
    confirm.go
    selector.go
    spinner.go
```
