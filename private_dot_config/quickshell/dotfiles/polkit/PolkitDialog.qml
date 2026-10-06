pragma ComponentBehavior: Bound

import "../"
import "../bar"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

// Surface §21 — the authentication dialog. Raised by the SYSTEM, not the user:
// it has no toggle and no IPC target, and its visibility is the agent's
// isActive and nothing else.
//
// 🚨 CONSTRUCTING PolkitAgent is what registers the agent, and a session may
// have exactly one. So the only way not to own polkit is not to construct it,
// which is why this whole window sits behind a Loader on Config.polkitOwned in
// shell.qml — the same shape, for the same reason, as NotificationServer.
// With the flag off, hypr/conf.d/polkit-gnome deploys instead and that agent
// keeps the session.
//
// 🚨 This surface is why the shell had to be supervised first. A crashed agent
// leaves the session with NONE, and every privileged action then fails with no
// prompt. quickshell.service (Restart=always) is what makes that a 2s gap
// rather than a dead desktop; the inventory deferred this entry until it existed.
PanelWindow {
    id: root

    // AuthFlow is not exported as a QML element in 0.3.1, so qmllint cannot
    // resolve the type of the property it is reached through. Upstream gap,
    // same class as DBusMenuHandle -- see .claude/rules/quickshell-qml.md.
    // qmllint disable unresolved-type
    readonly property var flow: agent.flow
    // qmllint enable unresolved-type
    // A group entity has no password of its own; polkit is asking which member
    // to authenticate as, and a group row would be unauthenticatable.
    readonly property var identities: root.flow ? root.flow.identities.filter(i => !i.isGroup) : []

    function cancel(): void {
        if (root.flow)
            root.flow.cancelAuthenticationRequest();
    }

    // The identity choice §21 names as "a real branch the current drawings
    // assume away". pkexec on a machine with several admins asks it every time.
    function cycleIdentity(step: int): void {
        if (root.identities.length < 2)
            return;
        const at = root.identities.indexOf(root.flow.selectedIdentity);
        const next = (at + step + root.identities.length) % root.identities.length;
        root.flow.selectedIdentity = root.identities[next];
    }

    function submit(): void {
        if (!root.flow || !root.flow.isResponseRequired)
            return;
        root.flow.submit(password.text);
        password.text = "";
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    visible: agent.isActive

    // qmllint disable unqualified unresolved-type
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    anchors.top: true
    // qmllint enable unqualified unresolved-type

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.layer: WlrLayer.Overlay

    // An interrupt takes the keyboard the moment it arrives, and the field it
    // takes it for is the password one — anything else loses the first
    // keystrokes of a password the user has already started typing.
    onVisibleChanged: {
        if (root.visible)
            password.forceActiveFocus();
        else
            password.text = "";
    }

    PolkitAgent {
        id: agent

        // `path` is deliberately unset: the default /org/quickshell/Polkit is
        // as good as any, and naming one here would only invite it to drift
        // from whatever the running binary defaults to.
    }

    // A fresh session is started for us after a failure, so the dialog stays up
    // and only the field is cleared. Nothing here destroys the flow.
    Connections {
        function onAuthenticationFailed(): void {
            password.text = "";
            password.forceActiveFocus();
        }

        target: root.flow
    }

    // 🚨 Theme.scrim, not a ground token: groundBase measures 0.71-0.96
    // luminance in the four light colorsets, so a wash built from it renders
    // near-white. Everything drawn straight onto it takes fgOnScrim.
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.scrim, Config.scrimOpacity)

        // Swallows clicks outside the panel WITHOUT dismissing. An interrupt
        // cannot be dismissed by looking away — cancelling is a decision, so it
        // costs Escape or the Cancel button.
        MouseArea {
            anchors.fill: parent
        }
    }

    Rectangle {
        anchors.centerIn: parent
        border.color: Theme.edge
        border.width: Config.hairline
        color: Theme.groundBase
        implicitHeight: layout.implicitHeight + Config.padLoose * 2
        radius: Config.radiusPanel
        width: Config.polkitDialogWidth

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: layout

            anchors.centerIn: parent
            spacing: Config.pad
            width: parent.width - Config.padLoose * 2

            // Header: what is being authorised, and who is asking.
            Row {
                spacing: Config.padTight
                width: parent.width

                IconImage {
                    id: appIcon

                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: Config.glyphTile
                    source: root.flow?.iconName ? Quickshell.iconPath(root.flow.iconName, true) : ""
                    visible: appIcon.source !== ""
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.inkPrimary
                    font.family: Config.guiFont
                    font.pixelSize: Config.fontTitle
                    // Verbatim from polkit. §21: "every failure state has text
                    // the surface must show verbatim from the system" — the
                    // same applies to the action description.
                    text: root.flow?.message ?? ""
                    textFormat: Text.PlainText
                    width: parent.width - (appIcon.visible ? appIcon.width + Config.padTight : 0)
                    wrapMode: Text.WordWrap
                }
            }

            // The action id. Meta, in the terminal face: it is an identifier
            // rather than prose, and it is what a user checks when the message
            // is vaguer than the thing it is about to do.
            Text {
                color: Theme.inkSecondary
                elide: Text.ElideMiddle
                font.family: Config.terminalFont
                font.pixelSize: Config.fontMeta
                text: root.flow?.actionId ?? ""
                textFormat: Text.PlainText
                width: parent.width
            }

            // Identity chips. Collapsed entirely at one identity, which is the
            // ordinary case — a selector with a single option is noise.
            Row {
                spacing: Config.gap
                visible: root.identities.length > 1
                width: parent.width

                Repeater {
                    model: root.identities

                    delegate: Rectangle {
                        id: chip

                        required property var modelData
                        readonly property bool current: root.flow?.selectedIdentity === chip.modelData

                        border.color: chip.current ? Theme.signalFocus : Theme.edge
                        border.width: Config.hairline
                        color: chip.current ? Theme.select : "transparent"
                        implicitWidth: chipLabel.implicitWidth + Config.padTight * 2
                        height: Config.pillHeight
                        radius: Config.radiusPill

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                root.flow.selectedIdentity = chip.modelData;
                                password.forceActiveFocus();
                            }
                        }

                        Text {
                            id: chipLabel

                            anchors.centerIn: parent
                            // The accent marks the selection; the tint alone
                            // reaches 1.10-1.98, so it never carries the state
                            // on its own.
                            color: chip.current ? Theme.inkPrimary : Theme.inkSecondary
                            font.family: Config.guiFont
                            font.pixelSize: Config.fontMeta
                            text: chip.modelData.displayName || chip.modelData.string
                            textFormat: Text.PlainText
                        }
                    }
                }
            }

            // The password field. echoMode follows the request: PAM says
            // whether the typed value may be shown, and a second factor read
            // off a token often may be.
            Rectangle {
                border.color: password.activeFocus ? Theme.signalFocus : Theme.edge
                border.width: Config.hairline
                color: Theme.groundRaised
                height: Config.rowH
                radius: Config.radiusChip
                width: parent.width

                TextInput {
                    id: password

                    anchors.fill: parent
                    anchors.leftMargin: Config.padTight
                    anchors.rightMargin: Config.padTight
                    clip: true
                    color: Theme.inkPrimary
                    echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                    enabled: root.flow?.isResponseRequired ?? false
                    focus: true
                    font.family: Config.guiFont
                    font.pixelSize: Config.fontBody
                    selectedTextColor: Theme.inkOnAction
                    selectionColor: Theme.action
                    verticalAlignment: TextInput.AlignVCenter

                    cursorDelegate: Rectangle {
                        color: Theme.signalFocus
                        width: 2
                    }

                    Keys.onEnterPressed: root.submit()
                    // Escape is the cancel, so the method cannot be named
                    // escape(): "Illegal method name" is a LOAD-time failure
                    // that qmllint passes clean.
                    Keys.onEscapePressed: root.cancel()
                    Keys.onReturnPressed: root.submit()
                    Keys.onTabPressed: root.cycleIdentity(1)
                    Keys.onBacktabPressed: root.cycleIdentity(-1)

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.inkSecondary
                        font.family: Config.guiFont
                        font.pixelSize: Config.fontBody
                        text: root.flow?.inputPrompt || qsTr("Password")
                        textFormat: Text.PlainText
                        visible: password.text === "" && !password.activeFocus
                    }
                }
            }

            // Feedback. Verbatim, always — a wrong-password message, a
            // remaining-attempts count and a second-factor instruction all
            // arrive through this one property and none of them may be
            // paraphrased.
            //
            // signalError is the ONLY semantic colour that clears 3:1 in all
            // eight colorsets; a non-error supplementary message stays neutral
            // rather than borrowing signalInfo, which lands at 2.80 in the
            // light sets.
            Text {
                color: root.flow?.supplementaryIsError ? Theme.signalError : Theme.inkSecondary
                font.family: Config.guiFont
                font.pixelSize: Config.fontMeta
                text: root.flow?.supplementaryMessage ?? ""
                textFormat: Text.PlainText
                visible: text !== ""
                width: parent.width
                wrapMode: Text.WordWrap
            }

            Text {
                color: Theme.inkSecondary
                font.family: Config.guiFont
                font.pixelSize: Config.fontMeta
                text: root.identities.length > 1 ? qsTr("Return authenticate · Tab identity · Esc cancel") : qsTr("Return authenticate · Esc cancel")
                width: parent.width
            }

            // The pointer route to both decisions. Until these existed the
            // dialog was keyboard-only, and a hint line naming keys is not a
            // control. MouseArea takes no focus, so the field keeps it.
            Row {
                anchors.right: parent.right
                spacing: Config.gap

                ActionButton {
                    emphasis: "neutral"
                    text: qsTr("Cancel")

                    onActivated: root.cancel()
                }

                ActionButton {
                    emphasis: "primary"
                    text: qsTr("Authenticate")

                    onActivated: root.submit()
                }
            }
        }
    }
}
