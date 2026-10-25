# Sourced by .mise/tasks/qmk/*.sh: one place for the pin and the paths.
#
# Pin = release tag 0.34.7 of mainline qmk/qmk_firmware, by SHA (a tag can be moved, a SHA
# cannot). This firmware sees every keystroke, so bump it deliberately: read the release notes,
# change QMK_FIRMWARE_REF, then run qmk:setup and qmk:build. See qmk/CLAUDE.md.
export QMK_FIRMWARE_REF=180f394b489c238cb231c2bf8b080262155e03c0
export QMK_FIRMWARE_URL=https://github.com/qmk/qmk_firmware

export QMK_KEYBOARD=ergodox_ez/base
export QMK_KEYMAP=workman_gaming

# Exported so no ~/.config/qmk/qmk.ini is needed.
QMK_HOME=${XDG_DATA_HOME:-$HOME/.local/share}/qmk/qmk_firmware
QMK_USERSPACE=$(git rev-parse --show-toplevel)/qmk
export QMK_HOME QMK_USERSPACE
