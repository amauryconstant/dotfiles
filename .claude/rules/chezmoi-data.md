# Chezmoi Data Files Reference

**Purpose**: Template data (YAML) for Go templates
**Location**: `.chezmoidata/`
**Access**: `{{ .key.subkey }}` in templates
**Trigger**: Changes trigger `run_onchange_*` scripts via hash

**See**: Root `CLAUDE.md` for core standards

---

## Data Files Overview

| File | Purpose | Template Access |
|------|---------|-----------------|
| `packages.yaml` | Package management (Arch + Flatpak) | `{{ .packages.* }}` |
| `ai.yaml` | AI model configuration | `{{ .ai.* }}` |
| `extensions.yaml` | VSCode extensions | `{{ .extensions.* }}` |
| `globals.yaml` | Global env vars (XDG, apps, boot, timeshift) | `{{ .globals.* }}` |

**Note**: All color theming uses theme system from `~/.config/themes/current/`

---

## Template Variable Patterns

### Built-in (chezmoi)

```go
.chezmoi.os, .chezmoi.arch, .chezmoi.hostname, .chezmoi.username
.chezmoi.sourceDir, .chezmoi.homeDir
```

### User-defined (`.chezmoi.yaml.tmpl`)

```go
.fullname, .firstname, .workEmail, .personalEmail
.privateServer, .chassisType  # laptop/desktop
.terminalFont                  # FiraCode Nerd Font (default), Iosevka Nerd Font, Geist Mono Nerd Font
```

### Data files (`.chezmoidata/`)

```go
.packages.install.arch     # Package lists with strategies
.extensions.code          # VSCode extension arrays
.globals.applications.*   # Default apps (EDITOR, VISUAL, BROWSER)
.globals.xdg.*           # XDG Base Directory paths
```

### Common Patterns

```go
# Direct access
{{ .packages.install.arch }}

# Range iteration
{{ range .extensions.code }}
  {{ . }}
{{ end }}

# Nested access
{{ .globals.applications.terminal }}

# Conditional
{{ if eq .chezmoi.os "linux" }}

# Filters
{{ .firstname | lower }}
{{ .privateServer | replace "www" "nextcloud" }}

# Defaults
{{ $var := .value | default "fallback" }}

# Whitespace control
{{- includeTemplate "log_step" "message" -}}
```

---

## Hash-Triggered Scripts

Changes to data files trigger specific `run_onchange_*` scripts:

| Data File | Trigger Script | Timing |
|-----------|----------------|--------|
| `packages.yaml` | `run_onchange_before_sync_packages.sh.tmpl` | BEFORE file application |
| `extensions.code` | `run_onchange_after_install_extensions.sh.tmpl` | AFTER file application |
| `ai.models` | `run_onchange_after_install_ai_models.sh.tmpl` | AFTER file application |

**Hash detection**: Scripts include `{{ .packages | toJson | sha256sum }}` comment. When data changes, hash changes, script re-runs.

---

## Validation Commands

```bash
# View all template data
chezmoi data

# View specific key
chezmoi data | jaq -r '.packages.install.arch'

# Test template variable access
chezmoi execute-template < template.tmpl
```

---

## Common Data Queries

```bash
# Check NVIDIA driver detection
chezmoi data | jaq -r '.nvidiaDriverType'

# View terminal font
chezmoi data | jaq -r '.terminalFont'

# List all packages
chezmoi data | jaq -r '.packages.install.arch[]'

# View globals
chezmoi data | jaq '.globals'
```
