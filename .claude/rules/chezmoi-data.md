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
| `ai.yaml` | AI server host/port (llama-swap `--listen`) | `{{ .ai.server.* }}` |
| `globals.yaml` | Global env vars (XDG, apps, boot, timeshift) | `{{ .globals.* }}` |
| `services.yaml` | Service enablement (system services, user services, timers) | `{{ .services.* }}` |
| `features.yaml` | Optional feature toggles (voxtype, restic) | `{{ .features.* }}` |
| `boot.yaml` | Boot config (GPU KMS, power management, hibernation) | `{{ .boot.* }}` |
| `gsettings.yaml` | GSettings font config (schema, sizes, extra_settings) | `{{ .gsettings.* }}` |
| `developer.yaml` | Developer env (shell, mise) | `{{ .developer.* }}` |
| `firefox_policies.json` | Firefox policy config (extensions, settings) | `{{ .firefox_policies.* }}` |

**Note**: All color theming uses theme system from `~/.config/themes/current/`
**Note**: User service files live in `private_dot_config/systemd/user/` (e.g. `llama-swap.service`, `darkman.service`)

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
.privateServer, .chassisType        # laptop/desktop
.nvidiaDriverType                    # modern|legacy — auto-detected from GPU at init (override: NVIDIA_DRIVER_OVERRIDE env)
.nvidiaGpuDetected                   # detected GPU name string
```

`.nvidiaDriverType`/`.nvidiaGpuDetected` are computed in `.chezmoi.yaml.tmpl` (not stored in `.chezmoidata/`) and consumed by `run_once_before_001_preflight...` and `run_onchange_before_sync_packages` to pick the right driver package.

### Data files (`.chezmoidata/`)

```go
.packages.install.arch     # Package lists with strategies
.globals.applications.*   # Default apps (EDITOR, VISUAL, BROWSER)
.globals.xdg.*           # XDG Base Directory paths
.globals.guiFont          # "Inter" — GTK/Qt/Waybar/Wofi/Hyprlock
.globals.terminalFont     # "GeistMono Nerd Font" — terminal/code/fontconfig
.services.user_timers     # List of user timers with name/enabled/start fields
.features.voxtype.enabled # Boolean toggle for Voxtype setup
.boot.gpu.kms             # Boolean: enable NVIDIA KMS modeset
.boot.hibernation.enabled # Boolean: configure hibernation
.gsettings.font_schema    # GSettings schema string
.gsettings.sizes.gui      # Font size integer
.developer.shell          # Default shell (e.g. zsh)
.developer.mise.enabled   # Boolean: enable mise setup
```

Fonts are referenced as `.globals.terminalFont`/`.globals.guiFont` (not top-level `.terminalFont`).

---

## Hash-Triggered Scripts

Changes to data files trigger specific `run_onchange_*` scripts:

| Data File | Trigger Script | Timing |
|-----------|----------------|--------|
| `packages.yaml` | `run_onchange_before_sync_packages.sh.tmpl` | BEFORE file application |
| `firefox_policies` | `run_onchange_after_install_extensions.sh.tmpl` | AFTER file application |
| `globals.timeshift` | `run_onchange_after_configure_timeshift_retention.sh.tmpl` | AFTER file application |

**Hash detection**: Scripts include `{{ .packages | toJson | sha256sum }}` comment. When data changes, hash changes, script re-runs.

---

## Inspecting Data

`chezmoi data` dumps the full merged data tree (built-in + `.chezmoi.yaml.tmpl` + `.chezmoidata/`). Pipe to `jaq` to check a resolved value, e.g. `chezmoi data | jaq -r '.nvidiaDriverType'` or `chezmoi data | jaq -r '.globals.terminalFont'`.
