#!/usr/bin/env bash
#MISE description="Compile and flash the ErgoDox EZ (press the reset button when prompted)"
set -euo pipefail

# shellcheck source=../../lib/qmk-env.sh
source "$(git rev-parse --show-toplevel)/.mise/lib/qmk-env.sh"

[[ -d "$QMK_HOME/.git" ]] || {
	echo "❌ no QMK clone at $QMK_HOME (run: mise run qmk:setup)" >&2
	exit 1
}

qmk flash -kb "$QMK_KEYBOARD" -km "$QMK_KEYMAP"
