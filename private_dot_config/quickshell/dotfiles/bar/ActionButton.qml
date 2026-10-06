import "../"
import QtQuick

// The one push button: a notification's actions, the centre's Clear and DND,
// the polkit dialog's Cancel and Authenticate. Every button in the tree is
// this file; none is hand-rolled from a Rectangle.
//
// Three emphases, and colour is what separates them:
//   primary   — Theme.action fill, inkOnAction label. The one thing the
//               surface is asking you to do.
//   secondary — Theme.action outline AND label. Something else you can do.
//   neutral   — inkSecondary outline, inkPrimary label. Ours, not the
//               sender's: Dismiss, Cancel, Clear. Grey means "go away".
// Theme.action is the accent SOLVED per theme to clear 4.5 as text on both
// grounds a button sits on — see its comment in Theme.qml.
//
// 🚨 A control's BOUNDARY owes 3:1 against the ground it sits on, and a
// ground-tier step never supplies it. The notification primary used to be
// groundRaised on the card's groundFloat: 1.00:1 in five of the eight
// colorsets (both gruvbox, rose-pine-dawn, both solarized) and 1.27 at best in
// latte. It had no edge at all, sat beside 3:1 outlines, and read as the
// DISABLED button rather than the primary one. groundRaised is also
// Theme.hover, so at rest it looked like a hovered button.
Rectangle {
    id: root

    property string text: ""
    // A glyph instead of a word: drawn at glyphRow, and the button is square.
    property string glyph: ""
    // "primary" | "secondary" | "neutral"
    property string emphasis: "secondary"

    signal activated

    readonly property bool primary: root.emphasis === "primary"
    readonly property color ink: root.primary ? Theme.inkOnAction : root.emphasis === "secondary" ? Theme.action : Theme.inkPrimary

    border.color: root.primary ? "transparent" : root.emphasis === "secondary" ? Theme.action : Theme.inkSecondary
    border.width: root.primary ? 0 : Config.hairline
    color: root.primary ? Theme.action : "transparent"
    implicitHeight: Config.buttonHeight
    implicitWidth: root.glyph !== "" ? Config.buttonHeight : label.implicitWidth + Config.padLoose
    radius: Config.radiusChip

    // Hover and press tint the button in its OWN ink. Theme.press is inkPrimary
    // and would vanish on a fill of the same lightness. Colour only, so not
    // animated.
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(root.ink, mouse.pressed ? Theme.pressAlpha * 2 : Theme.pressAlpha)
        radius: root.radius
        visible: mouse.containsMouse
    }

    Text {
        id: label

        anchors.centerIn: parent
        color: root.ink
        font.family: Config.guiFont
        font.pixelSize: root.glyph !== "" ? Config.glyphRow : Config.fontBody
        font.weight: Font.Medium
        text: root.glyph !== "" ? root.glyph : root.text
        // A sender's action label is foreign text.
        textFormat: Text.PlainText
    }

    MouseArea {
        id: mouse

        // The paint is buttonHeight; the pointer claim is hitMin.
        anchors.bottomMargin: -Math.max(0, (Config.hitMin - root.height) / 2)
        anchors.fill: parent
        anchors.topMargin: -Math.max(0, (Config.hitMin - root.height) / 2)
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: root.activated()
    }
}
