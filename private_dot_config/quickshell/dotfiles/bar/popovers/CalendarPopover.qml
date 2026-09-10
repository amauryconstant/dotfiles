pragma ComponentBehavior: Bound

import "../"
import "../../"
import Quickshell
import QtQuick

// Calendar popover, design page Shell-06-Popovers: month grid, today marked, no
// events. It reads no calendar source, so nothing here is clickable — the only
// interaction is the keyboard cursor, and only when the popover was opened from
// the submap.
//
// 🚨 Today is an accent fill PLUS a weight change, and the date number is what
// carries it (L3). The cursor is the ring; the two can sit on the same day.
BarPopover {
    id: root

    // The month being shown. Paging moves it; it resets to the real month
    // every time the popover opens, because a calendar that remembers where you
    // left it a week ago is lying about "today".
    property date shownMonth: new Date()
    // Day-of-month the keyboard cursor is on, or 0 for none.
    property int cursorDay: 0

    readonly property int daysInMonth: new Date(root.shownMonth.getFullYear(), root.shownMonth.getMonth() + 1, 0).getDate()
    // Monday-first, matching the system locale convention here and the grid
    // ClockWidget's tooltip already draws.
    readonly property int leading: (new Date(root.shownMonth.getFullYear(), root.shownMonth.getMonth(), 1).getDay() + 6) % 7
    readonly property date today: clock.date

    function isToday(day: int): bool {
        return day === root.today.getDate() && root.shownMonth.getMonth() === root.today.getMonth() && root.shownMonth.getFullYear() === root.today.getFullYear();
    }

    function shiftDays(delta: int): void {
        const at = new Date(root.shownMonth.getFullYear(), root.shownMonth.getMonth(), Math.max(1, root.cursorDay) + delta);
        root.shownMonth = at;
        root.cursorDay = at.getDate();
    }

    function shiftMonths(delta: int): void {
        const at = new Date(root.shownMonth.getFullYear(), root.shownMonth.getMonth() + delta, 1);
        root.shownMonth = at;
        root.cursorDay = Math.min(root.cursorDay, new Date(at.getFullYear(), at.getMonth() + 1, 0).getDate());
    }

    footerLeft: root.keyboardMode ? qsTr("←→ day · PgUp/PgDn month") : ""
    footerRight: Qt.formatDateTime(root.today, "ddd d MMM yyyy")
    glyph: "󰃭"
    title: `${Qt.locale().standaloneMonthName(root.shownMonth.getMonth())} ${root.shownMonth.getFullYear()}`

    // Arrows move by day and PgUp/PgDn by month, per the design. Up and Down
    // move a whole week, which is what a grid means by "up".
    onMoved: delta => root.shiftDays(delta * 7)
    onPaged: delta => root.shiftMonths(delta)
    onStepped: delta => root.shiftDays(delta)
    onVisibleChanged: {
        if (root.visible) {
            root.shownMonth = clock.date;
            root.cursorDay = root.keyboardMode ? clock.date.getDate() : 0;
        }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Grid {
        columns: 7
        spacing: 0
        width: parent.width

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

            Text {
                id: weekday

                required property string modelData

                color: Theme.inkSecondary
                font.capitalization: Font.AllUppercase
                font.family: Config.terminalFont
                font.pixelSize: Config.fontSection
                height: Config.menuSectionHeight
                horizontalAlignment: Text.AlignHCenter
                text: weekday.modelData
                verticalAlignment: Text.AlignVCenter
                width: parent.width / 7
            }
        }

        // The leading blanks are Items rather than empty Texts: a blank cell has
        // nothing to render and no state to carry.
        Repeater {
            model: root.leading

            Item {
                height: Config.rowH
                width: parent.width / 7
            }
        }

        Repeater {
            model: root.daysInMonth

            Item {
                id: cell

                required property int index

                readonly property int day: cell.index + 1
                readonly property bool cursor: root.keyboardMode && root.cursorDay === cell.day
                readonly property bool today: root.isToday(cell.day)

                height: Config.rowH
                width: parent.width / 7

                Rectangle {
                    anchors.centerIn: parent
                    border.color: cell.cursor ? Theme.focusRing : "transparent"
                    border.width: cell.cursor ? Config.popRingWidth : 0
                    color: cell.today ? Theme.signalFocus : "transparent"
                    height: Config.pillHeight
                    radius: Config.radiusPill
                    width: Config.pillHeight + Config.gap
                }

                Text {
                    anchors.centerIn: parent
                    // 🚨 inkOnSignal, never a raw ink: a signal fill is the one
                    // ground where the readable foreground is computed per
                    // theme rather than bound.
                    color: cell.today ? Theme.inkOnSignal : Theme.inkPrimary
                    font.family: Config.terminalFont
                    font.pixelSize: Config.fontBody
                    font.weight: cell.today ? Font.DemiBold : Font.Normal
                    text: cell.day
                }
            }
        }
    }
}
