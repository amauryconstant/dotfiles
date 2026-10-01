pragma ComponentBehavior: Bound

import "../"
import "../../"
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
// The first row is the adapter's power switch, the same one the widget's left
// click flips. While it is off the device list is withheld: BlueZ still lists
// paired devices then, and a list nothing can connect to is a list of lies.
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
    // What the arrows step through: the switch, then the devices while on.
    readonly property list<BluetoothDevice> shownDevices: root.powered ? root.devices : []
    // qmllint enable unresolved-type
    readonly property bool powered: root.adapter?.enabled ?? false
    readonly property bool busy: root.devices.some(d => d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting)

    function actionsFor(device: var): var {
        if (!device)
            return [];
        return [
            {
                label: device.connected ? qsTr("Disconnect") : qsTr("Connect"),
                glyph: device.connected ? Config.menuGlyphs.disconnect : Config.menuGlyphs.connect,
                run: () => root.toggleDevice(device)
            },
            // Unpairs. Pairing again still hands off to blueman, which is why
            // the header's rule about pair() stands.
            {
                label: qsTr("Forget"),
                glyph: Config.menuGlyphs.forget,
                destructive: true,
                run: () => device.forget()
            },
            {
                label: qsTr("Open blueman"),
                glyph: Config.menuGlyphs.open,
                run: () => root.runEscapeHatch()
            }
        ];
    }

    function togglePower(): void {
        if (root.adapter)
            root.adapter.enabled = !root.adapter.enabled;
    }

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
    glyph: root.powered ? Config.bluetoothGlyph : Config.bluetoothOffGlyph
    navCount: 1 + root.shownDevices.length
    title: qsTr("Bluetooth")

    onActivated: index => {
        if (index === 0)
            root.togglePower();
        else if (index - 1 < root.shownDevices.length)
            root.toggleDevice(root.shownDevices[index - 1]);
    }

    PopoverRow {
        badge: root.powered ? qsTr("on") : qsTr("off")
        cursor: root.keyboardMode && root.selected === 0
        glyph: root.powered ? Config.bluetoothGlyph : Config.bluetoothOffGlyph
        label: qsTr("Bluetooth")
        showRing: cursor
        visible: root.adapter !== null

        onClicked: root.togglePower()
    }

    PopoverRow {
        glyph: Config.bluetoothOffGlyph
        label: qsTr("No paired devices")
        visible: root.powered && root.devices.length === 0
    }

    Repeater {
        model: root.shownDevices

        PopoverRow {
            id: deviceRow

            required property int index
            required property var modelData

            // 🚨 `battery` is a 0..1 fraction and only means anything when
            // batteryAvailable is set; a device that reports none would draw a
            // confident 0%.
            badge: deviceRow.modelData.batteryAvailable ? `${Math.round(deviceRow.modelData.battery * 100)}%` : ""
            cursor: root.keyboardMode && root.selected === deviceRow.index + 1
            dimmed: root.busy && deviceRow.modelData.state === BluetoothDeviceState.Disconnected
            glyph: deviceRow.modelData.connected ? "󰂱" : "󰂯"
            label: deviceRow.modelData.deviceName ?? deviceRow.modelData.name
            menu: root.rowMenu
            menuActions: root.actionsFor(deviceRow.modelData)
            selected: deviceRow.modelData.connected
            showRing: deviceRow.cursor
            status: deviceRow.modelData.state === BluetoothDeviceState.Connecting ? qsTr("connecting") : deviceRow.modelData.state === BluetoothDeviceState.Disconnecting ? qsTr("disconnecting") : ""

            onClicked: root.toggleDevice(deviceRow.modelData)
        }
    }
}
