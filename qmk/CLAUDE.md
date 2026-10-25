# qmk/ — ErgoDox EZ firmware

QMK External Userspace for the ErgoDox EZ (`ergodox_ez/base`, keymap `workman_gaming`). Repo-only:
`.chezmoiignore` keeps it out of `~`. Origin: Oryx layout `zWQqd/orvjYG`, ported once to mainline
QMK; **Oryx is frozen, this directory is the source of truth** (never re-import from Oryx).

## Workflow

```bash
mise run qmk:setup   # clone mainline QMK at the pinned SHA → ~/.local/share/qmk/qmk_firmware
mise run qmk:build   # compile; hex lands in the QMK clone / qmk/, size is printed
mise run qmk:flash   # compile + flash; press the board's reset button when prompted
```

Needs the `keyboard_firmware` package module (`qmk`, `teensy_loader_cli`); `qmk` ships the udev
rules, no sudo step. The tasks export `QMK_HOME`/`QMK_USERSPACE`, so no `~/.config/qmk/qmk.ini`.
Pin and paths: `.mise/lib/qmk-env.sh`.

## Pin

Mainline `qmk/qmk_firmware` at tag `0.34.7` by SHA (`QMK_FIRMWARE_REF`). The board sees every
keystroke: bump deliberately (release notes, edit the SHA, `qmk:setup`, `qmk:build`, flash, check
all four layers). No ZSA fork: its only additions are the `zsa/oryx` (live layer view in Keymapp)
and `zsa/defaults` modules, neither needed to build or flash. To get the live view back, add
`zsa/qmk_modules` as a submodule at `qmk/modules/zsa` and list the modules in a `keymap.json`.

## Layout notes

- Layers: 0 Base (Workman), 1 Symbols (`TG(1)`), 2 Media (`LT(2, KC_BSLS)`), 3 Gaming. Top-right key
  (`DUAL_FUNC_0`): tap `-`, hold = `layer_move(3)` (a permanent switch; `TO(0)` on layer 3 leaves).
- LEDs: 1 = Symbols, 2 = Media, 3 = Gaming (`layer_state_set_user`).
- Base ErgoDox has no RGB: the Oryx RGB/HSV keys were dropped in the port.
- Tap-hold keys use QMK defaults (200 ms tapping term and quick tap term). A held tap-hold key
  cannot also hold its tap keycode: a game's held key must be a plain keycode.
