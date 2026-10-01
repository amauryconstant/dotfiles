import "../"
import "../../"
import Quickshell.Networking
import QtQuick

// Waybar's network module. Native throughout — Waybar polled at 5s for
// bandwidth; this is event-driven, and bandwidth is dropped because the native
// module does not expose counters.
//
// 🚨 No longer laptop-gated. "No wireless adapter" is not "no network": the
// widget reports the ACTIVE ROUTE and draws the wired glyph where there is one,
// and hides only when there is no networking at all. A desktop on ethernet has
// something to report, so it reports it — degradation is per SOURCE, never per
// machine class.
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

    readonly property bool wifiOn: Networking.wifiEnabled

    clickHint: Networking.wifiHardwareEnabled ? qsTr("L Wi-Fi on/off · R panel") : qsTr("R panel")
    icon: {
        // Wired with the radio off still reports the wired route below; only
        // "nothing at all, by choice" takes the off glyph.
        if (!root.active && !root.wifiOn)
            return Config.wifiOffGlyph;
        if (!root.active)
            return Config.noNetworkGlyph;
        if (!root.isWifi)
            return Config.wiredGlyph;
        // 🚨 signalStrength is a 0..1 fraction, like UPowerDevice.percentage
        // and unlike the 0..100 nmcli reports. Dividing by 25 as if it were
        // a percentage pinned the index at 0, so a full-strength link drew
        // the empty-signal glyph forever. Verified live: nmcli 61%, the
        // property 0.61.
        return Config.wifiGlyphs[Math.min(4, Math.floor((root.wifi?.signalStrength ?? 0) * 4))];
    }
    // Connected is the resting state and stays neutral; no route at all is a
    // fault worth colouring, which is the accent rule's "state only" clause.
    // The radio switched off is a choice, not a fault, so it stays neutral.
    iconColor: root.active || !root.wifiOn ? root.restColor : Theme.signalError
    tooltipText: {
        if (!root.active && !root.wifiOn)
            return "Wi-Fi off";
        if (!root.active)
            return "Disconnected\nNo network interface available";
        if (root.isWifi && root.wifi)
            return `${root.wifi.name}\n${root.active.address}\nSignal: ${Math.round(root.wifi.signalStrength * 100)}%`;
        return `Ethernet\n${root.active.address}`;
    }
    // Networking.devices is empty for the first ~1-2s and fills on its own;
    // ObjectModel.values notifies, so this binding recovers rather than
    // latching a startup reading.
    visible: Networking.devices.values.length > 0

    signal popoverRequested

    // A hard rfkill block cannot be lifted from here, so the click then opens
    // the panel instead of doing nothing.
    onClicked: {
        if (Networking.wifiHardwareEnabled)
            Networking.wifiEnabled = !Networking.wifiEnabled;
        else
            root.popoverRequested();
    }
    onRightClicked: root.popoverRequested()
}
