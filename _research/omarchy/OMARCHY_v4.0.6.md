# Omarchy v4.0.6 — Release Research

**Date researched**: 2026-11-05
**Previous version**: v4.0.5
**Commits**: 6
**Source**: Commit log fallback

---

## Summary

Patch release fixing migration problems from v4.0.5: the OpenClaw self-updating move is retired and re-shipped as a new migration that tolerates a user's own OpenClaw, and the console (`systemd.tty.term.console=dumb`) migration handles Limine configs that omit the parameter. Also keeps a non-Latin `vconsole.conf` out of the initramfs again and makes the Quickshell lock service read lock state afresh instead of from a property binding.

## Breaking Changes

*None*

## Features

- **OpenClaw launcher self-heals**: When the `openclaw` package is installed but no `openclaw` command exists (package became the seed before the user's OpenClaw moved), `omarchy-launch-openclaw` runs `omarchy-install-openclaw-cli --now` (in a floating terminal, or inline for `--tui`, showing failure via `omarchy-show-done 1`). Omarchy path: `bin/omarchy-launch-openclaw`.

## Bug Fixes

- **OpenClaw move with user's own OpenClaw in the way (#15875)**: `omarchy-install-openclaw-cli` detects a user-owned OpenClaw (command, other one on PATH, or running gateway) and exits with status 79 without changing anything, rather than failing and blocking all updates. The new migration treats 79 as success and leaves the move to launching OpenClaw. Omarchy path: `bin/omarchy-install-openclaw-cli`, `bin/omarchy-install-ai-openclaw`, `bin/omarchy-remove-ai-openclaw`.
- **`omarchy-agent` with packaged OpenClaw**: A missing `openclaw` command is no longer a hard error when the package is present; the launcher fixes it. Omarchy path: `bin/omarchy-agent`.
- **Lock decisions from current state (#14978)**: A property binding missing a change notification reported locked after unlock, so a lock request before suspend never locked the session. New `currentlyLocked()` function (`lockRequested || sessionLock.locked || sessionLock.secure`) is used in stranded-lock detection/recovery, `finishUnlock`, and the IPC `lock`, `isLocked`, `status` handlers. Omarchy path: `shell/plugins/lock/Service.qml`.
- **Non-Latin vconsole.conf kept out of initramfs (#14885)**: Since Arch plymouth 26.134.222-3 the plymouth hook copies `/etc/vconsole.conf` itself, making the LUKS passphrase untypeable for first layouts with no Latin letters (#14246, #6229). New drop-in wraps mkinitcpio `add_file` to refuse `/etc/vconsole.conf` unless `FILES` lists it and the first `XKBLAYOUT` is in a fixed non-Latin list (af, am, ara, bd, bg, by, et, ge, gr, il, in, iq, ir, kg, kh, kz, la, lk, mk, mm, mn, mv, np, rs, ru, sy, th, tj, ua). Latin layouts (e.g. German) are not refused. Omarchy path: `etc/mkinitcpio.conf.d/omarchy_vconsole.conf`.
- **Console migration with Limine config omitting the parameter (#15852)**: Migration `1791581004.sh` no longer fails forever when `/etc/default/limine` uses a plain `KERNEL_CMDLINE[default]=` (or per-kernel keys) that drops `systemd.tty.term.console=dumb`. It asks `limine-entry-tool --get-cmdline` per installed kernel (and fallbacks); if none carry the parameter, it prints a note recommending `+=` and completes. Parameter detection now parses the cmdline as systemd does (quotes, last assignment wins) via `carries_param()`. Omarchy path: `migrations/1791581004.sh`.

## Improvements

- **Test coverage**: Added/extended shell tests: `test/shell.d/openclaw-cli-test.sh`, `launch-openclaw-test.sh`, `default-agent-test.sh`, `remove-ai-test.sh`, `lock-stranded-recovery-test.sh`, `mkinitcpio-vconsole-test.sh`, `plymouth-vconsole-migration-test.sh`, `console-no-ansi-query-migration-test.sh`.
- **OpenClaw installer expanded**: `omarchy-install-openclaw-cli` grew by roughly 200 lines (detection of user-owned installs, exit 79 contract).

## Configuration Changes

- **Initramfs vconsole drop-in**: New `etc/mkinitcpio.conf.d/omarchy_vconsole.conf` (separate from `omarchy_hooks.conf` so it is not package-kept config and also reaches machines with an edited or pre-package `omarchy_hooks.conf`). Wraps `add_file` once (guarded against double-wrapping when mkinitcpio sources it again). Omarchy path: `etc/mkinitcpio.conf.d/omarchy_vconsole.conf`.
- **Migrations**:
  - `1790397381.sh` (shipped in 4.0.5): retired to an inert `exit 0`. In 4.0.5 it failed where the seed package was missing, stopping the update and later migrations (#15804).
  - `1792334754.sh` (new): re-ships the OpenClaw move to `~/.openclaw` once `/usr/share/openclaw/install-cli.sh` and `openclaw.tgz` exist; skips if the package is absent or still the runtime; status 79 is non-fatal.
  - `1791621765.sh` (new): rebuilds the boot image via `sudo limine-mkinitcpio` when the plymouth hook references `vconsole.conf` and evaluated mkinitcpio config would not add it; marker `/var/lib/omarchy/migrations/1791621765`; stays pending if a kernel failed to rebuild.
  - `1791581004.sh` (modified): see Bug Fixes.
  - Note: the commit summary lists "Revert migration-core changes from #14212 (#15864)" and the merge of #14212 (openclaw-migration-update-path).

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| (none changed) | `openclaw` | Package is now a seed (`/usr/share/openclaw/install-cli.sh`, `openclaw.tgz`) for a self-updating copy under `~/.openclaw`; migration/launcher depend on it, no package list change in this diff |
