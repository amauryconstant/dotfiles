import "../"
import "../../"
import Quickshell

// Waybar's backlight module never actually rendered: it was gated on
// `exec-if: which light`, and `light` is neither installed nor in
// packages.yaml. So this is not a port of a working module — it is the first
// time the bar has shown brightness at all.
//
// The sysfs reading lives in the Backlight singleton, shared with the OSD.
BarWidget {
    id: root

    // Icon-only: the seven-step glyph already reads as a level, and the exact
    // percentage is in the tooltip. Amendment A grants a number-carrying pill
    // to the battery alone.
    icon: Config.brightnessGlyph(Backlight.percent)
    tooltipText: `Brightness: ${Backlight.percent}%`
    visible: Config.isLaptop && Backlight.available

    onScrolledDown: Quickshell.execDetached([`${Config.scriptsDir}/desktop/brightness-set`, "down"])
    onScrolledUp: Quickshell.execDetached([`${Config.scriptsDir}/desktop/brightness-set`, "up"])
}
