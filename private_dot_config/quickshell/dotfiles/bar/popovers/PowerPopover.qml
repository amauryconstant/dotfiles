import "../"
// Config is reached only from inside a template literal below, which qmllint
// does not trace, so the import that makes it resolvable reads as unused.
// qmllint disable unused-imports
import "../../"
// qmllint enable unused-imports
import Quickshell.Services.UPower
import QtQuick

// Power popover, design page Shell-06-Popovers: battery detail, time estimate,
// health. Read-only, like the meters — navCount stays 0.
//
// 🚨 No profile row. The design's payload includes one, but
// power-profiles-daemon is neither installed here nor in packages.yaml, and
// PowerProfiles.profile still answers "Balanced" with no daemon running, so the
// row would state a profile that is not real. Page 03: a control that would do
// nothing is REMOVED, never disabled. It comes back by itself the day the
// daemon is installed, because the rows below are `visible`-gated on what
// UPower actually reports.
BarPopover {
    id: root

    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property bool charging: root.battery?.state === UPowerDeviceState.Charging
    // 🚨 A 0..1 fraction, not the 0..100 `upower -i` prints — the same trap
    // BatteryWidget documents.
    readonly property real percent: (root.battery?.percentage ?? 0) * 100
    readonly property bool plugged: root.battery?.state === UPowerDeviceState.FullyCharged || root.battery?.state === UPowerDeviceState.PendingCharge
    readonly property real watts: Number(root.battery?.changeRate ?? 0)

    function stateText(): string {
        if (root.charging)
            return qsTr("Charging");
        if (root.battery?.state === UPowerDeviceState.FullyCharged)
            return qsTr("Fully charged");
        if (root.plugged)
            return qsTr("Plugged in");
        return qsTr("On battery");
    }

    function timeText(): string {
        const seconds = root.charging ? root.battery?.timeToFull ?? 0 : root.battery?.timeToEmpty ?? 0;
        if (seconds <= 0)
            return root.plugged ? qsTr("—") : qsTr("Estimating…");
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return `${hours}h ${minutes}m`;
    }

    footerCommand: [`${Config.scriptsDir}/desktop/battery-status`]
    footerLeft: root.keyboardMode ? qsTr("esc close") : ""
    footerRight: "battery-status"
    glyph: root.charging ? "󰢜" : "󰁹"
    title: qsTr("Power")

    PopoverRow {
        badge: `${Math.round(root.percent)}%`
        glyph: root.charging ? "󰢜" : root.plugged ? "󰚥" : "󰁹"
        label: root.stateText()
    }

    PopoverRow {
        badge: root.timeText()
        glyph: "󰥔"
        label: root.charging ? qsTr("Until full") : qsTr("Remaining")
    }

    PopoverRow {
        badge: `${root.watts.toFixed(1)} W`
        glyph: "󱐋"
        label: qsTr("Draw")
        visible: root.watts !== 0
    }

    // healthPercentage reads 0 where the firmware does not report it, and a
    // literal "Health 0%" looks like a dead battery.
    PopoverRow {
        badge: `${Math.round(root.battery?.healthPercentage ?? 0)}%`
        glyph: "󰗐"
        label: qsTr("Health")
        visible: root.battery?.healthSupported ?? false
    }
}
