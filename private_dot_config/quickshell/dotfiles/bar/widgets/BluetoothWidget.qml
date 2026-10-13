import "../"
import "../../"
import Quickshell.Bluetooth
import QtQuick

// Waybar's bluetooth module, laptop-only. Native adapter and device state.
// Left click opens the device popover, right click powers the adapter, and
// blueman-manager stays the GUI behind it.
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
    // qmllint disable unresolved-type missing-property
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property list<BluetoothDevice> connected: Bluetooth.devices.values.filter(d => d.connected)
    // qmllint enable unresolved-type missing-property

    readonly property bool powered: root.adapter?.enabled ?? false

    clickHint: qsTr("L panel · R power")
    icon: root.powered ? Config.bluetoothGlyph : Config.bluetoothOffGlyph
    // How many devices is tooltip detail; the accent is the whole signal at
    // bar scale, so this carries one and drops the inline count.
    iconColor: root.connected.length > 0 ? Theme.signalFocus : root.restColor
    tooltipText: {
        if (!root.adapter)
            return "No bluetooth adapter";
        if (!root.powered)
            return `${root.adapter.name}\nOff`;
        if (root.connected.length === 0)
            return `${root.adapter.name}\n0 connected`;
        return `${root.adapter.name}\n${root.connected.length} connected\n\n` + root.connected.map(d => d.batteryAvailable ? `${d.name}  ${Math.round(d.battery * 100)}%` : d.name).join("\n");
    }
    tooltipMonospace: true
    // 🚨 A disabled adapter SHOWS, with its own glyph. Until 2026-10-01 off was
    // absence, and that left no place to turn the adapter back on from; now
    // that right click is the power switch, the widget must outlive the off
    // state. Absent hardware still hides, and nothing greys.
    visible: Config.isLaptop && root.adapter !== null

    signal popoverRequested

    onClicked: root.popoverRequested()
    // Inverted from the bar's rule by the user's choice: the selector is what
    // this chip is clicked for.
    onRightClicked: {
        if (root.adapter)
            root.adapter.enabled = !root.adapter.enabled;
    }
}
