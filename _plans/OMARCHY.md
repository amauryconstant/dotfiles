# Omarchy Integration Backlog

Living actionable backlog. Updated by `/omarchy-changes`.
Last updated: 2026-08-30 (through v4.0.1).

**Legend**: `[ ]` pending · `[x]` done · `[SKIPPED]` out of scope

> **v4.0.0 context**: Omarchy "Quattro" replaced its entire desktop shell (Waybar, Walker, Mako, SwayOSD, hyprlock, hypridle, swaybg, polkit-gnome) with a single Quickshell process, converted all Hyprland config to Lua, rewrote the theme schema from ANSI-indexed to 24-key semantic, and moved its internals from a git checkout into Arch packages. The shell replacement itself is out of scope (we use Waybar + Wofi + hyprlock/hypridle), but three sub-currents are directly relevant to us: **Hyprland Lua config for 0.56**, **the semantic colorset + template-rendered app themes**, and a batch of **script-level bug fixes that also exist verbatim in our ported scripts**.
>
> **v4.0.1 context**: A security-focused patch backporting fixes from the post-Quattro `quattro` branch — four CVE-class fixes (FIDO2 authfile symlink/ownership, USB/monitor device names executed as Hyprland Lua, theme-install code execution, video-title command forging) plus hardening, and one default-behavior reversal: **sudoless Docker group membership is no longer granted automatically**, because it is root-equivalent. Our `services.yaml` still grants it unconditionally — tracked as new P1 below. The device-name-as-Lua fix also lands directly on two of our own *not-yet-implemented* backlog items (touchpad toggle, clamshell handling) that were adapted from the exact scripts that had the bug.

---

## P1 — High Priority

### Sudoless Docker group granted by default (v4.0.1)

**What**: `docker` group membership is root-equivalent — `docker run -v /:/host busybox chroot /host` rewrites the host filesystem as root, no password required. Omarchy granted this by default for years and reversed it in v4.0.1: the group is no longer added on install/first-boot/upgrade, a migration strips it from existing installs, and the Docker CLI/TUI now route through `sudo`/polkit instead. Our `services.yaml` grants it unconditionally with no opt-in gate: the `docker.socket` entry carries `user_groups: [docker]`, applied via `usermod -aG` in `run_once_after_002_configure_system_services.sh.tmpl`.
**Target files**: `.chezmoidata/services.yaml`, `.chezmoiscripts/run_once_after_002_configure_system_services.sh.tmpl`, `.chezmoidata/packages.yaml` (`lazydocker`)
**Effort**: Medium
**Conflict**: Removing the auto-grant breaks any existing workflow assuming plain `docker`/`lazydocker` works without `sudo`; existing group membership also persists across `chezmoi apply` (nothing in the script reverts a prior grant) until explicitly removed.
**Adapt from**: `bin/omarchy-remove-security-sudoless-docker`, `applications/Docker.desktop`, `bin/omarchy-launch-docker-tui`

- [x] Decide policy: **accept the risk** (user decision 2026-08-30, reversing an earlier same-day attempt at gating behind `features.docker_sudoless.enabled`) — single-user desktop, current unconditional grant "just works as intended"; no code change *(done 2026-08-30)*
- [x] Accepted risk recorded in `system/CLAUDE.md` → Package Security Policy, noting the deliberate divergence from Omarchy's v4.0.1 reversal *(done 2026-08-30)*
- [SKIPPED] Feature-gating `services.yaml`/`run_once_after_002`/`menu-install` — built, then reverted per the above decision
- [N/A] `lazydocker` needs no separate access-path change — sudoless docker stays the default, same as before

---

### Waybar toggle leaves a stale process (v3.8.4)

**What**: Newer Waybar does not exit on `SIGTERM` in the toggle path, so `pkill waybar` leaves a stale process and the bar never comes back on the second toggle. Omarchy changed `pkill -x waybar` → `pkill -9 -x waybar`. Our `waybar-toggle` carried the same defect plus a bare `pkill` with no `-x`.
**Target files**: `private_dot_local/lib/scripts/desktop/executable_waybar-toggle`
**Effort**: Low
**Conflict**: Our script is a direct port of `omarchy-toggle-waybar` and carried the same defect.

> **Correction (2026-08-24)**: an earlier revision of this item claimed the bare `pkill waybar` could collaterally kill `voxtype-waybar-status`. It could not. `pkill` without `-f` matches `comm`, not the command line, and every `waybar`-named script here runs under `comm=sh` (`#!/usr/bin/env sh`) — verified with `ps -eo comm,args`. The `-9` was the real defect; `-x` is hygiene against a future rename, not a live bug.

- [x] Change `pkill waybar` → `pkill -9 -x waybar`
- [x] Confirm `pgrep -x waybar` guard still matches after the change
- [x] Test: four toggle cycles — bar returned each time, ends visible
- [x] Notifications moved after verification, so they report the state actually reached
- [x] Confirm `voxtype-waybar-status` respawns with the bar (2 instances, unaffected)

---

### hyprsunset cold-start temperature race (v4.0.0)

**What**: On a hyprsunset cold start the temperature can be dropped silently — the daemon is not ready when the temperature is set, so the filter never applies. Omarchy's fix resends the temperature until it sticks. Our `nightlight-toggle` did exactly the racy thing: `pkill hyprsunset` immediately followed by `hyprsunset -t <temp> &` with no wait and no verification, so a toggle could report success while the screen temperature never changed. It also read current state by parsing the process cmdline, which goes stale the moment temperature is changed any way other than respawning.
**Target files**: `private_dot_local/lib/scripts/desktop/executable_nightlight-toggle`, `private_dot_local/lib/scripts/desktop/executable_nightlight-config`, `private_dot_local/lib/scripts/user-interface/executable_menu-trigger`
**Effort**: Low
**Conflict**: Our script is a port of `omarchy-toggle-nightlight` and predates the fix.

Rather than hardening the kill/respawn, both scripts were moved onto hyprsunset's IPC (`hyprctl hyprsunset`), which was previously unused anywhere in the repo. Measured behaviour of that interface, since none of it is documented:

| Probe | Result |
|---|---|
| `hyprctl hyprsunset temperature` (bare) | reads the current Kelvin back — **undocumented getter** |
| `hyprctl hyprsunset temperature <k>` | prints `ok` |
| `hyprctl hyprsunset identity` | prints `ok`, but does **not** reset the temperature read-back |
| invalid command / out-of-range value | **still exits 0** — exit status proves nothing, check the output |

Because `identity` leaves the read-back unchanged, temperature alone cannot distinguish "filter on" from "identity active", so on/off is tracked with a marker in `$XDG_RUNTIME_DIR` (tmpfs — hyprsunset does not survive a logout either, so a persistent marker would claim "on" with no daemon; same reasoning as `idle-toggle:16`).

- [x] Drive the running daemon over IPC instead of kill/respawn; spawn only when absent, then wait for the socket
- [x] Use `identity` as "off" rather than a second daemon at 6000K
- [x] Verify by reading the temperature back; notify only after confirmation
- [x] Replace cmdline parsing with a runtime marker + a persistent Kelvin preference
- [x] Test: 6 consecutive toggles — daemon PID unchanged, count stayed 1, state matched every notification
- [x] Test: cold start, stale marker, corrupt preference, out-of-range preference — all recover

**Found while fixing**: `nightlight-config` had never worked. It offered a wofi Kelvin menu and then set `hyprctl keyword decoration:col.shadow 0xee...` per choice, notifying as though the temperature had changed — it never touched hyprsunset at all. It also had **no callers anywhere**, so it was both broken and unreachable.

- [x] Rewrite it onto the same IPC path; the chosen Kelvin is persisted as the warm preference `nightlight-toggle` turns on with
- [x] Make it reachable — added to the Toggle submenu in `menu-trigger` (menu entry, no new keybinding)

---

### Hyprland Lua config is the forward path (v4.0.0)

**What**: Omarchy converted all Hyprland configuration from `.conf` to Lua for Hyprland 0.56 (`hyprland.lua` sourcing a bootstrap, `hl.monitor{}`, `hl.env()`, `hl.unbind()`, `o.bind()` action tables, `omarchy_default_bindings = false` escape hatches, `.luarc.json` shipped alongside). Our repo has already done this migration.
**Target files**: `.chezmoiignore`, `private_dot_config/hypr/conf/**`, `private_dot_config/hypr/conf/bindings/**`, `.chezmoiscripts/run_once_after_007_validate_hyprland_config.sh.tmpl`
**Effort**: Medium
**Blocked on**: a Waybar release carrying PR #5013 — external, nothing to do here until it lands.

> **Correction (2026-08-24)**: an earlier revision of this item framed the dual `.conf`/`.lua` sources as unmanaged drift risk and asked which entry point is authoritative. That was wrong on both counts. The `.lua` set **is** deployed and live (`~/.config/hypr/conf/*.lua` all present); only the *entry point* is held back, deliberately, by `.chezmoiignore` — which documents why. Hyprland here is already 0.56.2, the version Omarchy converted for.

The real question is only whether Waybar has shipped PR #5013 (`fix(hyprland/workspaces): adapt dispatch commands for Lua IPC protocol`), because our Waybar workspace clicks depend on the legacy text dispatch that Lua mode removes.

Re-checked 2026-08-30: **merged 2026-05-04** into master; latest release still **0.15.0 (2026-02-06)**, predating it; Arch `extra` still ships `waybar 0.15.0-2`; no 0.16.0 exists. The fix is upstream but in no tagged release. Full state recorded in `.chezmoiignore` so the next check is a version comparison, not a re-investigation.

**Cutover runbook**: `_guides/HYPRLAND_LUA_CUTOVER.md` — hold status, cutover/rollback steps, hyprsplit coupling risk. Audit findings/verified prerequisites: `_research/HYPRLAND_LUA_AUDIT.md`.

`Hyprland --verify-config` exists ("Do not run Hyprland, only print if the config has any errors"). The entry point is chezmoiignore'd, so render it to a temp path first — it resolves the rest of the tree through `package.path` against the deployed `~/.config/hypr`:

```sh
TMP=$(mktemp -d)
chezmoi execute-template < private_dot_config/hypr/hyprland.lua.tmpl > "$TMP/hyprland.lua"
Hyprland --verify-config -c "$TMP/hyprland.lua"
```

Proves the tree parses and every `require` resolves; does **not** prove dispatcher arguments are correct — the 0.56.2 stub types every dispatcher as `fun(...)`.

- [x] Confirm which entry point Hyprland loads today — `hyprland.conf`, by deliberate `.chezmoiignore` exclusion of `hyprland.lua`
- [x] Establish the actual unblock condition and record it where the hold lives
- [x] Diff each `conf/X.conf` against `conf/X.lua` and reconcile any drift — 21 pairs, 17 at parity. Four findings *(2026-08-30)*: (1) `voice.lua` lacked `.tmpl`, so the two Parakeet bindings were unconditional instead of desktop-only → renamed `voice.lua.tmpl` with the `chassisType` gate; (2) rose-pine dawn/moon wrote 10-digit `0xff<rrggbb><aa>` borders in *both* formats, silently truncated by Hyprland to the last 8 (`hyprctl getoption` returned `907aa9ee`) → converted to `rgba(...)`; (3) `SUPER+ALT+m` was labelled "Move to other monitor" but neither source crossed a monitor → `movewindow, mon:+1` / `hl.dsp.window.move({ monitor = "+1" })`; (4) `media-keys.conf` lacked the `.lua` side's locked/repeat flags, so volume+brightness were dead on the lock screen → `bindeld`/`bindld`
- [ ] Resolve the `SUPER+ALT+M` double-bind — `voice` ("Toggle meeting transcription") vs `workspace-management` (finding 3 above). Identical in both `.conf` and `.lua`, so not drift, but a real conflict
- [ ] When Waybar >= 0.16.0 lands: delete the `.chezmoiignore` block, `chezmoi apply`, verify workspace clicks
- [ ] Gate the retirement of the `.conf` set behind an explicit user go-ahead — keep both until the Lua path is confirmed across a reboot and a `hyprctl reload`
- [ ] Extend `run_once_after_007_validate_hyprland_config` to validate whichever entry point is authoritative — use the `Hyprland --verify-config -c <path>` recipe above
- [ ] Review omarchy's helper surface (`hl.unbind`, `hl.monitor{ transform = }`, `hl.env`) against our `conf/helpers.lua` — adopt `unbind` if we ever need to drop an inherited default

**Not doing**: `waybar-git`. It would be the first locally-built `-git` package in the repo and needs a vendored `#commit=<sha>` pin per `_guides/PACKAGE_SUPPLY_CHAIN_SECURITY.md`.

---

## P2 — Medium Priority

### NVIDIA GPU detection via sysfs instead of lspci (v4.0.0)

**What**: Omarchy switched NVIDIA detection from `lspci` to sysfs because `lspci` resumes a runtime-suspended discrete GPU out of D3cold, which can exceed Hyprland's 1.5s config-load budget and stall session start. They also classify by PCI device ID so pre-Maxwell cards stay off an incompatible driver and missed Maxwell/Pascal parts are picked up. We compute `.nvidiaDriverType` / `.nvidiaGpuDetected` in `.chezmoi.yaml.tmpl` — worth checking which probe we use and whether the legacy/modern split matches by device ID or by name string.
**Target files**: `.chezmoi.yaml.tmpl`, `.chezmoiscripts/run_once_before_001_preflight_and_session_validation.sh.tmpl`
**Effort**: Medium
**Adapt from**: `bin/omarchy-hw-nvidia`, `default/hypr/nvidia.lua`

- [x] Switched from `lspci` to sysfs: `.chezmoi.yaml.tmpl` now scans `/sys/bus/pci/devices/*/{vendor,class,device}` for vendor `0x10de` + class `0x03xx` — pure sysfs reads, never touches live PCI config space, so it can't wake a runtime-suspended dGPU *(done 2026-08-30)*
- [x] Classification kept as the existing name-string regex (GTX 900/1000, Titan X/XP/Z, Quadro K/M/P) — not rebuilt against a full device-ID table (out of scope for this pass) — but now applied to a name resolved from the static `/usr/share/hwdata/pci.ids` database instead of a live `lspci` call, so it stays wake-safe. `.nvidiaGpuDetected` format changed from a friendly lspci string to a raw PCI ID (`10de:1f91`); the one consumer (`run_once_before_001` log lines) updated to match *(done 2026-08-30)*
- [x] Verified: `chezmoi execute-template < .chezmoi.yaml.tmpl` resolves `nvidiaDriverType: "modern"`, `nvidiaGpuDetected: "10de:1f91"` on this machine (GTX 1650 Mobile/Max-Q, TU117M — correctly classified modern/Turing) *(done 2026-08-30)*
- [x] Added `hasIntegratedGpu` (sysfs scan for vendor `0x8086`/`0x1002` + class `0x03xx`) as a side effect — needed by the kms-hook item below; found this machine is actually hybrid (`hasIntegratedGpu: true`), correcting an earlier assumption *(done 2026-08-30)*

---

### Drop the `kms` hook when proprietary NVIDIA handles early KMS (v4.0.0)

**What**: On NVIDIA-only machines the `kms` mkinitcpio hook pulls nouveau and ~100MB of firmware into every initramfs for no benefit, because the proprietary driver already handles early KMS via its own modules. Omarchy drops the hook on NVIDIA-only systems and rebuilds existing images on upgrade. We build UKIs and already write `/etc/mkinitcpio.conf.d/nvidia.conf`, so we pay this cost on every kernel update.
**Target files**: `.chezmoiscripts/run_once_after_005_configure_boot_system.sh.tmpl`, `.chezmoidata/boot.yaml`
**Effort**: Medium
**Conflict**: Interacts with `boot.gpu.kms` and the Plymouth hook ordering already handled in script 005.

- [x] Made conditional at apply-time instead of a manual per-machine assumption: `.chezmoi.yaml.tmpl` now exposes `hasIntegratedGpu` (sysfs scan for vendor `0x8086`/`0x1002` + class `0x03xx`, same technique as the NVIDIA sysfs item above) — `run_once_after_005_configure_boot_system.sh.tmpl` checks it, not a hardcoded "this machine is NVIDIA-only" belief. Confirmed via `chezmoi execute-template` that **this machine is actually hybrid** (`hasIntegratedGpu: true`), correcting the OMARCHY.md skip-list's "no hybrid graphics here" note — the hook stays on this box, drops automatically on a genuinely NVIDIA-only one *(done 2026-08-30)*
- [x] `i915` is now also conditional on `hasIntegratedGpu` in the `MODULES=(...)` write (it was previously hardcoded in, which was already wrong on an NVIDIA-only box); when no iGPU, `kms` is stripped from `/etc/mkinitcpio.conf`'s `HOOKS=` array via a sed pattern mirroring the existing Plymouth-hook-insertion convention (backup-before-first-edit, idempotency check, hard-fail with a clear error if removal verification fails) *(done 2026-08-30)*
- [x] `nvidia_drm.modeset=1` and the nvidia modules stay in `MODULES` regardless — only `i915` and the `kms` HOOKS entry are conditional, so Plymouth still gets an early mode set *(done 2026-08-30)*
- [x] Fixed a latent bug found while touching this section: the NVIDIA `MODULES=` conf write never set the script's `REBUILD_NEEDED` flag, so a first-time write (or this new HOOKS edit) could silently skip the `mkinitcpio -P` rebuild it required — both `NVIDIA_MODULES_CHANGED` and `KMS_HOOK_CHANGED` now feed into it *(done 2026-08-30)*
- [x] Verified: rendered both branches (`hasIntegratedGpu: true` and a simulated `false`) via `chezmoi execute-template`, `bash -n`, and `shellcheck` — clean on both, and unit-tested the HOOKS-removal sed against sample lines with `kms` mid-list and `kms` as the last hook (first version had a backreference bug — `\1` was missing from the replacement — caught and fixed before this) *(done 2026-08-30)*
- [ ] Rebuild UKIs and reboot-test on a real NVIDIA-only machine (none available in this session) — Plymouth must still theme the LUKS prompt, and UKI size should measurably drop

---

### Ghostty CSI-u `Shift+Return` encoding (v3.8.3, v4.0.0)

**What**: Omarchy moved all shipped terminals to CSI-u encoding so TUIs can distinguish `Shift+Enter` (`CSI 13;2u`) and `Alt+Shift+Enter` (`CSI 13;4u`) from plain `Enter` / `Alt+Enter`. Our Ghostty config still sends the ambiguous legacy sequence: `keybind = shift+enter=text:\x1b\r`, which is indistinguishable from `Alt+Return`. Claude Code, Codex and other TUIs use `Shift+Enter` for newline-without-submit.
**Target files**: `private_dot_config/ghostty/config.tmpl`
**Effort**: Low
**Conflict**: Existing `shift+enter=text:\x1b\r` binding must be replaced, not appended.

- [ ] Replace `keybind = shift+enter=text:\x1b\r` with `keybind = shift+enter=csi:13;2u`
- [ ] Add `keybind = alt+shift+enter=csi:13;4u`
- [ ] Verify Claude Code / opencode still insert a newline on `Shift+Enter` after the change (some TUIs only understand the legacy sequence — roll back if so)
- [N/A] Mirror into `private_dot_config/kitty/` — no `kitty/` directory exists in this repo; Kitty is not chezmoi-managed *(verified 2026-08-30)*

---

### External monitor brightness via DDC/CI (v4.0.0)

**What**: Brightness keys and OSD drive the focused *external* display over DDC/CI; laptop panels keep using the kernel backlight. Our `media-keys` bindings call `brightnessctl set +10%`, which only touches an internal backlight — on the desktop (DP-1, 3840x2160) the brightness keys currently do nothing.
**Target files**: `private_dot_config/hypr/conf/bindings/media-keys.conf` + `.lua`, `.chezmoidata/packages.yaml`, new `private_dot_local/lib/scripts/desktop/executable_brightness-set`
**Effort**: Medium
**Adapt from**: `bin/omarchy-brightness-display-ddc`

- [x] Added `ddcutil` to `packages.yaml` (`desktop_hyprland`, next to `brightnessctl`) *(done 2026-08-30)*
- [x] Implemented `desktop/executable_brightness-set {up|down}` — `brightnessctl` when `/sys/class/backlight/*` exists (unchanged laptop behavior, verified: this machine has `intel_backlight` and takes this path), else resolves the Hyprland-focused monitor and matches it to a ddcutil bus by DRM connector name (`ddcutil detect --brief`'s "DRM connector: cardN-DP-X" vs Hyprland's `.name`) — verified the awk parser against sample multi-monitor `ddcutil detect --brief` output. `ponytail:` comment marks the single-monitor fallback (first detected bus) as the ceiling if connector matching fails; upgrade path is a full multi-monitor match, not needed for this desktop's one external display *(done 2026-08-30)*
- [x] Bus number cached per-monitor in `$XDG_RUNTIME_DIR/ddc-bus-<name>` *(done 2026-08-30)*
- [x] Repointed `XF86MonBrightnessUp/Down` in `media-keys.conf` + `.lua` at the new script; ran `stylua` on the `.lua` edit (line length required reformatting to multi-line `o.bind` calls) *(done 2026-08-30)*
- [x] `i2c-dev` + group permissions: added to `run_once_after_002_configure_system_services.sh.tmpl` (module load via `/etc/modules-load.d/i2c-dev.conf`, `i2c` group created with `groupadd -f` since Arch doesn't ship one by default, udev rule `KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"`, user added to the group) — gated on `command -v ddcutil`, verified via `chezmoi execute-template` + `shellcheck` *(done 2026-08-30)*
- [ ] Manual test on the real desktop with an external DDC/CI-capable monitor (not available in this session)

---

### SSH keepalive and reconnect resilience (v4.0.0)

**What**: Dropped SSH connections leave the terminal in a broken state (leftover mouse tracking, alternate screen) and the drop is only noticed whenever TCP eventually gives up. Omarchy adds client keepalives so the drop surfaces in ~45s, plus a reconnect wrapper that resets the terminal. Our `private_dot_ssh/private_config.tmpl` has no `ServerAliveInterval` at all.
**Target files**: `private_dot_ssh/private_config.tmpl`, `private_dot_config/zsh/dot_zshrc.d/` (new `ssh-reconnect.zsh`)
**Effort**: Low
**Adapt from**: `install/config/ssh-keepalive.sh`, `default/bash/fns/ssh-reconnect`

- [ ] Add `ServerAliveInterval 15` + `ServerAliveCountMax 3` under `Host *` in the SSH config
- [ ] Add a reconnect wrapper that runs `tput rmcup; printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l'` on exit before retrying
- [ ] Verify it does not fight the existing `fip`/`dip`/`lip` background forwards (those use `-f -N`)

---

### Semantic `colors.toml` + template-rendered app themes (v3.3.0, v3.3.1, v4.0.0, v4.0.1)

**What**: v4.0.0 replaced the ANSI-indexed `color0`–`color15` schema with a **24-key semantic colorset** (`mode`, `accent`, `selection`, `muted`, four `*background`, four `*foreground`, named + `bright_*` colors) and renders every app theme from `default/themed/*.tpl` at theme-set time — btop, neovim, VS Code, Helix, Chromium, foot, ghostty, kitty, alacritty, `hyprland.lua`, `shell.toml`. Per-theme `btop.theme` files are dropped entirely. Placeholders are `{{ key }}`, `{{ key_strip }}` (no `#`), `{{ key_rgb }}`, plus `{{ mix background foreground 15% }}` and gradient helpers. User templates at `~/.config/omarchy/themed/*.tpl` render first and suppress the built-in; a hand-written per-theme file still wins over the template.
This directly parallels our 24-semantic-variable architecture (`colors.sh` with `BG_*`/`FG_*`/`ACCENT_*`), but we still hand-maintain ~20 config files per theme across 8 themes. The v4.0.0 design is now stable enough to evaluate seriously — including the per-theme escape hatch, which is what makes template generation tolerable. v4.0.1 sharpened this further: for themes installed via `omarchy theme install <url>` (i.e. not first-party or user-authored), staging now copies **only** `colors.toml`, `light.mode`, images, and `backgrounds/*` — the four terminal configs, `*.lua`, and `vscode.json` are dropped and generated from `default/themed/*.tpl` instead, closing a code-execution path where a downloaded theme's Lua/config ran at theme-set time. That reframes "hand-written wins over template" as a **trust boundary**, not just a maintenance escape hatch: generation becomes mandatory, not merely default, for anything not first-party/self-authored.
**Target files**: `private_dot_config/themes/`, `private_dot_config/themes/CLAUDE.md`, theme generation scripts
**Effort**: High

- [ ] Map our 24 `colors.sh` semantic variables onto omarchy's 24-key colorset — confirm the sets are genuinely isomorphic before committing to the pattern
- [ ] Prototype template rendering for the two lowest-risk targets first (`btop.theme`, `bat.conf`) and diff generated vs hand-written output byte-for-byte across all 8 themes
- [ ] Adopt the "hand-written per-theme file wins over the template" precedence rule — several of our themes have deliberate manual tuning that must not be flattened
- [ ] Decide whether generation runs at chezmoi apply time (template) or theme-switch time (script); the chezmoi route avoids a second templating engine
- [ ] Keep the existing hand-written files in place until the generated set is validated — do not delete on the same change
- [ ] If we ever add "install theme from an external source": make generation mandatory (not just default) for anything not repo-owned or self-authored — this is the security boundary v4.0.1 added, not just a maintenance nicety

---

### Weather in Waybar, with pinnable location (v3.8.0, v4.0.0)

**What**: A `custom/weather` module polls a weather script and shows current conditions in the bar, with a notification binding for the full report. v4.0.0 adds a **forecast panel and a location that can be pinned to a chosen place instead of IP geolocation** — worth building in from the start rather than retrofitting, since IP geolocation is wrong on VPN/Tailscale. The CSS block and config comment are already present in our Waybar files.
**Target files**: `private_dot_config/waybar/config.tmpl`, `private_dot_config/waybar/style.css.tmpl`, new `private_dot_local/lib/scripts/desktop/executable_waybar-weather`
**Effort**: Medium
**Adapt from**: `default/waybar/weather.sh`, `bin/omarchy-weather-location`, `bin/omarchy-weather-status`

- [ ] Implement weather script using `wttr.in` or `open-meteo.com` (local units, icon + temp output)
- [ ] Support a pinned location from a config file, falling back to IP geolocation only when unset
- [ ] Uncomment `"custom/weather"` in `modules-center` in `config.tmpl`
- [ ] Uncomment `#custom-weather` CSS block in `style.css.tmpl` (already present as comment)
- [ ] Add `Super+Ctrl+Alt+W` binding to show the full weather notification
- [ ] Set poll interval to 60 seconds in module config; cache the response so a bar restart does not re-hit the API

---

### Persistent Hyprland toggle system (v3.6.0)

**What**: Named flag configs persisted to `~/.local/state/omarchy/toggles/hypr/` and sourced on every `hyprctl reload`. Survives restarts. Powers touchpad toggle, display toggle, etc. v4.0.0 keeps this pattern as `require("default.hypr.toggles")` at the end of the Lua entry point.
**Target files**: `private_dot_config/hypr/hyprland.lua.tmpl` (add require/glob), new state directory
**Effort**: Medium
**Adapt from**: `bin/omarchy-hyprland-toggle`, `default/hypr/toggles/flags.conf`, `default/hypr/toggles.lua`

- [x] Built `.conf`-native instead of Lua: Hyprland here still boots from `hyprland.conf` (the `.lua` entry point is `.chezmoiignore`'d pending the Waybar-blocked cutover), so a `require("...toggles")`-only mechanism would be dead code until then. Added `source = ~/.local/state/dotfiles/toggles/hypr/current.conf` near the end of `hyprland.conf.tmpl` instead — a plain Hyprland-config fragment scripts rewrite, works today *(done 2026-08-30)*
- [x] `run_once_before_004_create_necessary_directories.sh.tmpl` now `mkdir -p`s the dir and `touch`es `current.conf` — a deliberate, documented exception to the lazy-mkdir-in-script convention used everywhere else, because `source =` errors on a missing file and this one is read before any toggle script has ever run *(done 2026-08-30)*
- [x] Implemented `desktop/executable_hypr-toggle {set|clear} <key> [line...]`: rewrites a `# BEGIN <key>`/`# END <key>` delimited block in `current.conf` (awk delete-between-markers, idempotent re-set/clear) then `hyprctl reload`s. Verified: set/clear round-trip leaves sibling keys' blocks untouched *(done 2026-08-30)*
- [x] Used as the foundation for touchpad-toggle below *(done 2026-08-30)*

---

### Lid / clamshell display handling (v3.6.0, v4.0.0, v4.0.1)

**What**: Internal display auto-toggles via Hyprland `bindl` on `switch:on:Lid Switch` / `switch:off:Lid Switch`. v4.0.0 adds idempotent scale recovery on clamshell transitions and a lid-close handler, fixing the case where reopening the lid leaves the internal panel at the wrong scale. Only relevant on laptops (`chassisType == "laptop"`). v4.0.1 fixed a code-execution bug in the exact script this item adapts from: monitor names sourced from `hyprctl` output (attacker-influenceable) were interpolated unvalidated into generated `.lua` files that Hyprland re-executes on reload — the fix validates output names against `^[A-Za-z0-9._-]+$` before writing them as Lua.
**Target files**: `private_dot_config/hypr/conf/bindings/desktop-utilities.conf` + `.lua` (or a new `hardware.conf`)
**Effort**: Medium
**Adapt from**: `bin/omarchy-hyprland-monitor-clamshell`, `bin/omarchy-hw-clamshell`, `bin/omarchy-system-lid-close`

- [x] Added `bindld` lid switch handlers (`switch:on:Lid Switch` / `switch:off:Lid Switch`) in new `private_dot_config/hypr/conf/bindings/hardware.conf.tmpl` + `.lua.tmpl`, gated `{{ if eq .chassisType "laptop" }}` *(done 2026-08-30)*
- [x] New script `desktop/executable_lid-toggle {close|open}` resolves the internal panel via `hyprctl monitors -j` (`eDP*` name), disables/enables it via `hyprctl keyword monitor` *(done 2026-08-30)*
- [x] Idempotent: `close` persists the panel's current scale to `~/.local/state/dotfiles/lid-monitor-<name>`; `open` reapplies that scale rather than a default, so repeated cycles converge *(done 2026-08-30)*
- [x] Guards against disabling the only active display (counts non-disabled monitors via `hyprctl monitors -j` first) *(done 2026-08-30)*
- [x] Checked HyprDynamicMonitors: `hyprdynamicmonitors/config.toml:3` has `enable_lid_events = false` — it deliberately doesn't touch lid events, so no conflict *(verified 2026-08-30)*
- [x] Output name validated against `^[A-Za-z0-9._-]+$` before any `hyprctl keyword` use (v4.0.1 fix pattern) — no existing in-repo helper to copy, written fresh as a small shell function shared with the touchpad-toggle item below *(done 2026-08-30)*
- [ ] Manual end-to-end test: real lid close/open cycle on hardware (not testable in this session — no live Hyprland compositor); functional logic verified with mocked `hyprctl`/`jaq` output instead

---

### `mise activate bash --shims` in uwsm/env (v3.4.2)

**What**: The `--shims` flag ensures mise-managed tools are available in non-interactive Wayland session environments (e.g. apps launched from Hyprland that don't spawn a login shell).
**Target files**: `private_dot_config/uwsm/env`
**Effort**: Low
**Note**: v4.0.0 moves this to a package-owned `/usr/share/uwsm/env.d/10-omarchy` — not applicable to us; `~/.config/uwsm/env` remains the right home for our copy.

- [x] Create `private_dot_config/uwsm/env` managed by chezmoi
- [x] Set `mise activate bash --shims` in that file
- [ ] Verify mise-managed tools (e.g. node, ruby) are visible to Wayland-launched apps

---

### LocalSend minimum window size rule (v3.4.2)

**What**: LocalSend opens with a small default window. A `windowrulev2` with `minsize` fixes this.
**Target files**: `private_dot_config/hypr/conf/windowrules.conf` + `.lua`
**Effort**: Low

- [x] Add window rule for LocalSend: `windowrule = match:class localsend, minsize 600 400`
- [ ] Confirm localsend class name: `hyprctl clients | grep -A5 -i localsend`
- [ ] Mirror the rule into `windowrules.lua` (dual-source drift risk — see P1 Lua item)

---

### Audio switch `wpctl set-default` fix (v3.6.0, v4.0.0)

**What**: `pactl set-default-sink` doesn't persist via WirePlumber; `wpctl set-default <id>` does. v4.0.0 additionally makes output/source switching **preserve playback** and adds recovery when audio services get stuck.
**Target files**: `private_dot_local/lib/scripts/desktop/executable_audio-switch`
**Effort**: Low
**Adapt from**: `bin/omarchy-restart-audio`, `bin/omarchy-audio-sink-availability`

- [x] Replace `pactl set-default-sink "$next_sink"` with `wpctl set-default` using PipeWire object ID from pactl JSON `.index` field *(done 2026-05-04)*
- [ ] Test: switch audio device, close session, reopen — sink should persist
- [ ] Consider moving existing streams to the new sink so playback survives the switch (v4.0.0 behaviour)

---

## P3 — Low Priority / Evaluate

### Apps launched in their own systemd scopes with oomd (v4.0.0)

**What**: Apps launched into per-app systemd scopes rather than the compositor's cgroup, with a `systemd-oomd` drop-in on `app.slice`, so a runaway app gets killed instead of the whole Hyprland session. Genuinely valuable — an OOM today takes the session down with it.
**Target files**: `private_dot_config/systemd/user/app.slice.d/10-oomd.conf` (new), `.chezmoiscripts/`
**Effort**: Medium
**Adapt from**: `default/systemd/user/app.slice.d/10-oomd.conf`, `etc/systemd/oomd.conf.d/10-omarchy.conf`

- [ ] Check whether uwsm already places launched apps in `app.slice` scopes (it largely does — confirm with `systemd-cgls`)
- [ ] Add an `app.slice.d/10-oomd.conf` user drop-in enabling `ManagedOOMMemoryPressure=kill`
- [ ] Verify `systemd-oomd` is running and confirm the session survives a deliberate memory hog

---

### zram swap tuning (v4.0.0)

**What**: zram left at kernel defaults makes large machines reach for the hibernation swapfile earlier than necessary. Omarchy ships a `zram-generator.conf.d` drop-in. We configure hibernation (`boot.hibernation.enabled`) but do not tune zram.
**Target files**: `.chezmoiscripts/run_once_after_005_configure_boot_system.sh.tmpl`, `.chezmoidata/boot.yaml`
**Effort**: Medium
**Adapt from**: `default/systemd/zram-generator.conf.d/90-omarchy.conf`, `etc/tmpfiles.d/omarchy-zswap.conf`

- [ ] Check current zram size (`zramctl`) and whether `zram-generator` is even installed
- [ ] If adopting: size zram relative to RAM and confirm it does not conflict with the hibernation resume offset already configured in script 005

---

### Power profile remembered per power source (v3.4.0, v3.5.1, v3.8.3, v4.0.0)

**What**: Power profile switches automatically on AC plug/unplug, applied at boot too (udev rules only fire on state changes). v3.8.3 fixes the udev rule failing on wakeup by dropping a fixed `--unit=` transient unit name that collided with a still-running unit from a prior trigger. v4.0.0 fixes a plug/unplug race and makes an **explicit** profile choice remembered *per power source* across reboots. Our setup only has manual switching via `menu-setup`.
**Target files**: Systemd udev rule or hook, `private_dot_local/lib/scripts/user-interface/executable_menu-setup.tmpl`
**Effort**: Medium
**Adapt from**: `bin/omarchy-ac-present`, `bin/omarchy-powerprofiles-init`, `bin/omarchy-powerprofiles-set`

- [ ] Add a boot-time autostart that applies the correct profile based on current AC state (fixes "stuck on balanced at boot")
- [ ] If adding udev rules: use `systemd-run --no-block --collect` **without** a fixed `--unit=` name (v3.8.3 fix)
- [ ] Persist the last explicit choice keyed by power source so a manual override is not clobbered by the next plug event
- [ ] Mostly a laptop concern — gate on `chassisType`

---

### QR code capture from screen region (v4.0.0)

**What**: Select a screen region and decode any QR inside it straight to the clipboard. The decoded value never touches disk and is marked sensitive so clipboard history skips it. We already have a `clipboard-store` wrapper that filters sensitive content, so the sensitive-marking half is half-built.
**Target files**: `.chezmoidata/packages.yaml`, `private_dot_local/lib/scripts/media/`, `private_dot_config/hypr/conf/bindings/screenshots.conf` + `.lua`
**Effort**: Low
**Adapt from**: `bin/omarchy-capture-qr`

- [x] Added `zbar` to `packages.yaml` (`desktop_hyprland`) *(done 2026-08-30)*
- [x] Implemented `media/executable_capture-qr`: `slurp` region → `grim -g` to stdout → `zbarimg --quiet --raw` → `wl-copy`, sharing a new `capture-region.sh` freeze/select helper with the OCR script below. Verified with mocked `slurp`/`grim`/`zbarimg`/`wl-copy` *(done 2026-08-30)*
- [x] No extra plumbing needed for the sensitive-content path — `wl-copy` already flows through the existing `wl-paste --watch clipboard-store | cliphist store` pipeline, which runs its gitleaks filter on every clipboard write regardless of source. Noted as a documented gap in the script: gitleaks matches known secret *patterns*, so a plain-looking payload (bare Wi-Fi PSK, etc.) with no recognizable format won't be caught *(done 2026-08-30)*
- [x] Decoded value never touches disk — piped stdout to stdout throughout *(done 2026-08-30)*
- Bound to `CTRL + Print` in `screenshots.conf`/`.lua` *(done 2026-08-30)*

---

### OCR text extraction from screen region (v3.7.0)

**What**: Freeze screen with `hyprpicker`, select region with `slurp`, capture with `grim`, extract text with `tesseract`, copy to clipboard.
**Target files**: `.chezmoidata/packages.yaml`, `private_dot_local/lib/scripts/media/`, `private_dot_config/hypr/conf/bindings/screenshots.conf`
**Effort**: Low
**Adapt from**: `bin/omarchy-capture-text-extraction`

- [x] Added `tesseract` + `tesseract-data-eng` to `packages.yaml` (`desktop_hyprland`) *(done 2026-08-30)*
- [x] Implemented `media/executable_capture-text-extraction`: `slurp` to select, `grim -g` to capture, `tesseract stdin stdout` to extract, `wl-copy` to clipboard. Used `wayfreeze` (not `hyprpicker -r -z`) for the freeze step — matches what `executable_screenshot` already uses in this repo, not Omarchy's tool. Shares the freeze/select plumbing with `capture-qr` via new `media/capture-region.sh` (extracted since 3 call sites — screenshot's own smart/windows/fullscreen modes were left untouched, too risky to retrofit for a working script with no test harness). Verified with mocked `tesseract` *(done 2026-08-30)*
- Bound to `SUPER CTRL SHIFT + Print` in `screenshots.conf`/`.lua` *(done 2026-08-30)*
- [ ] Share the freeze/select plumbing with `capture-qr` above

---

### Keyboard-driven region picker (v4.0.0)

**What**: In the region-select overlay, `RETURN` captures the highlighted window, `CTRL+RETURN` the whole display, `TAB`/arrows move the selection — no mouse needed. Implemented as **transient Hyprland binds registered on `layer.opened` for the `selection` namespace and removed on `layer.closed`**, which is the genuinely reusable trick here.
**Target files**: `private_dot_config/hypr/conf/bindings/screenshots.lua`, `private_dot_local/lib/scripts/media/executable_screenshot`
**Effort**: Medium
**Adapt from**: `default/hypr/bindings/utilities.lua`, `bin/omarchy-capture-region`

- [x] **Scoped down** (user decision 2026-08-30): Omarchy's full mouse-free transient-layer-bind overlay is out of scope for this pass. `executable_screenshot` already implemented `region`/`windows` modes with no keybinding attached — just bound them: `SUPER CTRL + Print` → `screenshot region`, `SUPER ALT + Print` → `screenshot windows`, in `screenshots.conf`/`.lua` *(done 2026-08-30)*
- [ ] The full transient-bind (`layer.opened`/`layer.closed` on `selection` namespace) mouse-free overlay remains unimplemented — revisit if wanted later
- [ ] Rotated-monitor handling in the region picker still untouched (applies to both `screenshot` and `screenrecord`)

---

### Screen recording notification thumbnail + open (v3.4.2, v3.5.0, v3.6.0, v4.0.0)

**What**: After stopping a recording, generate a thumbnail via `ffmpeg` and send a desktop notification with an open action. v3.5.0 fixes webcam overlay crop (`crop=iw/2:ih` before scaling); v3.6.0 adds single-pass audio normalization (`loudnorm=I=-14:TP=-1.5:LRA=11`, only when an audio stream is present); v4.0.0 fixes the region picker on rotated monitors and restricts webcam enumeration to real video capture devices.
**Target files**: `private_dot_local/lib/scripts/desktop/executable_screenrecord`
**Effort**: Medium
**Adapt from**: `bin/omarchy-capture-screenrecording` (renamed from `omarchy-cmd-screenrecord` in v3.7.0)

- [x] Added thumbnail generation: `ffmpeg -y -ss 0 -i "$saved_file" -vframes 1 "$thumb_file"` after recording stops. The stop branch didn't previously know the output path (only the PID was persisted) — added a sibling `${PID_FILE}.path` file written at recording start, read and removed at stop *(done 2026-08-30)*
- [x] Added `notify-send -A "open=Open"` with the thumbnail as icon, backgrounded in a subshell (so the script itself still returns immediately) — clicking "Open" runs a fixed `xdg-open "$saved_file"` argv resolved from the returned action name, never a shell-interpolated string built from notification data (the v4.0.1 injection-class fix). Verified end-to-end with mocked `ffmpeg`/`notify-send`/`xdg-open`: thumbnail generated, action click triggered `xdg-open`, PID+path files cleaned up, tracked process actually killed *(done 2026-08-30)*
- [ ] Audio normalization pass (`loudnorm=I=-14:TP=-1.5:LRA=11`) — not in this pass's scope, separate sub-feature
- [ ] Rotated-monitor handling in the region picker — not in this pass's scope, separate sub-feature (also noted under the keyboard-region-picker item above)
- [N/A] Webcam overlay crop fix — no webcam overlay compositing exists in this script at all (confirmed via exploration), nothing to fix

---

### Video transcode / GIF utilities (v3.7.0, v3.8.0, v4.0.0)

**What**: v3.7.0 adds a `transcode-video-gif` shell function; v3.8.0 expands to `omarchy-transcode` covering video (mp4, gif), audio and pictures. v4.0.0 ships **Omacut**, a dedicated ffmpeg-based video trimmer — the trim operation is the piece our screen-recording workflow actually lacks.
**Target files**: `private_dot_local/lib/scripts/media/` or `private_dot_config/zsh/dot_zshrc.d/`
**Effort**: Low
**Adapt from**: `bin/omarchy-transcode`

- [ ] Implement `video-to-gif` using `ffmpeg` (palette generation + dither for quality GIFs)
- [ ] Consider a minimal `video-trim START END` helper (`-ss`/`-to` with stream copy) for cutting screen recordings
- [ ] Skip the full audio/picture transcode menu unless a need appears

---

### `udiskie` automount for removable drives (v4.0.0)

**What**: Automounting of removable drives, added as a default in v4.0.0. We have no automount today — USB sticks require manual mounting.
**Target files**: `.chezmoidata/packages.yaml`, `private_dot_config/hypr/conf/autostart.conf` + `.lua`
**Effort**: Low

- [ ] Add `udiskie` to `packages.yaml`
- [ ] Autostart `udiskie --tray --notify` (or `--no-tray`) from Hyprland autostart
- [ ] Confirm it does not conflict with Thunar's own `gvfs`-based mounting

---

### Bluetooth power state persisted across reboots (v4.0.0)

**What**: Bluetooth power state persisted by making an rfkill soft block the state systemd restores at boot — so Bluetooth-off actually stays off. We use `blueman` + `bluetui`.
**Target files**: `private_dot_local/lib/scripts/desktop/`, `.chezmoiscripts/`
**Effort**: Low
**Adapt from**: `bin/omarchy-bluetooth-power`

- [ ] Check whether Bluetooth currently comes back on after a reboot when turned off
- [ ] If so: set the state via `rfkill block bluetooth` rather than `bluetoothctl power off` so systemd restores it

---

### Docker multi-arch builds by default (v4.0.0)

**What**: `qemu-user-static-binfmt` plus a `daemon.json` enabling multi-arch builds, so `docker buildx build --platform linux/arm64` works without per-session setup. We have `docker-buildx` already.
**Target files**: `.chezmoidata/packages.yaml`, `.chezmoiscripts/run_once_after_002_configure_system_services.sh.tmpl`
**Effort**: Low

- [ ] Add `qemu-user-static-binfmt` to `packages.yaml`
- [ ] Confirm binfmt handlers register at boot (`ls /proc/sys/fs/binfmt_misc/`)
- [ ] Only worth doing if cross-arch images are actually built here

---

### Chromium-based browsers pinned to gnome-libsecret (v4.0.0)

**What**: Chromium password-store backend autodetection can silently fail and log you out. Omarchy pins `--password-store=gnome-libsecret`. We have `gnome-keyring` installed; primary browser is Firefox, so this only matters for Chromium usage.
**Target files**: `private_dot_config/chromium-flags.conf` (new)
**Effort**: Low

- [ ] Only act if Chromium is in regular use
- [ ] Add `--password-store=gnome-libsecret` to a managed `chromium-flags.conf`

---

### `paccache` pruning + low-disk-space guard before updates (v4.0.0, v4.0.1)

**What**: Omarchy prunes the package cache with `paccache -rk2` as the **first** update step — before the snapshot, so the space is actually reclaimed — keeping one spare version for the offline downgrade path, and warns when disk space is low before updating. v4.0.1's Improvements list reconfirms "package cache pruned before updating" as part of the same update flow.
**Correction (2026-08-30)**: this item's premise was stale — `system-maintenance` does **not** use `pacman -Sc --noconfirm`; `--cleanup` already runs `paccache -rk2` + `paccache -ruk0` (with a comment explicitly documenting why `-Sc` is avoided). Only the free-space warning was actually missing.
**Target files**: `private_dot_local/lib/scripts/system/executable_system-maintenance`
**Effort**: Low
**Adapt from**: `bin/omarchy-update-pkg-prune`, `bin/omarchy-update-requires-free-space`

- [x] `paccache -rk2` + `paccache -ruk0` already implemented in `--cleanup` *(confirmed pre-existing, 2026-08-30)*
- [x] Added a free-space check to the `--update` path: warns via `ui_warning` (non-blocking, matches the script's non-interactive automation style) when `/` has under 2GiB free, before `pacman -Syu` runs *(done 2026-08-30)*
- [N/A] Order the prune before any Timeshift snapshot — `system-maintenance` has no snapshot step: `--update` and `--cleanup` are separate options and neither invokes Timeshift, so there is no ordering to fix *(verified 2026-08-30)*

---

### Hyprland reload paused during pacman transactions (v4.0.0)

**What**: ALPM hooks pause Hyprland config reload for the duration of a pacman transaction, avoiding reloads against a half-updated tree (which can leave the session with an error bar or a broken config).
**Target files**: `.chezmoiscripts/`, `/etc/pacman.d/hooks/` via a lifecycle script
**Effort**: Medium
**Adapt from**: `default/libalpm/hooks/10-omarchy-hyprland-reload-pause.hook`, `default/libalpm/hooks/90-omarchy-hyprland-reload-resume.hook`

- [ ] Assess whether we actually trigger Hyprland reloads during pacman transactions (we may not — this could be a non-problem here)
- [ ] If yes: add PreTransaction/PostTransaction hooks writing/removing a pause flag that our reload path checks

---

### AI crash diagnosis from systemd-coredump (v4.0.0)

**What**: A systemd user service streams the `systemd-coredump` journal, raises a "Process crashed" toast, and clicking it briefs the default coding agent with a `diagnose-crash` skill. Novel and cheap; we already have an AI stack (`llama-swap`, `menu-ai`, Claude Code).
**Target files**: `private_dot_config/systemd/user/`, `private_dot_local/lib/scripts/ai/`
**Effort**: Medium
**Adapt from**: `bin/omarchy-crash-watch`, `default/systemd/user/omarchy-crash-watch.service`, `default/agents/skills/diagnose-crash/`

- [ ] Implement a `journalctl -f -u systemd-coredump -o json` follower that emits `notify-send` on new coredumps
- [ ] Add an action that pipes `coredumpctl info` output into the agent
- [ ] Keep it opt-in via `features.yaml` — a chatty crash watcher is worse than none

---

### Coding-agent usage widget for Waybar (v4.0.0)

**What**: A bar widget showing Claude Code / Codex / Fireworks usage stats. Directly applicable — we run Waybar and Claude Code.
**Target files**: `private_dot_config/waybar/config.tmpl`, `private_dot_config/waybar/style.css.tmpl`, `private_dot_local/lib/scripts/ai/`
**Effort**: Medium
**Adapt from**: `bin/omarchy-agent-usage-claude`, `bin/omarchy-agent-usage-codex`

- [ ] Check what usage data Claude Code exposes locally (config/state dir) vs requiring an API call
- [ ] Implement a `custom/agent-usage` module with a sane poll interval (usage data changes slowly — 5 min, not 60s)
- [ ] Only add if the data source is local; do not poll a paid API from the bar

---

### Tailscale exit-node picker (v4.0.0)

**What**: A Tailscale connection control and exit-node picker with Mullvad nodes grouped by country. We have `tailscale` installed and a `network` script category.
**Target files**: `private_dot_local/lib/scripts/network/`, `private_dot_config/waybar/`
**Effort**: Medium
**Adapt from**: `bin/omarchy-install-service-tailscale`

- [ ] Implement a Wofi-driven exit-node picker over `tailscale exit-node list` (or `tailscale status --json`)
- [ ] Group by country in the picker labels
- [ ] Optionally surface connection state in Waybar

---

### Text scaling as a single knob (v4.0.0)

**What**: `omarchy display text size` (9–20px) moves the shell font, GTK `text-scaling-factor`, and terminal point size together. We set fonts via `gsettings.yaml` + `globals.guiFont`/`terminalFont` at apply time, with no runtime adjustment.
**Target files**: `private_dot_local/lib/scripts/desktop/`, `.chezmoidata/gsettings.yaml`
**Effort**: Medium
**Adapt from**: `bin/omarchy-display-text-size`

- [ ] Evaluate whether runtime text scaling is wanted at all, or whether the apply-time `gsettings.yaml` values are sufficient
- [ ] If pursuing: note `gsettings.extra_settings` already exists as the extension point for `text-scaling-factor`
- [ ] Terminal point size would need to be a Ghostty config write + reload, which weakens the "one knob" story

---

### Fine and coarse window resize tiers (v4.0.0)

**What**: Separate fine (±25px) and coarse (±100px) resizing tiers. Our `window-resizing.conf` has a single ±20px step on `SUPER CTRL + arrows`, which is slow for large changes on a 4K display.
**Target files**: `private_dot_config/hypr/conf/bindings/window-resizing.conf` + `.lua`
**Effort**: Low

- [ ] Consider raising the base step from 20 to ~50 on the 4K monitor
- [ ] A coarse tier would need a new modifier combination — weigh against the no-new-keybindings preference

---

### `dua-cli` as a `dust` replacement (v4.0.0)

**What**: Omarchy replaced `dust` with `dua-cli`. We have `dust` in `terminal_tools` and `alias du='dust'`. `dua` adds an interactive TUI mode (`dua i`) with deletion; `dust` is display-only.
**Target files**: `.chezmoidata/packages.yaml`, `private_dot_config/zsh/dot_zshrc.d/aliases.zsh`
**Effort**: Low

- [ ] Evaluate `dua i` against the current `dust` workflow — the interactive delete is the only real differentiator
- [ ] If adopting, keep `dust` alongside rather than swapping the `du` alias out from under muscle memory

---

### `tensaku` as a `satty` replacement (v4.0.0)

**What**: Omarchy replaced Satty with Tensaku for screenshot annotation. Our `screenshot` script uses `satty`.
**Target files**: `.chezmoidata/packages.yaml`, `private_dot_local/lib/scripts/media/executable_screenshot`
**Effort**: Low

- [ ] Check whether `tensaku` is packaged outside Omarchy's repo at all — if it is OPR-only, this is a non-starter
- [ ] Only switch if it offers something Satty lacks; Satty works today

---

### Lighter Nerd Font variant (v4.0.0)

**What**: `ttf-jetbrains-mono-nerd-basic` replaces the full Nerd Font, saving ~200MB. We ship `ttf-firacode-nerd` and use `GeistMono Nerd Font` as `terminalFont`.
**Target files**: `.chezmoidata/packages.yaml`
**Effort**: Low

- [ ] Check installed size of our Nerd Font packages and whether a `-basic` variant exists for them
- [ ] Only act if the saving is real and no glyphs in use are dropped (verify with `fc-list` against the icons in our Waybar/Starship configs)

---

### `imv` trash-on-delete (v4.0.0)

**What**: `imv` deletions go to trash instead of being unlinked, and `Ctrl+E` opens the image in the annotator. We have `imv` installed but no managed config.
**Target files**: `private_dot_config/imv/config` (new)
**Effort**: Low

- [ ] Create a managed `imv` config binding delete to `gio trash` rather than `rm`
- [ ] Add `Ctrl+E` → open in `satty`

---

### Caps Lock toggle via both Shift keys (v4.0.0)

**What**: Pressing both Shift keys together toggles Caps Lock. We already run `kanata` (see `kanata-layer` scripts), which is the natural place for this.
**Target files**: kanata config
**Effort**: Low

- [ ] Evaluate against the existing kanata layer setup — this may already be covered or deliberately omitted

---

### LUKS prompt keymap in the initramfs (v3.8.3, v4.0.0)

**What**: `FILES+=(/etc/vconsole.conf)` in the mkinitcpio drop-in so the console keymap is present in the initramfs, fixing a LUKS passphrase prompt that ignores the configured keyboard layout. **Currently a no-op for us**: `kb_layout = us` and the console default is `us`, so the prompt already accepts the right characters. Becomes relevant the moment a non-US layout (e.g. `fr`) is configured.
**Target files**: `.chezmoiscripts/run_once_after_005_configure_boot_system.sh.tmpl`
**Effort**: Low

- [ ] Defer while `kb_layout = us`
- [ ] If a non-US layout is ever adopted: append `FILES+=(/etc/vconsole.conf)` to the mkinitcpio drop-in and rebuild UKIs, then reboot-test the LUKS prompt before relying on it

---

### Theme-install input hardening (v4.0.0, v4.0.1)

**What**: v4.0.0 closed three theme-install code-execution paths: `colors.toml` values reaching GNU `sed`'s `e` flag, an unescaped VS Code theme name, and unvalidated keyboard RGB values. v4.0.1 went further than input validation: for non-first-party themes, executable files (`*.lua`, terminal configs, `vscode.json`) are no longer staged at all — they're generated from templates instead. That's a stronger boundary than sanitizing values, and directly informs the P2 template-rendering item above. Our themes are repo-owned and chezmoi-managed (low risk today), but `colors.sh` is `source`d by scripts — arbitrary shell in a theme file executes. This matters if theme import from external sources is ever added, or if the template-generation work above lands.
**Target files**: `private_dot_config/themes/CLAUDE.md`, theme generation/apply scripts
**Effort**: Low

- [ ] Document the trust boundary in `themes/CLAUDE.md`: theme files are executed, therefore repo-owned only
- [ ] If template generation lands: validate color values against `^#[0-9a-fA-F]{6}$` before substitution, and never pass theme-derived values through `sed` expressions
- [ ] Prefer "don't stage executable theme files at all" over "sanitize values" if external theme import is ever added — matches the v4.0.1 approach, stronger than input validation alone
- [ ] Never add an "import theme from URL" feature without this in place

---

### Touchpad toggle with OSD and persistence (v3.6.0, v4.0.1)

**What**: Touchpad `on`/`off`/`toggle` with state persisted via the toggle system. Hardware keys `XF86TouchpadOn/Off/Toggle`. Laptop-relevant only. v4.0.1 fixed a code-execution bug in the exact script this adapts from (`omarchy-toggle-input-device`): the disabled device name comes from USB descriptors (attacker-influenceable) and was interpolated unvalidated into `hyprctl eval` and a generated `.lua` file Hyprland re-executes on reload — reachable even from the **locked** `XF86TouchpadToggle` binding, since that bind is `locked = true`.
**Target files**: `private_dot_config/hypr/conf/bindings/`, `private_dot_local/lib/scripts/desktop/`
**Effort**: Medium
**Adapt from**: `bin/omarchy-hw-touchpad`

- [x] Depends on: persistent Hyprland toggle system (P2 item) — built first *(done 2026-08-30)*
- [x] Implemented `desktop/executable_touchpad-toggle`: finds the touchpad via `hyprctl devices -j`, toggles live via `hyprctl keyword "device[$name]:enabled" true/false`, `notify-send` OSD *(done 2026-08-30)*
- [x] **Post-apply bug found and fixed**: the initial name-match regex (`test("touchpad")`) worked against a mocked device name but failed on this machine's real hardware — `hyprctl devices -j` reports it as `synaptics-tm3512-010`, no literal "touchpad" substring. Widened the match to `touchpad|synaptics|clickpad|alps|elan` (excluding `trackpoint|trackball`, since some trackpoints are also Elan-branded). Verified end-to-end on real hardware after `chezmoi apply`: two full toggle cycles, `current.conf` block and marker file appeared/cleared correctly each time, touchpad left enabled *(done 2026-08-30)*
- [x] Persisted via `hypr-toggle set/clear touchpad` (item above) plus a boolean marker file (`~/.local/state/dotfiles/touchpad-disabled`) tracking current state across invocations *(done 2026-08-30)*
- [x] Device name validated against `^[A-Za-z0-9._:-]+$` (expanded from item 5's pattern to allow `:`, which real touchpad device names use) before it reaches the `hyprctl keyword` string or the persisted config fragment — passed as a quoted argv element, never `eval`'d — the exact v4.0.1 `omarchy-toggle-input-device` fix class *(done 2026-08-30)*
- [x] Bound `XF86TouchpadToggle` (`bindld` — locked, so it works even from the lock screen, matching the v4.0.1 finding that this bind is reachable while locked) in `hardware.conf.tmpl`/`.lua.tmpl` alongside the lid bindings, laptop-gated *(done 2026-08-30)*

---

### Idle lock display-off improvement (v3.8.0)

**What**: Powers off the display 3 seconds after locking if hyprlock is still running, and re-enables it on wake.
**Target files**: `private_dot_config/hypr/hypridle.conf.tmpl`, `private_dot_local/lib/scripts/desktop/executable_immediate-lock`
**Effort**: Low
**Adapt from**: `bin/omarchy-system-lock`, `bin/omarchy-system-wake`

- [ ] Check the current hypridle config for a DPMS timeout after lock
- [ ] If absent: add a 3-second post-lock `hyprctl dispatch dpms off`
- [ ] Ensure the display wakes correctly on resume

---

### Middle-click paste (GTK primary selection) (v3.8.0)

**What**: `gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true` enables middle-click paste in GTK apps and Chromium. Not applied in our setup — and `gsettings.extra_settings` already exists as the extension point.
**Target files**: `.chezmoidata/gsettings.yaml`
**Effort**: Low

- [ ] Add to `gsettings.extra_settings`: `{schema: "org.gnome.desktop.interface", key: "gtk-enable-primary-paste", value: "true"}`
- [ ] Verify `run_onchange_after_configure_gsettings` picks it up and it takes effect in Thunar

---

### FUSE filesystem hang on suspend fix (v3.5.0)

**What**: A `system-sleep` hook lazy-unmounts `gvfsd-fuse` filesystems before suspend/hibernate and restarts `gvfs-daemon.service` on wake.
**Target files**: `/etc/systemd/system-sleep/` via a lifecycle script
**Effort**: Medium
**Adapt from**: `default/systemd/system-sleep/unmount-fuse`

- [ ] Evaluate if gvfsd-fuse is relevant here (used by Thunar/GNOME Keyring)
- [ ] If yes: create `run_once_after_setup_fuse_suspend_hook.sh.tmpl`
- [ ] Hook: lazy-unmount gvfsd-fuse mounts before sleep; restart `gvfs-daemon.service` on wake

---

### Voxtype `pause_media` verification (v3.6.0)

**What**: `pause_media = true` under `[audio]` pauses MPRIS players while dictating.
**Target files**: `private_dot_config/voxtype/config.toml`
**Effort**: Low

- [x] Added `pause_media = true` to `[audio]`; file chezmoi-managed *(done 2026-05-04)*
- [ ] `voxtype setup systemd` may overwrite parts of the config — verify the approach survives a re-run

---

### ALT+TAB window cycling (v1.7.0)

**What**: `Alt+Tab` cycles between windows on the active workspace including floating.
**Target files**: `private_dot_config/hypr/conf/bindings/focus-navigation.conf`
**Effort**: Low
**Note**: May conflict with application-level Alt+Tab if Hyprland intercepts it globally. Also sits against the no-new-keybindings preference.

- [ ] Evaluate whether a global `Alt+Tab` intercept is desirable given application usage

---

### Battery notification persistence (v1.10.0)

**What**: Omarchy tested battery notification persistence at 30 seconds. Our idle timeouts are intentionally more relaxed, but notification duration may differ.
**Target files**: `private_dot_config/swaync/`
**Effort**: Low

- [ ] Review battery notification duration in swaync config — confirm 30s persistence or adjust to taste

---

### Switch `mise` to the packaged `mise-bin` (v4.0.1)

**What**: Omarchy switched from a source-built `mise` install to the `mise-bin` package (packaged binary distribution) — faster installs/updates, no build step. We install plain `mise` in `packages.yaml` (`developer.mise.enabled` gates whether the toolchain is set up, not which package resolves).
**Target files**: `.chezmoidata/packages.yaml`
**Effort**: Low

- [ ] Check whether our `mise` package currently builds from source or already resolves to a binary release
- [ ] If from-source: switch to `mise-bin` for faster installs, same binary/CLI

---

## Completed

- [x] **Sticky CWD when opening a new terminal** (v2.0.0, v4.0.0) — `SUPER + Return` launches the terminal with `--working-directory=$(terminal-cwd)`; script at `private_dot_local/lib/scripts/terminal/executable_terminal-cwd` *(confirmed 2026-08-24)*
- [x] **`fip`/`dip`/`lip` zsh parsing** (v3.4.0, v4.0.0) — v4.0.0 fixed omarchy's bash functions misparsing under zsh; our `ssh-port-forwarding.zsh` is a native zsh rewrite using `(( $# ))` and `for port in "$@"`, unaffected *(confirmed 2026-08-24)*
- [x] **Clipboard sensitive-content exclusion** (v1.3.1, v4.0.0) — `clipboard-store` wrapper filters by window class/title; v4.0.0's native equivalent adds nothing we lack *(confirmed 2026-08-24)*
- [x] **`quickshell` package** (v4.0.0, v4.0.1) — already in `packages.yaml` as the official `extra` package, driving the voxtype waveform OSD overlay; v4.0.1's switch to the packaged `quickshell` (away from a patched workaround build) matches what we already had; the full omarchy-shell replacement is out of scope *(confirmed 2026-08-30)*
- [x] **`networkmanager` as the network stack** (v4.0.0) — already in `packages.yaml` alongside `iwd` as the backend; omarchy's iwd→NM move validates the existing setup *(confirmed 2026-08-24)*
- [x] **`pacman-contrib`** (v4.0.0) — already in `packages.yaml`; `paccache` available for the update-prune item above *(confirmed 2026-08-24)*
- [x] **`wtype`** (v4.0.0) — already in `packages.yaml` as a voxtype dependency *(confirmed 2026-08-24)*
- [x] **`sof-firmware`** (v3.8.0, v3.8.3) — already in `packages.yaml`; v3.8.3 widened omarchy's install guard to all Intel SOF platforms, which does not change our unconditional inclusion *(confirmed 2026-08-24)*
- [x] **Monitor mirroring** (v3.7.0, v4.0.0) — `monitor-mirror` script already present in `lib/scripts/desktop/`; only omarchy's `Super+Ctrl+Alt+Del` binding was skipped *(confirmed 2026-08-24)*
- [x] **`tdl` alias split `ic`/`ix`/`icx`** (v3.7.0) — no `tdl` aliases exist in `aliases.zsh`; nothing to migrate *(confirmed 2026-08-24)*
- [x] **Audio switch `wpctl` persistence fix** (v3.6.0) — replaced `pactl set-default-sink` with `wpctl set-default` using PipeWire object ID from pactl JSON *(done 2026-05-04)*
- [x] **`sff` shell function** (v3.5.0) — `sff() { local f; f=$(fzf) && scp "$f" "$1"; }` added to `aliases.zsh` *(done 2026-05-04)*
- [x] **Battery status minutes-unit handling** (v3.5.0) — confirmed `awk '/time to empty/ {print $4, $5}'` handles both hours and minutes correctly *(confirmed 2026-05-04)*
- [x] **Fuller battery status notification** (v3.4.2, v3.5.0) — `battery-status` script + `Super+Ctrl+Alt+B` binding in `desktop-utilities.conf` *(done 2026-05-04)*
- [x] **VRR removal confirmed** (v3.6.0) — no `vrr,1` in `monitor.conf.tmpl`; explicit per-monitor lines unaffected *(confirmed 2026-05-04)*
- [x] **Scratchpad slide-in animation** (v3.4.2) — `animation = specialWorkspace, 1, 4, easeOutQuint, slidevert` + `bezier = easeOutQuint, 0.23, 1, 0.32, 1` enabled *(done 2026-05-04)*
- [x] **`hyprland-preview-share-picker` default page** (v3.4.2) — `config.yaml` created with `default_page: outputs` *(done 2026-05-04)*
- [x] **Notification grouping** (v3.8.0) — `"notification-grouping": true` already present in `swaync/config.json` *(confirmed 2026-05-13)*
- [x] **Scratchpad keybindings** (v3.1.4) — `Super+S` toggle scratchpad, `Super+Shift+S` move to scratchpad already implemented in `window-management.conf` *(confirmed 2026-02-21)*
- [x] **Smart screenshot selection** (v3.1.0) — `Print` smart screenshot, `Shift+Print` clipboard screenshot already implemented in `screenshots.conf` *(confirmed 2026-02-21)*
- [x] **`Super+Ctrl+T` Activity / `Super+Ctrl+B` Bluetooth** (v3.1.2, v3.3.0) — Both already implemented in `desktop-utilities.conf` *(confirmed 2026-02-21)*
- [x] **`hyprsunset` night light** (v1.10.0) — `hyprsunset` in packages.yaml; `Super+N` nightlight toggle in `desktop-utilities.conf` *(confirmed 2026-02-21)*
- [x] **Hyprland 0.53 windowrule/layerrule syntax** (v3.3.0) — `windowrules.conf` uses new `match:` syntax *(confirmed 2026-02-21)*
- [x] **`ghostty` as primary terminal** (v3.2.0) — In packages, used as default terminal *(confirmed 2026-02-21)*
- [x] **`starship` prompt** (v2.0.0) — In packages, configured *(confirmed 2026-02-21)*
- [x] **`dust` disk usage TUI** (v2.0.0) — In packages (`terminal_tools` module) *(confirmed 2026-02-21)*
- [x] **`satty` screenshot annotation** (v1.6.0) — In packages and used in screenshot workflow *(confirmed 2026-02-21)*
- [x] **`swayosd` OSD overlay** (v1.6.1) — In packages (`desktop_hyprland` module) *(confirmed 2026-02-21)*
- [x] **`gpu-screen-recorder-git`** (v2.0.0) — In packages (`desktop_hyprland` module) *(confirmed 2026-02-21)*
- [x] **`cliphist` clipboard manager** (v3.1.0) — In packages; `Super+C` opens clipboard history via wofi *(confirmed 2026-02-21)*
- [x] **`polkit-gnome`** (v1.3.0) — In packages (`desktop_hyprland` module) *(confirmed 2026-02-21)*
- [x] **`gnome-keyring`** (v1.3.0) — In packages (`system_utilities` module) *(confirmed 2026-02-21)*
- [x] **`uwsm`** (v1.4.0) — In packages (`desktop_hyprland` module) *(confirmed 2026-02-21)*
- [x] **`qt5-wayland`** (v2.1.0) — In packages (`system_utilities` module) *(confirmed 2026-02-21)*
- [x] **`ttf-firacode-nerd`** (v1.8.0) — In packages (`fonts` module) *(confirmed 2026-02-21)*
- [x] **`voxtype-bin`** (v3.3.0) — In packages; `Super+T` dictation implemented in `voice.conf` *(confirmed 2026-02-21)*
- [x] **`swaync` notification daemon** (v1.2.0) — In packages; `Super+Shift+N` notification panel *(confirmed 2026-02-21)*
- [x] **`docker-buildx`** (v1.5.0) — In packages (`development_core` module) *(confirmed 2026-02-21)*
- [x] **`usage` package** (v3.2.0) — In packages (`terminal_tools` module) *(confirmed 2026-02-21)*
- [x] **`btop` vim keybindings** (v3.1.0) — Noted; btop in packages, config managed separately *(confirmed 2026-02-21)*
- [x] **`localsend`** (v3.0.0) — In packages (`desktop_gui_apps` module) *(confirmed 2026-02-21)*
- [x] **`tailscale`** (v1.13.0) — In packages (`network` module) *(confirmed 2026-02-21)*
- [x] **hyprland-guiutils package rename** (v3.1.7) — Added `hyprland-guiutils` to `desktop_hyprland` module *(done 2026-02-21)*
- [x] **BlueTUI as Bluetooth backend** (v3.2.0) — Evaluated; kept `blueman` for GUI, added `bluetui` for TUI *(done 2026-02-21)*
- [x] **`ffmpegthumbnailer` for video thumbnails** (v1.2.0) — Added to `system_utilities` module *(done 2026-02-21)*
- [x] **`nodejs` package for tree-sitter** (v3.1.0) — Already managed via mise *(confirmed 2026-02-21)*
- [x] **VSCode auto-update disable** (v3.1.0) — Added `"update.mode": "none"` to settings.json *(done 2026-02-21)*
- [x] **`wl-clip-persist` sensitive data exclusion** (v1.3.1) — `clipboard-store` wrapper filters by window class/title *(done 2026-02-21)*
- [x] **`fontconfig/fonts.conf` defaults** (v1.4.0) — Added `fonts.conf` with FiraCode Nerd, Fira Sans, Liberation Serif *(done 2026-02-21)*
- [x] **`hyprpicker` for HDR screenshots** (v3.4.0) — Already in packages.yaml *(confirmed 2026-03-05)*
- [x] **Numlock enabled by default** (v2.1.1) — Added `numlock_by_default = true` to `input.conf` *(done 2026-03-05)*
- [x] **Cross-monitor workspace move** (v3.2.0) — `SUPER+SHIFT+ALT+Left/Right` added to `workspace-management.conf` *(done 2026-03-05)*
- [x] **WiFi quick-control `Super+Ctrl+W`** (v3.3.0) — Added `ghostty -e nmtui` binding to `desktop-utilities.conf` *(done 2026-03-05)*
- [x] **Docker socket activation** (v3.4.0) — Switched to `docker.socket` in `configure_system_services.sh.tmpl` *(done 2026-03-05)*
- [x] **Screen recording with audio** (v2.1.1) — `ALT+SHIFT+Print` and `CTRL+ALT+SHIFT+Print` added to `screenshots.conf` *(done 2026-03-05)*
- [x] **`eff` + `ff` aliases** (v3.4.0) — Added to `aliases.zsh` *(done 2026-03-05)*
- [x] **SSH port forwarding `fip`/`dip`/`lip`** (v3.4.0) — Added to `ssh-port-forwarding.zsh` (`dip` = disconnect, not dynamic) *(done 2026-03-05)*
- [x] **Tmux integration** (v3.4.0) — Package added, `tmux.conf` created, `t` alias + `tdl`/`tdlm`/`tsl` functions added *(done 2026-03-05)* — **superseded**: replaced by zellij
- [x] **Waybar idle-lock indicator** (v3.4.0) — `idle-indicator` script + Waybar module + CSS; DND already covered by `custom/swaync` *(done 2026-03-05)*
- [x] **`try` package** (v3.2.0) — Added to `terminal_tools` in packages.yaml *(done 2026-03-05)*

---

## Skipped / Out of Scope

### v4.0.1 — security patch backports

- [SKIPPED] **FIDO2 authfile symlink/ownership fix** (v4.0.1) — no FIDO2 setup in this repo (`omarchy-setup-security-fido2` has no equivalent here); nothing to patch
- [SKIPPED] **`omarchy-sudo-reset` removal** (v4.0.1) — omarchy-specific command, never had an equivalent here
- [SKIPPED] **Privileged DNS helper PATH pinning** (v4.0.1) — `omarchy-dns` has no equivalent; DNS is managed via NetworkManager/iwd directly, no passwordless root sudoers helper in this repo
- [SKIPPED] **Video title forging Download Video command** (v4.0.1) — no yt-dlp/download-video wrapper in this repo
- [SKIPPED] **`omarchy plugin-add` transport-helper guard** (v4.0.1) — our only plugin install (hyprsplit via hyprpm) is pinned to a fixed fork/commit in a lifecycle script, not a user-supplied URL at runtime
- [SKIPPED] **Quickshell-specific bug fixes** (v4.0.1) — race conditions in notification popup/history, bar sticking in move mode, closed network/Bluetooth panels leaving scans running, `o.shell_succeeds()`, UTF-16 clipboard/webp decoding, calendar day names, speed-test locale — all Quickshell (`omarchy-shell`) internals, already out of scope per the v4.0.0 shell-replacement skip below
- [SKIPPED] **Windows VM Docker Compose hardening** (v4.0.1) — Windows VM out of scope
- [SKIPPED] **`psmouse` ISO finalizer fix** (v4.0.1) — Omarchy installer/ISO scope

### v4.0.0 "Quattro" — architectural rewrite

- [SKIPPED] **Quickshell desktop shell (`omarchy-shell`)** (v4.0.0) — replaces Waybar, Walker, Mako, SwayOSD, hyprlock, hypridle, swaybg and polkit-gnome with one QML process (175 files). We use Waybar + Wofi + swaync + hyprlock/hypridle deliberately; wholesale replacement is not on the table. `quickshell` itself is already installed for the voxtype OSD. *Workflow patterns* worth noting for our own tooling: the event-driven (non-polling) status model, and the shell reading a single declarative layout file
- [SKIPPED] **Bar plugin system + `shell.json` / `shell.toml`** (v4.0.0) — Quickshell-specific manifest/plugin registry and layout state. Our Waybar config plus the theme system covers the same ground; the `shell.toml` idea of a machine-level style override merged over the theme is *conceptually* interesting but Waybar CSS already allows it
- [SKIPPED] **Native launcher, menu, notification daemon, clipboard manager, emoji picker, OSDs, lock screen, polkit agent** (v4.0.0) — all Quickshell plugins; each has an established equivalent here (Wofi, swaync, cliphist, swayosd, hyprlock, polkit-gnome)
- [SKIPPED] **Control panels (Audio / Bluetooth / Network / Display / Power)** (v4.0.0) — Quickshell panels bound to `Super+Ctrl+A/B/W/D/P`. We cover these via `audio-switch`, `blueman-manager`, `nmtui`, `monitor-switch` and `menu-setup`. Note `Super+Ctrl+B` and `Super+Ctrl+W` already match our bindings by coincidence
- [SKIPPED] **Omarchy internals shipped as Arch packages (`omarchy` + `omarchy-settings`, `/etc/skel`, `/usr/share/omarchy`)** (v4.0.0) — chezmoi is our distribution mechanism; the `/etc/skel` model explicitly does not update existing users, which is the problem chezmoi exists to solve
- [SKIPPED] **ALPM update guard blocking `pacman -Syu`** (v4.0.0) — `AbortOnFail` PreTransaction hook forcing updates through `omarchy update`. Hostile to a chezmoi-managed system and to `topgrade`
- [SKIPPED] **Per-channel pacman configs and mirrorlists (`stable`/`rc`/`edge`)** (v4.0.0) — Omarchy release-channel machinery
- [SKIPPED] **pkexec/polkit privilege escalation rework** (v4.0.0) — tied to the Quickshell polkit agent
- [SKIPPED] **Unified `omarchy` CLI subcommand surface** (v4.0.0) — the ~35 grouped subcommands are Omarchy-specific; only the metadata-header dispatch *pattern* is tracked (P3)
- [SKIPPED] **Menu extensions as JSONC (`omarchy-menu.jsonc`)** (v4.0.0) — replaces the removed `menu.sh`; both are Omarchy menu extension points
- [SKIPPED] **Deferred first-boot provisioning, LUKS re-keying, factory reset, dual-boot install** (v4.0.0) — installer/ISO scope
- [SKIPPED] **`foot` as default terminal** (v3.8.0, v4.0.0) — Ghostty is primary, Kitty is the baseline; no third terminal. Alacritty likewise skipped
- [SKIPPED] **`herdr` multiplexer** (v4.0.0) — we use zellij; `hdl`/`hds`/`hdlm`/`hsl` helpers and its keybindings viewer are herdr-specific
- [SKIPPED] **tmux pane bindings, window titles, extkeys, tab moves, zoom flag** (v3.8.3, v4.0.0) — using zellij, not tmux
- [SKIPPED] **Omawrite / Omacalc / Omacut / Tensaku / `ttfx`** (v4.0.0) — Omarchy first-party apps replacing Typora, GNOME Calculator, Satty and terminaltexteffects. Tensaku and the Omacut *trim* concept are tracked separately in P3; the rest are out of scope
- [SKIPPED] **Chromium extensions (yt-dlp download, WhatsApp slim, Google Meet PiP)** (v4.0.0) — Firefox is the primary browser
- [SKIPPED] **Moonlight / Sunshine streaming client** (v4.0.0) — gaming scope
- [SKIPPED] **NordVPN from the Omarchy package repository** (v4.0.0) — uses Tailscale
- [SKIPPED] **Configurable default coding agent + agent launcher** (v4.0.0) — Omarchy defaults system; we manage AI tooling via `ai.yaml` and `menu-ai`
- [SKIPPED] **Per-laptop PipeWire speaker tunings** (v4.0.0) — DMI-matched filter chains for Dell XPS 14/16; hardware-specific
- [SKIPPED] **New themes (Solitude, Last Horizon, Lupine, Pi) and backgrounds** (v4.0.0) — not variants we use
- [SKIPPED] **T2 Mac suspend/fan/gmux fixes, Broadcom Wi-Fi quirk, Tuxedo/Slimbook backlight, Framework 16 `qmk-hid`, IPU6 webcam, LVDS/DSI panel detection** (v4.0.0) — hardware-specific
- [SKIPPED] **Hybrid GPU / supergfxd fixes** (v4.0.0) — no hybrid graphics here
- [SKIPPED] **Snapper snapshot pruning and update-snapshot reporting** (v4.0.0) — we use Timeshift
- [SKIPPED] **`omarchy-upgrade-to-quattro`** (v4.0.0) — the 3.x→4.x migration path itself
- [SKIPPED] **fcitx5 service, Noto Arabic font preference, non-login-shell locale** (v4.0.0) — not applicable / already correct here
- [SKIPPED] **Software cursors on nouveau, cursors excluded from screenshots** (v4.0.0) — nouveau not in use (proprietary NVIDIA)
- [SKIPPED] **SDDM / Plymouth theming rework, faillock, sudoers drop-ins** (v4.0.0) — not using SDDM; sudoers drop-ins are Omarchy-specific grants
- [SKIPPED] **`omarchy-branding-*`, About window, screensaver, first-login toast** (v4.0.0) — Omarchy branding
- [SKIPPED] **Window width save/restore `Super+Alt+Home` / `Super+Home`** (v4.0.0) — no new keybindings preference
- [SKIPPED] **Alternative media next/previous bindings for play-only keyboards** (v4.0.0) — our keyboard has discrete media keys
- [SKIPPED] **SSHD setup/removal, disk speed test, LocalSend file-chooser sharing** (v4.0.0) — Omarchy menu features; not gaps here
- [SKIPPED] **`pre-refresh-pacman.d` hooks** (v4.0.0) — covered by our own hook system at `~/.config/dotfiles/hooks/`

### v3.8.3 / v3.8.4

- [SKIPPED] **CSI-u bindings for Alacritty and Foot** (v3.8.3) — neither terminal is in use; the Ghostty/Kitty half is tracked in P2
- [SKIPPED] **`cy` alias (`codex -s danger-full-access -a never`)** (v3.8.3) — Codex not in the current AI stack (we use `cc` for Claude Code and `opc` for opencode); also a deliberately unguarded full-access mode
- [SKIPPED] **Dell XPS 13 (DX13260) text scaling** (v3.8.3) — hardware-specific first-run step
- [SKIPPED] **`omarchy-hw-intel-sof` detector** (v3.8.3) — Intel SOF platform detection; our `sof-firmware` is installed unconditionally
- [SKIPPED] **Mesa Vulkan driver backfill (`vulkan-intel`/`vulkan-radeon`/`vulkan-asahi`)** (v3.8.3) — Intel/AMD/Asahi only; NVIDIA ships Vulkan via `nvidia-utils`
- [SKIPPED] **`libfprint` vs `libfprint-git` pre-removal fix, `omarchy-pkg-drop` provider-name fix** (v3.8.3) — Omarchy package-management internals
- [SKIPPED] **Power-profile udev `--unit=` collision fix** (v3.8.3) — Omarchy-specific rule; the correct pattern is folded into the P3 power-profile item
- [SKIPPED] **Hyprland 0.55+ `togglesplit` → `layoutmsg, togglesplit`** (v3.8.3) — we have no `togglesplit` binding; nothing to migrate
- [SKIPPED] **Neovim theme symlink retarget migration** (v3.8.4) — Omarchy 3.x/4.x state-path migration; our Neovim theming goes through `theme-apply-neovim`
- [SKIPPED] **RetroArch libretro core removals** (v3.8.4) — gaming scope
- [SKIPPED] **`nvim` ↔ `neovim` package renames** (v3.8.4, v4.0.0) — Omarchy manifest naming; v4.0.0's `nvim` is an OPR package, not the Arch `neovim`
- [SKIPPED] **Foot `[text-bindings]` migration hardening** (v3.8.4) — Foot not in use

### Earlier releases

- [SKIPPED] **Walker launcher** (v1.6.0+) — uses Wofi, not Walker. *Workflow pattern* note: Walker's fuzzy/acronym matching and nested command palette (v4.0.0) may be worth exploring for our Wofi menus
- [SKIPPED] **Aether theme creator** (v3.1.0) — Omarchy-specific app
- [SKIPPED] **Helium browser** (v3.0.2) — out of scope
- [SKIPPED] **Voxtype `Super+Ctrl+X`** (v3.3.0) — we use `Super+T` push-to-talk (different UX model)
- [SKIPPED] **SDDM keyring unlock** (v3.1.0) — different login flow
- [SKIPPED] **SDDM styling** (v3.4.0, v3.7.0, v3.8.0) — not using SDDM
- [SKIPPED] **Windows VM** (v3.1.0+) — out of scope
- [SKIPPED] **Omarchy ISO/installer** (v2.0.0, v3.0.0, v3.5.1, v3.7.0, v3.8.0, v4.0.0) — not applicable
- [SKIPPED] **OPR (Omarchy Package Repository)** (v2.0.0+) — uses standard Arch + AUR
- [SKIPPED] **Limine bootloader + Snapper rollback** (v2.0.0) — uses systemd-ukify + Timeshift (Btrfs)
- [SKIPPED] **Omarchy hooks system** (v3.1.0, v3.8.0, v4.0.0) — we use our own hooks at `~/.config/dotfiles/hooks/`
- [SKIPPED] **`omarchy-launch-browser`/`omarchy-launch-webapp`** (v2.0.0) — Omarchy-specific launcher scripts
- [SKIPPED] **Chaotic-AUR** (v1.6.2) — already in packages.yaml; keep/remove decision is independent
- [SKIPPED] **`omarchy-menu` / Walker menu system** (v1.11.0+) — Walker-specific; covered by our Wofi system-menu on `Super+Space`
- [SKIPPED] **T1/T2 MacBook support** (v3.0.0, v4.0.0) — not applicable hardware
- [SKIPPED] **Omarchy Chromium fork** (v2.0.0) — uses upstream Chromium
- [SKIPPED] **`~/.config/omarchy/extensions/menu.sh`** (v3.3.0, v3.4.0) — Omarchy-specific extension point
- [SKIPPED] **Hyprland tiling group keybindings** (v3.1.0) — `Super+G` stays as gap toggle; group navigate covered by `Super+Ctrl+H/L`
- [SKIPPED] **`Super+L` layout toggle** (v3.4.1) — lock screen binding takes priority
- [SKIPPED] **`Super+/` display resolution cycling** (v3.4.1) — keybinding help takes priority
- [SKIPPED] **Monitor focus cycling `Ctrl+Alt+Tab`** (v3.6.0) — no new keybindings preference
- [SKIPPED] **Window pinned floating overlay `Super+O`** (v3.1.5) — no new keybindings preference
- [SKIPPED] **Toggle menu `Super+Ctrl+O`** (v3.4.1, v3.7.0) — no new keybindings preference; v3.7.0 repurposes it for Limine Direct Boot
- [SKIPPED] **Monitor scaling cycle keybinding** (v3.4.0, v3.6.0) — no new keybindings preference
- [SKIPPED] **`ga`/`gd` git worktree helpers** (v3.4.2) — user does not use git worktrees via CLI
- [SKIPPED] **`ff` alias kitty icat preview** (v3.5.0) — Kitty is backup terminal only; Ghostty doesn't support icat
- [SKIPPED] **Voxtype dictation workflow/bindings** — permanent skip; `Super+T` push-to-talk is the established model
- [SKIPPED] **Asus/Slimbook/Tuxedo/Surface hardware drivers** (v3.4.0, v3.5.0, v3.7.0, v3.8.0) — not applicable hardware
- [SKIPPED] **NVIDIA GeForce Now installer** (v3.4.0) — out of scope
- [SKIPPED] **Walker crash fix** (v3.4.0, v3.5.1) — not using Walker
- [SKIPPED] **`omarchy-drive-select` partition info** (v3.4.0) — Omarchy-specific script
- [SKIPPED] **Remove Preinstalls menu** (v3.4.0) — Omarchy-specific menu system
- [SKIPPED] **Audio soft mixer toggle** (v3.4.0) — Asus Zephyrus-specific
- [SKIPPED] **Favicon extraction for web apps** (v3.4.0, v4.0.0) — Omarchy web app creation; v4.0.0's high-res site icons are the same feature
- [SKIPPED] **Scala installer** (v3.4.0) — not in current dev stack
- [SKIPPED] **NordVPN installer** (v3.4.0) — uses Tailscale
- [SKIPPED] **Google DNS option** (v3.4.0) — DNS config handled separately
- [SKIPPED] **User theme override system** (v3.4.0) — Omarchy-specific theme mechanism
- [SKIPPED] **`omarchy-cmd-screenshot` geometry fix** (v3.4.0) — Omarchy-specific script
- [SKIPPED] **fcitx5 double auto-start fix** (v3.4.1, v3.5.1) — not using fcitx5
- [SKIPPED] **SDDM password field overflow** (v3.4.1) — not using SDDM
- [SKIPPED] **`OMARCHY_PATH` SSH environment export** (v3.4.1) — Omarchy-specific env var
- [SKIPPED] **`omarchy-launch-or-focus` jq fix** (v3.4.1) — Omarchy-specific script; we have our own `launch-or-focus`
- [SKIPPED] **Screensaver `slidein` animation** (v3.4.1) — minor, Omarchy-specific default
- [SKIPPED] **Copilot key remapping via makima** (v3.4.2, v3.5.0, v3.5.1) — hardware-specific; makima removed entirely in v3.5.1
- [SKIPPED] **`Super+Shift+Return` browser shortcut** (v3.4.2) — we already have `Super+W` for browser
- [SKIPPED] **`plocate` AC-only indexing** (v3.4.2) — `plocate` not in our packages
- [SKIPPED] **Intel Panther Lake/Arc/PTL GPU fixes, thermald, intel-lpmd, media driver/VPL** (v3.4.2–v3.8.0) — Intel-specific, NVIDIA setup here
- [SKIPPED] **`wayfreeze-git` migration cleanup** (v3.4.2) — `wayfreeze-git` still in our packages (intentional)
- [SKIPPED] **Limine bootloader cmdline / Direct Boot** (v3.4.2–v3.7.1, v4.0.0) — not using Limine
- [SKIPPED] **LM Studio downgrade fix** (v3.4.2) — LM Studio not in our packages
- [SKIPPED] **wireless-regdb** (v2.1.1) — no 6GHz hardware detected
- [SKIPPED] **impala TUI** — depends directly on the `iwd` binary, incompatible with our NM+iwd backend setup; v4.0.0 removes it upstream too
- [SKIPPED] **Hypridle timing tuning** — our 5/10/15min is intentionally more relaxed than Omarchy's 2.5/5/5.5min
- [SKIPPED] **Dell XPS hardware fixes** (v3.5.0, v3.5.1, v3.8.0, v4.0.0) — Dell-specific hardware
- [SKIPPED] **ONCE installer** (v3.5.0) — Omarchy-specific service manager
- [SKIPPED] **npx lazy-install stubs** (v3.5.0, v3.5.1, v3.8.0) — we use mise for Node tool management
- [SKIPPED] **`omarchy-sudo-passwordless`** (v3.5.0, v3.7.0) — security-sensitive footgun
- [SKIPPED] **Battery-low hook** (v3.5.0) — Omarchy hooks system; *concept* could be a user hook but not urgent
- [SKIPPED] **Logitech MX Keys binding examples** (v3.5.1) — hardware-specific commented examples
- [SKIPPED] **Mic mute LED sync (Dell XPS, ThinkPad)** (v3.5.1, v3.6.0, v3.7.0) — device-specific hardware LED control
- [SKIPPED] **Resume performance boost** (v3.5.1) — Intel Panther Lake-specific; removed in v3.6.0
- [SKIPPED] **Internal monitor recovery service** (v3.6.0, v4.0.0) — `omarchy-recover-internal-monitor`; requires the persistent toggle system first and is heavy machinery for a desktop
- [SKIPPED] **Monitor watch daemon** (v3.6.0) — desktop-focused single monitor; HyprDynamicMonitors covers profile switching
- [SKIPPED] **Vantablack, Lumon Industries, Retro 82 themes** (v3.5.0, v3.6.0) — not variants we use
- [SKIPPED] **Snapper /home snapshots drop + btrfs quota disable** (v3.6.0) — we use Timeshift
- [SKIPPED] **Voxtype GPU acceleration via Vulkan** (v3.5.0, v3.6.0) — our voxtype is configured via `run_once_after_setup_optional_services`
- [SKIPPED] **Gaming installers** (v3.7.0) — Steam, RetroArch, Lutris, Heroic, Moonlight, Xbox — out of scope
- [SKIPPED] **`cliamp` TUI music player** (v3.7.0) — not in our workflow
- [SKIPPED] **`ghui` GitHub TUI** (v3.7.0) — using `gh` CLI
- [SKIPPED] **Plymouth unlock theming** (v3.7.0) — `omarchy-plymouth-*`; we use Timeshift + systemd-ukify
- [SKIPPED] **Omarchy logo backgrounds** (v3.7.0) — Omarchy-branded assets
- [SKIPPED] **Apple display brightness control** (v3.7.0) — Apple external display-specific
- [SKIPPED] **Helix editor theming** (v3.7.0, v3.8.0, v4.0.0) — not using Helix
- [SKIPPED] **gum theming** (v3.7.0) — we use gum without Omarchy theme coupling
- [SKIPPED] **Brave Origin browser theming** (v3.7.0, v4.0.0) — Brave Origin not in our browser setup
- [SKIPPED] **Monitor mirroring keybind `Super+Ctrl+Alt+Del`** (v3.7.0, v4.0.0) — hostile keybind; the `monitor-mirror` script itself is implemented
- [SKIPPED] **`omarchy-default-browser`/`terminal`/`editor` CLIs** (v3.8.0, v4.0.0) — we manage defaults via `globals.yaml`
- [SKIPPED] **`omarchy-install-browser`/`omarchy-remove-browser`** (v3.8.0) — we manage browsers via `packages.yaml`
- [SKIPPED] **Zed editor theming** (v3.8.0) — not using Zed
- [SKIPPED] **ASCII screensaver/about screen** (v3.8.0) — Omarchy branding tool
- [SKIPPED] **Voxtype post-boot install offer** (v3.8.0) — voxtype already installed
- [SKIPPED] **`pi` coding agent light/dark sync** (v3.8.0, v4.0.0) — not using pi agent
- [SKIPPED] **Chromium VAAPI flags migration** (v3.8.0) — Intel-specific issue
- [SKIPPED] **`omarchy-notification-send` helper** (v3.8.0) — we use `notify-send` directly
- [SKIPPED] **`omarchy-setup-security-fido2/fingerprint` refactor** (v3.8.0, v4.0.0) — we handle FIDO2/fingerprint separately
- [SKIPPED] **Lenovo Yoga Pro bass speaker fix** (v3.8.0) — hardware-specific

---

## Version Coverage

| Version | Research doc | Reviewed |
|---------|-------------|---------|
| v1.2.0 | `_research/omarchy/OMARCHY_v1.2.0.md` | 2026-02-21 |
| v1.3.0 | `_research/omarchy/OMARCHY_v1.3.0.md` | 2026-02-21 |
| v1.3.1 | `_research/omarchy/OMARCHY_v1.3.1.md` | 2026-02-21 |
| v1.3.2 | `_research/omarchy/OMARCHY_v1.3.2.md` | 2026-02-21 |
| v1.4.0 | `_research/omarchy/OMARCHY_v1.4.0.md` | 2026-02-21 |
| v1.4.1 | `_research/omarchy/OMARCHY_v1.4.1.md` | 2026-02-21 |
| v1.5.0 | `_research/omarchy/OMARCHY_v1.5.0.md` | 2026-02-21 |
| v1.5.1 | `_research/omarchy/OMARCHY_v1.5.1.md` | 2026-02-21 |
| v1.5.2 | `_research/omarchy/OMARCHY_v1.5.2.md` | 2026-02-21 |
| v1.6.0 | `_research/omarchy/OMARCHY_v1.6.0.md` | 2026-02-21 |
| v1.6.1 | `_research/omarchy/OMARCHY_v1.6.1.md` | 2026-02-21 |
| v1.6.2 | `_research/omarchy/OMARCHY_v1.6.2.md` | 2026-02-21 |
| v1.7.0 | `_research/omarchy/OMARCHY_v1.7.0.md` | 2026-02-21 |
| v1.8.0 | `_research/omarchy/OMARCHY_v1.8.0.md` | 2026-02-21 |
| v1.9.0 | `_research/omarchy/OMARCHY_v1.9.0.md` | 2026-02-21 |
| v1.10.0 | `_research/omarchy/OMARCHY_v1.10.0.md` | 2026-02-21 |
| v1.11.0 | `_research/omarchy/OMARCHY_v1.11.0.md` | 2026-02-21 |
| v1.12.0 | `_research/omarchy/OMARCHY_v1.12.0.md` | 2026-02-21 |
| v1.12.1 | `_research/omarchy/OMARCHY_v1.12.1.md` | 2026-02-21 |
| v1.13.0 | `_research/omarchy/OMARCHY_v1.13.0.md` | 2026-02-21 |
| v2.0.0 | `_research/omarchy/OMARCHY_v2.0.0.md` | 2026-02-21 |
| v2.0.1 | `_research/omarchy/OMARCHY_v2.0.1.md` | 2026-02-21 |
| v2.0.2 | `_research/omarchy/OMARCHY_v2.0.2.md` | 2026-02-21 |
| v2.0.3 | `_research/omarchy/OMARCHY_v2.0.3.md` | 2026-02-21 |
| v2.0.4 | `_research/omarchy/OMARCHY_v2.0.4.md` | 2026-02-21 |
| v2.0.5 | `_research/omarchy/OMARCHY_v2.0.5.md` | 2026-02-21 |
| v2.1.0 | `_research/omarchy/OMARCHY_v2.1.0.md` | 2026-02-21 |
| v2.1.1 | `_research/omarchy/OMARCHY_v2.1.1.md` | 2026-02-21 |
| v2.1.2 | `_research/omarchy/OMARCHY_v2.1.2.md` | 2026-02-21 |
| v3.0.0 | `_research/omarchy/OMARCHY_v3.0.0.md` | 2026-02-21 |
| v3.0.1 | `_research/omarchy/OMARCHY_v3.0.1.md` | 2026-02-21 |
| v3.0.2 | `_research/omarchy/OMARCHY_v3.0.2.md` | 2026-02-21 |
| v3.1.0 | `_research/omarchy/OMARCHY_v3.1.0.md` | 2026-02-21 |
| v3.1.1 | `_research/omarchy/OMARCHY_v3.1.1.md` | 2026-02-21 |
| v3.1.2 | `_research/omarchy/OMARCHY_v3.1.2.md` | 2026-02-21 |
| v3.1.3 | `_research/omarchy/OMARCHY_v3.1.3.md` | 2026-02-21 |
| v3.1.4 | `_research/omarchy/OMARCHY_v3.1.4.md` | 2026-02-21 |
| v3.1.5 | `_research/omarchy/OMARCHY_v3.1.5.md` | 2026-02-21 |
| v3.1.6 | `_research/omarchy/OMARCHY_v3.1.6.md` | 2026-02-21 |
| v3.1.7 | `_research/omarchy/OMARCHY_v3.1.7.md` | 2026-02-21 |
| v3.2.0 | `_research/omarchy/OMARCHY_v3.2.0.md` | 2026-02-21 |
| v3.2.1 | `_research/omarchy/OMARCHY_v3.2.1.md` | 2026-02-21 |
| v3.2.2 | `_research/omarchy/OMARCHY_v3.2.2.md` | 2026-02-21 |
| v3.2.3 | `_research/omarchy/OMARCHY_v3.2.3.md` | 2026-02-21 |
| v3.3.0 | `_research/omarchy/OMARCHY_v3.3.0.md` | 2026-02-21 |
| v3.3.1 | `_research/omarchy/OMARCHY_v3.3.1.md` | 2026-02-21 |
| v3.3.2 | `_research/omarchy/OMARCHY_v3.3.2.md` | 2026-02-21 |
| v3.3.3 | `_research/omarchy/OMARCHY_v3.3.3.md` | 2026-02-21 |
| v3.4.0 | `_research/omarchy/OMARCHY_v3.4.0.md` | 2026-03-05 |
| v3.4.1 | `_research/omarchy/OMARCHY_v3.4.1.md` | 2026-03-05 |
| v3.4.2 | `_research/omarchy/OMARCHY_v3.4.2.md` | 2026-03-12 |
| v3.5.0 | `_research/omarchy/OMARCHY_v3.5.0.md` | 2026-05-04 |
| v3.5.1 | `_research/omarchy/OMARCHY_v3.5.1.md` | 2026-05-04 |
| v3.6.0 | `_research/omarchy/OMARCHY_v3.6.0.md` | 2026-05-04 |
| v3.7.0 | `_research/omarchy/OMARCHY_v3.7.0.md` | 2026-05-13 |
| v3.7.1 | `_research/omarchy/OMARCHY_v3.7.1.md` | 2026-05-13 |
| v3.8.0 | `_research/omarchy/OMARCHY_v3.8.0.md` | 2026-05-13 |
| v3.8.1 | `_research/omarchy/OMARCHY_v3.8.1.md` | 2026-06-08 |
| v3.8.2 | `_research/omarchy/OMARCHY_v3.8.2.md` | 2026-06-08 |
| v3.8.3 | `_research/omarchy/OMARCHY_v3.8.3.md` | 2026-08-24 |
| v3.8.4 | `_research/omarchy/OMARCHY_v3.8.4.md` | 2026-08-24 |
| v4.0.0 | `_research/omarchy/OMARCHY_v4.0.0.md` | 2026-08-24 |
| v4.0.1 | `_research/omarchy/OMARCHY_v4.0.1.md` | 2026-08-30 |
