# qmk/ — ErgoDox EZ firmware

QMK External Userspace for the ErgoDox EZ (`ergodox_ez/base`, keymap `workman_gaming`). Repo-only:
`.chezmoiignore` keeps it out of `~`. Origin: Oryx layout `zWQqd/orvjYG`, ported once to mainline
QMK; **Oryx is frozen, this directory is the source of truth** (never re-import from Oryx).

## Workflow

```bash
mise run qmk:setup   # clone mainline QMK at the pinned SHA → ~/.local/share/qmk/qmk_firmware
mise run qmk:build   # compile; hex lands in the QMK clone / qmk/, size is printed
mise run qmk:update  # bump the pin: report what changed, rewrite it, rebuild (never flashes);
                     # `-- --check` reports only, `-- --to <tag>` picks a release
mise run qmk:flash   # compile + flash; press the board's reset button when prompted
```

Needs the `keyboard_firmware` package module (`qmk`, `teensy_loader_cli`); `qmk` ships the udev
rules, no sudo step. The tasks export `QMK_HOME`/`QMK_USERSPACE`, so no `~/.config/qmk/qmk.ini`.
Pin and paths: `.mise/lib/qmk-env.sh`.

## Pin

Mainline `qmk/qmk_firmware` by SHA (`QMK_FIRMWARE_REF`), named by `QMK_FIRMWARE_TAG`, both in
`.mise/lib/qmk-env.sh`. A tag can be moved upstream, so `qmk:setup` refuses a tag that no longer
resolves to the SHA. The board sees every keystroke: bump deliberately with `mise run qmk:update`
(prints the ChangeLog notes and the commits touching this board, rewrites the pin, runs setup +
build, never flashes or commits). Then flash and check all four layers and the bar's layer widget.
No ZSA fork or `zsa/qmk_modules`: the `oryx` module serves Keymapp, which draws the frozen Oryx
layout, and streams every key event once paired. The live layer is our own raw-HID report instead.

## Layout notes

- Layers: 0 Base (Workman), 1 Symbols (`TG(1)`), 2 Media (`LT(2, KC_BSLS)`), 3 Gaming. Top-right key
  (`DUAL_FUNC_0`): tap `-`, hold = `layer_move(3)` (a permanent switch; `TO(0)` on layer 3 leaves).
- LEDs: 1 = Symbols, 2 = Media, 3 = Gaming (`layer_state_set_user`).
- Base ErgoDox has no RGB: the Oryx RGB/HSV keys were dropped in the port.
- Gaming keys 1–5 are plain keycodes (the Oryx tap=1 / hold=F1 versions needed double-press+hold to
  hold "1": QMK defaults are 200 ms tapping term and quick tap term). A game's held key must be plain.
- Live layer: `RAW_ENABLE`. The host pings `0x01` (~2 s) over raw HID (usage page 0xFF60) and gets
  `{'L', layer}` per layer change; `0x02` unsubscribes. No ping for 5 s and the board goes quiet (a raw
  write blocks ~10 ms when nothing reads). Layer numbers only, never keys. Reader:
  `desktop/ergodox-layer` → `ErgodoxWidget` in the bar. QMK pins the raw interface at 1, so the
  udev rule (`run_onchange_after_configure_ergodox_hidraw`) matches only that one. `RAW_EPSIZE` is not
  visible to keymaps on LUFA: the report size is a literal 32.
