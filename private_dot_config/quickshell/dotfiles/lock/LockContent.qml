import "../"
import Quickshell
import QtQuick

// What surface §22 draws, once per output. Design page 12: "deliberately almost
// nothing" — clock, date, one field, one line.
//
// 🚨 No notifications, no media, no battery, and nothing else that reads a
// state. A lock screen showing message previews unlocks the user's mail for
// anyone walking past, so the absence is the feature. Adding a widget here is a
// security change, not a layout change.
Item {
    id: root

    required property string failureMessage
    required property bool inputEnabled
    // Exactly one output carries the field; every other output is covered and
    // silent. Two password fields is two places to type a secret.
    required property bool promptVisible
    // Absolute path, or "" for no wallpaper — the surface's own colour then
    // stands in.
    required property string wallpaper

    signal submitted(password: string)

    // 🚨 The wallpaper is drawn, the desktop is NOT. A blurred screenshot is
    // what hyprlock showed here and it puts window shapes and colours in front
    // of whoever is at the machine; the wallpaper is already public, so it
    // costs nothing to show and leaks nothing. Design page 12's rule — a lock
    // screen that shows previews unlocks the user's mail for anyone walking
    // past — is about content, and a wallpaper is not content.
    Image {
        anchors.fill: parent
        asynchronous: true
        cache: false
        fillMode: Image.PreserveAspectCrop
        source: root.wallpaper === "" ? "" : `file://${root.wallpaper}`
        // Decode at the size actually drawn; a 4K wallpaper decoded full-size
        // stalls the surface at exactly the moment it has to appear.
        sourceSize.height: root.height
        sourceSize.width: root.width
        visible: root.wallpaper !== "" && this.status === Image.Ready
    }

    // The dim is what makes the text legible over an arbitrary image, so it is
    // a token rather than a literal: Config.lockDimOpacity is the knob.
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.scrim, Config.lockDimOpacity)
    }

    // The scrim is dark in all eight colorsets, so a light theme's own inks are
    // simply not on it. Everything here takes fgOnScrim and separates by size
    // and weight instead — the same ruling notification cards took, and the
    // reason the hint line is not design page 12's ink-secondary.
    Column {
        anchors.centerIn: parent
        spacing: Config.padLoose

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Config.gap

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.fgOnScrim
                font.family: Config.guiFont
                font.pixelSize: Config.lockClockSize
                font.weight: Font.DemiBold
                text: Qt.formatDateTime(clock.date, "HH:mm")
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.fgOnScrim
                font.family: Config.guiFont
                // Page 12's prose calls the date meta; its mockup draws it at
                // the body step. Both are read against the density scale, and
                // on a full-screen ground the meta step is not a quiet role,
                // it is an unreadable one. The date takes the display step the
                // clock used to have, which keeps the two a rank apart.
                font.pixelSize: Config.fontDisplay
                text: Qt.formatDateTime(clock.date, "dddd d MMMM")
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Config.gap
            visible: root.promptVisible
            width: Config.lockFieldWidth

            Rectangle {
                border.color: password.activeFocus ? Theme.focusRing : Theme.edge
                border.width: Config.hairline
                color: Theme.groundBase
                height: Config.lockFieldHeight
                radius: Config.radiusPanel
                width: parent.width

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Config.padTight
                    anchors.rightMargin: Config.padTight
                    spacing: Config.gap

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.inkSecondary
                        font.family: Config.guiFont
                        font.pixelSize: Config.glyphOsd
                        text: "󰀄"
                    }

                    TextInput {
                        id: password

                        clip: true
                        color: Theme.inkPrimary
                        // No reveal toggle, by design: the only thing it could
                        // reveal is a password on a screen anyone can see.
                        echoMode: TextInput.Password
                        enabled: root.inputEnabled
                        focus: true
                        font.family: Config.terminalFont
                        font.pixelSize: Config.fontDisplay
                        height: parent.height
                        selectedTextColor: Theme.inkOnSignal
                        selectionColor: Theme.signalFocus
                        verticalAlignment: TextInput.AlignVCenter
                        width: parent.width - parent.spacing - Config.glyphOsd

                        cursorDelegate: Rectangle {
                            color: Theme.signalFocus
                            width: 2
                        }

                        // 🚨 No Keys.onEscapePressed. Page 12: this is "the only
                        // surface with no Esc" — a lock a keystroke can dismiss
                        // is not a lock.
                        Keys.onEnterPressed: root.submitted(password.text)
                        Keys.onReturnPressed: root.submitted(password.text)
                    }
                }
            }

            // 🚨 The failure line is NOT signalError. Measured against the
            // scrim it lands at 3.87 (latte) and 3.84 (gruvbox-light), under
            // the 4.5 text owes -- so the words carry the failure alone, which
            // page 12 demands of the colour anyway ("paired with words, never
            // colour alone"). The pair is a row in lint:theme-contrast.
            Text {
                color: Theme.fgOnScrim
                font.family: Config.guiFont
                font.pixelSize: Config.fontTitle
                horizontalAlignment: Text.AlignHCenter
                text: root.failureMessage !== "" ? root.failureMessage : qsTr("Enter password to unlock")
                textFormat: Text.PlainText
                width: parent.width
                wrapMode: Text.WordWrap
            }
        }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    // 🚨 Focus is claimed on EVERY edge that can reach this surface, because the
    // failure mode of missing one is a locked session that swallows keystrokes
    // and can only be escaped from a TTY. onPromptVisibleChanged does not fire
    // for a surface constructed with the prompt already on it, which is the
    // ordinary case: the lock is taken before the content exists.
    //
    // 🚨 And the claim is DEFERRED, always. A child's Component.onCompleted runs
    // before its window exists: ProxyWindowBase reparents the content item into
    // the real QQuickWindow in completeWindow() (`window/proxywindow.cpp:242`),
    // which only runs when the SURFACE completes -- after every child of it.
    // forceActiveFocus() on a windowless item is silently dropped, and the lock
    // then comes up with the field unfocused and the first password typed into
    // nothing. Omarchy defers the same call for the same reason
    // (`shell/plugins/lock/LockView.qml`).
    function claimFocus(): void {
        if (root.promptVisible)
            password.forceActiveFocus();
    }

    Component.onCompleted: Qt.callLater(root.claimFocus)

    // A failure clears the field and puts the caret back in it; the message
    // stays until the next attempt replaces it.
    onFailureMessageChanged: {
        if (root.failureMessage === "")
            return;
        password.text = "";
        Qt.callLater(root.claimFocus);
    }
    onPromptVisibleChanged: {
        if (root.promptVisible)
            Qt.callLater(root.claimFocus);
        else
            password.text = "";
    }
}
