# Omarchy v4.0.0 — Release Research

**Date researched**: 2026-08-24
**Previous version**: v3.8.4 (release notes compare against v3.8.5)
**Commits**: 1738
**Source**: GitHub release notes

---

## Summary

"The Quattro Release" replaces the entire Omarchy desktop shell stack with a single long-running [Quickshell](https://quickshell.org) process (`omarchy-shell`) that hosts the bar, launcher, menus, notifications, OSDs, control panels, lock screen, and polkit agent as plugins. Waybar, Walker/Elephant, Mako, SwayOSD, hyprlock, hypridle, swaybg, polkit-gnome, iwd/impala, bluetui, and wiremix are all removed. Omarchy internals move from a git checkout to two Arch packages (`omarchy` + `omarchy-settings`) shipping into `/usr/share/omarchy` and `/etc/skel`, all Hyprland configuration converts from `.conf` to Lua for Hyprland 0.56, and the theme palette expands from 8 ANSI colors to a 24-key semantic colorset used to autogenerate btop/neovim/VS Code/shell theme files.

The diff spans 1876 files, +104141/-13844 lines. `bin/` alone accounts for 21% of changed files, and a new `shell/` tree (175 files of QML) plus a new `etc/` tree (33 system drop-ins) did not exist before.

## Breaking Changes

- **Entire desktop shell stack replaced**: Waybar, Walker, Mako, SwayOSD, hyprlock, hypridle, swaybg, and polkit-gnome are removed from the package set and their config directories deleted (`config/waybar/`, `config/walker/`, `config/swayosd/`, `config/elephant/`, `config/hypr/hyprlock.conf`, `config/hypr/hypridle.conf`). All of their functions now live inside `omarchy-shell`, a Quickshell process. Any per-app config or styling for those tools no longer has an effect.
- **Hyprland configs converted from `.conf` to Lua**: every `config/hypr/*.conf` and `default/hypr/**/*.conf` is deleted and replaced by `.lua`. `hyprland.conf`, `bindings.conf`, `monitors.conf`, `input.conf`, `looknfeel.conf`, `autostart.conf` → `hyprland.lua`, `bindings.lua`, `monitors.lua`, `input.lua`, `looknfeel.lua`, `autostart.lua`. Requires Hyprland 0.56. Hand-written `source = ...` includes and `bind = ...` lines no longer parse.
- **Theme `colors.toml` schema replaced**: the ANSI-indexed `color0`–`color15` + `cursor`/`selection_foreground`/`selection_background` format is replaced by a 24-key semantic format (`mode`, `accent`, `selection`, `muted`, four `*background` keys, four `*foreground` keys, and named/bright color names). Legacy short names (`bg`, `fg`, `dark_bg`, …) remain supported as aliases, but the old numbered scheme is not the source of truth. Custom themes need porting.
- **Omarchy internals moved from git checkout to Arch packages**: `boot.sh` and `install.sh` are gone from the repo root. Files ship via `omarchy` (`/usr/bin/omarchy-*`, `/usr/share/omarchy/{install,migrations,themes,shell}`) and `omarchy-settings` (`/etc/skel/**`, `/etc/**` drop-ins, `/usr/lib`, fonts, plymouth/sddm themes). Updates flow through pacman. `~/.local/share/omarchy` as the live source tree is no longer the model.
- **Direct `pacman -Syu` blocked by an ALPM guard**: `default/libalpm/hooks/00-omarchy-update-guard.hook` runs `omarchy-update-pacman-guard` `PreTransaction` on `Target = *` with `AbortOnFail`. System updates must go through `omarchy update`; bypass with `OMARCHY_ALLOW_DIRECT_PACMAN=1`.
- **Wi-Fi stack switched from iwd to NetworkManager**: `iwd` and `impala` removed, `networkmanager` added. The upgrade path unmasks a `wpa_supplicant` left masked from the iwd era. Existing iwd-managed profiles do not carry over automatically.
- **Privilege escalation moved to pkexec/polkit**: privileged Omarchy operations now use pkexec with a themed shell prompt instead of `sudo` in a terminal. The unconstrained `tzupdate` sudoers grant was dropped.
- **Default terminal changed from Alacritty to Foot**: `alacritty` removed from the base package list, `foot` added, `config/foot/foot.ini` added. Alacritty remains available as a themed target (`default/themed/alacritty.toml.tpl`).
- **Default apps replaced**: Typora → Omawrite (`typora` package and `applications/typora.desktop` removed), GNOME Calculator → Omacalc (`gnome-calculator`, `libqalculate` removed), Satty → Tensaku, `dust` → `dua-cli`, `terminaltexteffects` → `ttfx`, `neovim` → `nvim`.
- **Signal, Spotify, and 1Password moved to on-demand installs**; Figma and GitHub removed from default web apps; the ChatGPT web app is replaced by a real desktop app under `Install > AI`.
- **`config/omarchy/extensions/menu.sh` removed**: menu extension format is now JSONC at `~/.config/omarchy/extensions/omarchy-menu.jsonc`.
- **`config/uwsm/{default,env}`, `config/environment.d/fcitx.conf`, `config/xdg-terminals.list`, `config/fontconfig/fonts.conf`, `config/fastfetch/config.jsonc`, `config/omarchy.ttf` removed from `$HOME`**: these moved to package-owned system paths (`/usr/share/uwsm/env.d/10-omarchy`, `/usr/lib/environment.d/`, `/usr/share/xdg-terminal-exec/`, `/usr/share/fontconfig/conf.avail/50-omarchy.conf`, `/etc/fastfetch/config.jsonc`, `/usr/share/fonts/omarchy/omarchy.ttf`).
- **Generated theme state relocated** to `~/.local/state/omarchy/current/` (`theme`, `theme.name`, `next-theme` staging dir). `~/.config/omarchy/` is reserved for user-authored files (user themes, hooks, shell layout, plugins, template overrides).
- **Existing users do not pick up new shipped defaults automatically**: `/etc/skel` only fires at user creation. Resyncing requires the explicit destructive `omarchy-reinstall-configs`.

## Features

- **Quickshell desktop shell**: new `shell/` tree (`shell.qml`, `Commons/`, `Ui/`, `services/`, `plugins/`) hosting bar, launcher, menus, notifications, OSDs, panels, lock screen, and polkit agent in one process. Omarchy path: `shell/`
- **Bar plugin system**: plugins are git repos with a root `manifest.json` (`schemaVersion`, `id`, `name`, `kinds`, `entryPoints`). Kinds: `bar-widget`, `bar`, `panel`, `overlay`, `menu`, `service`. Installed via `omarchy plugin add <git-url>` into `~/.config/omarchy/plugins/<id>/`; managed under `Setup > Plugins` (add, clone, enable, disable, remove). Plugins land disabled for review; updates show a diff. Omarchy path: `shell/services/PluginRegistry.qml`, `docs/omarchy-shell.md`
- **Modular interactive bar**: widgets for workspaces, active window, clock, weather, media (MPRIS), system tray, battery, keyboard layout, microphone, update indicator, model usage, plus manual-state indicators (DND, night light, stay awake, screen recording, dictation, reminders). Drag the bar to any screen edge (vertical on left/right), double-click empty space to toggle transparency. Widgets managed with `omarchy bar put` / `omarchy bar move`. Omarchy path: `shell/plugins/bar/Bar.qml`, `bin/omarchy-bar`
- **Unified menu + launcher**: `SUPER + SPACE` opens a filterable nested command palette that searches both apps and Omarchy commands; `SUPER + ALT + SPACE` opens an apps-only launcher. Fuzzy/acronym matching, live app icon indexing, hidden-entry management. Extensible via `~/.config/omarchy/extensions/omarchy-menu.jsonc`. Omarchy path: `config/omarchy/extensions/omarchy-menu.jsonc`, `shell/plugins/menu/Menu.qml`
- **Native notification daemon**: popups, do-not-disturb, deduping, replayable history (`SUPER + SHIFT + ALT + ,` replays the last ten, including DND-silenced ones), right-click dismissal, popups survive shell restarts. Bindings use xkbcommon `comma` (not `COMMA`). Omarchy path: `default/hypr/bindings/utilities.lua`
- **Native clipboard manager** with image previews and sensitive-content exclusion (`SUPER + CTRL + V`); **native emoji picker** (`SUPER + CTRL + E`, `omarchy-shell shell toggle omarchy.emojis`).
- **Control panels**: Audio (`SUPER + CTRL + A`), Bluetooth (`SUPER + CTRL + B`), Network (`SUPER + CTRL + W`), Display (`SUPER + CTRL + D`), Power (`SUPER + CTRL + P`). Right-side bar panels also open with `SUPER + CTRL + 1`…`9` counted left to right.
- **Network panel capabilities**: ping, live up/down stats, speed test, DNS provider selection, Wi-Fi QR sharing, Wi-Fi band toggle, enterprise 802.1X connections. Omarchy path: `bin/omarchy-network-*`, `bin/omarchy-dns`
- **Shell-powered lock screen and PAM flows**: replaces hyprlock; password and fingerprint PAM, first-run fingerprint enrollment offer when a reader is present, fingerprint offers on lock screen/polkit/sudo gated by lid state. Omarchy path: `install/config/lockscreen-pam.sh`, `bin/omarchy-setup-security-fingerprint`
- **Visual theme switcher** (`SUPER + SHIFT + CTRL + SPACE`) and **background switcher** (`SUPER + CTRL + SPACE`) as filterable live-preview carousels. Omarchy path: `bin/omarchy-theme-switcher`, `bin/omarchy-theme-bg-switcher`
- **Autogenerated app themes from the expanded colorset**: `default/themed/*.tpl` renders btop, neovim, VS Code, Helix, Chromium, Claude, Pi, Obsidian, foot, ghostty, kitty, alacritty, keyboard RGB, `hyprland.lua`, and `shell.toml` at theme-set time. Per-theme `btop.theme` files are dropped. Omarchy path: `default/themed/`, `bin/omarchy-theme-set-templates`
- **Text scaling in one knob**: `omarchy display text size` (9–20px) moves the shell font, GTK `text-scaling-factor`, and terminal point size together, with a notched slider in the Display panel. Omarchy path: `bin/omarchy-display-text-size`
- **Configurable default coding agent**: Claude Code, Codex, OpenCode, Pi, Oh My Pi, Gemini, Grok, Copilot, or Crush under `Setup > Defaults > Agent`. Launched with `SUPER + SHIFT + CTRL + A` or the `a` alias, lazy-installed on first use, opened as `org.omarchy.agent`, started in `~/Work` when summoned from home. Omarchy path: `bin/omarchy-default-agent`, `bin/omarchy-agent`
- **AI crash diagnosis**: systemd-coredump journal stream raises a "Process crashed" toast; clicking briefs the default agent using a `diagnose-crash` skill. Omarchy path: `bin/omarchy-crash-watch`, `default/systemd/user/omarchy-crash-watch.service`, `agents/skills/`, `default/agents/skills/diagnose-crash/`
- **Service widgets and panels for Tailscale and Dropbox**: Tailscale connection control and exit-node picker with Mullvad nodes grouped by country; Dropbox login, storage, recent files. Omarchy path: `bin/omarchy-install-service-tailscale`, `bin/omarchy-install-service-dropbox`
- **Weather panel** with forecast and a location pinnable to a chosen place instead of IP geolocation. Omarchy path: `bin/omarchy-weather-location`, `bin/omarchy-weather-status`
- **Model-usage bar widget** showing Claude Code / Codex / Fireworks usage stats. Omarchy path: `bin/omarchy-agent-usage-claude`, `bin/omarchy-agent-usage-codex`, `bin/omarchy-agent-usage-fireworks`
- **Google Meet picture-in-picture widget**.
- **New default apps**: Omawrite (Markdown editor, `SUPER + SHIFT + W`), Omacut (ffmpeg-based video trimmer), Omacalc (calculator, `SUPER + CTRL + Q` and `XF86Calculator`).
- **Herdr shipped alongside tmux**: matching keybindings and config, `hdl`/`hds`/`hdlm`/`hsl` development-layout helpers, `SUPER + CTRL + RETURN` to open, `SUPER + CTRL + K` for its keybindings viewer. Tmux keybindings viewer on `SUPER + ALT + K`. Omarchy path: `config/herdr/config.toml`, `default/bash/fns/herdr`
- **QR code capture**: select a region and decode a QR inside it straight to the clipboard; the decoded value never touches disk and is marked sensitive so clipboard history skips it. Omarchy path: `bin/omarchy-capture-qr`
- **Keyboard-driven region picker**: `RETURN` captures the highlighted window, `CTRL + RETURN` the whole display, `TAB`/arrows move the selection. Implemented as transient Hyprland binds registered on `layer.opened` for the `selection` namespace and removed on `layer.closed`. Omarchy path: `default/hypr/bindings/utilities.lua`, `bin/omarchy-capture-region`
- **Window width save/restore per app and workspace**: `SUPER + ALT + HOME` saves, `SUPER + HOME` restores. Omarchy path: `bin/omarchy-hyprland-window-width`, `default/hypr/workspace-layouts.lua`
- **External monitor brightness via DDC/CI**: brightness keys and OSD drive the focused external display; laptop panels keep using the kernel backlight. Omarchy path: `bin/omarchy-brightness-display-ddc`
- **Laptop clamshell handling**: idempotent scale recovery, internal-display toggle (`SUPER + CTRL + Delete`), display mirroring (`SUPER + CTRL + ALT + Delete`), lid switch binds. Omarchy path: `bin/omarchy-hyprland-monitor-clamshell`, `bin/omarchy-hw-clamshell`, `bin/omarchy-system-lid-close`
- **Per-laptop speaker tunings**: a PipeWire filter chain in front of the internal speaker sink, matched by DMI string. Ships for XPS 14/16; adding a machine is two data files. Omarchy path: `default/audio/filter-chain-host.conf`, `default/audio/tunings/dell-xps-2026/`, `install/hardware/speaker-tuning.sh`, `default/systemd/user/omarchy-speaker-tuning.service`, `docs/AUDIO-TUNING.md`
- **Deferred first-boot provisioning**: an install can finish with no user; the owner picks keyboard, account, hostname, and timezone on first boot. On an encrypted disk the LUKS volume is re-keyed from the throwaway install passphrase to the owner's password, all-or-nothing, killing every other slot. Omarchy path: `install/provisioning/`, `bin/omarchy-provision-first-run`, `bin/omarchy-provision-owner`, `bin/omarchy-provision-user`
- **Factory reset** (`Setup > Reset Computer`): swaps the running root for a fresh clone of the `@factory` snapshot taken at install, scrubs machine identity, accounts, and fingerprint enrollments. Refuses machines with no factory snapshot. Omarchy path: `bin/omarchy-system-factory-reset`, `install/provisioning/omarchy-system-factory-reset-finish.service`
- **Dual-boot installation** offered when free space is available.
- **New themes**: Solitude, Last Horizon, Lupine, and a Pi theme based on the system theme.
- **New backgrounds**: Quattro background, a winding-road launch background for Tokyo Night, and the classic Omakub background restored in Tokyo Night; retired backgrounds removed.
- **Chromium yt-dlp "Download Video" extension** (`Alt + Shift + D` on any URL with a video). Omarchy path: `default/chromium/extensions/yt-dlp/`, `bin/omarchy-chromium-ytdlp-host`
- **WhatsApp Web follows system light/dark theme** and collapses to a Signal-style avatar rail in slim windows. Omarchy path: `default/chromium/extensions/whatsapp-slim/`
- **Moonlight client** for Sunshine game/desktop streaming as a new default.
- **Automounting of removable drives** via udiskie.
- **mpv MPRIS support** so media keys control mpv.
- **SSHD setup and removal** under `Setup/Remove > Security`. Omarchy path: `bin/omarchy-setup-security-sshd`, `bin/omarchy-remove-security-sshd`
- **Disk speed test** under `Trigger > Speed Test`, sharing the live dial interface with the network test. Omarchy path: `bin/omarchy-disk-speedtest`
- **LocalSend sharing through the desktop file chooser** instead of an fzf pick over a `find` of `$HOME`. Omarchy path: `bin/omarchy-file-select`, `bin/omarchy-menu-share`
- **`pre-refresh-pacman.d` hooks** for custom repository support. Omarchy path: `config/omarchy/hooks/pre-refresh-pacman.d/add-custom-repo.sample`
- **Alternative media next/previous bindings** for keyboards with only a play button; **Caps Lock toggle by pressing both Shift keys**.
- **First-login toast** that opens the keybindings menu when clicked, gated on NetworkManager actually settling before deciding Wi-Fi is missing or offering an update.

## Bug Fixes

- **fontconfig monospace binding overriding app-specific fonts**. Omarchy path: `default/fontconfig/conf.avail/50-omarchy.conf`
- **Power profile race on plug/unplug events**; explicit power profile choices now remembered per power source (AC/battery) across reboots. Omarchy path: `bin/omarchy-powerprofiles-init`, `bin/omarchy-powerprofiles-set`
- **Brightness indicator glitches from hardware key auto-repeat**; **brightness OSD width jitter across percentages**.
- **New windows (including browser windows and portal file dialogs) opening on the wrong workspace**.
- **LUKS passphrase prompt ignoring the configured keyboard layout** — `vconsole.conf` bundled into the initramfs (Latin layouts). Omarchy path: `etc/mkinitcpio.conf.d/omarchy_hooks.conf`
- **Empty disk encryption passwords accepted when changing the drive password**. Omarchy path: `bin/omarchy-drive-password`
- **Snapshot pruning off-by-one vs Snapper retention**; **update proceeding without the expected Snapper snapshot now reported instead of claimed**.
- **Software cursors forced on nouveau**; **software-composited cursors kept out of screenshots**. Omarchy path: `install/user/hardware/fix-nouveau-cursor.sh`
- **New terminals not opening in the current directory on Kitty**. Omarchy path: `bin/omarchy-cmd-terminal-cwd`
- **`fip` and friends misparsing under zsh**.
- **F9 bound to Voxtype only when installed**. Omarchy path: `default/hypr/bindings/voxtype.lua`
- **Noto Naskh Arabic preferred over Nastaliq Urdu for Arabic text**.
- **Screensaver runs on every monitor**, not just the last one. Omarchy path: `bin/omarchy-screensaver`
- **Brave Origin switched from beta to stable release**.
- **High-res site icons fetched for web apps** instead of blurry favicons. Omarchy path: `bin/omarchy-webapp-install`
- **Night light temperature resent until it sticks on a hyprsunset cold start**. Omarchy path: `bin/omarchy-restart-hyprsunset`
- **XDG MIME browser handler fallback** when `xdg-settings` names no browser. Omarchy path: `bin/omarchy-default-browser`
- **About window fitted to rendered content** and reopened at its last settled size.
- **Background cycling for filenames with glob characters**. Omarchy path: `bin/omarchy-theme-bg-next`
- **Suspend and fan defaults on T2 Macs**; **gmux display backlight chosen instead of the Touch Bar on T2 Macs**; **T2 defaults migration rerun** after `pipefail` hardware-detection false negatives. Omarchy path: `install/hardware/apple/fix-t2.sh`
- **Tuxedo/Slimbook backlight fix no longer aborts hardware setup**. Omarchy path: `install/hardware/fix-tuxedo-backlight.sh`
- **Keyboard-layout migration no longer aborts** when `vconsole.conf` is missing or defines no layout.
- **UKIs found through a restricted `/boot`** on encrypted installs, fixing direct-boot setup and stale-UKI cleanup. Omarchy path: `bin/omarchy-setup-direct-boot`
- **Three theme-install code-execution paths closed**: `colors.toml` values reaching GNU sed's `e` flag, an unescaped VS Code theme name, unvalidated keyboard RGB. The unconstrained `tzupdate` sudoers grant that let any wheel user write a root-owned symlink anywhere was dropped. Omarchy path: `bin/omarchy-theme-install`, `etc/sudoers.d/omarchy-tzupdate`
- **Monitor brought up at 0x0 because it was powered off at boot** now recovered — the connector never drops at DRM level, so powering the screen on fires no event. Omarchy path: `bin/omarchy-hw-recover-internal-monitor`, `default/systemd/user/omarchy-recover-internal-monitor.service`
- **Broadcom Wi-Fi quirk applied to Macs without a T2**, gating on the PCI IDs `brcmfmac` actually binds rather than the T2 bridge; repairs machines installed before it shipped (WPA2/WPA3 transition-mode four-way handshake failures reported as a wrong password). Omarchy path: `install/hardware/apple/fix-brcmfmac-supplicant.sh`, `install/hardware/fix-bcm43xx.sh`
- **Non-login shells given the system locale**, so bash started by SSH or herdr's remote bridge stops printing `\u` escapes.
- **Theme symlinks repaired** where the state-move migration left an unexpanded literal `~`, which cost btop, Helix, and VS Code their theme while reporting success.
- **Boot images rebuilt** where the Plymouth migration left them stale, which kept encrypted machines falling back to an unthemed text LUKS prompt.
- **`--help` honored for commands that resolve with arguments left over** (e.g. `omarchy update aur --help`). Omarchy path: `bin/omarchy`
- **`kms` hook dropped when the proprietary NVIDIA driver handles early KMS**, cutting nouveau and ~100MB of firmware from every initramfs on NVIDIA-only machines; existing images rebuilt on upgrade. Omarchy path: `install/hardware/nvidia.sh`, `etc/mkinitcpio.conf.d/omarchy_hooks.conf`
- **Hybrid GPU mode queries and the menu's hybrid-GPU gate no longer hang** on a wedged supergfxd. Omarchy path: `bin/omarchy-hw-hybrid-gpu`, `bin/omarchy-toggle-hybrid-gpu`
- **Only real video capture devices offered as webcams**, so IPU6 laptops stop opening a black overlay. Omarchy path: `bin/omarchy-hw-webcam`, `bin/omarchy-capture-webcam-list`
- **LVDS and DSI panels treated as internal displays**, so older laptops stop counting their own screen as external. Omarchy path: `bin/omarchy-hw-external-monitors`
- **imv deletions go to trash**; `Ctrl+E` edits in Tensaku. Omarchy path: `config/imv/config`
- **Rotated monitors handled in the recording region picker**.

## Improvements

- **Event-driven shell**: status indicators, monitor and network state, and the background react to signals rather than polling, so an idle desktop stops consuming CPU.
- **ISO shrunk by over a gigabyte** (under 6GB) and **install sped up by +30%** (sub-minute installs possible).
- **Apps launched in their own systemd scopes** instead of the compositor's cgroup, with systemd-oomd able to kill a runaway app instead of the whole session. Omarchy path: `default/systemd/user/app.slice.d/10-oomd.conf`, `etc/systemd/oomd.conf.d/10-omarchy.conf`
- **Lazy-loaded tools (Claude Code, GitHub CLI) switched from npm to mise**, with wrappers and `omarchy update` kept on current releases instead of waiting out the release cooldown. Omarchy path: `bin/omarchy-mise-install`, `bin/omarchy-update-mise`
- **`ttfx` replaces terminaltexteffects**: a Rust port rendering byte-identical frames as a single dependency-free binary; screensaver starts in ~1ms instead of ~107ms and the base image no longer needs Python for it.
- **NVIDIA GPUs detected from sysfs instead of lspci**, avoiding resuming a runtime-suspended discrete GPU out of D3cold (which exceeded Hyprland's 1.5s config-load budget). Classified by device ID so pre-Maxwell cards stay off an incompatible driver and missed Maxwell/Pascal parts are picked up. Omarchy path: `bin/omarchy-hw-nvidia`, `default/hypr/nvidia.lua`
- **Package cache pruned with `paccache -rk2`** as the first update step, before the snapshot so space is actually reclaimed, keeping one spare version for the offline downgrade path. Omarchy path: `bin/omarchy-update-pkg-prune`
- **Low disk space warning before updating**. Omarchy path: `bin/omarchy-update-requires-free-space`
- **zram swap tuned** instead of left at kernel defaults, so large machines stop reaching for the hibernation swapfile early. Omarchy path: `default/systemd/zram-generator.conf.d/90-omarchy.conf`, `etc/tmpfiles.d/omarchy-zswap.conf`
- **Bluetooth power state persisted across reboots** by making an rfkill soft block the state systemd restores at boot. Omarchy path: `bin/omarchy-bluetooth-power`
- **Docker multi-arch builds enabled by default**. Omarchy path: `etc/docker/daemon.json`, `install/config/docker.sh`
- **Chromium-based browsers pinned to the gnome-libsecret password store** so backend autodetection can't silently log you out. Omarchy path: `install/user/default-keyring.sh`, `config/chromium-flags.conf`
- **SSH resilience**: dropped connections clean up the terminal (no leftover mouse tracking / alternate screen) and reconnect; client keepalives surface the drop in ~45s instead of whenever TCP gives up. Omarchy path: `install/config/ssh-keepalive.sh`, `default/bash/fns/ssh-reconnect`
- **Audio output/source switching preserves playback** with recovery when audio services get stuck. Omarchy path: `bin/omarchy-restart-audio`, `bin/omarchy-audio-sink-availability`
- **Quattro upgrade hardening**: boot-critical kernel parameters preserved and verified, package database forced fresh before keyring installation, partial-transition failures surfaced, NetworkManager/iwd handoff kept safe (including unmasking a masked `wpa_supplicant`). The upgrade follows the channel the machine is already on instead of dropping rc machines onto stable, leaves the Omarchy 3 session running until the reboot, shims legacy Hyprland defaults from the on-disk backup rather than a network fetch of master, runs the packaged firewall config so upgraded machines get ufw-docker rules, and clears the Hyprland error bar. Omarchy path: `bin/omarchy-upgrade-to-quattro`
- **Hyprland reload paused during pacman transactions** via ALPM hooks. Omarchy path: `default/libalpm/hooks/10-omarchy-hyprland-reload-pause.hook`, `default/libalpm/hooks/90-omarchy-hyprland-reload-resume.hook`
- **Fine (±25px) and coarse (±100px) window resizing tiers**.
- **Integrated corner controls (rounded/sharp)** applied across Hyprland, notifications, lock screen, and menus.
- **Keyboard layout widget shipped by default**: hidden while only one layout is configured, click to cycle, labeled with the xkb language code (EN, PT, AR) instead of a truncated description.
- **12-hour AM/PM clock formats** on right-clicking the bar clock; **battery percentage readout toggle** on right-clicking the power widget (also exposed in the Omarchy menu).
- **`ttf-jetbrains-mono-nerd-basic`** replaces the full Nerd Font, saving ~200MB on install.
- **NordVPN shipped directly from the Omarchy package repository**. Omarchy path: `bin/omarchy-install-service-nordvpn`
- **Discord community and Herdr's keybindings viewer added to the Learn menu**.
- **New pane/split bindings for tmux, kitty, ghostty, and alacritty**; tmux tab moves, zoom flag, hostname in window title, and hidden outer pane frame carried over to Herdr.

## Configuration Changes

- **Hyprland Lua config**: `~/.config/hypr/hyprland.lua` sources `$OMARCHY_PATH/default/hypr/bootstrap.lua` (defaulting to `/usr/share/omarchy`), then `require("default.hypr.omarchy")`, then user overrides `require("hypr.{monitors,input,bindings,looknfeel,autostart})`, then `require("default.hypr.toggles")`. Bindings use `o.bind("SUPER + SHIFT + W", "Omawrite", { launch = "omawrite" })`; other action tables are `{ omarchy = "..." }`, `{ tui = "..." }`, `{ webapp = "..." }`, plus `o.bind_toggle(...)`. `hl.unbind("KEY")` removes a default. Globals `omarchy_default_bindings = false` and `omarchy_preinstalled_bindings = false` disable all defaults or only preinstalled-app bindings. Monitors use `hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1, transform = 1 })` and `hl.env("GDK_SCALE", ...)`. A `.luarc.json` ships at repo root and at `config/hypr/.luarc.json`. Omarchy path: `config/hypr/hyprland.lua`, `config/hypr/bindings.lua`, `config/hypr/monitors.lua`, `default/hypr/bootstrap.lua`, `default/hypr/omarchy.lua`, `default/hypr/helpers.lua`, `default/hypr/paths.lua`
- **Theme `colors.toml` semantic format**: keys are `mode` plus `accent`/`selection`/`muted`, `background`/`dark_background`/`darker_background`/`lighter_background`, `foreground`/`dark_foreground`/`light_foreground`/`bright_foreground`, and named colors `red`/`yellow`/`orange`/`green`/`cyan`/`blue`/`magenta`/`brown` with `bright_*` variants. Legacy short aliases (`bg`, `fg`, `dark_bg`, `lighter_bg`, `bright_fg`, …) still resolve; canonical names win when both are defined. Cursors use `bright_foreground` (no separate cursor key); `selection_background = selection` and `selection_foreground = bright_foreground` are derived. Omarchy path: `themes/*/colors.toml`, `docs/theming.md`

  Old (v3.8.4):
  ```toml
  accent = "#7aa2f7"
  cursor = "#c0caf5"
  color0 = "#32344a"
  color1 = "#f7768e"
  ```
  New (v4.0.0):
  ```toml
  mode = "dark"
  accent = "#7aa2f7"
  selection = "#292e42"
  muted = "#414868"
  background = "#1a1b26"
  bright_foreground = "#c0caf5"
  red = "#f7768e"
  ```
- **Theme templates**: `default/themed/*.tpl` are plain files rendered by `omarchy-theme-set-templates`. Placeholders are `{{ key }}`, `{{ key_strip }}` (no `#`), `{{ key_rgb }}` (comma triple), plus `mix`/`mix_strip`/`mix_rgb` (e.g. `{{ mix background foreground 15% }}`) and gradient helpers. User templates at `~/.config/omarchy/themed/*.tpl` render first and suppress the matching built-in output. A hand-written `themes/<name>/shell.toml` or `hyprland.lua` wins over the template. Omarchy path: `default/themed/`, `config/omarchy/themed/alacritty.toml.tpl.sample`
- **Theme activation flow**: `omarchy-theme-set <name>` stages into `~/.local/state/omarchy/current/next-theme` (copy first-party theme → overlay `~/.config/omarchy/themes/<name>/` → generate `colors.toml` from `alacritty.toml` if needed → render templates), then moves it to `~/.local/state/omarchy/current/theme`, writes `theme.name`, and notifies the running shell. Omarchy path: `bin/omarchy-theme-set`, `docs/theming.md`
- **`~/.config/omarchy/shell.json`** — shell layout state, `version: 1`, with `idle` (`screensaver`, `lock` seconds), `bar` (`position`, `transparent`, `centerAnchor`, `layout.left/center/right` arrays of `{ "id": "omarchy.<widget>" }` with per-widget options like clock `format`/`formatAlt`/`verticalFormat`), and `plugins` / `disabledPlugins` arrays that record only deviations from built-in defaults. Omarchy path: `config/omarchy/shell.json`
- **`~/.config/omarchy/shell.toml`** — machine-level style override merged over the active theme's generated shell theme; watched, so edits re-flow the shell live. Sections: `[bar]`, `[hyprland]`, `[controls]`, `[spacing]`, `[font]`, `[popups]`, `[tooltip]`, `[notifications]`, `[launcher]`, `[menu]`, `[polkit]`, `[lock]`, `[image-picker]`. `[font].base-size` is the rem root for the whole type scale; `[spacing].scale` multiplies margins/gaps/padding; both have `scale-with-font`. Themes may ship `themes/<name>/shell.toml` to replace the generated file, and `themes/<name>/shell.lock.toml` overrides lock-screen tokens. Omarchy path: `default/themed/shell.toml.tpl`, `themes/*/shell.lock.toml`
- **Menu extensions moved to JSONC**: `~/.config/omarchy/extensions/omarchy-menu.jsonc` replaces the removed `config/omarchy/extensions/menu.sh`. Omarchy path: `config/omarchy/extensions/omarchy-menu.jsonc`
- **New `etc/` tree of package-owned system drop-ins** (33 files) covering NetworkManager Wi-Fi powersave, docker daemon, mkinitcpio hooks, modprobe USB autosuspend, plymouth, sddm, faillock, sudoers (`omarchy-asdcontrol`, `omarchy-passwd-tries`, `omarchy-tzupdate`), sysctl (file watchers), systemd logind/oomd/resolved/system.conf drop-ins, and tmpfiles. Omarchy path: `etc/`
- **New `default/systemd/user/` units**: `bt-agent.service`, `omarchy-crash-watch.service`, `omarchy-fcitx5.service`, `omarchy-migrate-notify.service`, `omarchy-recover-internal-monitor.service`, `omarchy-sleep-lock.service`, `omarchy-speaker-tuning.service`, `omarchy-tailscale-receive.service`, `app.slice.d/10-oomd.conf`. Installed to `/usr/lib/systemd/user/`. The old `config/systemd/user/omarchy-battery-monitor.{service,timer}` and `swayosd-server.service` are removed. Omarchy path: `default/systemd/user/`
- **Per-channel pacman configs and mirrorlists**: `default/pacman/pacman-{stable,rc,edge}.conf` and `default/pacman/mirrorlist-{stable,rc,edge}`. Omarchy path: `default/pacman/`
- **New user hook directory**: `config/omarchy/hooks/pre-refresh-pacman.d/` alongside existing `battery-low.d`, `font-set.d`, `post-boot.d`, `post-update.d`, `theme-set.d`. Omarchy path: `config/omarchy/hooks/`
- **New docs tree**: `docs/{AUDIO-TUNING,file-layout,migrations,omarchy-shell,theming,update-process}.md`. Omarchy path: `docs/`
- **Unified `omarchy` CLI**: `bin/omarchy` dispatches grouped subcommands (`agent`, `audio`, `bar`, `bluetooth`, `branch`, `branding`, `brightness`, `capture`, `channel`, `clipboard`, `cmd`, `config`, `debug`, `default`, `dev`, `disk`, `display`, `dns`, `drive`, `file`, `finalize`, `font`, `games`, `hibernation`, `hook`, `hw`, `hyprland`, `install`, `installed`, `launch`, `menu`, `plugin`, `theme`, `update`, …) by scanning metadata headers in `bin/omarchy-*`. Omarchy path: `bin/omarchy`
- **Foot terminal config added** at `config/foot/foot.ini`. Omarchy path: `config/foot/foot.ini`

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `quickshell-git` | Runtime for the new Quickshell desktop shell |
| Added | `networkmanager` | Replaces iwd/impala as the Wi-Fi/network stack |
| Added | `foot` | New default terminal |
| Added | `herdr` | Terminal multiplexer shipped alongside tmux |
| Added | `omawrite` | Markdown writing app (replaces Typora) |
| Added | `omacalc` | Calculator (replaces GNOME Calculator) |
| Added | `omacut` | ffmpeg-based video trimmer |
| Added | `tensaku` | Image annotator (replaces Satty) |
| Added | `moonlight-qt` | Sunshine game/desktop streaming client |
| Added | `dua-cli` | Disk usage (replaces `dust`) |
| Added | `ttfx` | Rust screensaver effects (replaces `python-terminaltexteffects`) |
| Added | `udiskie` | Automounting of removable drives |
| Added | `mpv-mpris` | MPRIS support so media keys control mpv |
| Added | `ddcutil` | External monitor brightness via DDC/CI |
| Added | `zbar`, `qrencode` | QR capture/decode and Wi-Fi QR sharing |
| Added | `yt-dlp` | Chromium "Download Video" extension backend |
| Added | `wtype` | Synthetic keystrokes (emoji picker insert) |
| Added | `bluez`, `bluez-tools`, `bluez-utils` | Bluetooth stack now managed directly (replaces bluetui) |
| Added | `lua51`, `luarocks` | Lua runtime for Hyprland Lua configs |
| Added | `inotify-tools` | File watching for live shell/theme reload |
| Added | `libvips` | Image processing for theme/background previews |
| Added | `pacman-contrib` | `paccache` pruning during update |
| Added | `qemu-user-static-binfmt` | Docker multi-arch builds |
| Added | `fakeroot`, `git` | Moved into the base package list (git dropped from `other`) |
| Added | `ttf-jetbrains-mono-nerd-basic` | Lighter Nerd Font, saves ~200MB |
| Added | `lsp-plugins-lv2` | LV2 limiter used by per-laptop speaker tunings |
| Added | `qmk-hid` | Framework 16 keyboard support |
| Removed | `waybar` | Bar now in Quickshell |
| Removed | `omarchy-walker` | Launcher now in Quickshell |
| Removed | `mako` | Notifications now in Quickshell |
| Removed | `swayosd` | OSDs now in Quickshell |
| Removed | `hyprlock` | Lock screen now in Quickshell |
| Removed | `hypridle` | Idle handling now in Quickshell (`shell.json` `idle`) |
| Removed | `swaybg` | Background now in Quickshell |
| Removed | `polkit-gnome` | Polkit agent now in Quickshell |
| Removed | `iwd`, `impala` | Replaced by NetworkManager + shell network panel |
| Removed | `bluetui` | Replaced by shell Bluetooth panel |
| Removed | `wiremix` | Replaced by shell Audio panel |
| Removed | `alacritty` | Foot is the new default terminal |
| Removed | `typora` | Replaced by Omawrite |
| Removed | `gnome-calculator`, `libqalculate` | Replaced by Omacalc |
| Removed | `satty` | Replaced by Tensaku |
| Removed | `dust` | Replaced by `dua-cli` |
| Removed | `python-terminaltexteffects` | Replaced by `ttfx` |
| Removed | `ttf-jetbrains-mono-nerd` | Replaced by the `-basic` variant |
| Removed | `signal-desktop`, `spotify`, `1password-beta`, `1password-cli` | Moved to on-demand installs |
| Removed | `claude-code`, `github-cli` | Now lazy-loaded via mise instead of npm/pacman |
| Removed | `playerctl` | Media control handled by the shell's MPRIS widget |
| Removed | `kvantum-qt5`, `qt5-wayland` | Qt5 theming no longer needed |
| Removed | `rust` | No longer required in the base image |
| Removed | `xmlstarlet` | Unused after config rework |
| Removed | `jdk-openjdk` | Dropped from the `other` package list |
| Removed | `tiny-dfr` | Dropped from T2 MacBook support packages |
| Renamed | `neovim` → `nvim` | Package rename |
| Renamed | `dotnet-runtime-9.0` → `dotnet-runtime` | Unpinned from the 9.0 series |
