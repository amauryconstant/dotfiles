# Omarchy v4.0.3 — Release Research

**Date researched**: 2026-09-12
**Previous version**: v4.0.2
**Commits**: 40
**Source**: Commit log fallback

---

## Summary

A security-and-hardening release layered on top of a large AI-agent expansion. The security half
hardens passwordless sudo (fail-closed expiry plus boot-time removal), root-owns the `system-sleep`
hooks with atomic staged installs, restricts Kitty remote control to `socket-only`, and introduces a
capability-scoped plugin API boundary in the Quickshell-based `omarchy-shell` so third-party plugins
no longer reach authentication services. The feature half adds five AI integrations (Hermes Desktop,
OpenClaw, T3 Code, Perplexity, Cursor CLI, Muse Code), rewrites Kitty configuration as a
system-defaults/user-overrides split under `/etc/xdg/kitty/`, and moves `locate` tuning from
rewriting `/etc/updatedb.conf` to a systemd drop-in.

## Breaking Changes

- **Kitty config split into system defaults + user overrides**: `~/.config/kitty/kitty.conf` is now
  only the theme include plus commented examples; all real defaults moved to
  `/etc/xdg/kitty/kitty.conf` (read by Kitty before the user file). A migration refreshes an
  unmodified stock user config and comments out any explicit `allow_remote_control yes|y|true` in a
  customized one (with a `.bak.XXXXXX` backup). Kitty must be fully restarted, not reloaded.
  Omarchy path: `config/kitty/kitty.conf`, `etc/xdg/kitty/kitty.conf`, `migrations/1788745941.sh`
- **`allow_remote_control` downgraded to `socket-only`**: remote control arriving through terminal
  output is rejected; only the Unix socket at
  `unix:${XDG_RUNTIME_DIR}/omarchy-kitty-{kitty_pid}` still works. Anything driving Kitty via escape
  sequences stops working. Omarchy path: `etc/xdg/kitty/kitty.conf`
- **`locate` configuration no longer written into `/etc/updatedb.conf`**: `install/config/locate.sh`
  and migration `1784809451.sh` were deleted; pruning now comes from a systemd drop-in overriding
  `ExecStart` with `updatedb --prune-bind-mounts=no --add-prunepaths=/.snapshots`. `/etc/updatedb.conf`
  is left to plocate. Any local expectation that Omarchy owns lines in that file is void.
  Omarchy path: `default/systemd/system/plocate-updatedb.service.d/10-omarchy.conf`
- **`broadcom-wl` replaced by `broadcom-wl-dkms`**: Arch dropped the prebuilt module, so the package
  name changed in both the package list and the BCM4360/BCM4331 hardware fixup.
  Omarchy path: `install/omarchy-other.packages`, `install/hardware/fix-bcm43xx.sh`
- **Third-party shell plugins lose direct host object access**: built-in plugins still receive the
  trusted host objects; third-party plugins now receive capability-scoped facades. Authentication
  services are kept out of the public service map and the QML object tree, and a replacement bar
  cannot request another plugin's live service object — service-backed third-party widgets have
  reduced function outside the built-in `omarchy.bar`. Omarchy path: `shell/services/PluginRegistry.qml`,
  `shell/services/Plugin*Api.qml`, `shell/shell.qml`
- **`omarchy plugin` add/update/remove now confirm even with arguments**: previously
  "interactive when bare, non-interactive when given arguments". Without a terminal they refuse
  rather than guess; `--yes` is the scripted path. Omarchy path: `shell/README.md`,
  `manual/32-shell-plugins.md`

## Features

- **Hermes Desktop + Hermes CLI**: new install/remove flows, a CLI wrapper installer that stands
  aside for an app-provided or user-owned `hermes`, a theme hand-off as a skin named `omarchy`, a
  Hyprland window rule for its frameless HUD, and skill symlinks into `~/.hermes/skills` and each
  existing `~/.hermes/profiles/*/skills`. Omarchy path: `bin/omarchy-install-ai-hermes`,
  `bin/omarchy-install-hermes-cli`, `bin/omarchy-remove-ai-hermes`, `bin/omarchy-theme-set-hermes`,
  `default/hypr/apps/hermes.lua`, `default/themed/hermes.yaml.tpl`
- **OpenClaw**: agent platform with a launcher that owns onboarding and the gateway attach dance
  (`omarchy-launch-openclaw --tui`, `--message` seeds an interactive session), plus an `openclaw`
  command group in the `omarchy` dispatcher. Omarchy path: `bin/omarchy-install-ai-openclaw`,
  `bin/omarchy-install-openclaw-cli`, `bin/omarchy-launch-openclaw`, `bin/omarchy-openclaw-onboard`,
  `bin/omarchy-remove-ai-openclaw`
- **T3 Code**: added to the AI install menu with its own theme template.
  Omarchy path: `bin/omarchy-install-ai-t3-code`, `bin/omarchy-remove-ai-t3-code`,
  `bin/omarchy-theme-set-t3code`, `default/themed/t3code.json.tpl`
- **Cursor CLI as a coding agent**: installed through mise with a `tool_alias` that exposes only the
  launcher so Cursor's bundled Node cannot shadow the user's Node on `PATH`. An existing
  `~/.local/bin/cursor-agent` symlink from Cursor's own installer is treated as user-owned and kept.
  Omarchy path: `etc/mise/conf.d/omarchy.toml`, `install/user/mise.sh`, `migrations/1788577553.sh`
- **Muse Code as a default coding agent**: Meta's `muse`, installed through mise's HTTP backend
  against `https://api.meta.ai/muse-launcher.sh`; launched with `--approval-mode never`.
  Omarchy path: `bin/omarchy-default-agent`, `bin/omarchy-agent`, `migrations/1788724825.sh`
- **Perplexity desktop app**: install/remove menu entries.
  Omarchy path: `bin/omarchy-remove-ai-perplexity`
- **`Remove > AI` menu group**: new top-level removal group for T3 Code, OpenClaw and Perplexity
  (Hermes Desktop sits under it too). Omarchy path: `default/omarchy/omarchy-menu.jsonc`
- **`keepLoaded` honored for services across plugin hot-reload**: a service with the top-level
  manifest key `keepLoaded: true` survives a reload, so `omarchy.lock` is not destroyed while
  Hyprland still holds the session lock. The kept instance is not replaced — code changes to a
  `keepLoaded` service need a shell restart. Omarchy path: `shell/services/PluginRegistry.qml`,
  `shell/plugins/lock/manifest.json`
- **Plugin bar API surface**: `PluginBarApi`, `PluginBarStateApi`, `PluginBarWidgetRegistryApi`,
  `PluginAppLibraryApi`, `PluginFirstPartyServiceApi`, `PluginRegistryApi`, `PluginShellApi` and
  `AuthServiceStore.js`, providing detached bar-configuration and widget-catalog snapshots plus
  narrow proxies for non-authentication services. Omarchy path: `shell/Ui/PluginBarApi.qml`,
  `shell/services/`
- **Four new icon-font glyphs**: `U+E90A` Hermes, `U+E90B` Perplexity, `U+E90C` OpenClaw,
  `U+E90D` Cursor (`U+E908` T3 Code also present). Omarchy path: `default/fonts/omarchy/omarchy.ttf`,
  `default/fonts/omarchy/README.md`

## Bug Fixes

- **Passwordless sudo fail-closed expiry**: arming the `systemd-run` expiry timer is now checked; if
  scheduling fails the sudoers drop-in is removed immediately (and a CRITICAL message printed if that
  also fails). Omarchy path: `bin/omarchy-sudo-passwordless`
- **Passwordless sudo no longer survives a reboot**: transient timers do not survive a
  reboot, so a boot-only (`r!`) tmpfiles rule removes any leftover
  `/etc/sudoers.d/99-omarchy-nopasswd-*` during early boot.
  Omarchy path: `etc/tmpfiles.d/omarchy-nopasswd-sudo.conf`
- **`system-sleep` hooks published root-owned and atomically**: `force-igpu` and `keyboard-backlight`
  are now installed via a staged `mktemp` + `install -o root -g root` + `mv -Tf` helper with a
  validated stage path, rather than `cp -p`. The hybrid-GPU toggle installs every supporting file
  before flipping `/etc/supergfxd.conf`, so a failed step is retryable.
  Omarchy path: `bin/omarchy-toggle-hybrid-gpu`, `bin/omarchy-hibernation-setup`,
  `migrations/1788662350.sh`
- **`force-igpu` no longer reads a mutable mode as its restore source**: a `/run` marker records the
  mode the sleep cycle started in (supergfxctl persists the temporary hibernate switch to Vfio), mode
  transitions are confirmed with a bounded `timeout` retry loop, and symlinked markers abort.
  Omarchy path: `default/systemd/system-sleep/force-igpu`
- **Sleep hooks read `SYSTEMD_SLEEP_ACTION`**: both hooks now prefer the environment variable over
  the positional `$2`. Omarchy path: `default/systemd/system-sleep/{force-igpu,keyboard-backlight}`
- **fprintd path hardening**: `omarchy-apply-lock` pins `PATH` when run as root and calls
  `/usr/bin/fprintd-list` by absolute path instead of resolving it through `omarchy-cmd-present`.
  `omarchy-upgrade-to-quattro` stops exposing the target user's `~/.local/bin` to `as_root` commands.
  Omarchy path: `bin/omarchy-apply-lock`, `bin/omarchy-upgrade-to-quattro`
- **`omarchy-mise-install` argument-injection guard**: the command name is rejected if it contains a
  slash, a leading dot or dash, or control characters (it becomes a file name under `~/.local/bin`),
  and package/bin values are quoted before being written into the generated wrapper heredoc.
  Omarchy path: `bin/omarchy-mise-install`
- **Fingerprint reader install repaired**: setup now installs `libfprint-git fprintd usbutils` in one
  `pacman -S --needed --noconfirm --ask 4` transaction instead of pre-removing `libfprint-git`, so a
  failed install leaves the existing driver in place. The old swap-back migration is rewritten to
  only repair an fprintd left with no libfprint at all.
  Omarchy path: `bin/omarchy-setup-security-fingerprint`, `migrations/1785090473.sh`
- **1Password oversized on scaled monitors**: the hotkey launcher passes
  `--force-device-scale-factor=1`, matching the packaged `.desktop`.
  Omarchy path: `bin/omarchy-launch-1password`
- **mise upgrades pruned a running version**: `mise settings set upgrade.auto_prune false` so
  `mise up` cannot delete the install dir a live session is executing from.
  Omarchy path: `install/user/mise.sh`, `migrations/1787215483.sh`
- **Kitty font helpers work against the system defaults**: `omarchy-font-set` and
  `omarchy-display-text-size` now create `~/.config/kitty/kitty.conf` overrides when the setting is
  inherited from `/etc/xdg`, append when absent, use `sed --follow-symlinks`, escape the font name,
  and read the last (not first) match. Omarchy path: `bin/omarchy-font-set`,
  `bin/omarchy-display-text-size`
- **Legacy user icon font retired**: the Quattro upgrade treated
  `~/.local/share/fonts/omarchy.ttf` as `~/.config/omarchy.ttf` and left the old family registered
  next to the packaged font. The migration removes it only when the hash matches the known stock
  file, keeps custom fonts and symlinks, refuses if the packaged font is missing, then runs
  `fc-cache -f`. Omarchy path: `migrations/1788848726.sh`
- **`omarchy-install-hermes-cli` cannot abort user provisioning**: it is the one line in
  `install/user/mise.sh` that can fail (Hermes Desktop owning Hermes mid-setup), so it is guarded
  with `|| true` — the leaf is sourced under `bash -eE` and would otherwise skip the default browser,
  the mailto handler and the finalize-user marker. Omarchy path: `install/user/mise.sh`

## Improvements

- **`omarchy-remove-preinstalls` distinguishes owned wrappers from user installs**: only a wrapper
  matching the mise stub pattern for `cursor-agent` / `muse` is removed, and
  `omarchy-install-hermes-cli --owns` decides for `hermes`.
- **Agent launch modes**: `omarchy-agent` gained `openclaw`, `cursor-agent` (`--yolo --trust`, with
  the `agent` subcommand named outright so a one-word prompt is not read as a subcommand), `hermes`
  and `muse` cases.
- **Menu icon consistency**: Cursor entries use the `omarchy` icon font; new default-agent rows for
  Cursor CLI, Hermes, Muse Code and OpenClaw; `hermes` added to `launcher.hides`.
- **`updatedb` invocations aligned**: post-install and AUR-install refreshes pass the same
  `--prune-bind-mounts=no --add-prunepaths=/.snapshots` options as the service drop-in, since
  installation may run without systemd. Omarchy path: `install/post-install/localdb.sh`,
  `bin/omarchy-pkg-aur-install`
- **Security-report credits recorded**: @Chainfire for the passwordless asdcontrol watchdog-reboot
  report (fixed in the 4.0.2 security work), and _SiCk // afflicted.sh for reproducing and reviewing
  the passwordless-sudo persistence fix, with co-author credit to @Adolanium for the boot-cleanup
  patch.
- **Test coverage expansion**: ~30 new/expanded `test/shell.d/*` suites covering Hermes, OpenClaw,
  T3 Code, plugin auth boundary and lifecycle, sleep-hook ownership migration, kitty config,
  fingerprint packages/migration, mise install guards, nopasswd sudo expiry, legacy icon font, and a
  runtime smoke test.

## Configuration Changes

- **Kitty**: user file reduced to the theme include plus commented examples; system defaults at
  `/etc/xdg/kitty/kitty.conf` shipped by `omarchy-settings`. `allow_remote_control yes` →
  `allow_remote_control socket-only`. Inherited bindings can be unmapped with a bare
  `map <shortcut>` or cleared entirely with `clear_all_shortcuts yes`.
  Omarchy path: `config/kitty/kitty.conf`, `etc/xdg/kitty/kitty.conf`, `docs/file-layout.md`
- **plocate**: new vendor drop-in at
  `/usr/lib/systemd/system/plocate-updatedb.service.d/10-omarchy.conf` clearing and replacing
  `ExecStart`. The upstream timer, resource limits and sandbox are retained, as is Omarchy's AC-power
  condition. Omarchy path: `default/systemd/system/plocate-updatedb.service.d/10-omarchy.conf`
- **mise**: new `/etc/mise/conf.d/omarchy.toml` with a `[tool_alias]` entry for `cursor-agent` using
  `http:cursor-agent[bin_path=bin,postinstall=...]` to symlink only `bin/cursor-agent`.
  Plus a global `upgrade.auto_prune = false` setting. Omarchy path: `etc/mise/conf.d/omarchy.toml`
- **sudoers cleanup**: new `/etc/tmpfiles.d/omarchy-nopasswd-sudo.conf` with a boot-only
  `r! /etc/sudoers.d/99-omarchy-nopasswd-*` rule (boot-only so a later
  `systemd-tmpfiles --remove` cannot cut a live grant short).
- **Plugin manifests**: new optional top-level `omarchy.capabilities` array. `authentication` is
  stamped only from trusted first-party manifests; `omarchy.lock` and `omarchy.polkit` declare it.
  Omarchy path: `shell/plugins/{lock,polkit}/manifest.json`, `shell/services/PluginRegistry.qml`
- **Skill symlinks**: `omarchy-provision-user` now also creates `~/.hermes/skills/<name>` and, when
  `~/.hermes/profiles/*/` already exist, `<profile>/skills/<name>`. It does not create Hermes
  profiles. Omarchy path: `bin/omarchy-provision-user`, `migrations/1787843905.sh`
- **Theme post-commands**: `omarchy-theme-set-hermes` and `omarchy-theme-set-t3code` appended to
  `post_theme_commands`. Omarchy path: `bin/omarchy-theme-set`

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Renamed | `broadcom-wl` → `broadcom-wl-dkms` | Arch dropped the prebuilt module; BCM4360/BCM4331 support |
| Removed | `dkms` (from the BCM fixup call) | `broadcom-wl-dkms` pulls it in; `linux-headers` still added |
| Changed | `libfprint` → `libfprint-git` | Tracks upstream ahead of the Arch release so a new reader needs only a pin bump; installed with `--ask 4` in one transaction |
| Added | `fprintd`, `usbutils` | Installed together with `libfprint-git` in the fingerprint setup transaction |
| Added | `hermes-desktop` | Hermes Desktop AI app (Install > AI) |
| Added | `openclaw` | OpenClaw agent platform + gateway (Install > AI) |
| Added | `t3code-bin` | T3 Code AI app (Install > AI) |
| Added | `perplexity` | Perplexity desktop app (Install > AI) |
| Added | `cursor-agent` (mise, `http:` backend via `tool_alias`) | Cursor CLI coding agent |
| Added | `muse` (mise, `http:` backend) | Meta's Muse Code coding agent |
