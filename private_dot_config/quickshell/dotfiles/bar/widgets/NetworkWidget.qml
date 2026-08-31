import "../"
import "../../"
import Quickshell
import Quickshell.Networking
import QtQuick

// Waybar's network module, laptop-only as it was there. Native throughout —
// Waybar polled at 5s for bandwidth; this is event-driven, and bandwidth is
// dropped because the native module does not expose counters.
BarWidget {
    id: root

    readonly property NetworkDevice active: {
        const devices = Networking.devices.values;
        return devices.find(d => d.connected && d.type === DeviceType.Wifi) ?? devices.find(d => d.connected) ?? null;
    }
    // Same class of upstream gap as BluetoothWidget: Networking's qmltypes
    // records this property as the unqualified "DeviceType::Enum", which
    // which the linter cannot match to the module's own exported DeviceType.
    // qmllint disable unresolved-type
    readonly property bool isWifi: root.active?.type === DeviceType.Wifi
    // qmllint enable unresolved-type
    readonly property var wifi: root.isWifi ? root.active.networks.values.find(n => n.connected) ?? null : null

    icon: {
        if (!root.active)
            return "󰖪";
        if (!root.isWifi)
            return "󰈀";
        // 🚨 signalStrength is a 0..1 fraction, like UPowerDevice.percentage
        // and unlike the 0..100 nmcli reports. Dividing by 25 as if it were
        // a percentage pinned the index at 0, so a full-strength link drew
        // the empty-signal glyph forever. Verified live: nmcli 61%, the
        // property 0.61.
        const bars = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"];
        return bars[Math.min(4, Math.floor((root.wifi?.signalStrength ?? 0) * 4))];
    }
    // Connected is the resting state and stays neutral; no route at all is a
    // fault worth colouring, which is the accent rule's "state only" clause.
    iconColor: root.active ? root.restColor : Theme.accentError
    tooltipText: {
        if (!root.active)
            return "Disconnected\nNo network interface available";
        if (root.isWifi && root.wifi)
            return `${root.wifi.name}\n${root.active.address}\nSignal: ${Math.round(root.wifi.signalStrength * 100)}%`;
        return `Ethernet\n${root.active.address}`;
    }
    visible: Config.isLaptop

    onClicked: Quickshell.execDetached(["ghostty", "--class=network-manager", "-e", "nmtui"])
}
