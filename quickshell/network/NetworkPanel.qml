import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import "../overlay"
import "kinds.js" as Kinds

// Connects the network panel to Quickshell (NetworkManager and BlueZ).
// Scans are short: Wi-Fi for a few seconds when the tab shows, Bluetooth
// for 20 seconds when asked; nothing runs while the panel is closed.
Scope {
    id: root

    property bool open: false
    property string tab: "wifi"
    property var failures: ({})        // network name or device address -> reason
    property var pendingNetwork: null  // last network asked to connect
    property var pendingDevice: null   // last device asked to pair

    readonly property var devices: Networking.devices.values
    readonly property var wifiDevice: root.devices.find(device => device.type === DeviceType.Wifi) || null
    readonly property var wiredDevice: root.devices.find(device => device.type === DeviceType.Wired && device.connected) || null
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool airplane: !Networking.wifiEnabled && !(root.adapter && root.adapter.enabled)

    // Password networks (WPA, WPA2, WPA3 personal), company logins, open networks.
    readonly property var personal: [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae]
    readonly property var company: [WifiSecurityType.WpaEap, WifiSecurityType.Wpa2Eap, WifiSecurityType.Wpa3SuiteB192]
    readonly property var unlocked: [WifiSecurityType.Open, WifiSecurityType.Owe]

    function toggle() {
        open = !open;
    }

    function show(page) {
        tab = page;
        open = true;
    }

    function fail(key, reason) {
        const all = Object.assign({}, failures);
        all[key] = reason;
        failures = all;
    }

    function clear(key) {
        const all = Object.assign({}, failures);
        delete all[key];
        failures = all;
    }

    function connectNetwork(network, password) {
        clear(network.name);
        pendingNetwork = network;
        if (company.includes(network.security) && !network.known)
            fail(network.name, "enterprise");
        else if (password)
            network.connectWithPsk(password);
        else
            network.connect();
    }

    function activateDevice(device, paired, connected) {
        clear(device.address);
        if (!paired) {
            pendingDevice = device;
            device.pair();
        } else if (connected) {
            device.disconnect();
        } else {
            device.connect();
        }
    }

    function updateScans() {
        if (open && tab === "wifi" && wifiDevice) {
            wifiDevice.scannerEnabled = true;
            wifiScan.restart();
        } else if (wifiDevice) {
            wifiDevice.scannerEnabled = false;
        }
        if (adapter && adapter.enabled)
            adapter.discovering = open && tab === "bluetooth";
        if (open && tab === "bluetooth")
            discovery.restart();
    }

    onOpenChanged: updateScans()
    onTabChanged: updateScans()

    Timer { id: wifiScan; interval: 4000 }
    Timer {
        id: discovery
        interval: 20000
        onTriggered: if (root.adapter) root.adapter.discovering = false
    }

    Connections {
        target: root.pendingNetwork
        ignoreUnknownSignals: true
        function onConnectionFailed(reason) {
            const reasons = {};
            reasons[ConnectionFailReason.NoSecrets] = "password";
            reasons[ConnectionFailReason.WifiClientFailed] = "wrong";
            reasons[ConnectionFailReason.WifiAuthTimeout] = "wrong";
            reasons[ConnectionFailReason.WifiClientDisconnected] = "wrong";
            reasons[ConnectionFailReason.WifiNetworkLost] = "lost";
            root.fail(root.pendingNetwork.name, reasons[reason] || "other");
        }
    }

    // After pairing, the device is trusted (it reconnects by itself) and connected.
    Connections {
        target: root.pendingDevice
        ignoreUnknownSignals: true
        function onPairingChanged() {
            const device = root.pendingDevice;
            if (device.pairing)
                return;
            if (device.paired) {
                device.trusted = true;
                device.connect();
            } else {
                root.fail(device.address, "pair");
            }
        }
    }

    LazyLoader {
        active: root.open

        OverlayWindow {
            name: "network"
            dim: 0.2
            onDismissed: root.open = false

            NetworkContent {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                width: implicitWidth
                height: implicitHeight
                tab: root.tab
                onTabChanged: root.tab = tab
                airplane: root.airplane
                wifi: ({
                    active: Networking.wifiEnabled,
                    scanning: wifiScan.running,
                    wired: root.wiredDevice ? root.wiredDevice.name : "",
                    connectivity: Networking.connectivity === NetworkConnectivity.Portal ? "portal"
                        : Networking.connectivity === NetworkConnectivity.Limited ? "limited" : "full",
                    networks: root.wifiDevice ? root.wifiDevice.networks.values.filter(n => n.name).map(n => ({
                        ref: n,
                        name: n.name,
                        strength: n.signalStrength,
                        secured: !root.unlocked.includes(n.security),
                        needsPassword: root.personal.includes(n.security) && !n.known,
                        known: n.known,
                        connected: n.connected,
                        busy: n.stateChanging,
                        failed: root.failures[n.name] || ""
                    })) : []
                })
                bluetooth: ({
                    available: root.adapter !== null,
                    active: root.adapter ? root.adapter.enabled : false,
                    discovering: root.adapter ? root.adapter.discovering : false,
                    discoverable: root.adapter ? root.adapter.discoverable : false,
                    name: root.adapter ? root.adapter.name : "",
                    // Unnamed devices nearby are only addresses: left out.
                    devices: root.adapter ? root.adapter.devices.values.filter(d => d.paired || d.deviceName).map(d => ({
                        ref: d,
                        name: d.name || d.deviceName || d.address,
                        kind: Kinds.deviceIcon(d.icon),
                        paired: d.paired,
                        connected: d.connected,
                        busy: d.pairing || d.state === BluetoothDeviceState.Connecting
                            || d.state === BluetoothDeviceState.Disconnecting,
                        battery: d.batteryAvailable ? d.battery : -1,
                        failed: root.failures[d.address] || ""
                    })) : []
                })
                onWifiToggled: on => Networking.wifiEnabled = on
                onBluetoothToggled: on => { if (root.adapter) root.adapter.enabled = on; }
                onAirplaneToggled: on => {
                    Networking.wifiEnabled = !on;
                    if (root.adapter)
                        root.adapter.enabled = !on;
                }
                onScanRequested: root.updateScans()
                onConnectRequested: (ref, password) => root.connectNetwork(ref, password)
                onDisconnectRequested: ref => ref.disconnect()
                onForgetNetworkRequested: ref => {
                    root.clear(ref.name);
                    ref.forget();
                }
                onDiscoverRequested: {
                    if (root.adapter && root.adapter.enabled) {
                        root.adapter.discovering = true;
                        discovery.restart();
                    }
                }
                onDiscoverableRequested: visible => { if (root.adapter) root.adapter.discoverable = visible; }
                onDeviceActivated: (ref, paired, connected) => root.activateDevice(ref, paired, connected)
                onForgetDeviceRequested: ref => ref.forget()
                onClosed: root.open = false
                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}
