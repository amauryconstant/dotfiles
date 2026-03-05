# Omarchy v3.4.0 — Release Research

**Date researched**: 2026-03-05
**Previous version**: v3.3.3
**Commits**: 467
**Source**: GitHub release notes

---

## Summary

v3.4.0 is a major feature release with 467 commits, adding Tmux as a first-class terminal multiplexer with AI agent-focused layouts, Claude Code as a default install, and broad hardware compatibility improvements for Asus, Slimbook, Tuxedo, Surface, and NVIDIA RTX Pro machines. The release includes three new themes, a new default wallpaper for Tokyo Night, extensive Hyprland keybinding additions, and a large volume of bug fixes spanning GPU drivers, screenrecording, Windows VM, AUR package management, and system sleep reliability.

---

## Features

- **Single screenshot flow**: PrintScr now triggers a single screenshot with an editing option pushed via notification. Omarchy path: screenshot/capture keybindings.
- **Tmux integration**: Tmux added with a tailored config for aesthetics and ergonomics; accessible via `t` alias in any terminal.
- **AI agent Tmux layouts**: `tdl` (Tmux Dev Layout), `tdlm` (Tmux Dev Layout Multiplier), and `tsl` (Tmux Swarm Layout) commands for agent-focused multi-pane workflows.
- **Claude Code default install**: Claude Code installed by default; `cx` alias starts it in accept-all mode.
- **Hibernation by default**: New installs now enable hibernation by default.
- **Waybar idle-lock and notification-silencing icons**: Two new status indicators added to Waybar.
- **Asus Zephyrus G14/G16 compatibility**: Full volume, brightness, and hybrid GPU switching support added.
- **Motorcomm YT6801 ethernet driver**: Compatible driver added for Slimbook and Tuxedo laptops.
- **NVIDIA GeForce Now installer**: Installer and window rules available via Install > Gaming menu.
- **Automatic power profile switching**: Profile switches automatically when AC power is plugged or unplugged.
- **SSH port forwarding functions**: `fip`, `dip`, and `lip` commands added for web development port forwarding.
- **`eff` command**: Opens fuzzy-find results directly in the configured editor.
- **Remove Preinstalls option**: New Remove > Preinstalls menu entry to remove all preinstalled packages.
- **Audio soft mixer opt-in**: Toggle available via Setup > Audio (required for Asus Zephyrus).
- **Menu extension hook**: `~/.config/omarchy/extensions/menu.sh` allows overloading any menu action.
- **nautilus-python**: Adds "Open in Ghostty" context menu entry in Nautilus.
- **Bitwarden Chrome Extension window rules**: Window rules added for Bitwarden extension popup.
- **Emoji picker auto-pasting**: Emoji picker now pastes selection automatically.
- **Chromium restored**: Mainline Chromium re-added now that upstream live theming is fixed.
- **Screenrecord "With no audio" option**: Silent recording option added to screenrecord menu.
- **Tab-cycle completion for bash**: File/directory expansion uses tab-cycle completion.
- **User theme override**: User themes with the same name as built-in themes can overwrite individual files selectively.
- **Favicon extraction for web apps**: Favicon extraction added when creating new web apps.
- **NordVPN installer**: Available via Install > Services menu.
- **Vulkan drivers**: Installed by default on new installs.
- **Scala**: Added to Install > Development menu.
- **Tmux in config refresh menu**: Tmux configuration added to the refresh menu.
- **Drive partition info**: `omarchy-drive-select` now displays partition information.
- **Google DNS option**: Google added as a DNS provider choice.
- **Logout option and styled SDDM login**: Logout added to System Menu; SDDM login screen now themed.
- **Suspend restored to System Menu**: Suspend re-added as default (with opt-out via Setup > System Sleep for incompatible hardware).

## Bug Fixes

- **Alacritty as default terminal on new installs**: New installs default to Alacritty instead of Ghostty for GPU compatibility on older hardware.
- **AUR package preference**: AUR packages preferred over repos when available.
- **Ghostty high IO pressure**: Fixed excessive IO on some machines.
- **NVIDIA environment variables**: Fixed for Maxwell, Pascal, and Volta GPU generations.
- **JetBrains window rules**: Fixed window rules not applying correctly.
- **Telegram focus stealing**: Fixed Telegram stealing focus on every incoming message.
- **Steam window opacity rules**: Fixed.
- **Video PWA window rules**: Fixed.
- **Walker crash on exit**: Fixed Walker not restarting after crash.
- **Hibernation reliability**: Fixed to work reliably across different laptop hardware.
- **hyprlock fingerprint auth**: Fixed auth check logic.
- **Update snapshot cleanup**: Failed updates now properly clean stale snapshots.
- **Windows VM clipboard sharing**: Fixed clipboard sharing via RDP.
- **Windows VM dynamic boot detection**: Fixed.
- **Windows VM timezone, removal confirmation, port binding**: Timezone set correctly; confirmation prompt before VM removal; ports/restart-unless-stopped scoped to localhost only.
- **gum confirm color**: Fixed incorrect color for "no" option.
- **omarchy-update-firmware**: Fixed premature exit.
- **swayosd style path**: Fixed incorrect path reference.
- **yq dependency**: Replaced yq with pure bash TOML parsing, removing the dependency.
- **AUR updates after interrupted git sessions**: Fixed broken AUR updates caused by interrupted git state.
- **Synaptics InterTouch touchpad detection**: Fixed.
- **Starship prompt sanitization**: Fixed.
- **Chromium Wayland color manager flag**: Fixed removal of deprecated flag.
- **Development remove menu icons**: Fixed missing icons.
- **kb_variant support in input.conf**: Fixed keyboard variant configuration.
- **wiremix default device character display**: Fixed character rendering.
- **opencode auto-update**: Disabled for pacman-managed installs.
- **Waybar Omarchy glyph spacing**: Fixed using thin space.
- **suspend-to-hibernate removed as default**: Removed due to failures on several laptop models.
- **x11 fallback in SDL_VIDEODRIVER**: Fixed for compatibility.
- **AUR update ordering**: AUR packages now update only after system packages and migrations complete.
- **archlinux-keyring update ordering**: Updated before other packages.
- **Docker socket activation**: Docker now starts on-demand via socket activation, saving memory.
- **HDR screenshot rendering**: Switched from wayfreeze to hyprpicker for correct HDR screenshot capture.
- **format-drive macOS compatibility**: Fixed.
- **Kernel module availability after upgrade**: Fixed modules becoming unavailable post-upgrade.
- **Obsidian theme low contrast**: Fixed muted/faint text contrast.
- **Alacritty emoji rendering**: Fixed.
- **Keyboard backlighting during idle**: Fixed backlighting staying on when system is idle.
- **Vertical/horizontal split naming**: Renamed to match human spatial expectations.
- **Alacritty OSC 52 clipboard**: Full OSC 52 clipboard support restored.
- **Kernel change detection**: Fixed to work with any installed kernel, not only specific ones.
- **Drive info vendor string**: Includes vendor when not already part of model string.
- **Snapshot delete on update**: Removed broken snapshot delete function; correct call added.
- **WiFi power saving on AC**: Power saving disabled when connected to AC power.
- **AUR install sudo session timeout**: Fixed sudo timeout during long AUR installs.
- **NVIDIA RTX Pro driver install**: nvidia-open now installed for RTX Pro card owners.
- **Bluetooth friendly name**: Fixed device showing bluez ID instead of human-readable name.
- **omarchy-cmd-screenshot geometry**: Fixed for transformed/rotated monitors.
- **fcitx5 tray icon**: Hidden from Waybar.
- **Mouse cursor workspace sync**: Cursor now syncs with last focused window when switching workspaces.
- **nvim gutter color**: Fixed incorrect gutter color on some themes (e.g. Kanagawa).
- **User manager shutdown hang**: Reduced maximum hang time from 2 minutes to 5 seconds on restart/shutdown.
- **Errant login.keyring via SDDM**: Fixed spurious keyring creation requiring manual unlock.
- **Screenrecording Mac compatibility**: Switched to h264 codec.
- **Screenrecording first-frame garbage**: First 100ms trimmed to remove corrupt frames.
- **Manual install channel pinning**: Fixed packages on manual installs not matching channel version.
- **mise precompiled binaries**: mise now uses precompiled binaries.
- **Surface laptop driver kit**: Surface driver kit installed by default.

## Breaking Changes

- **Hyprland windowrule/layerrule syntax**: Upgrading from versions earlier than v3.3.0 will surface Hyprland config errors until the update completes and the system is restarted. Custom `windowrules` or `layerrules` must be manually converted to the new syntax using https://itsohen.github.io/hyprrulefix/.

*None beyond the noted Hyprland syntax migration for pre-3.3.0 upgrades.*

## Improvements

- **Aesthetics — visual background picker**: New UI for selecting wallpapers.
- **Aesthetics — Asus ROG keyboard backlighting**: Backlighting syncs with active theme.
- **Aesthetics — Framework 16 keyboard backlighting**: Backlighting syncs with active theme.
- **Aesthetics — Tokyo Night default wallpaper**: New default wallpaper added for the Tokyo Night theme.
- **Aesthetics — Miasma theme**: New theme added.
- **Aesthetics — Vantablack theme**: New theme added.
- **Aesthetics — White theme**: New theme added.
- **Aesthetics — Waybar headset icon**: Headset icon added for audio device in Waybar.
- **Keybinding — Voxtype toggle**: `Super + Ctrl + X` changed from push-to-talk to toggle due to Hyprland button-release limitations.
- **Keybinding — Tmux terminal**: `Super + Alt + Return` launches terminal in Tmux mode.
- **Keybinding — browser alternative**: `Super + Shift + Return` added as alternative browser launch keybind.
- **Keybinding — capture alternative**: `Super + Ctrl + C` added as alternative capture keybind for keyboards without PrintScr.
- **Keybinding — Nautilus in terminal CWD**: `Super + Alt + Shift + F` opens Nautilus in current terminal directory.
- **Keybinding — monitor scaling cycle**: `Super + Ctrl + Backspace` cycles through 1x, 1.6x, 2x, 3x scaling.
- **Keybinding — square aspect ratio toggle**: `Super + Ctrl + Alt + Backspace` toggles single-window square aspect ratio.
- **Keybinding — zoom**: `Super + Ctrl + Z` zooms in (repeatable); `Super + Ctrl + Alt + Z` zooms out.
- **Keybinding — Nautilus in terminal CWD (open)**: Opening Nautilus from terminal's current working directory.
- **Keybinding — scratchpad auto-toggle**: Scratchpad auto-toggles on workspace switch.
- **Keybinding — single-key backlight cycling**: Single-key backlight cycling for laptops without separate up/down backlight keys.

## Configuration Changes

- **`~/.config/omarchy/extensions/menu.sh`**: New extension hook file path for overloading any Omarchy menu action. Users place this file to inject custom entries.
- **`input.conf`**: `kb_variant` now supported for keyboard variant configuration.
- **Tmux config**: New tailored Tmux configuration file added to Omarchy; included in config refresh menu.
- **SDDM login**: SDDM login screen now styled/themed by Omarchy.
- **System sleep defaults**: Suspend re-added to System Menu by default; suspend-to-hibernate removed as default; opt-out available via Setup > System Sleep.
- **Docker**: Reconfigured to use socket activation for on-demand startup.
- **WiFi power management**: Power saving policy updated to disable when on AC power.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `tmux` | Terminal multiplexer with tailored config |
| Added | `claude-code` | AI coding agent, default install |
| Added | `nautilus-python` | Enables "Open in Ghostty" Nautilus context menu |
| Added | `nordvpn` (installer) | VPN service, via Install > Services |
| Added | `vulkan-*` drivers | Vulkan GPU support, installed by default |
| Added | Motorcomm YT6801 driver | Ethernet for Slimbook/Tuxedo laptops |
| Added | Surface driver kit | Hardware support for Microsoft Surface laptops |
| Added | Scala toolchain | Via Install > Development |
| Added | `hyprpicker` | Replaces wayfreeze for HDR screenshot capture |
| Removed | `yq` | Replaced by pure bash TOML parsing |
| Changed | Default terminal | New installs default to Alacritty instead of Ghostty |
| Changed | `mise` | Now uses precompiled binaries |

---

<details><summary>Original release notes</summary>

```
## What's Changed

Update existing installations using `Update > Omarchy` from Omarchy menu (`Super + Alt + Space`).

Install on new machines with the ISO:
- Download: https://iso.omarchy.org/omarchy-3.4.0.iso
- SHA256: a68349ddf41b2553b4dfbae6bd6f08a993a12dc5ccec1d9316a4c0ac2bb33649

*IMPORTANT:* If upgrading from a version earlier than 3.3.0, you'll see a bunch of Hyprland config errors. They'll go away after the update has fully completed and you've restarted your system. But if you've added any windowrules or layerrules of your own, you'll need to convert them to the new syntax too. You can use https://itsohen.github.io/hyprrulefix/.

## Features

- Add single screenshot flow on PrintScr with editing option pushed to notification by @ryanrhughes
- Add Tmux with tailored config for improved aesthetics and ergonomics accessible via `t` alias in any terminal by @dhh
- Add AI agent-focused Tmux layouts via `tdl` (Tmux Dev Layout), `tdlm` (Tmux Dev Layout Multiplier), and `tsl` (Tmux Swarm Layout) by @dhh
- Add Claude Code as default install with `cx` alias to start it in accept-all mode by @dhh
- Add hibernation by default on new installs by @dhh
- Add idle-lock and notification-silencing icons to Waybar by @dhh
- Add full compatibility (volume/brightness/hybrid GPU switching) with Asus Zephyrous G14/16 laptops by @dhh
- Add compatible ethernet driver (Motorcomm YT6801) for Slimbook + Tuxedo laptops by @dhh
- Add NVIDIA GeForce Now installer and window rules via *Install > Gaming* by @dhh
- Add automatic power profile switching when plugged/unplugged by @pomartel
- Add SSH port forwarding functions `fip`/`dip`/`lip` for web development by @dhh
- Add `eff` command to open fuzzy find results directly in your editor by @dhh
- Add option to remove all preinstalls via *Remove > Preinstalls* by @dhh
- Add audio soft mixer as opt-in toggle via *Setup > Audio* (needed for Asus Zephyrus) by @dhh
- Add `~/.config/omarchy/extensions/menu.sh` for overloading any menu action by @bhaveshsooka
- Add nautilus-python for "Open in Ghostty" context menu by @pomartel
- Add window rules for Bitwarden Chrome Extension by @sgruendel
- Add emoji picker auto-pasting by @pomartel
- Add back mainline Chromium now that upstream has live themeing fixed by @dhh
- Add "With no audio" option to screenrecord menu by @robzolkos
- Add tab-cycle completion for bash file/dir expansion by @coolbotic
- Add option to have user themes of same name as built-in themes that just overwrite individual files by @tmn73
- Add favicon extraction for new web apps by @pomartel + @dhh
- Add NordVPN installer via _Install > Services_ by @jamerrq
- Add Vulkan drivers installed by default by @ElBrodino
- Add Scala to _Install > Development_ by @saftacatalinmihai
- Add Tmux to the config refresh menu by @guidovicino
- Add drive partition info display to omarchy-drive-select by @johnbarney
- Add Google as a DNS provider option by @dhh
- Add Logout option to System Menu together with styled SDDM login by @dhh
- Add Suspend back to System Menu as default on (but with opt-out when it doesn't work under _Setup > System Sleep_) by @dhh

## Aesthetics

- Add visual background picker by @dhms013
- Add theme-synced keyboard backlighting on Asus ROG laptops by @dhh
- Add theme-synced keyboard backlighting on Framework 16 laptops by @godlewski
- Add new default wallpaper for Tokyo Night theme by @Maxteabag
- Add Miasma theme by @OldJobobo
- Add Vantablack theme by @bjarneo
- Add White theme by @bjarneo
- Add headset icon for audio in Waybar by @pomartel

## Keybindings

- Change `Super + Ctrl + X` for Voxtype to a toggle instead of push-to-talk due to Hyprland complications with button release by @dhh
- Add `Super + Alt + Return` to start terminal in Tmux mode by @dhh
- Add `Super + Shift + Return` as alternative keybind for launching browser by @dhh
- Add `Super + Ctrl + C` as alternative capture keybind for machines without PrintScr button by @dhh
- Add `Super + Alt + Shift + F` to open nautilus in current directory of terminal by X
- Add `Super + Ctrl + Backspace` to cycle through monitor scaling of 1x, 1.6x, 2x, 3x by @dhh
- Add `Super + Ctrl + Alt + Backspace` to toggle single-window square aspect ratio by @dhh
- Add `Super + Ctrl + Z` to zoom in (repeat = more zoom) and `Super + Ctrl + Alt + Z` to zoom out by @pelephant2
- Add opening Nautilus in terminal's current working directory by @schwepmo
- Add scratchpad auto-toggle on workspace switch by @mitanjan
- Add single-key keyboard backlight cycling for laptops without separate up/down keys by @hattapauzi

## Fixes

- Fix new installations should default to Alacritty instead of Ghostty to ensure even old systems without compatible GPUs can run Omarchy out of the box by @dhh
- Fix AUR package installation to prefer AUR over repos when available by @dhh
- Fix Ghostty high IO pressure on some machines by @NicolasDorier
- Fix NVIDIA environment variables for Maxwell/Pascal/Volta GPUs by @johnzfitch
- Fix JetBrains window rules not working properly by @NicolasDorier
- Fix Telegram stealing focus on every message by @ryanrhughes
- Fix Steam window opacity rules by @nptr
- Fix video PWA window rules by @dhh
- Fix Walker crashing and not restarting by @dhh
- Fix hibernation to work reliably across different laptops by @dhh
- Fix hyprlock fingerprint auth check by @dhh
- Fix update snapshots not being cleaned on failed updates by @Mridul-Agarwal
- Fix Windows VM clipboard sharing in RDP by @arcangelo7
- Fix Windows VM dynamic boot detection by @felixzsh
- Fix Windows VM timezone and add confirmation before VM removal by @pomartel
- Fix Windows VM should only bind ports and restart-unless-stopped to localhost by @loud-func
- Fix gum confirm color for "no" option by @dhh
- Fix omarchy-update-firmware premature exit by @nnutter
- Fix swayosd style path by @gilescope
- Fix yq dependency by replacing with pure bash TOML parsing by @dommmel
- Fix AUR updates broken by interrupted git sessions by @dhh
- Fix Synaptics InterTouch touchpad detection by @Sameer292
- Fix Starship prompt sanitization by @jamesrobey
- Fix Chromium Wayland color manager flag removal by @shreyansh-malviya
- Fix Development remove menu icons by @annoyedmilk
- Fix kb_variant support in input.conf by @manuel-rams
- Fix wiremix default device character display by @l1ghty
- Fix opencode auto-update disabled for pacman management by @sgruendel
- Fix Waybar Omarchy glyph spacing with thin space by @horaceko
- Fix suspend-to-hibernate failing on several laptops by removing it as a default by @dhh
- Fix missing Wayland color manager disabling flag in Chromium by @shreyansh-malviya
- Fix x11 fallback in SDL_VIDEODRIVER for compatibility by @ryanrhughes
- Fix AUR packages shouldn't update until after system packages and migrations by @dhh
- Fix archlinux-keyring should be updated before updating packages by @defer
- Fix Docker on-demand startup via socket activation (saves memory, starts on first use) by @timohubois
- Fix HDR screenshot rendering by switching to hyprpicker from wayfreeze by @jtaw5649
- Fix format-drive compatibility with macOS by @prepin
- Fix kernel modules becoming unavailable after kernel upgrade by @defer
- Fix low contrast for muted/faint text in Obsidian theme by @guidovicino
- Fix emoji rendering in Alacritty by @glauberdmo
- Fix keyboard backlighting staying on during idle by @pukljak
- Fix vertical/horizontal split naming to match human expectations by @dhh
- Fix full OSC 52 clipboard support in Alacritty by @sgruendel
- Fix kernel change detection to work with any kernel by @dhh
- Fix drive info to include vendor when not part of model string by @KR9SIS
- Fix remove broken snapshot delete function and call on update by @ryanrhughes
- Fix wifi power saving should not be happening when connected to power by @dhh
- Fix AUR install sudo session timeout by @dhms013
- Fix nvidia drivers should be installed for (the lucky) owners of Nvidia RTX Pro cards by @zachfleeman
- Fix Bluetooth device showing bluez ID instead of friendly name by @shawnyeager
- Fix omarchy-cmd-screenshot geometry for transformed monitors by @riozee
- Fix fcitx5 tray icon should be hidden from waybar by @pomartel
- Fix mouse cursor should sync with the last focused window when switching workspaces by @foucist
- Fix nvim gutter would have the wrong color on some themes like Kanagawa by @dhh
- Fix user manager hanging on restart/shutdown for two minutes (now can only hang for 5 seconds) by @dhh
- Fix errant login.keyring being created if you logged in via SDDM which then wanted to be manually unlocked every time by @dhh
- Fix screenrecording compatibility with Mac by using h264 by @dhh
- Fix first-frame garbage on screenrecordings by trimming 100ms by @dhh
- Fix manual installs could end up with packages too new for their channel by @dhh
- Fix mise should use precompiled binaries by @dhh
- Fix Surface laptops should have driver kit installed by default by @dhh
```

</details>
