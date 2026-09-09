import "../"
import "../../"
import Quickshell
import Quickshell.Bluetooth
import QtQuick

// Waybar's bluetooth module, laptop-only. Native adapter and device state;
// blueman-manager stays the GUI, as in Waybar's on-click.
BarWidget {
    id: root

    // Upstream qmltypes gap, not a missing import here: quickshell 0.3.1's
    // Quickshell/Bluetooth/qmldir omits `depends Quickshell`, which every
    // comparable module (Pipewire, SystemTray, Networking) declares, so
    // the linter therefore cannot resolve the core types these properties
    // are declared as. Suppressed over just these two lines rather than
    // tree-wide: unresolved-type is also how a real missing import surfaces.
    //
    // NB a comment whose first word is the linter's own name is parsed as a
    // directive, so the prose above deliberately never starts a line with it.
    // qmllint disable unresolved-type
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property list<BluetoothDevice> connected: Bluetooth.devices.values.filter(d => d.connected)
    // qmllint enable unresolved-type

    icon: "󰂯"
    // How many devices is tooltip detail; the accent is the whole signal at
    // bar scale, so this carries one and drops the inline count.
    iconColor: root.connected.length > 0 ? Theme.signalFocus : root.restColor
    tooltipText: {
        if (!root.adapter)
            return "No bluetooth adapter";
        if (root.connected.length === 0)
            return `${root.adapter.name}\n0 connected`;
        return `${root.adapter.name}\n${root.connected.length} connected\n\n` + root.connected.map(d => d.batteryAvailable ? `${d.name}  ${Math.round(d.battery * 100)}%` : d.name).join("\n");
    }
    tooltipMonospace: true
    // 🚨 A disabled adapter HIDES the widget rather than dimming it. Absent
    // hardware hides, a failed service shows, and nothing greys — so there is
    // no "bluetooth off" glyph in this tree, because off is absence.
    visible: Config.isLaptop && (root.adapter?.enabled ?? false)

    onClicked: Quickshell.execDetached(["blueman-manager"])
}
