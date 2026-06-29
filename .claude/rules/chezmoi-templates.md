# Chezmoi Template System Reference

**Purpose**: Go template syntax for dynamic configs
**Location**: `.chezmoitemplates/` (includes), any `*.tmpl` file
**Language**: Go templates (text/template + Sprig)

**See**: Root `CLAUDE.md` for core standards
**See**: `.claude/rules/chezmoi-data.md` for template variables

---

## Quick Commands

| Task | Command | Purpose |
|------|---------|---------|
| Test template syntax | `chezmoi execute-template < file.tmpl` | Validate Go template |
| View data | `chezmoi data` | All template vars |
| Preview output | `chezmoi cat path/to/file` | Final rendered |
| Validate script | `bash -n script.sh.tmpl` | Shell syntax |
| Test modify_manager | `chezmoi cat path/to/target` | Preview merge |
| Check modify syntax | `chezmoi_modify_manager --help-syntax` | Directive reference |

---

## Available Template Includes

**Log Templates** - Located in `.chezmoitemplates/`:

| Template | Output | Use Case |
|----------|--------|----------|
| `log_start` | "🚀 message" | Script start |
| `log_step` | "→ message" | Step execution |
| `log_success` | "✅ message" | Success state |
| `log_error` | "❌ message" | Error state |
| `log_warning` | "⚠️ message" | Warning |
| `log_info` | "ℹ️ message" | Information |
| `log_progress` | "⏳ message" | In progress |
| `log_debug` | "🐛 message" | Debug output |
| `log_skip` | "⏭️ message" | Skipped action |
| `log_complete` | "🎉 message" | Script complete |

**Utility Templates**:
- (Currently none - placeholder for future)

---

## Usage Patterns

### Basic Logging (MANDATORY for .chezmoiscripts/)

```go
{{ includeTemplate "log_start" "Installing packages..." }}
{{ includeTemplate "log_step" "Updating pacman cache..." }}
{{ includeTemplate "log_success" "Package installation complete" }}
```

### Conditional Logging

```go
{{ if .condition }}
  {{ includeTemplate "log_step" "Processing..." }}
{{ else }}
  {{ includeTemplate "log_skip" "Skipping..." }}
{{ end }}
```

### Whitespace Control

```go
{{- includeTemplate "log_step" "Processing..." -}}
```

**Effect**: Removes whitespace before (`{{-`) and/or after (`-}}`)

---

## Template Standards

### MUST Follow

- **Use template logging** (not echo) in `.chezmoiscripts/` files
- **Control whitespace** with `{{-` and `-}}`
- **Validate syntax**: `chezmoi execute-template < file.tmpl`
- **Test output**: `chezmoi cat path/to/target`

### Script Template Structure

```bash
#!/usr/bin/env sh

# Script: [filename]
# Purpose: [clear description]
# Requirements: Arch Linux, [dependencies]

{{ includeTemplate "log_start" "[description]" }}

set -euo pipefail

# Implementation (NO main function)
# Use log templates for ALL output

{{ includeTemplate "log_complete" "[message]" }}
```

---

## Error Handling in Templates

### Template Validation

```go
{{ if not .firstname }}
{{   fail "firstname variable is required" }}
{{ end }}
```

### Safe Defaults

```go
{{ $server := .privateServer | default "localhost" }}
{{ $font := .globals.terminalFont | default "GeistMono Nerd Font" }}
```

### Conditional Blocks

```go
{{ if eq .chezmoi.os "linux" }}
  # Linux-specific config
{{ end }}

{{ if eq .chassisType "laptop" }}
  # Laptop-specific config
{{ end }}
```

---

## Validation

Templates render with full Sprig support (string functions, defaults, conditionals) — consult Sprig docs for function reference. The repo-specific validation chain is:

```bash
chezmoi execute-template < file.tmpl              # render; shows exact Go-template errors
chezmoi execute-template < script.sh.tmpl | shellcheck -   # lint rendered shell (templates render to shell)
chezmoi cat path/to/target                        # final applied output (templates + modify_manager)
```

A `.sh.tmpl` whose source passes `bash -n` can still render invalid shell — always validate the rendered output, not the source.
