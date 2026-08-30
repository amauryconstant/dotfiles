#!/usr/bin/env sh

# Library: capture-region.sh
# Purpose: Shared freeze + region-select plumbing for capture-qr and
#          capture-text-extraction (screenshot has its own smart/windows/
#          fullscreen modes and is left untouched — this is the plain-region
#          subset the two newer scripts actually need)
# Usage: . capture-region.sh; geometry=$(capture_region_select) || exit 1

capture_region_select() {
    wayfreeze_pid=""
    if command -v wayfreeze >/dev/null 2>&1; then
        wayfreeze &
        wayfreeze_pid=$!
        sleep 0.1
    fi

    geometry=$(slurp 2>/dev/null)

    [ -n "$wayfreeze_pid" ] && kill "$wayfreeze_pid" 2>/dev/null

    [ -n "$geometry" ] || return 1
    printf '%s\n' "$geometry"
}
