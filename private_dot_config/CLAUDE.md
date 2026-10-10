# XDG Configuration - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/`
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: XDG Base Directory config (`~/.config/`)
- **Target**: Desktop environment, applications, shell configs
- **Structure**: Category-based subdirectories
- **Templates**: Many `.tmpl` files use Go templates

## XDG Structure

**Config categories**:

| Directory | Purpose | Has CLAUDE.md? |
|-----------|---------|----------------|
| `hypr/` | Hyprland compositor | ✅ Yes |
| `shell/` | POSIX shell layer + Zephyr patterns | ✅ Yes |
| `zsh/` | Zsh-specific config (antidote, plugins, functions) | ✅ Yes |
| `systemd/user/` | User services | ✅ Yes |
| `wireplumber/` | PipeWire session policy (Bluetooth profile, device defaults) | ✅ Yes |
| `Nextcloud/` | Nextcloud client | ✅ Yes |
| `git/` | Git config | ✅ Yes |
| `themes/` | Theme system | ✅ Yes |
| `waybar/` | Status bar | ✅ Yes |
| `quickshell/` | Quickshell desktop shell — the active one (Waybar stack is the fallback) | ✅ Yes |
| `uwsm/` | Session environment (`env.tmpl`) — exported to Hyprland AND systemd units | ❌ No |
| `wofi/` | Application launcher | ✅ Yes |
| `wlogout/` | Power menu | ✅ Yes |
| `swaync/` | Notification daemon | ✅ Yes |
| `btop/` | System monitor (themed) | ✅ Yes |
| `hyprdynamicmonitors/` | Monitor profile manager | ✅ Yes |
| `hyprwhenthen/` | Event-driven window automation | ✅ Yes |
| `jj/` | Jujutsu VCS config | ✅ Yes |
| `dotfiles/` | Hook system + extra bindings | ✅ Yes |
| `opencode/` | opencode TUI config (theme-managed, `modify_opencode.jsonc`) | ❌ No |
| `claude/` | Claude Code config (`create_private_settings.json` — seeds a missing file, `run_onchange_after_merge_claude_settings` jaq-merges it into an existing one; caveman owns `env`/`hooks`; `accounts/<name>.json` — `ccp -a` overrides, e.g. ringstone) | ❌ No |
| `bat/` | Syntax highlighting (symlink-only, themed) | ❌ No |
| `broot/` | File tree (conf.hjson + verbs.hjson + theme symlink) | ❌ No |
| `lazygit/` | Git TUI (symlink-only, themed) | ❌ No |
| `yazi/` | File manager (symlink-only, themed) | ❌ No |
| `ghostty/` | Terminal config (template) | ❌ No |
| `starship/base.toml` | Prompt base; joined with the theme palette into `starship.toml` | ❌ No |
| `topgrade.toml.tmpl` | Update tool | ❌ No |

## Desktop Environment

### Hyprland Compositor (`hypr/`)
- Modular config in `conf/`; the `.lua` tree is live (cutover 2026-09-01), `.conf` twins kept as fallback
- Templates: `hyprland.{conf,lua}.tmpl`, `hyprlock.conf.tmpl`, `hypridle{,-nolock}.conf.tmpl`, `conf/monitor.{conf,lua}.tmpl`, `conf/bindings/applications.{conf,lua}.tmpl`, `conf/bindings/voice.{conf,lua}.tmpl`
- Theme integration via `source ~/.config/themes/current/hyprland.conf`

### Desktop Components (Consolidated)

**Theme system** (`themes/`):
- Variants: Catppuccin (latte/mocha), Rose Pine (dawn/moon), Gruvbox (light/dark), Solarized (light/dark)
- Semantic variables (backgrounds, foregrounds, accents)
- Desktop apps: Waybar, Swaync, Wofi, Wlogout, Hyprland, Ghostty, Hyprlock (CSS/conf files)
- Quickshell reads the **same** `colors.sh` the shell scripts do — see `themes/CLAUDE.md` →
  "Two vocabularies, one palette"
- CLI tools: bat, broot, btop, lazygit, starship, yazi
- Switching: `theme switch <name>`, darkman (solar auto), keybindings
- See: `themes/CLAUDE.md`

**Quickshell shell** (`quickshell/`) — **the active desktop shell**:
- One QML tree owns bar, OSDs, launcher, power menu, notifications, popovers and every picker
- Gated by `features.quickshell_shell` (**on**) and `features.quickshell_notifications` (**on**)
- See: `quickshell/CLAUDE.md`, `.claude/rules/quickshell-qml.md`

**Waybar status bar** — **fallback bar, not the active one**:
- Deployed only when `features.quickshell_shell` is off; `.chezmoiignore` picks exactly one of
  `hypr/conf.d/{quickshell,waybar}.{lua,conf}`, because the two cannot stack
- Modules (workspaces, clock, CPU, memory, network, etc.)
- Theme integration via `@import "themes/current/waybar.css"`
- Files: `config.tmpl` (JSON5), `style.css.tmpl` (CSS)
- Reload: `killall -SIGUSR2 waybar`

**Wofi launcher** — **fallback only**:
- Replaced 2026-09-09 by the Quickshell launcher, dmenu picker and clipboard picker
- Still reached when `desktop/quickshell-menu` cannot open the socket, and by `SUPER+D` /
  `SUPER+C` in the Waybar branch
- Files: `config` (static), `style.css.tmpl` (themed)
- Theme: CSS import from `themes/current/wofi.css`

## Shell Configuration

**Zsh** (`zsh/`):
- Antidote plugin manager + Zephyr framework
- Fish-like features (autosuggestions, syntax highlighting)
- See: `zsh/CLAUDE.md`

**Common shell** (`shell/`):
- POSIX-compliant layered config
- Files: env, login.tmpl, interactive, logout
- Shared between Zsh and Bash

## Application Configs

**Nextcloud** (`Nextcloud/`):
- chezmoi_modify_manager (separates settings from state)
- Template: `modify_nextcloud.cfg.tmpl`

**Git** (`git/`):
- Config template: `config.tmpl`
- Attributes: `.gitattributes` (template merge driver)
- Hooks: Pre-commit, etc.

**Jujutsu** (`jj/`):
- Version control system config
- Files: `config.toml.tmpl`
- Delta integration via git config inheritance
- See: `jj/CLAUDE.md`

**Claude Code ringstone account** (`claude/accounts/ringstone.json`, layered by `ccp -a ringstone`):
- **No `permissions.blockReadsOutsideWorkingDirectories`**: under it, any Bash command touching a
  path outside the repo skips the auto-mode classifier and prompts. Reads outside the repo are
  therefore open, and the `deny` list is the fence — keep it complete (credentials, history,
  keyrings, rbw cache, browser profiles, CLI auth dirs)
- Denies are **per account**: the personal account and plain `claude` have none, by choice
- **Bash sandbox** (`sandbox.*`): Read/Edit deny rules feed its `denyRead`/`denyWrite`, so
  `cat ~/.ssh/...` is blocked too. Needs `bubblewrap` + `socat` (`packages.yaml`);
  `failIfUnavailable` refuses to launch without them
- **No `additionalDirectories`**: they become sandbox **write** roots — plugins, shell snapshots and
  the `--settings` file would be writable from sandboxed Bash
- `excludedCommands` use Bash permission-rule syntax: `gh:*`, not `gh` (exact match only). Excluded:
  credential CLIs (ssh git ops, gh, firebase, gcloud, docker) and the emulator tests — sandboxed
  node cannot reach the host's `127.0.0.1` emulator
- `allowWrite` is download caches only (`~/.cache/{pnpm,uv}`, pnpm store) — never all of `~/.cache`
  (zsh `.zwc`, antidote, paru PKGBUILDs) or install/state dirs (mise `trusted-configs` gates code
  execution). A new violation: cache → `allowWrite`, anything else → `excludedCommands`
- Friction: a compound command is sandboxed unless **every** part is excluded, so
  `git commit && git push` fails at the push

**CLI tools** (themed):
- **bat**: Syntax highlighting via `~/.config/bat/config` symlink
- **broot**: File tree skin via `~/.config/broot/skin.hjson` symlink
- **btop**: System monitor via `~/.config/btop/color_theme` symlink
- **lazygit**: Git TUI via `~/.config/lazygit/config.yml` symlink
- **starship**: Shell prompt; `~/.config/starship.toml` is generated by `theme-apply-starship` (base + theme palette)
- **yazi**: File manager via `~/.config/yazi/theme.toml` symlink

**Ghostty terminal** (`ghostty/`):
- Terminal config
- Theme integration via `source ~/.config/themes/current/ghostty.conf`

**Topgrade** (`topgrade.toml.tmpl`):
- Unified update workflow (firmware, git, cleanup)
- Calls `package-manager update` as pre-command (packages handled by package-manager)
- Disabled: system (Arch/AUR), flatpak (handled by package-manager); mise (built-in step always runs `mise self-update`, which pacman-built mise rejects); claude_code (mise tool, updated by `mise upgrade`); chezmoi (`chezmoi update` applies without diff review — `git_repos` pulls, apply stays manual)
- Antidote: built-in `antidote` step only (no custom command — it ran twice)
- Custom commands: mise tool upgrade, system-health, unmanaged package check, orphan removal

## Systemd User Services

**User services** (`systemd/user/`):
- Wallpaper cycle timer (30 min)
- Other user services

(Per-subdirectory docs are listed in the "Has CLAUDE.md?" column above; see those files for detail. Template syntax/data: `.claude/rules/chezmoi-templates.md` and `chezmoi-data.md`.)

## Integration Points

- **Chezmoi data**: `.chezmoidata/` (colors, globals, packages)
- **Scripts**: `~/.local/lib/scripts/` (desktop utilities)
- **CLI**: `~/.local/bin/` (command wrappers)
- **Zephyr**: Zstyle-based Zsh config
