# Omarchy v4.5.0 — Release Research

**Date researched**: 2026-11-05
**Previous version**: v4.0.6
**Commits**: 1402
**Source**: Commit log fallback

---

## Summary

v4.5.0 is a large cumulative release from the `quattro` development branch (the 4.x line: Quickshell-based `omarchy-shell` plus Lua Hyprland config). The 4.0.2-onward hardening work lands (passwordless sudo expiry, USB/Thunderbolt approval attempts, signed OPR packages, command-scoped sudo during updates, Plymouth/Windows VM/browser-policy hardening), the shell is expanded (own notification engine, agents panel, Elsewhen world clock, tray drawer, dock, panel animations, shell-handled media/volume/brightness keys), and Hyprland gains per-monitor workspaces, floating-with-titlebars workspace mode, and multiple resilience fixes. Also: i18n in 50 languages, OWE video backgrounds, Omasnap screenshots, Superwhisper/Voxtype dictation, ARM/Snapdragon/N1x hardware support, and a test-suite overhaul. Diff vs v4.0.6: 4426 files, +481840/-25505. `default/hypr` changed in 48 files (+2311/-173).

## Breaking Changes

- **Notification engine replaced in place**: swaync-style/Omapager plugin engine replaced by a built-in shell engine (stacks, snooze, history kept in shell, keyboard control); notification panel, snooze and screen-sharing offer later removed (#16430, #16429); inline reply and KDE Connect helper removed; Omapager plugin retired. No migration (replaced in place). Action: anything depending on the old notification panel/IPC/options is affected.
- **Notifications sent via D-Bus Notify method, never `notify-send`**; `--exec` removed, only `--exec-arg` (argv, not shell strings) for click commands. Action: custom scripts passing `--exec` must change.
- **Ordinary sudo replaces custom sudo handling**: "one password for ten minutes, plain update scripts" (#17000); update authorizes once (`omarchy update`, AUR and boot check included); passwordless-sudo expiry fails closed and duration is user-selectable; update hooks run without reusable sudo authority; sudo lockout reset command removed. Action: update hooks/scripts must not assume reusable sudo.
- **Signed packages required from the Omarchy repository; OPR prioritized in pacman.conf**. Action: unsigned/unknown-key repo packages fail.
- **power-profiles-daemon replaced by `omarchy-power-profiles-daemon`** (stock has no cppc_cpufreq; ARM). Power profile now tracked via Quickshell/D-Bus rather than polling `powerprofilesctl`/busctl.
- **Docker group opt-in**: user is no longer added to `docker` group; toggle offered with reboot prompt (#8056, #8080, #8098).
- **Keybinding changes**: Super+Ctrl+T themes, Super+Ctrl+W backgrounds, Network moved to Super+Ctrl+N (#16072); Calculator/Activity moved to apps tier (#16071); Super+Shift+S screenshot (#8827), keyboard screenshot on Super+Ctrl+Alt+C, Google Maps regains Super+Shift+S (#16048); Super+Q second close chord (#7767); Alt+Shift+Tab cycles backwards (#8576); dictation toggle Alt+Space, push-to-talk Right Alt (#17188); Caps Lock returned to normal, Shift+Caps Lock = compose key (#14939); lone Shift toggles input method (#14975); Super+Ctrl+Alt+F full-screen desktop; Super+Ctrl+Alt+E Elsewhen; Super+comma notification handling (dismiss/invoke/focus); Ctrl+brightness keys control keyboard backlight (#16650); universal select all and terminal clipboard shortcuts (#14307).
- **Menu reorganization**: "Appearance" top-level menu holds Style options, menu bar, window corners/opacity, indicators/clock format (#15973, #14973, #14982, #14990, #14991); Reboot to Boot Menu item removed (#15795); Update > Extra Themes only shown when present.
- **Per-monitor workspaces** (#15655): each monitor gets its own workspace set (`monitor-workspaces.lua`); layouts reset to a new default; dwindle relabeled "tiling".
- **Application transparency is opt-in** (#14253); Windows VM and Resolve kept opaque.
- **Boot**: 1-second quiet boot with a way back to the menu (#15301); console/keymap migrations (non-Latin vconsole kept out of initramfs).
- **Theme/background changes**: backgrounds stored as webp; Osaka Jade replaced by Jade Horse (#16594); Tokyo Night backgrounds renumbered (a migration preserves picks); max 1 intro video per theme; extra themes deletable from the picker.
- **USB/Thunderbolt device approval** was added (new USB devices require approval by default) then **fully reverted** (#15091) before release; net: not shipped.
- **Azerbaijani keyboard choice dropped** (installed AZERTY).
- **Quattro-to-4.5 migrations**: "Require Quattro migrations to complete"; stricter migration ordering; migration tests removed from the suite (#16302). Snapshot restores leave migrations marked as run (documented, #15159).

## Features

- **Omarchy shell (Quickshell) expansion**: shell menus/panels opened through Hyprland global shortcuts (#13418); volume/media/notification keys and internal backlight stepping handled in the shell (#13424, #13427); shell answers `omarchy-shell` calls over its own socket (#13435); panels grow out of the bar, morph between each other, grow with late content (#16470, #16483); motion rules via `Style.duration` with test enforcement; bar tooltips, hover give on buttons/icons; bar widgets live in the tray drawer (#15281); drag a widget off the bar to remove it (with poof animation); workspaces widget scroll-wheel; media widget marquee; bar widget orientation/sections rework (#15517); clock formats (live seconds, Appearance > Clock); glassy bar background; transparent bar sampled from wallpaper; remote-session indicator (shown only in a remote session). Omarchy path: `default/hypr/omarchy-shell.lua`, `default/hypr/apps/omarchy-shell.lua`.
- **Agents panel**: multiple Claude/Codex subscriptions, Kimi, Grok, Hermes, Ori, Cursor CLI, Muse Code, Amp Desktop, OpenClaw (self-updating, under `~/.openclaw`), T3 Code (AppImage), Antigravity replaces Gemini; usage/limit rows, agent account switching, copy logins over SSH; claude/codex launched with auto-review instead of full bypass.
- **Elsewhen** (world clock/globe) moved into Omarchy as `omarchy.elsewhen`, installed by default, keyboard-driven (Super+Ctrl+Alt+E), weather and places.
- **Dictation**: selectable Voxtype and Superwhisper (cloud, shipped by default). Omarchy path: `default/hypr/dictation-backend.lua`.
- **OWE** owns desktop video backgrounds and feeds lock screen frames; native video wallpaper; theme intro videos at boot/theme switch; per-theme wallpaper memory.
- **Omasnap** screenshots (Open/Edit toasts, scroll capture); Omacut/Open buttons on recording toast.
- **Floating mode with titlebars** in workspace layout cycle, dock on floating workspaces; Quake console (own file `qconsole.lua`, centered 2:1) separate from scratchpad. Package `omarchy-hyprland-titlebars`. Omarchy path: `default/hypr/workspace-modes.lua`, `default/hypr/qconsole.lua`, `default/hypr/workspace-layouts.lua`, `default/hypr/pop.lua`.
- **`o.rebind`** helper to replace Hyprland keybindings from Lua config. Omarchy path: `default/hypr/helpers.lua`.
- **Translations**: Omarchy in 50 languages; CJK input setups (fcitx5 mozc/chewing/hangul/chinese-addons).
- **Apps added to menus**: Notion, Slack, Microsoft (Word/Excel/PowerPoint/Outlook/Teams web apps), Amp Desktop, Claude desktop, Perplexity, OpenClaw, Cloudflare CLI, basecamp-cli, hey-cli (lazy mise tools), SSH Agent (gcr-ssh-agent), Signed (PDF signing), Disktree, Hype (Markdown presentations), Monologue, gliff, vi. Remove > AI added.
- **Network**: captive-portal detection/sign-in in network panel (ping.omacom.io), DNS provider switch without password, network speed via Omarchy's own service, `geo.omarchy.org` / `ntp.omarchy.org` endpoints, China mirrors.
- **Install media** can preset language, keyboard, timezone; first-run git identity with GitHub sign-in; traced-icon first-boot progress screen.
- **Hardware**: NVIDIA N1x laptops, Snapdragon (cameras, video decode, keyboards at disk unlock), Apple Silicon (stable/rc channels, power-profiles), 2017 iMac 5K, Dell XPS 13 Panther Lake and sidecar amps, ASUS ProArt P14, HP EliteBook Ultra G1q, Elgato Cam Link 4K virtual camera, Wildcat Lake video decoding, GB10 idle states.
- **Kernel**: `linux-omarchy` default (except T2 Macs); Omarchy PTL kernel; Update > Kernel default switch; TCP BBR + fq; kyber I/O scheduler on real disks.
- **Misc**: no-animations mode (default in VMs); `omarchy-crash-mute`; Omarchy logo font ASCII art; About logo glint; Herdr theme sync/autostart; Disktree; mpv hardware decode config; Chromium overlay scrollbars; `omarchy up` alias.

## Bug Fixes

- **Hyprland reload resilience**: reload from outside the session (#17420); stale-Hyprland reload guard; startup cursor recovery across reloads; Quake console seeded from `workspace.created`; HDR kept SDR in fullscreen (#17157); Hyprland support popup disabled (#17153); monitor re-enable keeps layout; per-monitor workspaces stay right after unplug; FALLBACK output ignored; `o.shell_succeeds()` returning false inside Hyprland fixed; keyboard-layout widget no longer switches wrong device; GDK_SCALE from lowest monitor scale; per-monitor scaling persisted; popped-out window recentered across monitors.
- **Shell stability**: bar startup stall/restart race (#11015); stale shell restarted before migrations; hidden bar no longer catches clicks over fullscreen; bar icons level/centered; PwNode objects out of audio Repeater; plugin hot-reload keepLoaded; Qt 6.12 palette/QtQuick 6.11 import workarounds (#14845, #14553).
- **Clipboard**: capture hangs prevented (#9488); UTF-16 decoding; larger history; empty/no-match messages; preview divider. Emoji picker no-match message.
- **Lock/idle/power**: idle timeout 0 = disabled; lock ignores key auto-repeat; NVIDIA suspend VT-switch lock usable; keyboard backlight level; Hibernate hidden if unsupported; resume device by UUID; gvfs FUSE restored after resume; lid close no longer interrupts shutdown.
- **Security fixes**: asdcontrol, sshd (disabled unless a key is authorized; hardening migration), theme names/URLs/web-app names validated, plugin capability restrictions, third-party plugin boundaries, mise-install argument guards, Plymouth publication race, Windows VM mount boundary and RDP password out of argv, browser policy dirs, predictable /tmp paths (FIDO2, screen-recording state), polkit/system-auth for fingerprint/FIDO2.
- **Updates**: pacman shielded from session teardown; updates finish when mise downloads fail; keyring refreshed before updates; orphan removal auto-approved; mise GOROOT kept out of AUR builds; one pending-migrations reminder.
- **Misc**: Dropbox, Bitwarden popout, Inkscape/1Password/Battle.net/Resolve window rules, DDC brightness, night light reset, fingerprint enrollment, locale-safe parsing (C locale for pactl/top/EPOCHREALTIME), DST tick flood, SDDM greeter keyboard layout, Wi-Fi OWE handling, Neovim remote yanks.

## Improvements

- Performance pass: lazy panel content, polling replaced by events (audio sink, power profile, sudo indicator, input seat, Fcitx), cached workspace layouts, faster menu guards, theme-switch speedups (single-awk template render, retint terminals first), faster bash prompt, image picker bounded for large collections and HiDPI.
- Node installed lazily via mise; default CLI tools via mise lazy shims; mise shims given to agents.
- Test suite: parallel shell tests, many tests sped up, removed pixel/source-text/migration tests, readiness signals instead of sleeps; docs reorganized by genre (hotkeys layout, manual fixes, plugin manual to plugins.omarchy.org, motion rules).
- Notification UX: stacking, keyboard control, Open/Edit/Cut action buttons, 30s low-battery toast, no site icon fetching.
- Theme: new Starship default theme, Flexoki Light intro, Liftoff Tokyo Night wallpaper, ethereal roadster starlight, VS Code theme hover/current-line visibility, catppuccin flavour colorscheme.

## Configuration Changes

- **Hyprland Lua config split into many modules**: `default/hypr/` now holds `apps/*.lua` (1password, battlenet, bitwarden, browser, captive-portal, davinci-resolve, geforce, hermes, inkscape, jetbrains, localsend, moonlight, omarchy-shell, ...), `bindings/`, `toggles/`, `glass.lua`, `monitor-workspaces.lua`, `workspace-modes.lua`, `workspace-layouts.lua`, `qconsole.lua`, `pop.lua`, `startup-cursor.lua`, `disabled-input-device.lua`, `dictation-backend.lua`, `keyboard.lua`, `nvidia.lua`, `paths.lua`, `require_all.lua`, `require_optional.lua`. User config: `config/hypr/{autostart,bindings,hyprland,input,looknfeel,monitors}.lua`. Omarchy path: `default/hypr/`.
- **Bash startup**: privileged Bash startup exception documented; Apple Silicon shell setup loads Omarchy's shell; `~/.bashrc.bak` preserved.
- **Terminal config**: Kitty defaults moved to system config (opt-out documented); foot touchpad scroll factor and TUI touchpad scroll; terminal font size preserved on family change; Ghostty/foot `[text-bindings]` repair.
- **Browser**: Chromium first-run EULA skipped; overlay scrollbars; native messaging hosts for Brave Origin; default browser read from mimeapps.list; links from all apps routed through running default browser.
- **System**: pacman repo order/signing (OPR first); `xdg-desktop-portal` uses gnome-keyring; mpv `hwdec` system config; sysctl/udev (BBR, kyber); EasyEffects 8 sink resolution; WirePlumber camera discovery; limine quiet menu; fcitx5 unit inert when not installed; `shell.json` never overwritten if unreadable; mise upgrade pruning setting shipped, user mise config located where mise keeps it.
- **Clipboard** store enlarged; tmux theme sync via single `source-file`; Neovim/herdr/Hunk follow terminal background/theme.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `omarchy-hyprland-titlebars` | floating workspace titlebars |
| Added | `omarchy-power-profiles-daemon` | working power profiles on ARM |
| Removed | `power-profiles-daemon` | replaced by above |
| Added | `owe` | desktop video backgrounds, lock feed |
| Added | `omasnap` | screenshots |
| Added | `signed` | PDF signing |
| Removed | `xournalpp` | replaced by Signed |
| Added | `superwhisper-bin` | cloud dictation |
| Added | `disktree-bin` | disk usage TUI |
| Removed | `dua-cli` | replaced by Disktree |
| Added | `gliff` | default tool |
| Added | `hype` | Markdown presentations |
| Added | `monologue` | default app |
| Added | `vi` | original vi as standard editor |
| Added | `ffmpeg` | media/thumbnail handling |
| Added | `base-devel` | build tooling |
| Added | `qt6-base`, `qt6-declarative`, `qt6-multimedia`, `qt6-svg`, `qt6-wayland` | Qt6 for shell/QML |
| Added | `xorg-xsetroot` | X11 root cursor restore (XWayland) |
| Added | `fcitx5-chewing`, `fcitx5-chinese-addons`, `fcitx5-hangul`, `fcitx5-mozc`, `fcitx5-table-extra` | CJK input methods |
| Removed | `obs-studio`, `kdenlive` | no longer shipped to new installs |
| Removed | `lazydocker` | dropped from new installs |
| Removed | `clang`, `llvm` | now installed with the Rust dev environment |
| Removed | `tensaku` | dropped |
| Removed | `yt6801-dkms` | replaced by in-kernel/other driver |
| Added | `pipewire-libcamera` | camera support |
| Added | `dell-xps13-sidecar-amps` | XPS 13 speakers |
| Added | `asus-proart-p14-speaker-firmware` | ASUS ProArt P14 |
| Added | `v4l2loopback-dkms`, `v4l2loopback-utils`, `v4l2-relayd` | Elgato Cam Link 4K virtual camera |
| Added | `broadcom-wl-dkms` | Arch dropped prebuilt module (migration/hardware) |
| Added | `libfprint-git` | every fingerprint reader (migration) |
| Added | `apple-bcm-firmware-fetcher` | T2 firmware (replaces superseded package) |
