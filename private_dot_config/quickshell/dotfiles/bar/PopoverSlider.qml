import "../"
import QtQuick

// The slider — the only place in the shell where drag and the wheel both exist
// (design page Shell-06-Popovers). The percentage lives in the row label above
// it, never on the thumb, so it can never occlude the value it reports.
//
// 🚨 The fill is `signalFocus` on a `groundRaised` track, NOT the design's
// `fillInert` on `groundRaised`: that pair measures about 1.3:1 in Mocha
// (#45475a on #313244) against page 13's own 3:1 graphic floor. Same ruling
// already taken for the OSD, see osd/Osd.qml.
//
// 🚨 The thumb's hairline is `Theme.edge`, not the design's `accent-border`:
// that token was deleted from all eight colorsets on 2026-09-09 for having no
// consumer, and page 13 itself lists it as compositor decoration measured only
// so nobody re-adopts it.
Item {
    id: root

    property bool showRing: false
    property real step: Config.volumeStep
    // 0..1, like every audio and backlight value in this tree.
    property real value: 0

    signal moved(real value)

    function setFromX(x: real): void {
        root.moved(Math.max(0, Math.min(1, (x - Config.popSliderThumb / 2) / Math.max(1, track.width))));
    }

    // Tall enough for the ring, which sits OUTSIDE the thumb: the body clips,
    // so a ring drawn past this height would be cut rather than drawn.
    height: Config.popSliderThumb + Config.popRingWidth * 4
    implicitHeight: Config.popSliderThumb + Config.popRingWidth * 4
    width: parent ? parent.width : 0

    Rectangle {
        id: track

        anchors.left: parent.left
        anchors.leftMargin: Config.popSliderThumb / 2
        anchors.right: parent.right
        anchors.rightMargin: Config.popSliderThumb / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.groundRaised
        height: Config.popSliderTrack
        radius: Config.radiusPill

        Rectangle {
            color: Theme.signalFocus
            height: parent.height
            radius: parent.radius
            width: Math.max(0, Math.min(1, root.value)) * parent.width

            Behavior on width {
                NumberAnimation {
                    duration: Config.motionFast
                }
            }
        }
    }

    Rectangle {
        id: thumb

        border.color: Theme.edge
        border.width: Config.hairline
        color: Theme.signalFocus
        height: Config.popSliderThumb
        radius: Config.radiusPill
        width: Config.popSliderThumb
        x: Math.max(0, Math.min(1, root.value)) * track.width
        y: (parent.height - height) / 2

        Behavior on x {
            NumberAnimation {
                duration: Config.motionFast
            }
        }
    }

    // The ring is two bands: the popover's own ground first, then the ring
    // itself, so an accent thumb inside an accent ring still reads as two
    // things. Never animated, and it follows the thumb without a Behavior of
    // its own — anchoring to the thumb inherits the thumb's.
    Rectangle {
        anchors.centerIn: thumb
        border.color: Theme.groundBase
        border.width: Config.popRingWidth
        color: "transparent"
        height: width
        radius: Config.radiusPill
        visible: root.showRing
        width: thumb.width + Config.popRingWidth * 2

        Rectangle {
            anchors.centerIn: parent
            border.color: Theme.focusRing
            border.width: Config.popRingWidth
            color: "transparent"
            height: width
            radius: Config.radiusPill
            width: parent.width + Config.popRingWidth * 2
        }
    }

    // A click on the track JUMPS to that position rather than nudging — a jump
    // is what the click means. Drag moves continuously; the wheel steps by the
    // same increment the compositor bindings use, and fires the OSD as a
    // binding would, because the value changing is the same event either way.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: false

        onPositionChanged: event => {
            if (pressed)
                root.setFromX(event.x);
        }
        onPressed: event => root.setFromX(event.x)
        onWheel: event => {
            if (event.angleDelta.y > 0)
                root.moved(Math.min(1, root.value + root.step));
            else if (event.angleDelta.y < 0)
                root.moved(Math.max(0, root.value - root.step));
        }
    }
}
