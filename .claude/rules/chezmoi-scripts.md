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

1. **`run_once_before_*`** (000-008)
   - 000: System prerequisites
   - 001: **Hyprland session validation** (prevents crashes)
   - 002-006: Setup tasks
   - 007: Default theme structure (BEFORE file application — configs reference `~/.config/themes/current/`)
   - 008: Hyprland plugins + monitor automation services

2. **`run_onchange_before_*`** (sync_packages)
   - Runs on first install AND package changes

3. **File application**
   - Chezmoi applies configs

4. **`run_once_after_*`** (001-008, 010-012, 999)
   - 001-003: Configuration tasks
   - 004: Clone wallpapers repo via SSH (theming source) — must precede 005, whose initial wallpaper-cycle trigger needs the repo already present
   - 005-008, 010-011: Configuration tasks
   - 008: **Hyprland config validation** (post-install safety check)
   - 999: SSH remote switch

5. **`run_onchange_after_*`** (hash-based, any order)
   - Extensions, bat cache, plymouth theme, Timeshift retention

**Trust execution order**: chezmoi runs scripts in order and aborts on the first failure, so a later script can assume earlier ones succeeded — e.g. `002_install_package_manager` provisions paru/yq/gum, so `003+` and all `run_onchange_before` package work assume those binaries exist. Don't re-check prerequisites a numerically-earlier script already guarantees.

---

## Current Scripts

### run_once_before_*

| Number | Script | Purpose |
|--------|--------|---------|
| 000 | backup_archinstall_configs | Preflight checks (sudo, git, network, pacman) |
| 001 | preflight_and_session_validation | Hyprland session validation + NVIDIA driver migration check |
| 002 | install_package_manager | Package manager setup + dependencies (paru, yq, gum) |
| 003 | configure_locale | Locale configuration |
| 004 | create_necessary_directories | Directory creation |
| 005 | instantiate_encryption_key | Encryption key setup |
| 006 | install_chezmoi_modify_manager | chezmoi_modify_manager install |
| 007 | setup_default_theme | Theme directory structure + symlinks (must run before file application) |
| 008 | setup_hyprland_plugins | hyprsplit via hyprpm + HyprDynamicMonitors/hyprwhenthen services |

### run_onchange_before_*

| Script | Purpose | Trigger |
|--------|---------|---------|
| sync_packages | Package sync (Arch + Flatpak); also auto-seeds the AUR supply-chain trust DB on the first successful sync (bootstrap → established, equivalent to `package-manager approve --seed`) | First install AND `packages.yaml` changes |

**Timing**: Runs BEFORE file application (ensures packages exist for config scripts)

### run_once_after_*

| Number | Script | Purpose |
|--------|--------|---------|
| 001 | configure_developer_tools | CLI generation, git tools |
| 002 | configure_system_services | System services (Docker, etc.) |
| 003 | setup_network_printer | Network printer |
| 004 | clone_wallpapers_repo | Clone `~/.config/wallpapers` via SSH (theming source for random-wallpaper); must run before 005, whose initial wallpaper-cycle trigger needs the repo present |
| 005 | enable_user_timers | Enable systemd timers (wallpaper, health, backup) |
| 006 | configure_boot_system | Boot system (Plymouth, GRUB) |
| 007 | setup_darkman | Darkman solar auto-theme service |
| 008 | validate_hyprland_config | **Hyprland config validation** (post-install safety check) |
| 010 | configure_spicetify | Spicetify for Flatpak Spotify (skips if not installed) |
| 011 | setup_optional_services | Voxtype STT + Restic home backup init (skips if not installed) |
| 012 | migrate_xdg_directories | Migrate legacy `~/.npm` etc. to XDG locations |
| 999 | switch_to_ssh_remote | SSH remote switch |

**Renumbering note (2026-09-11)**: 004-011 shifted to 005-012 to insert `clone_wallpapers_repo` at 004 with correct ordering. Renumbering an already-executed `run_once_*` script makes chezmoi treat it as new — all 8 shifted scripts (005-012) re-run once on the next `chezmoi apply` on any machine that had already provisioned under the old numbering. All are idempotent (checked individually before this change): `configure_boot_system` (006) guards every step and skips the `mkinitcpio -P` rebuild when nothing changed; `migrate_xdg_directories` (012) no-ops when source directories are already migrated; the rest re-enable/re-check already-satisfied state.

### run_onchange_after_*

| Script | Purpose | Trigger |
|--------|---------|---------|
| configure_timeshift_retention | Timeshift retention + timer config | `globals.timeshift` changes |
| configure_gsettings | GSettings font config | `globals.guiFont`/`globals.terminalFont`/`gsettings` changes |
| configure_voxtype | Voxtype STT setup | Installed voxtype version or `features.voxtype` changes |
| install_extensions | Firefox policies | `firefox_policies` changes |
| configure_firefox_egl_workaround | Route Firefox desktop entries through the `bin/executable_firefox` egl-wayland2 wrapper | Installed `firefox`/`firefox-esr`/`egl-wayland2` versions change — see `_research/FIREFOX_NVIDIA_EGL_DEADLOCK.md` |
| rebuild_bat_cache | Bat syntax highlighting cache | Theme changes |
| update_plymouth_theme | Plymouth theme | Theme changes |

---

## Package Installation Strategy

**Single script approach**: `run_onchange_before_sync_packages.sh.tmpl` handles both:

- **First install**: Script runs (no prior hash) → installs all packages
- **Updates**: Script re-runs when `packages.yaml` changes (hash-triggered sync)

**Self-contained, by design**: the script shells out to `pacman`/`paru`/`flatpak` directly and
**never calls `package-manager`** — it runs BEFORE file application, when `lib/scripts` is not yet
on disk. Its own header says so.

🚨 **Deleting a package from `packages.install` does NOT uninstall it.** The script installs what
is declared and never prunes, so a package dropped from the list just stops being installed on new
machines; every machine that already has it keeps it. **Retiring a package is a manual
`paru -Rns <pkg>`.**

`packages.delete` is **not** that mechanism. It is one-time migration cleanup — carrying a
now-wrong package off a machine that was provisioned before the change (`yay` before paru, the
kitty entries at the KDE→GTK migration). It is a poor fit for ongoing retirement: the hash covers
all of `.packages`, so the block re-runs on *every* packages.yaml edit and no entry ever expires,
making the list an unbounded denylist that will silently re-remove a package you deliberately
reinstall.

The block **filters to what is installed** before calling `paru -Rns`, and that guard is
load-bearing: pacman aborts the whole transaction on one unknown target, so a single spent entry
used to stop every other removal while `2>/dev/null || true` reported success. That is exactly what
happened — `yay` went absent, and `kitty-shell-integration`/`kitty-terminfo` then sat on the list
from 2025-11-12 until 2026-09-21 without being removed. With the filter in place a spent entry is
harmless, so entries can stay as a record of the migration they came from.

### Retiring a package

Two manual steps, in order:

```sh
# 1. drop it from .chezmoidata/packages.yaml (declarative source of truth)
# 2. remove it from this machine:
package-manager sync --prune
```

`sync --prune` diffs `packages.yaml` against `~/.local/state/package-manager/package-state.yaml`,
prints every package installed but no longer declared, and asks before removing anything
(`_sync_prune_orphans`). `package-manager update` — and therefore topgrade — runs it too, so a
retirement also surfaces on the normal update path. Step 1 alone uninstalls nothing.

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

`run_onchange_*` scripts re-run only when their rendered content changes. Embed the watched data in a hash comment so editing that data re-triggers the script:

```bash
#!/usr/bin/env sh
# Hash: {{ .packages | toJson | sha256sum }}
```

The hashed expression must cover exactly the data the script depends on — too narrow and changes are missed, too broad and the script re-runs needlessly. See the table above for which data each script watches.
