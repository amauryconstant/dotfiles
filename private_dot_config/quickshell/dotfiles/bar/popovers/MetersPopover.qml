import "../"
import "../../"
import QtQuick

// Meters popover, design page Shell-06-Popovers: CPU, memory, uptime.
//
// 🚨 Read-only, so it takes no grab worth trapping: navCount stays 0 and Tab is
// a no-op even when it was opened from the submap. Fills animate at motionFast,
// digits never.
//
// ponytail: no temperature row. Meters.qml records why — a temperature is not a
// percentage until someone names the hwmon path and the threshold it is a
// percentage OF. Add the row when a machine needs it.
BarPopover {
    id: root

    footerLeft: root.keyboardMode ? qsTr("esc close") : ""
    footerRight: "btop"
    footerCommand: [Config.terminal, "-e", "btop"]
    glyph: Config.meterGlyph
    title: qsTr("Meters")

    component MeterRow: Column {
        id: meterRow

        property string label: ""
        property int value: 0

        readonly property bool critical: meterRow.value >= Config.meterCriticalPercent
        readonly property bool warning: meterRow.value >= Config.meterWarnPercent

        spacing: Config.gap - 2
        width: parent ? parent.width : 0

        Item {
            height: Config.fontBody + 2
            width: parent.width

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.inkPrimary
                font.family: Config.guiFont
                font.pixelSize: Config.fontBody
                text: meterRow.label
            }

            // 🚨 The state is a WORD, not a hue on the digits. signalWarn
            // measures 2.05 in rose-pine-dawn and is banned as a graphic here,
            // and signalError as text is banned in every theme — so the band
            // says its own name and the number stays ink-primary.
            Text {
                anchors.right: readout.left
                anchors.rightMargin: Config.gap
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.inkSecondary
                font.family: Config.terminalFont
                font.pixelSize: Config.fontMeta
                text: meterRow.critical ? qsTr("critical") : meterRow.warning ? qsTr("warn") : ""
            }

            Text {
                id: readout

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.inkPrimary
                font.family: Config.terminalFont
                font.pixelSize: Config.fontBody
                text: `${meterRow.value}%`
            }
        }

        Rectangle {
            color: Theme.groundRaised
            height: Config.popSliderTrack
            radius: Config.radiusPill
            width: parent.width

            // The fill is the OSD's dimmed pair, not the design's fillInert:
            // fillInert is the tier that accepts nothing on top of it and
            // measures under the 3:1 a graphic owes on this ground. Critical
            // takes signalError, the one semantic role that clears 3:1 in all
            // eight colorsets.
            Rectangle {
                color: meterRow.critical ? Theme.signalError : Theme.inkSecondary
                height: parent.height
                radius: parent.radius
                width: Math.max(0, Math.min(100, meterRow.value)) / 100 * parent.width

                Behavior on width {
                    NumberAnimation {
                        duration: Config.motionFast
                    }
                }
            }
        }
    }

    MeterRow {
        label: qsTr("CPU")
        value: Meters.cpu
    }

    MeterRow {
        label: qsTr("Memory")
        value: Meters.memory
    }

    PopoverRow {
        glyph: "󰅐"
        badge: Meters.uptimeText()
        label: qsTr("Uptime")
    }
}
