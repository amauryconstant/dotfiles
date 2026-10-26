import "../"
// Config is only reached from inside a template literal, which the linter
// does not trace, so the import reads as unused while being load-bearing.
// qmllint disable unused-imports
import "../../"
// qmllint enable unused-imports
import QtQuick

// The ErgoDox EZ's active layer (Base / Sym / Media / Game).
//
// The firmware answers a raw-HID ping and reports layer numbers only (see
// qmk/.../workman_gaming/keymap.c); desktop/ergodox-layer does the pinging and
// prints Waybar JSON, so this is the same shape as the Kanata widget. Empty
// text while the board is unplugged hides it.
BarWidget {
    id: root

    icon: "󰌓"
    label: source.text
    tooltipText: source.tooltip
    visible: source.text !== ""

    WaybarJsonSource {
        id: source

        command: [`${Config.scriptsDir}/desktop/ergodox-layer`]
    }
}
