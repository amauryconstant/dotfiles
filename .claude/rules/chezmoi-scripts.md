# Chezmoi Lifecycle Scripts Reference

**Purpose**: Automated setup, configuration, and maintenance scripts
**Location**: `.chezmoiscripts/`
**Types**: `run_once_*`, `run_onchange_*`
**Standards**: See `private_dot_local/lib/scripts/CLAUDE.md` for script standards

**See**: Root `CLAUDE.md` for core standards

---

## Script Types

| Type | Prefix | Purpose | Execution |
|------|--------|---------|-----------|
| Setup | `run_once_before_*` | System preparation | Before file application |
| Configuration | `run_once_after_*` | Service setup | After file application |
| Content-driven | `run_onchange_*` | Data file changes | Hash-triggered |

---

## Execution Order

1. **`run_once_before_*`** (000-006)
   - 000: System prerequisites
   - 001: **Hyprland session validation** (prevents crashes)
   - 002-006: Setup tasks

2. **`run_onchange_before_*`** (sync_packages)
   - Runs on first install AND package changes

3. **File application**
   - Chezmoi applies configs

4. **`run_once_after_*`** (001-010, 999)
   - 001-009: Configuration tasks
   - 010: **Hyprland config validation** (post-install safety check)
   - 999: SSH remote switch

5. **`run_onchange_after_*`** (hash-based, any order)
   - Extensions, AI models, bat cache, plymouth theme

**Trust execution order**: Previous scripts succeeded (chezmoi stops on failure). Don't add redundant checks.

---

## Current Scripts (22 total)

### run_once_before_* (7)

| Number | Script | Purpose |
|--------|--------|---------|
| 000 | backup_archinstall_configs | Preflight checks (sudo, git, network, pacman) |
| 001 | preflight_checks | Hyprland session validation + NVIDIA driver migration check |
| 002 | validate_hyprland_session | Package manager setup + dependencies (paru, yq, gum) |
| 003 | install_package_manager | Locale configuration |
| 004 | configure_locale | Directory creation |
| 005 | create_necessary_directories | Encryption key setup |
| 006 | instantiate_encryption_key | chezmoi_modify_manager install |

### run_onchange_before_* (1)

| Script | Purpose | Trigger |
|--------|---------|---------|
| sync_packages | Package sync (Arch + Flatpak) | First install AND `packages.yaml` changes |

**Timing**: Runs BEFORE file application (ensures Docker, systemd services exist for config scripts)

### run_once_after_* (11)

| Number | Script | Purpose |
|--------|--------|---------|
| 001 | generate_and_config_cli | CLI generation |
| 002 | configure_system_services | System services |
| 003 | setup_network_printer | Network printer |
| 004 | configure_git_tools | Git tools |
| 005 | setup_wallpaper_timer | Wallpaper timer |
| 006 | configure_boot_system | Boot system |
| 007 | setup_default_theme | Default theme setup |
| 008 | setup_darkman | Darkman service |
| 009 | configure_timeshift_retention | Timeshift retention policy |
| 010 | validate_hyprland_config | Hyprland config validation |
| 999 | switch_to_ssh_remote | SSH remote switch |

### run_onchange_after_* (4)

| Script | Purpose | Trigger |
|--------|---------|---------|
| install_extensions | VSCode extensions | `extensions.code` changes |
| install_ai_models | Ollama models | `ai.models` changes |
| rebuild_bat_cache | Bat syntax highlighting cache | Theme changes |
| update_plymouth_theme | Plymouth theme | Theme changes |

---

## Package Installation Strategy

**Single script approach**: `run_onchange_before_sync_packages.sh.tmpl` handles both:

- **First install**: Script runs (no prior hash) → installs all packages
- **Updates**: Script re-runs when `packages.yaml` changes (hash-triggered sync)

**Package manager integration**: Calls `package-manager sync --prune`
- Handles Arch and Flatpak packages
- Respects version constraints
- Handles conflicts
- Validates packages

**See**: `private_dot_local/lib/scripts/system/CLAUDE.md` for package-manager details

---

## Script Numbering

- **run_onchange**: No numbering (hash-tracked, order independent)
- **run_once**: Use next available number
- **999**: Reserved for finalization (SSH remote switch)

---

## Script Usage Guidelines

**DO use .chezmoiscripts/ for**:
- ✅ Initial system setup
- ✅ Tool installation
- ✅ Configuration setup
- ✅ Dotfiles-driven changes

**DO NOT use .chezmoiscripts/ for**:
- ❌ System updates (use manual tools like topgrade)
- ❌ Ongoing maintenance (use CLI tools)
- ❌ Regular monitoring (use CLI tools)
- ❌ User-initiated tasks (use CLI functions)

---

## Hash-Based Change Detection

**Pattern** in `run_onchange_*` scripts:

```bash
#!/usr/bin/env sh
# Hash: {{ .packages | toJson | sha256sum }}

{{ includeTemplate "log_start" "Syncing packages..." }}
# Script implementation
{{ includeTemplate "log_complete" "Package sync complete" }}
```

**How it works**:
1. Chezmoi calculates hash of data
2. Hash stored in script metadata
3. Data changes → hash changes → script re-runs
4. No data changes → hash same → script skipped
