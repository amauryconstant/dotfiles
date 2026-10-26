---
paths:
  - ".chezmoiscripts/**"
---

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
| Retry-until-done | `run_after_*` | Work that can fail transiently and must retry | Every apply; script self-skips |

---

## Execution Order

1. **`run_once_before_*`** (000-007)
   - 000: System prerequisites
   - 001: **Hyprland session validation** (prevents crashes)
   - 002-006: Setup tasks
   - 007: Default theme structure (BEFORE file application — configs reference `~/.config/themes/current/`)
   - (008 retired 2026-10-06: hyprsplit is a `.chezmoiexternal.yaml` git-repo, monitor services are in `services.yaml` — it ran before packages and aborted fresh installs)

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

5. **`run_onchange_after_*`** (hash-based; alphabetical by name like every phase —)
   - Extensions, bat cache, boot theme, Timeshift retention

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

### run_onchange_before_*

| Script | Purpose | Trigger |
|--------|---------|---------|
| sync_packages | Renders the declared set (enabled modules + NVIDIA choice) and runs `package-manager sync` from the source tree: installs it, removes what the previous sync declared but this one doesn't, tripwire-gates AUR; auto-seeds the trust DB on the first sync (bootstrap → established) | First install, `packages.yaml` change, or an edit to the tool (`executable_package-manager`, `lib/sync.sh`, `lib/tripwire.sh`) |

**Timing**: Runs BEFORE file application (ensures packages exist for config scripts)

### run_once_after_*

| Number | Script | Purpose |
|--------|--------|---------|
| 001 | configure_developer_tools | Default shell, git merge driver |
| 002 | configure_system_services | System services (Docker, etc.) |
| 003 | setup_network_printer | Network printer |
| 004 | clone_wallpapers_repo | Clone `~/.config/wallpapers` via SSH (theming source for random-wallpaper); must run before 005, whose initial wallpaper-cycle trigger needs the repo present |
| 005 | enable_user_timers | Enable systemd timers (wallpaper, health, backup) |
| 006 | configure_boot_system | Boot system (NVIDIA, Plymouth, SDDM, hibernation, UKI presets; rEFInd via `refind-install` on desktop only, plus best-effort Bazzite ESP restore: Fedora loader + grub stub, fstab UUID, stale UEFI entries) |
| 007 | setup_darkman | Darkman solar auto-theme service |
| 008 | validate_hyprland_config | **Hyprland config validation** (post-install safety check) |
| 010 | configure_spicetify | Spicetify for Flatpak Spotify (skips if not installed) |
| 011 | setup_optional_services | Restic home backup init (skips if not installed) |
| 012 | migrate_xdg_directories | Migrate legacy `~/.npm` etc. to XDG locations |
| 999 | switch_to_ssh_remote | SSH remote switch |

**Renumbering note (2026-09-11)**: 004-011 shifted to 005-012 to insert `clone_wallpapers_repo` at 004 with correct ordering. Renumbering an already-executed `run_once_*` script makes chezmoi treat it as new — all 8 shifted scripts (005-012) re-run once on the next `chezmoi apply` on any machine that had already provisioned under the old numbering. All are idempotent (checked individually before this change): `configure_boot_system` (006) guards every step and skips the `mkinitcpio -P` rebuild when nothing changed; `migrate_xdg_directories` (012) no-ops when source directories are already migrated; the rest re-enable/re-check already-satisfied state.

### run_onchange_after_*

| Script | Purpose | Trigger |
|--------|---------|---------|
| configure_timeshift_retention | Timeshift first-run config seed (BTRFS, no GUI) + retention + timer config | `globals.timeshift` changes |
| configure_gsettings | GSettings font config | `globals.guiFont`/`globals.terminalFont`/`gsettings` changes |
| configure_voxtype | Voxtype STT setup | Installed voxtype version or `features.voxtype` changes |
| configure_kanata | Kanata keyboard remapper (groups, uinput udev/module, service) — laptop only | `features.kanata` or `.chassisType` changes |
| configure_ergodox_hidraw | udev `uaccess` rule for the ErgoDox raw-HID interface (live layer in the bar) | `keyboard_firmware` enable flag or the rule version changes |
| merge_claude_settings | jaq-merge `claude/create_settings.json` into the live `~/.config/claude/settings.json` | The seed file changes |
| install_extensions | Firefox policies | `firefox_policies` changes |
| configure_firefox_egl_workaround | Route Firefox desktop entries through the `bin/executable_firefox` egl-wayland2 wrapper | Installed `firefox`/`firefox-esr`/`egl-wayland2` versions change — see `_research/FIREFOX_NVIDIA_EGL_DEADLOCK.md` |
| apply_starship_config | Runs `theme-apply-starship`; first install, and an apply that edits the base reaches the generated file | `starship/base.toml` or any `themes/*/starship.toml` changes |
| rebuild_bat_cache | Bat syntax highlighting cache | Theme changes |
| sync_mise_tools | `mise install` for the tools in `.chezmoidata/mise.yaml` (rendered to `conf.d/tools.toml`). Install only: dropping a tool does not uninstall it — `mise prune` by hand | `mise.yaml` changes |
| render_boot_theme | Renders `.boot/` (palette `.boot/colors.sh`, `.boot/render.sh`) and installs the SDDM greeter theme, the Plymouth theme (`plymouth-set-default-theme -R`, which rebuilds the UKI) and, desktop only, the rEFInd theme + one `include` line in `refind.conf`. Owns the Plymouth/SDDM theme selection; 006 only installs and enables | Any `.boot/` source, `globals.{boot,plymouth,sddm}`, fonts, or the lock geometry in `Config.qml.tmpl` |

---

### run_after_*

Runs on **every** apply, so it must be cheap and idempotent. Use it only where
`run_onchange_*` is wrong: a run_onchange script that exits 0 on failure is recorded as
done and is never retried, so network-dependent work would stay undone until its inputs
change. A `run_after_` script guards itself with a stamp and exits early once satisfied.

| Script | Purpose | Skips when |
|--------|---------|------------|
| build_egl_wayland2_patched | Builds egl-wayland2 from a pinned upstream commit plus `.patches/egl-wayland2-bounded-frame-wait.patch` into `~/.local/lib/egl-wayland2-patched`; only the Firefox wrapper and `quickshell.service` use it, through `desktop/egl-wayland2-patched`. Verifies the patch landed (symbol check) before writing `.stamp`. A failed build warns, exits 0 and installs nothing — the wrapper falls back to XWayland and the next apply retries | `.stamp` matches pin + patch hash, or egl-wayland2 is absent |

---

## Package Installation Strategy

**Single script, one tool**: `run_onchange_before_sync_packages.sh.tmpl` renders the declared
set and calls `package-manager sync` **from `{{ .chezmoi.sourceDir }}`** (it runs BEFORE file
application, so `~/.local/lib/scripts` may not exist; none of the tool's files are templates, so
the source copy is runnable as-is). `UI_LIB` points at the source `executable_gum-ui.sh`.

- **First install**: no prior hash → installs everything, records `applied.txt`, removes nothing.
- **Later runs**: re-run when `.packages` or the tool's hashed files change.
- **NVIDIA**: the template picks `graphics_drivers_legacy` or `_modern` from `.nvidiaDriverType`,
  ignoring their `enabled` flags.

### Retiring a package

Delete its line from `.chezmoidata/packages.yaml`; the next apply removes it. Removal is
`(applied − declared) ∩ installed` (see `package-manager/CLAUDE.md`), so only packages a previous
sync declared are ever removed. Exceptions: packages retired *before* `applied.txt` existed (manual
`paru -Rns` once), and anything over the 10-removal guard (`PACKAGE_MANAGER_ALLOW_REMOVE=1`).
A retired package that something else still depends on stays installed as a dependency.

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
