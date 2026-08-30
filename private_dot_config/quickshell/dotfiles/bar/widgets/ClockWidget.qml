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
BarWidget {
    id: root

    // Only bind while hovered: rebuilding the grid on every minute tick when
    // nobody is looking is pure waste.
    tooltipMonospace: true
    tooltipText: root.hovered ? root.monthGrid(clock.date) : ""

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
        color: Theme.accentPrimary
        font.family: Config.guiFont
        font.pixelSize: Config.fontSize
        text: Qt.formatDateTime(clock.date, "dddd d MMM. yyyy - HH:mm")
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }
}
