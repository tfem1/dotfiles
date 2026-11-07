pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// The network panel (SUPER + N): quick toggles for Wi-Fi, Bluetooth and
// airplane mode, then a Wi-Fi tab and a Bluetooth tab. Every color comes
// from the theme (module colors for Wi-Fi and Bluetooth), so it follows a
// theme change. Plain data in, requests out: NetworkPanel.qml connects it
// to Quickshell, the preview feeds it sample data.
Rectangle {
    id: panel

    property var wifi: ({ active: false, scanning: false, wired: "", connectivity: "full", networks: [] })
    property var bluetooth: ({ available: false, active: false, discovering: false, discoverable: false, name: "", devices: [] })
    property bool airplane: false
    property string tab: "wifi"
    signal wifiToggled(bool on)
    signal bluetoothToggled(bool on)
    signal airplaneToggled(bool on)
    signal scanRequested
    signal connectRequested(var ref, string password)
    signal disconnectRequested(var ref)
    signal forgetNetworkRequested(var ref)
    signal discoverRequested
    signal discoverableRequested(bool visible)
    signal deviceActivated(var ref, bool paired, bool connected)
    signal forgetDeviceRequested(var ref)
    signal closed

    readonly property var current: wifi.networks.find(network => network.connected)
    readonly property int connectedDevices: bluetooth.devices.filter(device => device.connected).length

    implicitWidth: 440
    implicitHeight: 600
    radius: Theme.radius + 8
    color: Theme.panel
    focus: true
    Keys.onEscapePressed: closed()

    // Keeps clicks inside the panel from closing it.
    MouseArea {
        anchors.fill: parent
    }

    Row {
        id: tiles
        x: 16
        y: 16
        width: parent.width - 32
        spacing: 8

        QuickTile {
            width: (tiles.width - 16) / 3
            icon: panel.wifi.active ? "wifi" : "wifi_off"
            title: "Wi-Fi"
            subtitle: !panel.wifi.active ? "Off" : panel.current ? panel.current.name : "Not connected"
            on: panel.wifi.active
            tint: Theme.modules.wifi
            onClicked: panel.wifiToggled(!panel.wifi.active)
        }
        QuickTile {
            width: (tiles.width - 16) / 3
            icon: !panel.bluetooth.active ? "bluetooth_disabled" : panel.connectedDevices ? "bluetooth_connected" : "bluetooth"
            title: "Bluetooth"
            subtitle: !panel.bluetooth.active ? "Off" : panel.connectedDevices ? panel.connectedDevices + " connected" : "On"
            on: panel.bluetooth.active
            tint: Theme.modules.bluetooth
            onClicked: panel.bluetoothToggled(!panel.bluetooth.active)
        }
        QuickTile {
            width: (tiles.width - 16) / 3
            icon: "airplanemode_active"
            title: "Airplane"
            subtitle: panel.airplane ? "On" : "Off"
            on: panel.airplane
            tint: Theme.accent
            onClicked: panel.airplaneToggled(!panel.airplane)
        }
    }

    // Tabs: the active one takes its module color.
    Rectangle {
        id: tabs
        anchors.top: tiles.bottom
        anchors.topMargin: 14
        x: 16
        width: parent.width - 32
        height: 40
        radius: 20
        color: Theme.bgAlt

        Row {
            anchors.fill: parent
            anchors.margins: 4

            Repeater {
                model: [["wifi", "Wi-Fi", "wifi"], ["bluetooth", "Bluetooth", "bluetooth"]]

                Rectangle {
                    id: tabButton
                    required property var modelData
                    readonly property bool selected: panel.tab === modelData[0]
                    readonly property color tint: modelData[0] === "wifi" ? Theme.modules.wifi : Theme.modules.bluetooth
                    width: (tabs.width - 8) / 2
                    height: parent.height
                    radius: height / 2
                    color: selected ? Qt.alpha(tint, 0.22) : "transparent"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: tabButton.modelData[2]
                            color: tabButton.selected ? tabButton.tint : Theme.subtle
                            size: 18
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tabButton.modelData[1]
                            color: tabButton.selected ? Theme.fgBright : Theme.subtle
                            font.weight: Font.DemiBold
                        }
                    }
                    TapHandler { onTapped: panel.tab = tabButton.modelData[0] }
                }
            }
        }
    }

    WifiPage {
        id: wifiPage
        anchors.top: tabs.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        x: 10
        width: parent.width - 20
        visible: panel.tab === "wifi"
        active: panel.wifi.active
        scanning: panel.wifi.scanning
        wired: panel.wifi.wired
        connectivity: panel.wifi.connectivity
        networks: panel.wifi.networks
        onEnableRequested: panel.wifiToggled(true)
        onScanRequested: panel.scanRequested()
        onConnectRequested: (ref, password) => panel.connectRequested(ref, password)
        onDisconnectRequested: ref => panel.disconnectRequested(ref)
        onForgetRequested: ref => panel.forgetNetworkRequested(ref)
    }

    BluetoothPage {
        id: bluetoothPage
        anchors.fill: wifiPage
        visible: panel.tab === "bluetooth"
        available: panel.bluetooth.available
        active: panel.bluetooth.active
        discovering: panel.bluetooth.discovering
        discoverable: panel.bluetooth.discoverable
        name: panel.bluetooth.name
        devices: panel.bluetooth.devices
        onEnableRequested: panel.bluetoothToggled(true)
        onDiscoverRequested: panel.discoverRequested()
        onDiscoverableRequested: visible => panel.discoverableRequested(visible)
        onDeviceActivated: (ref, paired, connected) => panel.deviceActivated(ref, paired, connected)
        onForgetRequested: ref => panel.forgetDeviceRequested(ref)
    }
}
