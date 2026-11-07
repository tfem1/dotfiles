pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking

// Network and Bluetooth state for the bar icons.
Singleton {
    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected) || null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) || null
    readonly property string state: wired ? "wired" : wifi ? "wifi" : "offline"
    readonly property real strength: {
        if (!wifi)
            return 0;
        const network = wifi.networks.values.find(n => n.connected);
        return network ? network.signalStrength : 0;
    }

    readonly property bool bluetoothOn: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
    readonly property bool bluetoothConnected: Bluetooth.devices.values.some(d => d.connected)
}
