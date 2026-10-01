pragma ComponentBehavior: Bound

import "../"
import "../../"
import Quickshell.Networking
import QtQuick

// Network popover, design page Shell-06-Popovers: the active route first, then
// known networks, then everything in range.
//
// 🚨 NO PASSWORD FIELD. `WifiNetwork.connectWithPsk()` exists and is
// deliberately not called: a shell that stores secrets badly is worse than one
// that does not, so an unknown network hands off to nm-connection-editor, which
// the footer names.
BarPopover {
    id: root

    // Same upstream qmltypes gap NetworkWidget documents: Networking records
    // this enum unqualified, so the linter cannot match it to the module's own
    // exported type.
    // qmllint disable unresolved-type
    readonly property NetworkDevice active: {
        const devices = Networking.devices.values;
        return devices.find(d => d.connected && d.type === DeviceType.Wifi) ?? devices.find(d => d.connected) ?? null;
    }
    readonly property bool isWifi: root.active?.type === DeviceType.Wifi
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    // qmllint enable unresolved-type
    // Known first, then the rest by signal: the design's order, minus the
    // active one, which is drawn on its own above the list.
    readonly property var networks: {
        const all = root.wifiDevice?.networks?.values ?? [];
        const rest = all.filter(n => !n.connected);
        return rest.slice().sort((a, b) => (b.known - a.known) || (b.signalStrength - a.signalStrength));
    }
    readonly property var connectedNetwork: root.isWifi ? root.active.networks.values.find(n => n.connected) ?? null : null
    // The connected row takes keyboard index 0 when there is one, so the list
    // below starts after it.
    readonly property int listOffset: root.connectedNetwork ? 1 : 0
    readonly property bool busy: (root.connectedNetwork?.stateChanging ?? false) || root.networks.some(n => n.stateChanging)

    function bars(strength: real): string {
        // 🚨 signalStrength is a 0..1 fraction, not the 0..100 nmcli prints.
        return Config.wifiGlyphs[Math.min(4, Math.floor((strength ?? 0) * 4))];
    }

    // A click on the connected network drops it; a click on any other joins it.
    function toggle(network: var): void {
        if (!network || network.stateChanging)
            return;
        if (network.connected) {
            network.disconnect();
            return;
        }
        // An unknown network needs credentials, which this surface does not
        // collect — the escape hatch is where that happens.
        if (!network.known) {
            root.runEscapeHatch();
            return;
        }
        // 🚨 `connect()`, not `connectWithSettings()`: the latter needs one of
        // `nmSettings` as its argument and returns silently on anything else,
        // so calling it bare connected nothing. `connect()` lets NetworkManager
        // pick the saved profile.
        network.connect();
    }

    footerCommand: ["nm-connection-editor"]
    footerLeft: root.keyboardMode ? qsTr("↑↓ move · ↵ connect / disconnect") : ""
    footerRight: "nm-connection-editor"
    glyph: root.active ? root.isWifi ? root.bars(root.connectedNetwork?.signalStrength ?? 0) : Config.wiredGlyph : Config.noNetworkGlyph
    navCount: root.listOffset + root.networks.length
    title: qsTr("Network")

    onActivated: index => {
        if (index < root.listOffset)
            root.toggle(root.connectedNetwork);
        else if (index - root.listOffset < root.networks.length)
            root.toggle(root.networks[index - root.listOffset]);
    }

    // Scanning costs power and is only worth it while the list is on screen —
    // the bar widget deliberately never turns it on.
    Binding {
        property: "scannerEnabled"
        target: root.wifiDevice
        value: root.shown
        when: root.wifiDevice !== null && root.isWifi
    }

    PopoverRow {
        glyph: root.isWifi ? root.bars(root.connectedNetwork?.signalStrength ?? 0) : Config.wiredGlyph
        label: root.isWifi ? root.connectedNetwork?.name ?? qsTr("Wireless") : qsTr("Wired")
        badge: root.active?.address ?? ""
        cursor: root.keyboardMode && root.listOffset === 1 && root.selected === 0
        // Only a wifi network can be dropped from here: a wired route has no
        // list to come back from, so its row stays inert.
        dimmed: root.busy && !(root.connectedNetwork?.stateChanging ?? false)
        selected: true
        showRing: cursor
        status: root.connectedNetwork?.stateChanging ? qsTr("disconnecting") : ""
        visible: root.active !== null

        onClicked: root.toggle(root.connectedNetwork)
    }

    PopoverRow {
        glyph: Config.noNetworkGlyph
        label: qsTr("No network")
        visible: root.active === null
    }

    Text {
        color: Theme.inkSecondary
        font.capitalization: Font.AllUppercase
        font.family: Config.terminalFont
        font.letterSpacing: 1
        font.pixelSize: Config.fontSection
        height: Config.menuSectionHeight
        text: qsTr("Networks")
        verticalAlignment: Text.AlignBottom
        visible: root.networks.length > 0
    }

    // The list is bounded by the chrome, not by a count: eight rows of 34 with
    // their gaps is exactly what popMaxH leaves, and a ninth scrolls.
    ListView {
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        currentIndex: root.selected - root.listOffset
        height: Math.min(contentHeight, root.bodyMaxHeight - Config.rowH * 2)
        model: root.networks
        width: parent.width

        delegate: PopoverRow {
            id: networkRow

            required property int index
            required property var modelData

            badge: networkRow.modelData.known ? qsTr("known") : ""
            cursor: root.keyboardMode && root.selected === root.listOffset + networkRow.index
            // Page 03: an operation in flight reports in the row that started
            // it and its SIBLINGS disable for the duration.
            dimmed: root.busy && !networkRow.modelData.stateChanging
            glyph: root.bars(networkRow.modelData.signalStrength)
            label: networkRow.modelData.name
            showRing: networkRow.cursor
            status: networkRow.modelData.stateChanging ? qsTr("connecting") : ""

            onClicked: root.toggle(networkRow.modelData)
        }
    }
}
