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

    tooltipText: {
        if (!root.adapter)
            return "No bluetooth adapter";
        if (!root.adapter.enabled)
            return "Bluetooth disabled";
        if (root.connected.length === 0)
            return `${root.adapter.name}\n0 connected`;
        return `${root.adapter.name}\n${root.connected.length} connected\n\n` + root.connected.map(d => d.batteryAvailable ? `${d.name}  ${Math.round(d.battery * 100)}%` : d.name).join("\n");
    }
    tooltipMonospace: true
    visible: Config.isLaptop && root.adapter !== null

    onClicked: Quickshell.execDetached(["blueman-manager"])

    Text {
        anchors.verticalCenter: parent.verticalCenter
        // accent-highlight once something is connected, per waybar/CLAUDE.md.
        color: !root.adapter?.enabled ? Theme.fgMuted : root.connected.length > 0 ? Theme.accentHighlight : Theme.accentInfo
        font.family: Config.guiFont
        font.pixelSize: Config.fontSize
        text: !root.adapter?.enabled ? "󰂲" : root.connected.length > 0 ? ` ${root.connected.length}` : "󰂯"
    }
}
