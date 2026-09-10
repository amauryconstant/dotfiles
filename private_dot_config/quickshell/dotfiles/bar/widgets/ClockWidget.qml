import "../"
import "../../"
import Quickshell
import QtQuick

// Waybar's clock: `{:%A %e %b. %Y - %H:%M}` with a calendar tooltip.
//
// Deliberate deviation from strict parity: Waybar's `format-alt` turned the
// bar text itself into a monospace calendar block on click. That is a Waybar
// workaround for having nowhere else to put it — here the calendar lives in
// the tooltip, where Waybar's own default also puts it, so click is free.
//
// The time renders in terminalFont, not guiFont. Not a design adoption: a
// proportional face changes width as the digits change, so the centre zone
// reflowed on every minute tick.
BarWidget {
    id: root

    signal popoverRequested

    hoverBackground: false
    tooltipMonospace: true
    // Only bind while hovered: rebuilding the grid on every minute tick when
    // nobody is looking is pure waste.
    tooltipText: root.hovered ? root.monthGrid(clock.date) : ""

    onClicked: root.popoverRequested()

    function monthGrid(now: date): string {
        const year = now.getFullYear();
        const month = now.getMonth();
        const first = new Date(year, month, 1);
        const days = new Date(year, month + 1, 0).getDate();
        const locale = Qt.locale();

        // Monday-first, matching the system locale convention here.
        let offset = (first.getDay() + 6) % 7;
        let out = `${locale.standaloneMonthName(month)} ${year}\nMo Tu We Th Fr Sa Su\n`;
        let line = "   ".repeat(offset);

        for (let day = 1; day <= days; day++) {
            line += String(day).padStart(2, " ") + " ";
            if (++offset % 7 === 0) {
                out += line.replace(/\s+$/, "") + "\n";
                line = "";
            }
        }
        return (out + line).replace(/\s+$/, "");
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.inkPrimary
        font.family: Config.terminalFont
        font.pixelSize: Config.fontTitle
        text: Qt.formatDateTime(clock.date, "HH:mm")
    }

    Text {
        id: date

        anchors.verticalCenter: parent.verticalCenter
        color: Theme.inkSecondary
        font.family: Config.guiFont
        font.pixelSize: Config.fontBody
        text: Qt.formatDateTime(clock.date, "ddd d MMM")
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }
}
