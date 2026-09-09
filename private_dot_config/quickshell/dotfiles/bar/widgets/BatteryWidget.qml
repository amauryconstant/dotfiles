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
    // 🚨 The battery carries SHAPE: an eleven-step level glyph plus a distinct
    // charging glyph and a distinct plugged one. Colour fires exactly once, at
    // signalError, because it is the only semantic role that clears 3:1 on a
    // light ground in all eight colorsets — signalWarn measures 2.05 in
    // rose-pine-dawn and 2.19 in gruvbox-light, so the 20-30% band it used to
    // carry was a colour nobody could see. The bands still exist; they are
    // expressed by the glyph and, at critical, by the pill's own tint.
    iconColor: root.percent <= 10 && !root.charging ? Theme.signalError : root.restColor
    // The mockup tints the whole pill at critical, so the one number that
    // matters raises its voice without a second accent appearing on the bar.
    groundColor: root.percent <= 10 && !root.charging ? Qt.alpha(Theme.signalError, 0.14) : Theme.groundRaised
    label: `${Math.round(root.percent)}%`
    // The glyph and the tint carry the state; the number stays readable.
    // signalError as TEXT is banned in every theme (2.81 at worst), and this is
    // the number that most has to be legible when it is low.
    labelColor: root.restColor
    monoLabel: true
    pill: true
    tooltipText: root.battery ? root.tooltipLines() : ""
    visible: Config.isLaptop && root.battery !== null

    onClicked: Quickshell.execDetached([`${Config.scriptsDir}/desktop/battery-status`])
}
