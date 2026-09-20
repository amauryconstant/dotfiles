# Omarchy Integration Backlog

Living actionable backlog. Updated by `/omarchy-changes`.
Last updated: 2026-09-17 (through v4.0.4). Trimmed to outstanding work 2026-09-21.

**Legend**: `[ ]` pending · `[x]` done · `[SKIPPED]` out of scope · `[REOPENED]` was skipped, premise no longer holds

**Closed work lives in `_plans/archive/OMARCHY_COMPLETED.md`** — every completed item
(with its full implementation notes), every done sub-task of the items still open
here, and the whole skipped/out-of-scope list. **Read it before adding an item**:
most of Omarchy's surface is already decided, and re-adding a settled item is the
main failure mode when this plan is rewritten.

> **v4.0.0 context**: Omarchy "Quattro" replaced its entire desktop shell (Waybar, Walker, Mako, SwayOSD, hyprlock, hypridle, swaybg, polkit-gnome) with a single Quickshell process, converted all Hyprland config to Lua, rewrote the theme schema from ANSI-indexed to 24-key semantic, and moved its internals from a git checkout into Arch packages. The shell replacement itself is out of scope (we use Waybar + Wofi + hyprlock/hypridle), but three sub-currents are directly relevant to us: **Hyprland Lua config for 0.56**, **the semantic colorset + template-rendered app themes**, and a batch of **script-level bug fixes that also exist verbatim in our ported scripts**.
>
> **v4.0.1 context**: A security-focused patch backporting fixes from the post-Quattro `quattro` branch — four CVE-class fixes (FIDO2 authfile symlink/ownership, USB/monitor device names executed as Hyprland Lua, theme-install code execution, video-title command forging) plus hardening, and one default-behavior reversal: sudoless Docker group membership is no longer granted automatically. Our divergence from that reversal is a recorded, accepted risk (see the archive).
>
> **v4.0.4 context**: A kernel-packaging release — Omarchy replaces the stock Arch `linux` kernel with its own `linux-omarchy` package, retires the Dell XPS Panther Lake `linux-ptl` special case, and rewrites Limine's `BOOT_ORDER`. All of that is Omarchy/OPR/Limine scope and skipped. The one transferable current is the *second* change: **matching kernel headers for the running kernel become a base-system guarantee**, stripped out of every individual DKMS installer, backed by a new `verify_kernel_headers` acceptance check. Both halves land on us — our `linux-headers` sit inside the disabled `graphics_drivers_legacy` module (P3), and we have no running-kernel/reboot-required signal at all, a gap confirmed live on this machine (P2).

---

## P1 — High Priority

### Hyprland Lua config is the forward path (v4.0.0)

**What**: Omarchy converted all Hyprland configuration from `.conf` to Lua for Hyprland 0.56 (`hyprland.lua` sourcing a bootstrap, `hl.monitor{}`, `hl.env()`, `hl.unbind()`, `o.bind()` action tables, `omarchy_default_bindings = false` escape hatches, `.luarc.json` shipped alongside). Our repo has already done this migration; only the entry-point cutover is held back.
**Target files**: `.chezmoiignore`, `private_dot_config/hypr/conf/**`, `private_dot_config/hypr/conf/bindings/**`, `.chezmoiscripts/run_once_after_007_validate_hyprland_config.sh.tmpl`
**Effort**: Medium
**Blocked on**: a Waybar release carrying PR #5013 (`fix(hyprland/workspaces): adapt dispatch commands for Lua IPC protocol`) — our Waybar workspace clicks depend on the legacy text dispatch that Lua mode removes. Merged upstream 2026-05-04, in no tagged release as of 2026-08-30 (latest 0.15.0). External; nothing to do here until it lands.

**Cutover runbook**: `_guides/HYPRLAND_LUA_CUTOVER.md` — hold status, cutover/rollback steps, hyprsplit coupling risk. Audit findings/verified prerequisites: `_research/HYPRLAND_LUA_AUDIT.md`. Entry point confirmed as `hyprland.conf` by deliberate `.chezmoiignore` exclusion; the 21 `.conf`/`.lua` pairs were diffed and reconciled (4 findings, all fixed — see archive).

`Hyprland --verify-config` exists ("Do not run Hyprland, only print if the config has any errors"). The entry point is chezmoiignore'd, so render it to a temp path first — it resolves the rest of the tree through `package.path` against the deployed `~/.config/hypr`:

```sh
TMP=$(mktemp -d)
chezmoi execute-template < private_dot_config/hypr/hyprland.lua.tmpl > "$TMP/hyprland.lua"
Hyprland --verify-config -c "$TMP/hyprland.lua"
```

Proves the tree parses and every `require` resolves; does **not** prove dispatcher arguments are correct — the 0.56.2 stub types every dispatcher as `fun(...)`.

- [ ] Resolve the `SUPER+ALT+M` double-bind — `voice` ("Toggle meeting transcription") vs `workspace-management` ("Move to other monitor"). Identical in both `.conf` and `.lua`, so not drift, but a real conflict
- [ ] When Waybar >= 0.16.0 lands: delete the `.chezmoiignore` block, `chezmoi apply`, verify workspace clicks
- [ ] Gate the retirement of the `.conf` set behind an explicit user go-ahead — keep both until the Lua path is confirmed across a reboot and a `hyprctl reload`
- [ ] Extend `run_once_after_007_validate_hyprland_config` to validate whichever entry point is authoritative — use the `Hyprland --verify-config -c <path>` recipe above
- [ ] Review omarchy's helper surface (`hl.unbind`, `hl.monitor{ transform = }`, `hl.env`) against our `conf/helpers.lua` — adopt `unbind` if we ever need to drop an inherited default

**Not doing**: `waybar-git`. It would be the first locally-built `-git` package in the repo and needs a vendored `#commit=<sha>` pin per `_guides/PACKAGE_SUPPLY_CHAIN_SECURITY.md`.

---

## P2 — Medium Priority

### Running-kernel modules / DKMS header mismatch check (v4.0.4)

**What**: Omarchy added an acceptance check asserting that `/usr/lib/modules/$(uname -r)/pkgbase` names the supported kernel, that `<kernel>-headers` is installed, and that `.../build/include/config/kernel.release` equals the running release. What it really catches is the state where a kernel upgrade has landed but the machine has not rebooted — DKMS then builds against a kernel that is not running, and module loads fail.
**Confirmed live here (2026-09-17)**: `linux` is `7.2.6.arch2-1` while `uname -r` reports `7.2.4-arch1-2`, and `/usr/lib/modules/7.2.4-arch1-2/` no longer exists — the upgrade deleted it. Any module not already resident cannot load until reboot. Nothing in the repo surfaces this: `system-health --check` covers disk, failed user units and load average only, and no reboot-required signal exists anywhere in `lib/scripts/` or Waybar.
**Target files**: `private_dot_local/lib/scripts/system/executable_system-health`
**Effort**: Low
**Adapt from**: `test/acceptance.d/system-test.sh` → `verify_kernel_headers`

- [ ] Add to the `--check` branch: `notify-send` when `/usr/lib/modules/$(uname -r)` is missing or its `pkgbase` package version no longer matches the running release (kernel upgraded, reboot pending)
- [ ] Add the same as a `--brief` line (running vs installed kernel), so it is visible on demand and not only from the timer
- [ ] Assert `<kernel>-headers` + `build/include/config/kernel.release` **only when `dkms` is installed** — headers are deliberately absent on the pre-built `nvidia-open` path (see the P3 item below), so an unconditional assertion would fire permanently
- [ ] Keep it advisory: never block, never auto-reboot — `--check` runs unattended from `system-health-check.timer`

---

### Drop the `kms` hook when proprietary NVIDIA handles early KMS (v4.0.0)

**What**: On NVIDIA-only machines the `kms` mkinitcpio hook pulls nouveau and ~100MB of firmware into every initramfs for no benefit, because the proprietary driver already handles early KMS via its own modules. Implemented and verified against both rendered branches; `hasIntegratedGpu` decides it at apply time (this machine is hybrid, so the hook stays here).
**Target files**: `.chezmoiscripts/run_once_after_005_configure_boot_system.sh.tmpl`, `.chezmoidata/boot.yaml`
**Effort**: Medium

- [ ] Rebuild UKIs and reboot-test on a real NVIDIA-only machine (none available so far) — Plymouth must still theme the LUKS prompt, and UKI size should measurably drop

---

### Ghostty CSI-u `Shift+Return` encoding (v3.8.3, v4.0.0)

**What**: Omarchy moved all shipped terminals to CSI-u encoding so TUIs can distinguish `Shift+Enter` (`CSI 13;2u`) and `Alt+Shift+Enter` (`CSI 13;4u`) from plain `Enter` / `Alt+Enter`. Our Ghostty config still sends the ambiguous legacy sequence: `keybind = shift+enter=text:\x1b\r`, which is indistinguishable from `Alt+Return`. Claude Code, Codex and other TUIs use `Shift+Enter` for newline-without-submit.
**Target files**: `private_dot_config/ghostty/config.tmpl`
**Effort**: Low
**Conflict**: Existing `shift+enter=text:\x1b\r` binding must be replaced, not appended.

- [ ] Replace `keybind = shift+enter=text:\x1b\r` with `keybind = shift+enter=csi:13;2u`
- [ ] Add `keybind = alt+shift+enter=csi:13;4u`
- [ ] Verify Claude Code / opencode still insert a newline on `Shift+Enter` after the change (some TUIs only understand the legacy sequence — roll back if so)

---

### External monitor brightness via DDC/CI (v4.0.0)

**What**: Brightness keys and OSD drive the focused *external* display over DDC/CI; laptop panels keep using the kernel backlight. Implemented as `desktop/executable_brightness-set`, with `ddcutil`, the `i2c-dev` module/group plumbing and the `XF86MonBrightness*` rebind all in place.
**Target files**: `private_dot_local/lib/scripts/desktop/executable_brightness-set`, `private_dot_config/hypr/conf/bindings/media-keys.conf` + `.lua`
**Effort**: Medium

- [ ] Manual test on the real desktop with an external DDC/CI-capable monitor (not available so far)

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
This directly parallels our 24-semantic-variable architecture (`colors.sh` with `BG_*`/`FG_*`/`ACCENT_*`), but we still hand-maintain ~20 config files per theme across 8 themes. v4.0.1 sharpened it further: for themes installed via `omarchy theme install <url>`, staging now copies **only** `colors.toml`, `light.mode`, images, and `backgrounds/*` — the four terminal configs, `*.lua`, and `vscode.json` are dropped and generated from `default/themed/*.tpl` instead, closing a code-execution path where a downloaded theme's Lua/config ran at theme-set time. That reframes "hand-written wins over template" as a **trust boundary**, not just a maintenance escape hatch.
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

### Lid / clamshell display handling (v3.6.0, v4.0.0, v4.0.1)

**What**: Internal display auto-toggles via Hyprland `bindl` on `switch:on:Lid Switch` / `switch:off:Lid Switch`, with idempotent scale recovery on clamshell transitions. Laptop-gated. Implemented as `desktop/executable_lid-toggle` + `conf/bindings/hardware.conf.tmpl`/`.lua.tmpl`, including the v4.0.1 output-name validation fix.
**Target files**: `private_dot_config/hypr/conf/bindings/hardware.conf.tmpl` + `.lua.tmpl`, `private_dot_local/lib/scripts/desktop/executable_lid-toggle`
**Effort**: Medium

- [ ] Manual end-to-end test: real lid close/open cycle on hardware (not yet done — functional logic verified with mocked `hyprctl`/`jaq` output instead)

---

### `mise activate bash --shims` in uwsm/env (v3.4.2)

**What**: The `--shims` flag ensures mise-managed tools are available in non-interactive Wayland session environments (e.g. apps launched from Hyprland that don't spawn a login shell). File created and set.
**Target files**: `private_dot_config/uwsm/env`
**Effort**: Low
**Note**: v4.0.0 moves this to a package-owned `/usr/share/uwsm/env.d/10-omarchy` — not applicable to us; `~/.config/uwsm/env` remains the right home for our copy.

- [ ] Verify mise-managed tools (e.g. node, ruby) are visible to Wayland-launched apps

---

### LocalSend minimum window size rule (v3.4.2)

**What**: LocalSend opens with a small default window. A `windowrulev2` with `minsize` fixes this. Rule added to `windowrules.conf`.
**Target files**: `private_dot_config/hypr/conf/windowrules.conf` + `.lua`
**Effort**: Low

- [ ] Confirm localsend class name: `hyprctl clients | grep -A5 -i localsend`
- [ ] Mirror the rule into `windowrules.lua` (dual-source drift risk — see P1 Lua item)

---

### Audio switch `wpctl set-default` fix (v3.6.0, v4.0.0)

**What**: `pactl set-default-sink` doesn't persist via WirePlumber; `wpctl set-default <id>` does (already switched). v4.0.0 additionally makes output/source switching **preserve playback** and adds recovery when audio services get stuck.
**Target files**: `private_dot_local/lib/scripts/desktop/executable_audio-switch`
**Effort**: Low
**Adapt from**: `bin/omarchy-restart-audio`, `bin/omarchy-audio-sink-availability`

- [ ] Test: switch audio device, close session, reopen — sink should persist
- [ ] Consider moving existing streams to the new sink so playback survives the switch (v4.0.0 behaviour)

---

## P3 — Low Priority / Evaluate

### Kernel headers owned by `base`, not by the NVIDIA legacy module (v4.0.4)

**What**: Omarchy made matching kernel headers a base-system guarantee and stripped `linux-headers` from every individual DKMS installer (`omarchy-pkg-add linux-headers <driver>` → `omarchy-pkg-add <driver>`), so DKMS scripts install only their driver. Our `packages.yaml` has the inverse coupling: `dkms`, `linux-headers` and `linux-lts-headers` live **only** inside `graphics_drivers_legacy` (`enabled: false` here), while `base` carries `linux` + `linux-lts`. On the modern `nvidia-open` (pre-built) path none of the three are installed — verified: `pacman -Q dkms linux-headers linux-lts-headers` all report "not found" — and `package-manager sync --prune` would remove them if they ever appeared. Correct today and a real disk saving, but it means the first DKMS package added for any *other* reason (`v4l2loopback` for a virtual camera, `ddcci-dkms`, VirtualBox) fails to build with no obvious cause.
**Target files**: `.chezmoidata/packages.yaml`
**Effort**: Low

- [ ] Decide the policy explicitly: keep headers driver-coupled (status quo, saves disk) or promote `dkms` + `linux-headers` + `linux-lts-headers` into `base` so any future DKMS package builds unattended
- [ ] If any non-NVIDIA DKMS package is ever added, move the three into `base` in that same change rather than duplicating them into a second module
- [ ] Keep `linux-lts-headers` paired with `linux-lts` either way — both kernels are installed, so a single-kernel header set would silently skip module builds for the fallback kernel

---

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

### Keyboard-driven region picker (v4.0.0)

**What**: In the region-select overlay, `RETURN` captures the highlighted window, `CTRL+RETURN` the whole display, `TAB`/arrows move the selection — no mouse needed. Implemented as **transient Hyprland binds registered on `layer.opened` for the `selection` namespace and removed on `layer.closed`**, which is the genuinely reusable trick here. **Scoped down 2026-08-30** to just binding the existing `region`/`windows` screenshot modes; the overlay itself was not built.
**Target files**: `private_dot_config/hypr/conf/bindings/screenshots.lua`, `private_dot_local/lib/scripts/media/executable_screenshot`
**Effort**: Medium
**Adapt from**: `default/hypr/bindings/utilities.lua`, `bin/omarchy-capture-region`

- [ ] The full transient-bind (`layer.opened`/`layer.closed` on `selection` namespace) mouse-free overlay remains unimplemented — revisit if wanted later
- [ ] Rotated-monitor handling in the region picker still untouched (applies to both `screenshot` and `screenrecord`)

---

### Screen recording notification thumbnail + open (v3.4.2, v3.5.0, v3.6.0, v4.0.0)

**What**: After stopping a recording, generate a thumbnail via `ffmpeg` and send a desktop notification with an open action (done). v3.5.0 fixes webcam overlay crop (N/A here); v3.6.0 adds single-pass audio normalization (`loudnorm=I=-14:TP=-1.5:LRA=11`, only when an audio stream is present); v4.0.0 fixes the region picker on rotated monitors and restricts webcam enumeration to real video capture devices.
**Target files**: `private_dot_local/lib/scripts/desktop/executable_screenrecord`
**Effort**: Medium
**Adapt from**: `bin/omarchy-capture-screenrecording` (renamed from `omarchy-cmd-screenrecord` in v3.7.0)

- [ ] Audio normalization pass (`loudnorm=I=-14:TP=-1.5:LRA=11`) — separate sub-feature
- [ ] Rotated-monitor handling in the region picker — separate sub-feature (also noted under the keyboard-region-picker item above)

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

**What**: v4.0.0 closed three theme-install code-execution paths: `colors.toml` values reaching GNU `sed`'s `e` flag, an unescaped VS Code theme name, and unvalidated keyboard RGB values. v4.0.1 went further than input validation: for non-first-party themes, executable files (`*.lua`, terminal configs, `vscode.json`) are no longer staged at all — they're generated from templates instead. That's a stronger boundary than sanitizing values, and directly informs the P2 template-rendering item above. Our themes are repo-owned and chezmoi-managed (low risk today), but `colors.sh` is `source`d by scripts — arbitrary shell in a theme file executes.
**Target files**: `private_dot_config/themes/CLAUDE.md`, theme generation/apply scripts
**Effort**: Low

- [ ] Document the trust boundary in `themes/CLAUDE.md`: theme files are executed, therefore repo-owned only
- [ ] If template generation lands: validate color values against `^#[0-9a-fA-F]{6}$` before substitution, and never pass theme-derived values through `sed` expressions
- [ ] Prefer "don't stage executable theme files at all" over "sanitize values" if external theme import is ever added — matches the v4.0.1 approach, stronger than input validation alone
- [ ] Never add an "import theme from URL" feature without this in place

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

**What**: `pause_media = true` under `[audio]` pauses MPRIS players while dictating. Added and chezmoi-managed.
**Target files**: `private_dot_config/voxtype/config.toml`
**Effort**: Low

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

## Completed / Skipped

Moved to `_plans/archive/OMARCHY_COMPLETED.md` (2026-09-21). Consult it before
adding an item here — it also records the `[REOPENED]` `herdr` multiplexer
evaluation and the accepted-risk decision on sudoless Docker.

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
| v4.0.4 | `_research/omarchy/OMARCHY_v4.0.4.md` | 2026-09-17 |
