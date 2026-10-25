#!/usr/bin/env bash
#MISE description="Compile the ErgoDox EZ keymap from qmk/ and print the firmware size"
set -euo pipefail

# shellcheck source=../../lib/qmk-env.sh
source "$(git rev-parse --show-toplevel)/.mise/lib/qmk-env.sh"

[[ -d "$QMK_HOME/.git" ]] || {
	echo "❌ no QMK clone at $QMK_HOME (run: mise run qmk:setup)" >&2
	exit 1
}

qmk compile -kb "$QMK_KEYBOARD" -km "$QMK_KEYMAP"
