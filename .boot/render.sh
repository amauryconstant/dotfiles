#!/usr/bin/env bash
# Render the boot-stack themes (rEFInd, Plymouth, SDDM) from .boot/colors.sh.
#
# Usage: render.sh OUTDIR
# Env:   GUI_FONT, TERMINAL_FONT   family names (from globals.yaml)
#        BOOT_WALLPAPER            image behind the greeter and rEFInd; empty = wallpaper/ribbed.jpg
#                                  (Unsplash, see wallpaper/ATTRIBUTION.md); "none" = flat ground
#        GREETER_DIM               black scrim over that image in the greeter
#        GREETER_SCALE             greeter size multiplier (on top of the scale by screen height)
#        CONFIG_QML                Config.qml.tmpl, source of the lock geometry
#        REFIND_ICONS              rEFInd's shipped icon dir
#
# Needs no root: the chezmoi script (run_onchange_after_render_boot_theme)
# calls this into a scratch dir and installs the result. Run it by hand to
# look at the PNGs.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
out=${1:?usage: render.sh OUTDIR}
GUI_FONT=${GUI_FONT:-Inter}
TERMINAL_FONT=${TERMINAL_FONT:-GeistMono Nerd Font}
BOOT_WALLPAPER=${BOOT_WALLPAPER:-}
GREETER_DIM=${GREETER_DIM:-0.2}
GREETER_SCALE=${GREETER_SCALE:-0.9}
CONFIG_QML=${CONFIG_QML:-$here/../private_dot_config/quickshell/dotfiles/Config.qml.tmpl}
REFIND_ICONS=${REFIND_ICONS:-/usr/share/refind/icons}

# shellcheck source=colors.sh
. "$here/colors.sh"

# ---------------------------------------------------------------- helpers

# One number from Config.qml.tmpl: `readonly property <int|real> NAME: 72`.
cfg() {
	local v
	v=$(sed -n "s/^[[:space:]]*readonly property [a-z]* $1: \([0-9.]*\).*/\1/p" "$CONFIG_QML" | head -n 1)
	[ -n "$v" ] || {
		echo "render.sh: $1 not found in $CONFIG_QML" >&2
		exit 1
	}
	printf '%s' "$v"
}

# Fill @KEY@ placeholders. Arguments are KEY=VALUE; values must not contain '|'.
fill() {
	local src=$1 dst=$2 pair expr=()
	shift 2
	for pair in "$@"; do
		expr+=(-e "s|@${pair%%=*}@|${pair#*=}|g")
	done
	sed "${expr[@]}" "$src" >"$dst"
}

hex0x() { printf '0x%s' "${1#\#}"; }

font_file() {
	fc-match -f '%{file}' "$1"
}

command -v magick >/dev/null || {
	echo "render.sh: ImageMagick (magick) is required" >&2
	exit 1
}

mkdir -p "$out/sddm" "$out/plymouth" "$out/refind/icons"

# The image: the vendored Unsplash one unless globals says otherwise.
case "$BOOT_WALLPAPER" in
"") BOOT_WALLPAPER="$here/wallpaper/ribbed.jpg" ;;
none) BOOT_WALLPAPER="" ;;
esac

# ------------------------------------------------------------------- SDDM

background=""
if [ -n "$BOOT_WALLPAPER" ] && [ -f "$BOOT_WALLPAPER" ]; then
	# The greeter runs as the sddm user and cannot read ~, so the wallpaper
	# travels inside the theme directory. Capped at 2560 wide: it is dimmed
	# to 30% and a 4K decode buys nothing on the way to a login prompt.
	magick "$BOOT_WALLPAPER" -auto-orient -resize '2560x>' -quality 88 "$out/sddm/background.jpg"
	background="background.jpg"
fi

cp "$here/sddm/Main.qml" "$here/sddm/metadata.desktop" "$out/sddm/"
fill "$here/sddm/theme.conf.in" "$out/sddm/theme.conf" \
	"BACKGROUND=$background" "DIM=$GREETER_DIM" "UI_SCALE=$GREETER_SCALE" "GUI_FONT=$GUI_FONT" "TERMINAL_FONT=$TERMINAL_FONT" \
	"GROUND_BASE=$GROUND_BASE" "GROUND_RAISED=$GROUND_RAISED" \
	"INK_PRIMARY=$INK_PRIMARY" "INK_SECONDARY=$INK_SECONDARY" "SIGNAL_FOCUS=$SIGNAL_FOCUS" \
	"lockClockSize=$(cfg lockClockSize)" \
	"lockFieldWidth=$(cfg lockFieldWidth)" "lockFieldHeight=$(cfg lockFieldHeight)" \
	"fontDisplay=$(cfg fontDisplay)" "fontTitle=$(cfg fontTitle)" \
	"radiusPanel=$(cfg radiusPanel)" "hairline=$(cfg hairline)" \
	"padTight=$(cfg padTight)" "gap=$(cfg gap)" "padLoose=$(cfg padLoose)"

# --------------------------------------------------------------- Plymouth

fill "$here/plymouth/dotfiles.plymouth.in" "$out/plymouth/dotfiles.plymouth" \
	"TERMINAL_FONT=$TERMINAL_FONT" "BG_HEX=$(hex0x "$GROUND_BASE")" \
	"TRACK_HEX=$(hex0x "$GROUND_FLOAT")" "FOCUS_HEX=$(hex0x "$SIGNAL_FOCUS")"

ply=$out/plymouth
fw=$(cfg lockFieldWidth)
fh=$(cfg lockFieldHeight)
fr=$(cfg radiusPanel)

# Spinner: a GROUND_FLOAT ring with a 100-degree SIGNAL_FOCUS head, 36 frames.
# Drawn at 4x and shrunk, because -draw does not antialias an arc.
for i in $(seq 1 36); do
	start=$(((i - 1) * 10))
	end=$((start + 100))
	frame=$(printf '%s/animation-%04d.png' "$ply" "$i")
	magick -size 192x192 xc:none -fill none -strokewidth 14 \
		-stroke "$GROUND_FLOAT" -draw 'circle 96,96 96,14' \
		-stroke "$SIGNAL_FOCUS" -draw "arc 14,14 178,178 $((start - 90)),$((end - 90))" \
		-resize 48x48 "$frame"
	cp "$frame" "$(printf '%s/throbber-%04d.png' "$ply" "$i")"
done

# The passphrase field: the lock's field (base body, rounded, hairline).
# GROUND_FLOAT edge rather than the lock's GROUND_RAISED: on a flat ground there
# is no wallpaper to give the 1.05:1 tier step an outline to sit against.
magick -size "${fw}x${fh}" xc:none -fill "$GROUND_BASE" -stroke "$GROUND_FLOAT" -strokewidth 1 \
	-draw "roundrectangle 0.5,0.5 $((fw - 1)),$((fh - 1)) $fr,$fr" "$ply/entry.png"
magick -size 12x12 xc:none -fill "$INK_PRIMARY" -draw 'circle 6,6 6,0.5' "$ply/bullet.png"
magick -size 1x1 xc:none "$ply/lock.png"
magick -size 1x1 xc:none "$ply/keyboard.png"
magick -size 1x1 xc:none "$ply/keymap-render.png"
magick -size 20x20 xc:none -fill "$INK_SECONDARY" \
	-draw 'polygon 10,2 18,11 13,11 13,18 7,18 7,11 2,11' "$ply/capslock.png"

# ----------------------------------------------------------------- rEFInd

rf=$out/refind
cp "$here/refind/theme.conf.in" "$rf/theme.conf"

if [ -n "$BOOT_WALLPAPER" ] && [ -f "$BOOT_WALLPAPER" ]; then
	# Same image as the greeter, at 1080p: rEFInd scales it to the screen
	# (banner_scale fillscreen) and a decode of 4K pixels in firmware is slow.
	# PNG, not JPEG: rEFInd's JPEG decoder has restrictions, PNG is proven here.
	magick "$BOOT_WALLPAPER" -auto-orient -resize 1920x1080^ -gravity center -extent 1920x1080 \
		-define png:compression-level=9 "$rf/bg.png"
else
	magick -size 64x64 "xc:$GROUND_BASE" "$rf/bg.png"
fi

# Labels are hidden (icons only, like the minimal reference themes), so the
# selection tile is the ONLY cue for the current entry: GROUND_FLOAT body, 2px
# SIGNAL_FOCUS outline. rEFInd wants a tile 16px larger than its icon: 256+16
# and 96+16.
magick -size 272x272 xc:none -fill "$GROUND_FLOAT" -stroke "$SIGNAL_FOCUS" -strokewidth 2 \
	-draw 'roundrectangle 1,1 270,270 28,28' "$rf/selection_big.png"
magick -size 112x112 xc:none -fill "$GROUND_FLOAT" -stroke "$SIGNAL_FOCUS" -strokewidth 2 \
	-draw 'roundrectangle 1,1 110,110 16,16' "$rf/selection_small.png"

# The dark end of the icon tint: 40% of INK_SECONDARY, not GROUND_FLOAT, which
# is the selection tile's own colour and would swallow an icon's inner detail.
lo=$(printf '#%02x%02x%02x' \
	$((0x${INK_SECONDARY:1:2} * 4 / 10)) $((0x${INK_SECONDARY:3:2} * 4 / 10)) $((0x${INK_SECONDARY:5:2} * 4 / 10)))

# Every shipped icon, desaturated, mapped between $lo and INK_SECONDARY so the
# menu reads as one family, then doubled (Lanczos) for the 256/96 icon sizes.
# icons_dir REPLACES the default directory in rEFInd, so an icon not copied
# here is an icon not drawn.
if [ -d "$REFIND_ICONS" ]; then
	for icon in "$REFIND_ICONS"/*.png; do
		# Tint the colour channels, then put the original alpha back: the level
		# mapping alone turns every transparent pixel into an opaque colour.
		magick "$icon" \( +clone -alpha extract \) \
			\( -clone 0 -alpha off -colorspace Gray +level-colors "${lo},${INK_SECONDARY}" \) \
			-delete 0 +swap -compose CopyOpacity -composite \
			-filter Lanczos -resize 200% "$rf/icons/$(basename "$icon")"
	done

	# Labels are hidden, so the two Arch entries need different icons: the same
	# mark with an LTS pill, bottom right.
	bold=$(font_file "$TERMINAL_FONT Mono:bold")
	magick "$rf/icons/os_arch.png" \
		-fill "$GROUND_FLOAT" -stroke "$SIGNAL_FOCUS" -strokewidth 2 \
		-draw 'roundrectangle 140,190 250,244 14,14' \
		-stroke none -fill "$INK_PRIMARY" -font "$bold" -pointsize 34 \
		-gravity none -annotate +161+229 'LTS' "$rf/icons/os_arch_lts.png"
else
	echo "render.sh: $REFIND_ICONS missing -- rEFInd icons skipped" >&2
fi
