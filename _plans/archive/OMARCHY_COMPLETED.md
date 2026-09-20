# Omarchy Integration Backlog — Archive

**Archived**: 2026-09-21, at plan state "through v4.0.4".

Everything here is **decided**: `[x]` done · `[SKIPPED]` out of scope · `[N/A]` not
applicable · `[REOPENED]` sent back to the live plan. The live backlog
(`_plans/OMARCHY.md`) keeps only outstanding work and the release-context notes.

Read this before adding anything to the live plan — a large share of Omarchy's
surface has already been evaluated and rejected, and re-adding a settled item is
the main failure mode of a rewritten plan.

---

## Closed items (full implementation notes)

These items had every sub-task resolved and were removed from the live plan
wholesale.

### Sudoless Docker group granted by default (v4.0.1) — P1

**What**: `docker` group membership is root-equivalent — `docker run -v /:/host busybox chroot /host` rewrites the host filesystem as root, no password required. Omarchy granted this by default for years and reversed it in v4.0.1: the group is no longer added on install/first-boot/upgrade, a migration strips it from existing installs, and the Docker CLI/TUI now route through `sudo`/polkit instead. Our `services.yaml` grants it unconditionally with no opt-in gate: the `docker.socket` entry carries `user_groups: [docker]`, applied via `usermod -aG` in `run_once_after_002_configure_system_services.sh.tmpl`.
**Target files**: `.chezmoidata/services.yaml`, `.chezmoiscripts/run_once_after_002_configure_system_services.sh.tmpl`, `.chezmoidata/packages.yaml` (`lazydocker`)
**Adapt from**: `bin/omarchy-remove-security-sudoless-docker`, `applications/Docker.desktop`, `bin/omarchy-launch-docker-tui`

- [x] Decide policy: **accept the risk** (user decision 2026-08-30, reversing an earlier same-day attempt at gating behind `features.docker_sudoless.enabled`) — single-user desktop, current unconditional grant "just works as intended"; no code change *(done 2026-08-30)*
- [x] Accepted risk recorded in `system/CLAUDE.md` → Package Security Policy, noting the deliberate divergence from Omarchy's v4.0.1 reversal *(done 2026-08-30)*
- [SKIPPED] Feature-gating `services.yaml`/`run_once_after_002`/`menu-install` — built, then reverted per the above decision
- [N/A] `lazydocker` needs no separate access-path change — sudoless docker stays the default, same as before

---

### Waybar toggle leaves a stale process (v3.8.4) — P1

**What**: Newer Waybar does not exit on `SIGTERM` in the toggle path, so `pkill waybar` leaves a stale process and the bar never comes back on the second toggle. Omarchy changed `pkill -x waybar` → `pkill -9 -x waybar`. Our `waybar-toggle` carried the same defect plus a bare `pkill` with no `-x`.
**Target files**: `private_dot_local/lib/scripts/desktop/executable_waybar-toggle`

> **Correction (2026-08-24)**: an earlier revision of this item claimed the bare `pkill waybar` could collaterally kill `voxtype-waybar-status`. It could not. `pkill` without `-f` matches `comm`, not the command line, and every `waybar`-named script here runs under `comm=sh` (`#!/usr/bin/env sh`) — verified with `ps -eo comm,args`. The `-9` was the real defect; `-x` is hygiene against a future rename, not a live bug.

- [x] Change `pkill waybar` → `pkill -9 -x waybar`
- [x] Confirm `pgrep -x waybar` guard still matches after the change
- [x] Test: four toggle cycles — bar returned each time, ends visible
- [x] Notifications moved after verification, so they report the state actually reached
- [x] Confirm `voxtype-waybar-status` respawns with the bar (2 instances, unaffected)

---

### hyprsunset cold-start temperature race (v4.0.0) — P1

**What**: On a hyprsunset cold start the temperature can be dropped silently — the daemon is not ready when the temperature is set, so the filter never applies. Omarchy's fix resends the temperature until it sticks. Our `nightlight-toggle` did exactly the racy thing: `pkill hyprsunset` immediately followed by `hyprsunset -t <temp> &` with no wait and no verification, so a toggle could report success while the screen temperature never changed. It also read current state by parsing the process cmdline, which goes stale the moment temperature is changed any way other than respawning.
**Target files**: `private_dot_local/lib/scripts/desktop/executable_nightlight-toggle`, `private_dot_local/lib/scripts/desktop/executable_nightlight-config`, `private_dot_local/lib/scripts/user-interface/executable_menu-trigger`

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

### NVIDIA GPU detection via sysfs instead of lspci (v4.0.0) — P2

**What**: Omarchy switched NVIDIA detection from `lspci` to sysfs because `lspci` resumes a runtime-suspended discrete GPU out of D3cold, which can exceed Hyprland's 1.5s config-load budget and stall session start. They also classify by PCI device ID so pre-Maxwell cards stay off an incompatible driver and missed Maxwell/Pascal parts are picked up.
**Target files**: `.chezmoi.yaml.tmpl`, `.chezmoiscripts/run_once_before_001_preflight_and_session_validation.sh.tmpl`
**Adapt from**: `bin/omarchy-hw-nvidia`, `default/hypr/nvidia.lua`

- [x] Switched from `lspci` to sysfs: `.chezmoi.yaml.tmpl` now scans `/sys/bus/pci/devices/*/{vendor,class,device}` for vendor `0x10de` + class `0x03xx` — pure sysfs reads, never touches live PCI config space, so it can't wake a runtime-suspended dGPU *(done 2026-08-30)*
- [x] Classification kept as the existing name-string regex (GTX 900/1000, Titan X/XP/Z, Quadro K/M/P) — not rebuilt against a full device-ID table (out of scope for this pass) — but now applied to a name resolved from the static `/usr/share/hwdata/pci.ids` database instead of a live `lspci` call, so it stays wake-safe. `.nvidiaGpuDetected` format changed from a friendly lspci string to a raw PCI ID (`10de:1f91`); the one consumer (`run_once_before_001` log lines) updated to match *(done 2026-08-30)*
- [x] Verified: `chezmoi execute-template < .chezmoi.yaml.tmpl` resolves `nvidiaDriverType: "modern"`, `nvidiaGpuDetected: "10de:1f91"` on this machine (GTX 1650 Mobile/Max-Q, TU117M — correctly classified modern/Turing) *(done 2026-08-30)*
- [x] Added `hasIntegratedGpu` (sysfs scan for vendor `0x8086`/`0x1002` + class `0x03xx`) as a side effect — needed by the kms-hook item, found this machine is actually hybrid (`hasIntegratedGpu: true`), correcting an earlier assumption *(done 2026-08-30)*

---

### Persistent Hyprland toggle system (v3.6.0) — P2

**What**: Named flag configs persisted to `~/.local/state/omarchy/toggles/hypr/` and sourced on every `hyprctl reload`. Survives restarts. Powers touchpad toggle, display toggle, etc. v4.0.0 keeps this pattern as `require("default.hypr.toggles")` at the end of the Lua entry point.
**Target files**: `private_dot_config/hypr/hyprland.lua.tmpl` (add require/glob), new state directory
**Adapt from**: `bin/omarchy-hyprland-toggle`, `default/hypr/toggles/flags.conf`, `default/hypr/toggles.lua`

- [x] Built `.conf`-native instead of Lua: Hyprland here still boots from `hyprland.conf` (the `.lua` entry point is `.chezmoiignore`'d pending the Waybar-blocked cutover), so a `require("...toggles")`-only mechanism would be dead code until then. Added `source = ~/.local/state/dotfiles/toggles/hypr/current.conf` near the end of `hyprland.conf.tmpl` instead — a plain Hyprland-config fragment scripts rewrite, works today *(done 2026-08-30)*
- [x] `run_once_before_004_create_necessary_directories.sh.tmpl` now `mkdir -p`s the dir and `touch`es `current.conf` — a deliberate, documented exception to the lazy-mkdir-in-script convention used everywhere else, because `source =` errors on a missing file and this one is read before any toggle script has ever run *(done 2026-08-30)*
- [x] Implemented `desktop/executable_hypr-toggle {set|clear} <key> [line...]`: rewrites a `# BEGIN <key>`/`# END <key>` delimited block in `current.conf` (awk delete-between-markers, idempotent re-set/clear) then `hyprctl reload`s. Verified: set/clear round-trip leaves sibling keys' blocks untouched *(done 2026-08-30)*
- [x] Used as the foundation for touchpad-toggle *(done 2026-08-30)*

---

### QR code capture from screen region (v4.0.0) — P3

**What**: Select a screen region and decode any QR inside it straight to the clipboard. The decoded value never touches disk and is marked sensitive so clipboard history skips it.
**Target files**: `.chezmoidata/packages.yaml`, `private_dot_local/lib/scripts/media/`, `private_dot_config/hypr/conf/bindings/screenshots.conf` + `.lua`
**Adapt from**: `bin/omarchy-capture-qr`

- [x] Added `zbar` to `packages.yaml` (`desktop_hyprland`) *(done 2026-08-30)*
- [x] Implemented `media/executable_capture-qr`: `slurp` region → `grim -g` to stdout → `zbarimg --quiet --raw` → `wl-copy`, sharing a new `capture-region.sh` freeze/select helper with the OCR script. Verified with mocked `slurp`/`grim`/`zbarimg`/`wl-copy` *(done 2026-08-30)*
- [x] No extra plumbing needed for the sensitive-content path — `wl-copy` already flows through the existing `wl-paste --watch clipboard-store | cliphist store` pipeline, which runs its gitleaks filter on every clipboard write regardless of source. Noted as a documented gap in the script: gitleaks matches known secret *patterns*, so a plain-looking payload (bare Wi-Fi PSK, etc.) with no recognizable format won't be caught *(done 2026-08-30)*
- [x] Decoded value never touches disk — piped stdout to stdout throughout *(done 2026-08-30)*
- [x] Bound to `CTRL + Print` in `screenshots.conf`/`.lua` *(done 2026-08-30)*

---

### OCR text extraction from screen region (v3.7.0) — P3

**What**: Freeze screen with `hyprpicker`, select region with `slurp`, capture with `grim`, extract text with `tesseract`, copy to clipboard.
**Target files**: `.chezmoidata/packages.yaml`, `private_dot_local/lib/scripts/media/`, `private_dot_config/hypr/conf/bindings/screenshots.conf`
**Adapt from**: `bin/omarchy-capture-text-extraction`

- [x] Added `tesseract` + `tesseract-data-eng` to `packages.yaml` (`desktop_hyprland`) *(done 2026-08-30)*
- [x] Implemented `media/executable_capture-text-extraction`: `slurp` to select, `grim -g` to capture, `tesseract stdin stdout` to extract, `wl-copy` to clipboard. Used `wayfreeze` (not `hyprpicker -r -z`) for the freeze step — matches what `executable_screenshot` already uses in this repo, not Omarchy's tool. Verified with mocked `tesseract` *(done 2026-08-30)*
- [x] Bound to `SUPER CTRL SHIFT + Print` in `screenshots.conf`/`.lua` *(done 2026-08-30)*
- [x] Share the freeze/select plumbing with `capture-qr` — done in the same change via `media/capture-region.sh` (3 call sites; `executable_screenshot`'s own smart/windows/fullscreen modes were deliberately left untouched, too risky to retrofit for a working script with no test harness). *This box was left unticked in the live plan by mistake — the line above it already described the shared helper; reconciled at archive time 2026-09-21.*

---

### `paccache` pruning + low-disk-space guard before updates (v4.0.0, v4.0.1) — P3

**What**: Omarchy prunes the package cache with `paccache -rk2` as the **first** update step — before the snapshot, so the space is actually reclaimed — keeping one spare version for the offline downgrade path, and warns when disk space is low before updating.
**Correction (2026-08-30)**: this item's premise was stale — `system-maintenance` does **not** use `pacman -Sc --noconfirm`; `--cleanup` already runs `paccache -rk2` + `paccache -ruk0` (with a comment explicitly documenting why `-Sc` is avoided). Only the free-space warning was actually missing.
**Target files**: `private_dot_local/lib/scripts/system/executable_system-maintenance`
**Adapt from**: `bin/omarchy-update-pkg-prune`, `bin/omarchy-update-requires-free-space`

- [x] `paccache -rk2` + `paccache -ruk0` already implemented in `--cleanup` *(confirmed pre-existing, 2026-08-30)*
- [x] Added a free-space check to the `--update` path: warns via `ui_warning` (non-blocking, matches the script's non-interactive automation style) when `/` has under 2GiB free, before `pacman -Syu` runs *(done 2026-08-30)*
- [N/A] Order the prune before any Timeshift snapshot — `system-maintenance` has no snapshot step: `--update` and `--cleanup` are separate options and neither invokes Timeshift, so there is no ordering to fix *(verified 2026-08-30)*

---

### Touchpad toggle with OSD and persistence (v3.6.0, v4.0.1) — P3

**What**: Touchpad `on`/`off`/`toggle` with state persisted via the toggle system. Hardware keys `XF86TouchpadOn/Off/Toggle`. Laptop-relevant only. v4.0.1 fixed a code-execution bug in the exact script this adapts from (`omarchy-toggle-input-device`): the disabled device name comes from USB descriptors (attacker-influenceable) and was interpolated unvalidated into `hyprctl eval` and a generated `.lua` file Hyprland re-executes on reload — reachable even from the **locked** `XF86TouchpadToggle` binding, since that bind is `locked = true`.
**Target files**: `private_dot_config/hypr/conf/bindings/`, `private_dot_local/lib/scripts/desktop/`
**Adapt from**: `bin/omarchy-hw-touchpad`

- [x] Depends on: persistent Hyprland toggle system — built first *(done 2026-08-30)*
- [x] Implemented `desktop/executable_touchpad-toggle`: finds the touchpad via `hyprctl devices -j`, toggles live via `hyprctl keyword "device[$name]:enabled" true/false`, `notify-send` OSD *(done 2026-08-30)*
- [x] **Post-apply bug found and fixed**: the initial name-match regex (`test("touchpad")`) worked against a mocked device name but failed on this machine's real hardware — `hyprctl devices -j` reports it as `synaptics-tm3512-010`, no literal "touchpad" substring. Widened the match to `touchpad|synaptics|clickpad|alps|elan` (excluding `trackpoint|trackball`, since some trackpoints are also Elan-branded). Verified end-to-end on real hardware after `chezmoi apply`: two full toggle cycles, `current.conf` block and marker file appeared/cleared correctly each time, touchpad left enabled *(done 2026-08-30)*
- [x] Persisted via `hypr-toggle set/clear touchpad` plus a boolean marker file (`~/.local/state/dotfiles/touchpad-disabled`) tracking current state across invocations *(done 2026-08-30)*
- [x] Device name validated against `^[A-Za-z0-9._:-]+$` (expanded from the lid item's pattern to allow `:`, which real touchpad device names use) before it reaches the `hyprctl keyword` string or the persisted config fragment — passed as a quoted argv element, never `eval`'d — the exact v4.0.1 `omarchy-toggle-input-device` fix class *(done 2026-08-30)*
- [x] Bound `XF86TouchpadToggle` (`bindld` — locked, so it works even from the lock screen, matching the v4.0.1 finding that this bind is reachable while locked) in `hardware.conf.tmpl`/`.lua.tmpl` alongside the lid bindings, laptop-gated *(done 2026-08-30)*

---

## Done sub-tasks of items still open in the live plan

The live plan carries the remaining `[ ]` boxes; the work already landed is recorded here.

### Hyprland Lua config is the forward path (v4.0.0) — P1

- [x] Confirm which entry point Hyprland loads today — `hyprland.conf`, by deliberate `.chezmoiignore` exclusion of `hyprland.lua`
- [x] Establish the actual unblock condition and record it where the hold lives
- [x] Diff each `conf/X.conf` against `conf/X.lua` and reconcile any drift — 21 pairs, 17 at parity. Four findings *(2026-08-30)*: (1) `voice.lua` lacked `.tmpl`, so the two Parakeet bindings were unconditional instead of desktop-only → renamed `voice.lua.tmpl` with the `chassisType` gate; (2) rose-pine dawn/moon wrote 10-digit `0xff<rrggbb><aa>` borders in *both* formats, silently truncated by Hyprland to the last 8 (`hyprctl getoption` returned `907aa9ee`) → converted to `rgba(...)`; (3) `SUPER+ALT+m` was labelled "Move to other monitor" but neither source crossed a monitor → `movewindow, mon:+1` / `hl.dsp.window.move({ monitor = "+1" })`; (4) `media-keys.conf` lacked the `.lua` side's locked/repeat flags, so volume+brightness were dead on the lock screen → `bindeld`/`bindld`

> **Correction (2026-08-24)**: an earlier revision of this item framed the dual `.conf`/`.lua` sources as unmanaged drift risk and asked which entry point is authoritative. That was wrong on both counts. The `.lua` set **is** deployed and live (`~/.config/hypr/conf/*.lua` all present); only the *entry point* is held back, deliberately, by `.chezmoiignore` — which documents why. Hyprland here is already 0.56.2, the version Omarchy converted for.

Waybar PR #5013 re-check, 2026-08-30: **merged 2026-05-04** into master; latest release still **0.15.0 (2026-02-06)**, predating it; Arch `extra` still ships `waybar 0.15.0-2`; no 0.16.0 exists. The fix is upstream but in no tagged release. Full state recorded in `.chezmoiignore` so the next check is a version comparison, not a re-investigation.

### Drop the `kms` hook when proprietary NVIDIA handles early KMS (v4.0.0) — P2

- [x] Made conditional at apply-time instead of a manual per-machine assumption: `.chezmoi.yaml.tmpl` now exposes `hasIntegratedGpu` (sysfs scan for vendor `0x8086`/`0x1002` + class `0x03xx`, same technique as the NVIDIA sysfs item above) — `run_once_after_005_configure_boot_system.sh.tmpl` checks it, not a hardcoded "this machine is NVIDIA-only" belief. Confirmed via `chezmoi execute-template` that **this machine is actually hybrid** (`hasIntegratedGpu: true`), correcting the skip-list's "no hybrid graphics here" note — the hook stays on this box, drops automatically on a genuinely NVIDIA-only one *(done 2026-08-30)*
- [x] `i915` is now also conditional on `hasIntegratedGpu` in the `MODULES=(...)` write (it was previously hardcoded in, which was already wrong on an NVIDIA-only box); when no iGPU, `kms` is stripped from `/etc/mkinitcpio.conf`'s `HOOKS=` array via a sed pattern mirroring the existing Plymouth-hook-insertion convention (backup-before-first-edit, idempotency check, hard-fail with a clear error if removal verification fails) *(done 2026-08-30)*
- [x] `nvidia_drm.modeset=1` and the nvidia modules stay in `MODULES` regardless — only `i915` and the `kms` HOOKS entry are conditional, so Plymouth still gets an early mode set *(done 2026-08-30)*
- [x] Fixed a latent bug found while touching this section: the NVIDIA `MODULES=` conf write never set the script's `REBUILD_NEEDED` flag, so a first-time write (or this new HOOKS edit) could silently skip the `mkinitcpio -P` rebuild it required — both `NVIDIA_MODULES_CHANGED` and `KMS_HOOK_CHANGED` now feed into it *(done 2026-08-30)*
- [x] Verified: rendered both branches (`hasIntegratedGpu: true` and a simulated `false`) via `chezmoi execute-template`, `bash -n`, and `shellcheck` — clean on both, and unit-tested the HOOKS-removal sed against sample lines with `kms` mid-list and `kms` as the last hook (first version had a backreference bug — `\1` was missing from the replacement — caught and fixed before this) *(done 2026-08-30)*

### External monitor brightness via DDC/CI (v4.0.0) — P2

- [x] Added `ddcutil` to `packages.yaml` (`desktop_hyprland`, next to `brightnessctl`) *(done 2026-08-30)*
- [x] Implemented `desktop/executable_brightness-set {up|down}` — `brightnessctl` when `/sys/class/backlight/*` exists (unchanged laptop behavior, verified: this machine has `intel_backlight` and takes this path), else resolves the Hyprland-focused monitor and matches it to a ddcutil bus by DRM connector name (`ddcutil detect --brief`'s "DRM connector: cardN-DP-X" vs Hyprland's `.name`) — verified the awk parser against sample multi-monitor `ddcutil detect --brief` output. `ponytail:` comment marks the single-monitor fallback (first detected bus) as the ceiling if connector matching fails; upgrade path is a full multi-monitor match, not needed for this desktop's one external display *(done 2026-08-30)*
- [x] Bus number cached per-monitor in `$XDG_RUNTIME_DIR/ddc-bus-<name>` *(done 2026-08-30)*
- [x] Repointed `XF86MonBrightnessUp/Down` in `media-keys.conf` + `.lua` at the new script; ran `stylua` on the `.lua` edit (line length required reformatting to multi-line `o.bind` calls) *(done 2026-08-30)*
- [x] `i2c-dev` + group permissions: added to `run_once_after_002_configure_system_services.sh.tmpl` (module load via `/etc/modules-load.d/i2c-dev.conf`, `i2c` group created with `groupadd -f` since Arch doesn't ship one by default, udev rule `KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"`, user added to the group) — gated on `command -v ddcutil`, verified via `chezmoi execute-template` + `shellcheck` *(done 2026-08-30)*

### Lid / clamshell display handling (v3.6.0, v4.0.0, v4.0.1) — P2

- [x] Added `bindld` lid switch handlers (`switch:on:Lid Switch` / `switch:off:Lid Switch`) in new `private_dot_config/hypr/conf/bindings/hardware.conf.tmpl` + `.lua.tmpl`, gated `{{ if eq .chassisType "laptop" }}` *(done 2026-08-30)*
- [x] New script `desktop/executable_lid-toggle {close|open}` resolves the internal panel via `hyprctl monitors -j` (`eDP*` name), disables/enables it via `hyprctl keyword monitor` *(done 2026-08-30)*
- [x] Idempotent: `close` persists the panel's current scale to `~/.local/state/dotfiles/lid-monitor-<name>`; `open` reapplies that scale rather than a default, so repeated cycles converge *(done 2026-08-30)*
- [x] Guards against disabling the only active display (counts non-disabled monitors via `hyprctl monitors -j` first) *(done 2026-08-30)*
- [x] Checked HyprDynamicMonitors: `hyprdynamicmonitors/config.toml:3` has `enable_lid_events = false` — it deliberately doesn't touch lid events, so no conflict *(verified 2026-08-30)*
- [x] Output name validated against `^[A-Za-z0-9._-]+$` before any `hyprctl keyword` use (v4.0.1 fix pattern) — no existing in-repo helper to copy, written fresh as a small shell function shared with the touchpad-toggle item *(done 2026-08-30)*

### `mise activate bash --shims` in uwsm/env (v3.4.2) — P2

- [x] Create `private_dot_config/uwsm/env` managed by chezmoi
- [x] Set `mise activate bash --shims` in that file

### LocalSend minimum window size rule (v3.4.2) — P2

- [x] Add window rule for LocalSend: `windowrule = match:class localsend, minsize 600 400`

### Audio switch `wpctl set-default` fix (v3.6.0, v4.0.0) — P2

- [x] Replace `pactl set-default-sink "$next_sink"` with `wpctl set-default` using PipeWire object ID from pactl JSON `.index` field *(done 2026-05-04)*

### Keyboard-driven region picker (v4.0.0) — P3

- [x] **Scoped down** (user decision 2026-08-30): Omarchy's full mouse-free transient-layer-bind overlay is out of scope for this pass. `executable_screenshot` already implemented `region`/`windows` modes with no keybinding attached — just bound them: `SUPER CTRL + Print` → `screenshot region`, `SUPER ALT + Print` → `screenshot windows`, in `screenshots.conf`/`.lua` *(done 2026-08-30)*

### Screen recording notification thumbnail + open (v3.4.2, v3.5.0, v3.6.0, v4.0.0) — P3

- [x] Added thumbnail generation: `ffmpeg -y -ss 0 -i "$saved_file" -vframes 1 "$thumb_file"` after recording stops. The stop branch didn't previously know the output path (only the PID was persisted) — added a sibling `${PID_FILE}.path` file written at recording start, read and removed at stop *(done 2026-08-30)*
- [x] Added `notify-send -A "open=Open"` with the thumbnail as icon, backgrounded in a subshell (so the script itself still returns immediately) — clicking "Open" runs a fixed `xdg-open "$saved_file"` argv resolved from the returned action name, never a shell-interpolated string built from notification data (the v4.0.1 injection-class fix). Verified end-to-end with mocked `ffmpeg`/`notify-send`/`xdg-open`: thumbnail generated, action click triggered `xdg-open`, PID+path files cleaned up, tracked process actually killed *(done 2026-08-30)*
- [N/A] Webcam overlay crop fix — no webcam overlay compositing exists in this script at all (confirmed via exploration), nothing to fix

### Voxtype `pause_media` verification (v3.6.0) — P3

- [x] Added `pause_media = true` to `[audio]`; file chezmoi-managed *(done 2026-05-04)*

### Ghostty CSI-u `Shift+Return` encoding (v3.8.3, v4.0.0) — P2

- [N/A] Mirror into `private_dot_config/kitty/` — no `kitty/` directory exists in this repo; Kitty is not chezmoi-managed *(verified 2026-08-30)*

---

## Completed

- [x] **Sticky CWD when opening a new terminal** (v2.0.0, v4.0.0) — `SUPER + Return` launches the terminal with `--working-directory=$(terminal-cwd)`; script at `private_dot_local/lib/scripts/terminal/executable_terminal-cwd` *(confirmed 2026-08-24)*
- [x] **`fip`/`dip`/`lip` zsh parsing** (v3.4.0, v4.0.0) — v4.0.0 fixed omarchy's bash functions misparsing under zsh; our `ssh-port-forwarding.zsh` is a native zsh rewrite using `(( $# ))` and `for port in "$@"`, unaffected *(confirmed 2026-08-24)*
- [x] **Clipboard sensitive-content exclusion** (v1.3.1, v4.0.0) — `clipboard-store` wrapper filters by window class/title; v4.0.0's native equivalent adds nothing we lack *(confirmed 2026-08-24)*
- [x] **`quickshell` package** (v4.0.0, v4.0.1) — already in `packages.yaml` as the official `extra` package, driving the voxtype waveform OSD overlay; v4.0.1's switch to the packaged `quickshell` (away from a patched workaround build) matches what we already had; the full omarchy-shell replacement is out of scope *(confirmed 2026-08-30)*
- [x] **`networkmanager` as the network stack** (v4.0.0) — already in `packages.yaml` alongside `iwd` as the backend; omarchy's iwd→NM move validates the existing setup *(confirmed 2026-08-24)*
- [x] **`pacman-contrib`** (v4.0.0) — already in `packages.yaml`; `paccache` available for the update-prune item *(confirmed 2026-08-24)*
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
- [x] **Tmux integration** (v3.4.0) — Package added, `tmux.conf` created, `t` alias + `tdl`/`tdlm`/`tsl` functions added *(done 2026-03-05)* — **superseded twice**: replaced by zellij, then by native Ghostty splits + Neovim (2026-09-21)
- [x] **Waybar idle-lock indicator** (v3.4.0) — `idle-indicator` script + Waybar module + CSS; DND already covered by `custom/swaync` *(done 2026-03-05)*
- [x] **`try` package** (v3.2.0) — Added to `terminal_tools` in packages.yaml *(done 2026-03-05)*

---

## Skipped / Out of Scope

### v4.0.4 — kernel packaging

- [SKIPPED] **`linux-omarchy` kernel replacing stock `linux`** (v4.0.4) — Omarchy's own kernel package; we run stock `linux` + `linux-lts` from `[core]`, booted via systemd-ukify. The migration (`1789325478.sh`), its machine-wide marker under `/var/lib/omarchy/migrations/`, the `OMARCHY_KERNEL_REBUILD_MARKER` override and the explicit `reboot-required` flag are all Omarchy migration machinery, on top of an OPR-only package
- [SKIPPED] **Header-repair migration `1789444024.sh`** (v4.0.4) — installs `<kernel>-headers` for whichever of `linux-omarchy`/`linux-t2` is present; both kernels are out of scope, and the underlying *idea* (base system guarantees headers) is tracked as a P3 item in the live plan
- [SKIPPED] **Omarchy shell/acceptance test additions** (v4.0.4) — `omarchy-kernel-migration-test.sh`, `kernel-headers-migration-test.sh`, `limine-defaults-test.sh`, stubbing `pacman`/`sudo`/`limine-mkinitcpio`/`limine-entry-tool`/`omarchy-state`. The one portable *assertion* (`verify_kernel_headers`) is tracked as the P2 health check in the live plan
- [SKIPPED] **`agents/skills/install-scripts.md` rule** (v4.0.4) — Omarchy agent documentation governing its own install scripts

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
- [REOPENED] **`herdr` multiplexer** (v4.0.0) — **reopened 2026-09-21**: skipped originally because we used zellij, and zellij is now removed. Evaluated at source level in `_research/TERMINAL_AGENT_RUNTIME.md` as an agent-pane layer (it vendors `libghostty-vt`, so it does not compete with Ghostty). Its `hdl`/`hds`/`hdlm`/`hsl` helpers and keybindings viewer are herdr-specific and would only follow adoption
- [SKIPPED] **tmux pane bindings, window titles, extkeys, tab moves, zoom flag** (v3.8.3, v4.0.0) — no multiplexer; panes are native Ghostty splits + Neovim
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
- [SKIPPED] **T1/T2 MacBook support** (v3.0.0, v4.0.0, v4.0.4) — not applicable hardware; v4.0.4 exempts T2 Macs from the `linux-omarchy` kernel swap and keeps `linux-t2`
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
- [SKIPPED] **Intel Panther Lake/Arc/PTL GPU fixes, thermald, intel-lpmd, media driver/VPL** (v3.4.2–v3.8.0, v4.0.4) — Intel-specific, NVIDIA setup here; v4.0.4 retires the `linux-ptl` kernel and its `zz-dell-xps-panther-lake.conf` Limine drop-in, closing the special case entirely
- [SKIPPED] **`wayfreeze-git` migration cleanup** (v3.4.2) — `wayfreeze-git` still in our packages (intentional)
- [SKIPPED] **Limine bootloader cmdline / Direct Boot** (v3.4.2–v3.7.1, v4.0.0, v4.0.4) — not using Limine; v4.0.4's `BOOT_ORDER` rewrite in `/etc/default/limine` + `omarchy-defaults.conf` has no analogue under systemd-ukify
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
