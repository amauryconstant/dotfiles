---
name: desk
description: Disposable desktop for testing Hyprland and Quickshell changes visually BEFORE `chezmoi apply` — a nested Hyprland running the rendered SOURCE tree, with screenshots Claude can read and a window the user can inspect. Use when a change to hypr/, quickshell/ or themes/ must be seen or interacted with, instead of asking the user to apply it to the live session.
allowed-tools: Read, Bash(.claude/skills/desk/scripts/desk:*)
---

# desk

A nested Hyprland (a window on the live desktop) whose `XDG_CONFIG_HOME` is a copy **rendered from the repo source**, so un-applied edits are what runs. The live session, `~/.config` and the live systemd units are never touched. Use it for anything visual or interactive; lint and `qml:smoke` cover the rest.

```bash
D=.claude/skills/desk/scripts/desk
$D up                      # render, start nested Hyprland + Quickshell, wait until the bar is drawn
$D shot [file]             # grim the nested output; prints the PNG path → Read it
$D run <cmd…>              # run a command INSIDE the sandbox (hyprctl, quickshell ipc, a toggle script, an app)
$D reload                  # re-render from source, reload Hyprland, restart the nested shell
$D logs [hypr|qs]          # tails of the two logs
$D status | down
```

## Loop

1. Edit source. `$D up` (or `$D reload` if already up).
2. Drive it: `$D run ~/.local/lib/scripts/desktop/quickshell-toggle launcher`, `$D run quickshell -c dotfiles ipc call …`, `$D run hyprctl dispatch '<hl.dsp…>'`.
3. `$D shot`, then **Read the PNG** and check what you changed. Give the shell ~1.5s after opening a surface.
4. For anything subjective (spacing, feel, animation) tell the user the sandbox window is up and ask them to look. They can click inside it.
5. **Always `$D down` when finished**, including after a failure. It removes the compositor, the shell, the instance dir and the scratch tree.

## What is real and what is not

- Real: the rendered `hypr/`, `themes/`, `quickshell/`, `dotfiles/` trees; the live theme (`themes/current`), D-Bus, MPRIS, network, tray data.
- **Autostart is replaced** with nothing: the real one runs `dbus-update-activation-environment --systemd`, which would repoint the live units at the nested display.
- The shell copy has its singletons off (notification bus name, polkit, lock, menu socket renamed): a second shell must not contend with the live one.
- `hyprsplit` is borrowed from the live checkout (an external, absent from the render). The nested monitor is not on the desktop's EDID list, so its workspace shows as 21, not 1. Cosmetic.
- `Theme.qml` reads `$HOME/.config/themes/current/colors.sh`, the LIVE theme. Theme-switching tests do not work here.

## Traps

- **`wtype` does not fire binds** in the nested compositor (verified: exit 0, nothing happens). Run what the bind runs (the toggle script, `hyprctl dispatch`) instead.
- A SUPER bind pressed by the user is caught by the LIVE Hyprland, not the sandbox.
- Hardware binds (volume, brightness, media) act on the real devices. Launched apps share `$HOME`, so Firefox hits its profile lock: test with `ghostty`.
- "Configuration Loaded" is not "drawn": `up`/`reload` already wait for the first layer surface. A `shot` taken straight after `run` of a toggle may still be empty.
- `$D run` replaces the shell with the command (`exec`); background long-running apps with `run_in_background`.
- Never `chezmoi apply` to "see what happens". That is what this replaces.
