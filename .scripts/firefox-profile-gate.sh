#!/usr/bin/env bash

# Script: firefox-profile-gate.sh
# Purpose: Re-prove how Firefox treats managed profiles on THIS machine: the
#          picker, window identity (class) and per-profile remoting, against a
#          throwaway profile root. Re-run after a Firefox major bump or a change
#          to private_dot_local/bin/executable_firefox.
# Requirements: Firefox via the EGL wrapper, hyprctl, jaq, a running Hyprland session
# Record: _research/FIREFOX_PROFILE_LAUNCH_BEHAVIOUR.md
#
# Usage:
#   firefox-profile-gate.sh A                 picker + Default=1 preselect (interactive)
#   firefox-profile-gate.sh S [flag] [x11]    start Alpha + Beta, print classes and titles
#   firefox-profile-gate.sh R [flag] <1|2|3>  send a URL to the running pair
#                                             1: -P Beta --new-tab URL
#                                             2: --profile <path> URL
#                                             3: URL only (expected to MISROUTE)
#   firefox-profile-gate.sh K                 kill the test instances
#   firefox-profile-gate.sh X                 kill, then delete the throwaway tree
#
# flag: both (default) | --name | --class. x11 forces the wrapper's XWayland fallback.
#
# Isolation: overriding HOME is NOT enough. The session exports XDG_CONFIG_HOME and
# Firefox honours it first, so without the XDG overrides below the test silently runs
# against the real profile root. BASH_ENV is unset because the login shell's file
# sources $HOME/.config/shell/env, which the throwaway home lacks.
#
# Never use `pkill -f` to clean up: the instances' command lines do not contain the
# test path. K matches on XDG_CONFIG_HOME in the process environment instead, so it
# cannot touch the real Firefox.

set -u

TESTHOME="${TESTHOME:-/tmp/ff-gate-home}"
FFROOT="$TESTHOME/.config/mozilla/firefox"
WRAP="$HOME/.local/bin/firefox"
BACKEND=""

case "$TESTHOME" in
/tmp/*) ;;
*)
	echo "TESTHOME must be under /tmp (got $TESTHOME)" >&2
	exit 2
	;;
esac

setup() {
	rm -rf "$TESTHOME"
	mkdir -p "$FFROOT/alpha" "$FFROOT/beta" "$TESTHOME/.local"
	# The wrapper reads PATCHED_LIB from $HOME; without this it falls back to XWayland.
	ln -s "$HOME/.local/lib" "$TESTHOME/.local/lib"
	cat >"$FFROOT/profiles.ini" <<'EOF'
[General]
StartWithLastProfile=0
Version=2

[Profile0]
Name=Alpha
IsRelative=1
Path=alpha
Default=1

[Profile1]
Name=Beta
IsRelative=1
Path=beta
EOF
}

ff() {
	local extra=()
	[ -n "$BACKEND" ] && extra=("FIREFOX_BACKEND=$BACKEND")
	env -u BASH_ENV HOME="$TESTHOME" \
		XDG_CONFIG_HOME="$TESTHOME/.config" \
		XDG_CACHE_HOME="$TESTHOME/.cache" \
		XDG_DATA_HOME="$TESTHOME/.local/share" \
		MOZ_LEGACY_PROFILES=1 "${extra[@]}" "$WRAP" "$@"
}

# Identity args for a profile id, per the chosen flag
IDARGS=()
idargs() {
	case "$FLAG" in
	both) IDARGS=(--name "$1" --class "$1") ;;
	*) IDARGS=("$FLAG" "$1") ;;
	esac
}

windows() {
	hyprctl clients -j | jaq -r '.[] | select(.class | test("irefox")) | "\(.class)\t\(.pid)\t\(.title)"'
}

# Profile Manager windows are titled "Choose User Profile". -P matches the profiles.ini
# Name= (case-sensitive), and a miss opens that dialog while --name still sets a class
# on it, so a class check alone proves nothing.
report() {
	windows
	if windows | grep -q 'Choose User Profile'; then
		echo "!! a Profile Manager is open: -P did not match a Name= in profiles.ini"
	fi
}

count_parents() {
	pgrep -af '/usr/lib/firefox/firefox' | grep -v contentproc | grep -cE 'Alpha|Beta|alpha|beta'
}

kill_test() {
	local p left=0
	for p in $(pgrep -f '/usr/lib/firefox/firefox'); do
		if tr '\0' '\n' <"/proc/$p/environ" 2>/dev/null | grep -qx "XDG_CONFIG_HOME=$TESTHOME/.config"; then
			kill "$p" 2>/dev/null
		fi
	done
	sleep 3
	for p in $(pgrep -f '/usr/lib/firefox/firefox'); do
		if tr '\0' '\n' <"/proc/$p/environ" 2>/dev/null | grep -qx "XDG_CONFIG_HOME=$TESTHOME/.config"; then
			left=$((left + 1))
		fi
	done
	echo "test firefox processes left: $left"
}

FLAG="${2:-both}"

case "${1:-}" in
A)
	setup
	echo ">> Expect: Profile Manager lists Alpha + Beta only, Alpha preselected. Close it unlaunched."
	ff -no-remote
	ls -1 "$FFROOT"
	echo "[Install] lines: $(grep -c '^\[Install' "$FFROOT/profiles.ini")  (expect 0)"
	[ ! -e "$FFROOT/installs.ini" ] && echo "no installs.ini - OK"
	;;
S)
	[ "${3:-}" = x11 ] && BACKEND=x11
	setup
	idargs firefox-alpha
	ff "${IDARGS[@]}" -P Alpha about:blank &
	sleep 10
	idargs firefox-beta
	ff "${IDARGS[@]}" -P Beta about:blank &
	sleep 10
	echo "== windows (class, pid, title); expect firefox-alpha and firefox-beta:"
	report
	echo "== parent processes: $(count_parents) (expect 2)"
	echo "== profile dir populated: $(find "$FFROOT/alpha" -maxdepth 1 | wc -l) entries (expect > 1)"
	;;
R)
	# Second argument may be the variant when the flag is omitted: R 1
	if [ -z "${3:-}" ] && [[ "${2:-}" =~ ^[123]$ ]]; then
		v="$2"
		FLAG=both
	else
		v="${3:?variant 1|2|3}"
	fi
	before="$(count_parents)"
	idargs firefox-beta
	case "$v" in
	1) ff "${IDARGS[@]}" -P Beta --new-tab "https://example.org/v1" & ;;
	2) ff "${IDARGS[@]}" --profile "$FFROOT/beta" "https://example.org/v2" & ;;
	3) ff "${IDARGS[@]}" "https://example.org/v3" & ;;
	*)
		echo "variant must be 1, 2 or 3" >&2
		exit 2
		;;
	esac
	sleep 6
	echo "== parent processes before/after: $before / $(count_parents)  (expect equal)"
	report
	echo ">> Which window got the v$v tab? Expect BETA's, for 1 and 2. Variant 3 is expected to misroute."
	;;
K)
	kill_test
	;;
X)
	kill_test
	rm -rf "$TESTHOME"
	echo "removed $TESTHOME"
	;;
*)
	echo "usage: $0 A | S [flag] [x11] | R [flag] <1|2|3> | K | X" >&2
	exit 2
	;;
esac
