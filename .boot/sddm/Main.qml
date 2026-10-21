import QtQuick

// The login screen, drawn like lock/LockContent.qml: wallpaper, black scrim,
// clock, date, one field, one line. Colours and geometry arrive through
// theme.conf (config.*), because the greeter cannot import the Quickshell
// Theme/Config singletons and runs as the sddm user.
//
// 🚨 Keep in step with LockContent.qml by hand. A failed login clears the field
// and keeps the message until the next attempt, same as the lock.
Rectangle {
    id: root

    readonly property real dim: Number(config.dimOpacity)
    // The geometry is the lock's, drawn for a 1080p panel. The greeter runs
    // unscaled (X11, no HiDPI), so it scales by screen height - 1x at 1080p, 2x at
    // 4K - and by uiScale, the one knob (globals.boot.greeterScale) for "bigger".
    readonly property real scale: Math.max(1, root.height / 1080) * Number(config.uiScale)
    property bool busy: false
    property string message: ""
    property date now: new Date()

    color: config.groundBase
    height: 1080
    width: 1920

    Image {
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: config.background === "" ? "" : Qt.resolvedUrl(config.background)
        visible: config.background !== ""
    }

    // The scrim is a literal black, like Theme.scrim.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, root.dim)
    }

    // A click anywhere claims the field (the field's own hit target is smaller
    // than the box the user aims at).
    MouseArea {
        anchors.fill: parent

        onClicked: password.forceActiveFocus()
    }

    Timer {
        interval: 1000
        repeat: true
        running: true

        onTriggered: root.now = new Date()
    }

    Column {
        anchors.centerIn: parent
        spacing: root.px(Number(config.padLoose))

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.px(Number(config.gap))

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: config.inkPrimary
                font.family: config.guiFont
                font.pixelSize: root.px(Number(config.lockClockSize))
                font.weight: Font.DemiBold
                text: Qt.formatDateTime(root.now, "HH:mm")
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: config.inkPrimary
                font.family: config.guiFont
                font.pixelSize: root.px(Number(config.fontDisplay))
                text: Qt.formatDateTime(root.now, "dddd d MMMM")
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.px(Number(config.gap))
            width: root.px(Number(config.lockFieldWidth))

            Rectangle {
                border.color: password.activeFocus ? config.signalFocus : config.groundRaised
                border.width: root.px(Number(config.hairline))
                color: config.groundBase
                height: root.px(Number(config.lockFieldHeight))
                radius: root.px(Number(config.radiusPanel))
                width: parent.width

                TextInput {
                    id: password

                    anchors.fill: parent
                    anchors.leftMargin: root.px(Number(config.padTight))
                    anchors.rightMargin: root.px(Number(config.padTight))
                    clip: true
                    color: config.inkPrimary
                    echoMode: TextInput.Password
                    focus: true
                    font.family: config.terminalFont
                    font.pixelSize: root.px(Number(config.fontDisplay))
                    readOnly: root.busy
                    selectedTextColor: config.groundBase
                    selectionColor: config.signalFocus
                    verticalAlignment: TextInput.AlignVCenter

                    cursorDelegate: Rectangle {
                        color: config.signalFocus
                        width: root.px(2)
                    }

                    Keys.onEnterPressed: root.submit()
                    Keys.onReturnPressed: root.submit()
                }
            }

            // The user is named under the field: unlike the lock, nobody is
            // signed in yet. Clicking it steps to the next account.
            Text {
                color: config.inkPrimary
                font.family: config.guiFont
                font.pixelSize: root.px((Number(config.fontTitle) + Number(config.fontDisplay)) / 2)
                horizontalAlignment: Text.AlignHCenter
                text: root.message !== "" ? root.message : qsTr("Enter password to log in as %1").arg(root.user)
                textFormat: Text.PlainText
                width: parent.width
                wrapMode: Text.WordWrap

                MouseArea {
                    anchors.fill: parent

                    onClicked: root.nextUser()
                }
            }
        }
    }

    property int userIndex: userModel.lastIndex
    readonly property string user: userModel.count > 0 ? userModel.data(userModel.index(root.userIndex, 0), Qt.UserRole + 1) : userModel.lastUser

    function px(n: real): int {
        return Math.max(1, Math.round(n * root.scale));
    }

    function nextUser(): void {
        if (userModel.count > 1)
            root.userIndex = (root.userIndex + 1) % userModel.count;
    }

    function submit(): void {
        if (root.busy || password.text === "")
            return;
        root.busy = true;
        sddm.login(root.user, password.text, sessionModel.lastIndex);
    }

    Connections {
        target: sddm

        function onLoginFailed(): void {
            root.busy = false;
            root.message = qsTr("Wrong password");
            password.text = "";
            password.forceActiveFocus();
        }

        function onLoginSucceeded(): void {
            root.message = "";
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
