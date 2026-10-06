#!/usr/bin/env sh
ADDRESS="0x$1"

# Under the Lua config provider hl.dsp.window.resize takes NUMBERS -- there is
# no percent form, so the old `resizewindowpixel exact 50% 50%` has to be
# computed against the monitor the window is actually on.
MONITOR=$(hyprctl clients -j | jq -r --arg a "$ADDRESS" 'map(select(.address == $a))[0].monitor // empty')
[ -n "$MONITOR" ] || exit 0
# .width/.height are PHYSICAL pixels; window geometry is LOGICAL, so divide by
# .scale first. Missing that made "50%" render as the whole monitor.
# They are also the MODE's axes, before rotation: an odd .transform (90/270,
# flipped or not -- the desktop's portrait BenQ is 1) swaps them on screen.
DIMS=$(hyprctl monitors -j | jq -r --argjson m "$MONITOR" 'map(select(.id == $m))[0]
    | (if .transform % 2 == 1 then [.height, .width] else [.width, .height] end) as [$w, $h]
    | "\($w / .scale / 2 | floor) \($h / .scale / 2 | floor)"')
[ -n "$DIMS" ] || exit 0
WIDTH=${DIMS% *}
HEIGHT=${DIMS#* }

hyprctl dispatch "hl.dsp.window.float({ window = \"address:$ADDRESS\" })" 2>/dev/null || exit 0
hyprctl dispatch "hl.dsp.window.resize({ x = $WIDTH, y = $HEIGHT, window = \"address:$ADDRESS\" })" 2>/dev/null || exit 0
hyprctl dispatch "hl.dsp.focus({ window = \"address:$ADDRESS\" })" 2>/dev/null || exit 0
hyprctl dispatch 'hl.dsp.window.center({})' 2>/dev/null || exit 0
