pragma ComponentBehavior: Bound

import "../"
import Quickshell.Bluetooth
import QtQuick

// Bluetooth popover, design page Shell-06-Popovers: paired devices, with
// battery where the device reports one.
//
// 🚨 Connect and disconnect only — PAIRING HANDS OFF. `pair()` and `forget()`
// exist on the device and are deliberately not called: pairing needs an agent,
// a passkey exchange and a place to show it, which is blueman's job and the
// escape hatch the footer names.
//
// An adapter that is off means the WIDGET is absent, so there is nothing to
// open: off is absence, and no "off" glyph exists in this tree.
BarPopover {
    id: root

    // Upstream qmltypes gap, not a missing import: quickshell 0.3.1's
    // Quickshell/Bluetooth/qmldir omits `depends Quickshell`, so the linter
    // cannot resolve the core types these are declared as. Suppressed over
    // these lines only — unresolved-type is also how a real missing import
    // surfaces.
    // qmllint disable unresolved-type
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property list<BluetoothDevice> devices: Bluetooth.devices.values.filter(d => d.paired || d.connected)
    // qmllint enable unresolved-type
    readonly property bool busy: root.devices.some(d => d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting)

    function toggleDevice(device: var): void {
        if (!device)
            return;
        if (device.connected)
            device.disconnect();
        else
            device.connect();
    }

    footerCommand: ["blueman-manager"]
    footerLeft: root.keyboardMode ? qsTr("↑↓ move · ↵ connect") : ""
    footerRight: "blueman"
    glyph: "󰂯"
    navCount: root.devices.length
    title: qsTr("Bluetooth")

    onActivated: index => {
        if (index >= 0 && index < root.devices.length)
            root.toggleDevice(root.devices[index]);
    }

    PopoverRow {
        glyph: "󰂲"
        label: qsTr("No paired devices")
        visible: root.devices.length === 0
    }

    Repeater {
        model: root.devices

        PopoverRow {
            id: deviceRow

            required property int index
            required property var modelData

            // 🚨 `battery` is a 0..1 fraction and only means anything when
            // batteryAvailable is set; a device that reports none would draw a
            // confident 0%.
            badge: deviceRow.modelData.batteryAvailable ? `${Math.round(deviceRow.modelData.battery * 100)}%` : ""
            cursor: root.keyboardMode && root.selected === deviceRow.index
            dimmed: root.busy && deviceRow.modelData.state === BluetoothDeviceState.Disconnected
            glyph: deviceRow.modelData.connected ? "󰂱" : "󰂯"
            label: deviceRow.modelData.deviceName ?? deviceRow.modelData.name
            selected: deviceRow.modelData.connected
            showRing: deviceRow.cursor
            status: deviceRow.modelData.state === BluetoothDeviceState.Connecting ? qsTr("connecting") : deviceRow.modelData.state === BluetoothDeviceState.Disconnecting ? qsTr("disconnecting") : ""

            onClicked: root.toggleDevice(deviceRow.modelData)
        }
    }
}
