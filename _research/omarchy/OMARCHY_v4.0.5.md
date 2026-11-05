# Omarchy v4.0.5 — Release Research

**Date researched**: 2026-11-05
**Previous version**: v4.0.4
**Commits**: 43
**Source**: Commit log fallback

---

## Summary

Stabilization release (201 files, about 6.6k insertions, 1.9k deletions; roughly half is new tests). Main themes: browser link routing through a single `omarchy-browser.desktop` handler, Hermes/OpenClaw AI CLIs moving to self-updating installs under `~/.hermes` / `~/.openclaw`, hardware fixes (NVIDIA hybrid VA-API, Dell XPS 13 Panther Lake speakers, T2 firmware, KEF USB sink, speaker-tuning RTKit), and the Omarchy pacman repo being moved ahead of Arch repos. The Quickshell-based shell gets Qt 6.12 palette qualification and a bar startup/restart race fix.

## Breaking Changes

- **Omarchy repo priority in pacman.conf**: `[omarchy]` section now precedes the Arch repositories in `default/pacman/pacman-{stable,rc,edge}.conf`. Migration `1791403252.sh` reorders the existing section in `/etc/pacman.conf` (backup at `/etc/pacman.conf.bak`, requires sudo) and re-syncs/upgrades. Omarchy packages now win over same-named Arch packages.
- **Project `bin` PATH injection removed**: the stock `~/Work/.mise.toml` no longer sets `_.path = "{{cwd}}/bin"`; migration `1789095456.sh` strips the stock line (matched by sha256 of the 4.0.3 file). Per-project `bin/` directories are no longer on PATH automatically. `install/user/mise-work.sh` and `install/user/mise.sh` lost related lines.
- **Hermes mise install retired**: migration `1790017600.sh` calls `omarchy-install-hermes-cli --retire-mise`, removing the mise-built Hermes wrapper/environment; Hermes now installs as an upstream checkout under `~/.hermes` and updates itself via `hermes update`. `omarchy-provision-user` no longer runs `omarchy-install-hermes-cli`.
- **OpenClaw self-updating move**: migration `1790397381.sh` is an inert stub ("shipped too early", #15804); the real move is a later migration (`1792334754.sh`, outside this tag range).

## Features

- **Default-browser link routing**: new `applications/omarchy-browser.desktop` is the http/https handler; links from any app go to the running default browser. New helpers `bin/omarchy-cmd-browser-handoff` and `bin/omarchy-cmd-default-browser`; default browser is read from `mimeapps.list`; `omarchy-launch-browser` and `omarchy-launch-webapp` hand off to the running browser directly. New `config/hyprland-mimeapps.list`. Migration `1791934674.sh` installs the desktop file and seeds `~/.config/hyprland-mimeapps.list`.
- **Browsers stop asking to be default**: `--no-default-browser-check` added to `config/chromium-flags.conf`; new `default/chromium/policies/omarchy.json`; `default/firefox/policies.json` updated; `install/helpers/browser-policy.sh` added. Migration `1791935188.sh` applies to existing flag files and hardened policy dirs.
- **Dell XPS 13 Panther Lake speaker firmware**: new `bin/omarchy-hw-dell-xps13-dx13260-ptl`, `install/hardware/dell-xps13-ptl-speaker-firmware.sh`; migration `1791265613.sh` (sets reboot-required).
- **KEF LSX II LT no-suspend**: `config/wireplumber/wireplumber.conf.d/kef-lsx-no-suspend.conf`; migration `1789130779.sh` copies it and restarts wireplumber.
- **NVIDIA display detection**: new `bin/omarchy-hw-nvidia-display`.
- **Session-lock stranded detection**: new `bin/omarchy-hyprland-session-lock-stranded`.
- **Hermes/OpenClaw CLI installers**: `omarchy-install-hermes-cli` (large rewrite) and `omarchy-install-openclaw-cli` expanded; `omarchy-remove-ai-hermes` reworked; new tests for mise-retire migration, openclaw CLI.

## Bug Fixes

- **Remote Neovim yanks/paste**: migration `1788996284.sh` replaces known-Omarchy `~/.config/nvim/lua/config/remote_clipboard.lua` versions (skips symlink-managed). Omarchy path: `~/.config/nvim/lua/config/remote_clipboard.lua`.
- **Hybrid NVIDIA VA-API/GLX**: `default/hypr/nvidia.lua` only sets `LIBVA_DRIVER_NAME` / `__GLX_VENDOR_LIBRARY_NAME` to nvidia when NVIDIA drives the display (black video in Chromium browsers on hybrid laptops). Migration `1790282866.sh` sets reboot-required. Omarchy path: `default/hypr/nvidia.lua`.
- **Boot black screen (~1 in 10)**: kernel cmdline `systemd.tty.term.console=dumb` skips systemd's console size query under Plymouth. Omarchy path: `etc/limine-entry-tool.d/omarchy-defaults.conf`; migration `1791581004.sh` triggers boot image rebuild.
- **Speaker tuning RTKit**: filter-chain host asks RTKit directly instead of via xdg-desktop-portal (zero RLIMIT_RTTIME killed host). Omarchy path: `default/audio/filter-chain-host.conf`, `default/systemd/user/omarchy-speaker-tuning.service`; migration `1790114905.sh`.
- **Audio filter pair resolution**: `effect_input`/`effect_output` pairs and EasyEffects sink resolver in `bin/omarchy-audio-output-sink` (+ `audio-output-sink-test.sh`).
- **Bar startup stall / shell restart race**: `shell/plugins/bar/Bar.qml`, `bar/widgets/Indicators.qml`, `bin/omarchy-restart-shell`.
- **Session lock recovery**: only recovers a lock no other locker may hold. Omarchy path: `bin/omarchy-hyprland-session-lock-stranded`, `shell/plugins/lock/Service.qml`.
- **Calendar month grid**: built in UTC. Omarchy path: `shell/plugins/panels/clock/Model.js`.
- **Qt 6.12 palette references**: qualified across `shell/Commons/Style.qml`, `shell/Ui/*`, and most plugins.
- **Keyring refresh**: signing keyrings refreshed only when a newer version is out. Omarchy path: `bin/omarchy-update-keyring`.
- **Monitor panel display toggle**: `shell/plugins/panels/monitor/Panel.qml`.
- **Idle timeout zero**: `shell/plugins/services/idle/IdleModel.js`, `Service.qml`.
- **Shutdown lid inhibit**: `bin/omarchy-system-shutdown`.
- **Factory reset password hashes**: `bin/omarchy-system-factory-reset`.
- **Windows VM setgid mount boundary**: `bin/omarchy-windows-vm`.
- **sshd firewall cleanup**: `bin/omarchy-remove-security-sshd`.
- **Steam GPU drivers before Steam**: `bin/omarchy-install-gaming-steam`, `omarchy-install-gaming-gpu-lib32`.
- **RetroArch removal**: drops libretro database. Omarchy path: `bin/omarchy-remove-gaming-retroarch`.
- **Fastfetch swap label**: `etc/fastfetch/config.jsonc`.
- **Agent usage display**: `bin/omarchy-agent-usage-claude`.
- **Plugin third-party sourcedir**: `bin/omarchy-hook-install`/plugin handling (#11925).
- **Basecamp GitHub URLs** fixed in docs/manual.
- **Command operands as literals**: end-of-options marker (`--`) added in `omarchy-pkg-add`, `omarchy-pkg-aur-add`, `omarchy-pkg-present`, `omarchy-pkg-missing`, `omarchy-cmd-present`, `omarchy-cmd-missing`, `omarchy-hw-match`, etc.
- **T2 firmware fetcher**: `install/hardware/apple/fix-t2.sh`.

## Improvements

- **Default agent**: `omarchy-default-agent` and provisioning leave Hermes to the default agent; Hermes Desktop default-agent flow.
- **Network QR test environment** simplified (`bin/omarchy-network-qr`).
- **Docs/manual**: `docs/omarchy-shell.md`, `docs/theming.md`, `manual/17-ai.md`, `manual/19-shell-tools.md`, `manual/30-updates.md`, `manual/49-omarchy-on.md`, `agents/skills/shell-dev.md`.
- **Test suite**: many new `test/shell.d/*` files (browser handoff, command operand boundaries, factory reset, xps13 firmware, opr priority, etc.).

## Configuration Changes

- **pacman.conf ordering**: `[omarchy]` moved above Arch repos in all three channel templates. Omarchy path: `default/pacman/pacman-stable.conf` (and rc, edge).
- **Pacman hook sample**: `config/omarchy/hooks/pre-refresh-pacman.d/add-custom-repo.sample` updated for new ordering.
- **Chromium flags**: `--no-default-browser-check` appended. Omarchy path: `config/chromium-flags.conf`.
- **Browser policies**: new `default/chromium/policies/omarchy.json`; edits to `default/firefox/policies.json`.
- **mimeapps**: `config/hyprland-mimeapps.list` maps `x-scheme-handler/http(s)` to `omarchy-browser.desktop`.
- **WirePlumber**: `config/wireplumber/wireplumber.conf.d/kef-lsx-no-suspend.conf`.
- **Limine defaults**: kernel cmdline `systemd.tty.term.console=dumb`.
- **Hyprland**: `default/hypr/nvidia.lua` conditional env; `default/hypr/apps/jetbrains.lua` small edit.
- **Audio**: `default/audio/filter-chain-host.conf`.
- **Migrations added**: `1788996284`, `1789095456`, `1789130779`, `1790017600`, `1790114905`, `1790282866`, `1790397381`, `1791265613`, `1791403252`, `1791581004`, `1791934674`, `1791935188`; `1787760281` modified.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `linux-firmware-cirrus-dx13260` | Dell XPS 13 Panther Lake speaker firmware |
| Renamed | `apple-bcm-firmware` -> `apple-bcm-firmware-fetcher` | T2 MacBook firmware fetcher fix |
