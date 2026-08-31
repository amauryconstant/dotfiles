import "../"
import "../../"
import Quickshell
import Quickshell.Services.UPower
import QtQuick

// Waybar's battery module, laptop-only via Config.isLaptop.
//
// This is the one pill on the bar (Amendment A): every other widget is
// icon-only at rest, because charge is the single number that has to be
// readable without a hover.
//
// PowerProfiles is deliberately NOT wired up, despite being the obvious
// native counterpart. power-profiles-daemon is neither installed here nor in
// packages.yaml, so Waybar's `on-click: powerprofilesctl` was already dead —
// it launched a binary that does not exist. Worse, PowerProfiles.profile
// still reports "Balanced" with no daemon running, so surfacing it would
// state a profile that is not real. Click goes to `battery-status` instead,
// the script already bound to SUPER+CTRL+ALT+B, which actually reports.
BarWidget {
    id: root

    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property bool charging: root.battery?.state === UPowerDeviceState.Charging
    // 🚨 UPowerDevice.percentage is a 0..1 fraction, NOT the 0..100 the
    // UPower D-Bus API and `upower -i` both report. Verified against a real
    // battery: upower said 72%, this property said 0.72. Treating it as a
    // percentage silently puts every threshold 100x out and renders "1%".
    readonly property real percent: (root.battery?.percentage ?? 0) * 100
    // PendingCharge is what a charge-limited laptop sits in for most of its
    // life: plugged in, not charging, and not FullyCharged either.
    readonly property bool plugged: root.battery?.state === UPowerDeviceState.FullyCharged || root.battery?.state === UPowerDeviceState.PendingCharge

    function tooltipLines(): string {
        const watts = Number(root.battery?.changeRate ?? 0);
        const parts = [root.timeText(), `${Math.round(root.percent)}% - ${watts.toFixed(1)}W`];
        // healthPercentage reads 0 when the firmware does not report it; a
        // literal "Health: 0%" would look like a dead battery.
        if (root.battery?.healthSupported)
            parts.push(`Health: ${Math.round(root.battery.healthPercentage)}%`);
        return parts.join("\n");
    }

    function timeText(): string {
        const seconds = root.charging ? root.battery?.timeToFull ?? 0 : root.battery?.timeToEmpty ?? 0;
        if (seconds <= 0)
            return root.plugged ? "Plugged in" : "Estimating…";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return `${hours}h ${minutes}m ${root.charging ? "until full" : "remaining"}`;
    }

    icon: {
        const levels = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰂃", "󰁹"];
        return root.charging ? "󰢜" : root.plugged ? "󰚥" : levels[Math.min(10, Math.floor(root.percent / 10))];
    }
    // Graded states from waybar/CLAUDE.md: charging is informational, then
    // error < 10, warning <= 20, urgent-secondary for the 20-30 band. A
    // healthy discharging battery is the resting case and stays neutral.
    iconColor: root.charging ? Theme.accentInfo : root.percent <= 10 ? Theme.accentError : root.percent <= 20 ? Theme.accentWarning : root.percent <= 30 ? Theme.accentUrgentSecondary : root.restColor
    // The mockup tints the whole pill at critical, so the one number that
    // matters raises its voice without a second accent appearing on the bar.
    groundColor: root.percent <= 10 && !root.charging ? Qt.alpha(Theme.accentError, 0.14) : Theme.bgSecondary
    label: `${Math.round(root.percent)}%`
    // The glyph carries the state; the number stays readable.
    labelColor: root.percent <= 10 && !root.charging ? Theme.accentError : Theme.fgPrimary
    monoLabel: true
    pill: true
    tooltipText: root.battery ? root.tooltipLines() : ""
    visible: Config.isLaptop && root.battery !== null

    onClicked: Quickshell.execDetached([`${Config.scriptsDir}/desktop/battery-status`])
}
