#!/usr/bin/env bash
#MISE description="Bump the pinned QMK release: report what changed, rewrite the pin, rebuild (never flashes)"
set -euo pipefail

# Usage: mise run qmk:update                    newest release tag
#        mise run qmk:update -- --to 0.35.0     a specific tag
#        mise run qmk:update -- --check         report only, change nothing
#
# 🚨 This firmware sees every keystroke, so the pin moves only when this command is run and the
# report is read. It NEVER flashes and NEVER commits, and a failed build leaves the new pin in
# place (so the keymap can be fixed against it); the rollback is printed.

root=$(git rev-parse --show-toplevel)
# shellcheck source=../../lib/qmk-env.sh
source "$root/.mise/lib/qmk-env.sh"
env_file="$root/.mise/lib/qmk-env.sh"

check=0
target=""
while [[ $# -gt 0 ]]; do
	case "$1" in
	--check) check=1 ;;
	--to)
		target="${2:-}"
		[[ -n "$target" ]] || {
			echo "❌ --to needs a tag" >&2
			exit 2
		}
		shift
		;;
	*)
		echo "❌ unknown argument: $1" >&2
		exit 2
		;;
	esac
	shift
done

[[ -d "$QMK_HOME/.git" ]] || {
	echo "❌ no QMK clone at $QMK_HOME (run: mise run qmk:setup)" >&2
	exit 1
}

git -C "$QMK_HOME" fetch --tags --quiet origin

if [[ -z "$target" ]]; then
	target=$(git -C "$QMK_HOME" tag --list | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
fi
new_sha=$(git -C "$QMK_HOME" rev-parse --verify --quiet "refs/tags/$target^{commit}") || {
	echo "❌ no such release tag: $target" >&2
	exit 1
}

if [[ "$new_sha" == "$QMK_FIRMWARE_REF" ]]; then
	echo "✅ already at $QMK_FIRMWARE_TAG"
	exit 0
fi

echo "QMK $QMK_FIRMWARE_TAG -> $target"
echo "https://github.com/qmk/qmk_firmware/compare/$QMK_FIRMWARE_TAG...$target"

echo
echo "== Breaking-change notes added in range (docs/ChangeLog/) =="
git -C "$QMK_HOME" diff --name-only --diff-filter=A "$QMK_FIRMWARE_REF" "$new_sha" -- docs/ChangeLog/ || true

echo
echo "== Commits touching this board, its USB stack and the AVR platform =="
git -C "$QMK_HOME" log --oneline "$QMK_FIRMWARE_REF..$new_sha" -- \
	keyboards/ergodox_ez quantum tmk_core/protocol/lufa platforms/avr builddefs || true

if [[ $check -eq 1 ]]; then
	exit 0
fi

old_size=$(qmk compile -kb "$QMK_KEYBOARD" -km "$QMK_KEYMAP" 2>&1 | grep -oE '[0-9]+/32256' | head -1 || true)

sed -i \
	-e "s|^export QMK_FIRMWARE_TAG=.*|export QMK_FIRMWARE_TAG=$target|" \
	-e "s|^export QMK_FIRMWARE_REF=.*|export QMK_FIRMWARE_REF=$new_sha|" \
	"$env_file"

rollback="git checkout .mise/lib/qmk-env.sh && mise run qmk:setup"

# The env file changed, so setup/build must re-source it: run them as fresh processes.
if ! "$root/.mise/tasks/qmk/setup.sh"; then
	echo "❌ setup failed. Roll back: $rollback" >&2
	exit 1
fi

if ! build_out=$("$root/.mise/tasks/qmk/build.sh" 2>&1); then
	printf '%s\n' "$build_out" | tail -30 >&2
	echo "❌ build failed against $target. Fix the keymap, or roll back: $rollback" >&2
	exit 1
fi
new_size=$(printf '%s\n' "$build_out" | grep -oE '[0-9]+/32256' | head -1 || true)

echo
echo "✅ built against $target. Firmware size: ${old_size:-?} -> ${new_size:-?} bytes"
echo
echo "Next, by hand:"
echo "  1. mise run qmk:flash"
echo "  2. test all four layers, the LEDs, the top-right key and the bar's layer widget"
echo "  3. commit through the commit skill"
