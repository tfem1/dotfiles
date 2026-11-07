import QtQuick
import "../theme"
import "../components"

// Keyboard layout, sound, network, Bluetooth and battery, each in its
// module color. Clicking opens the system panel.
Pill {
    id: area

    property string keyboard: ""
    property real volume: 0
    property bool muted: false
    property string network: "offline"      // wifi | wired | offline
    property real wifiStrength: 0
    property bool bluetoothOn: false
    property bool bluetoothConnected: false
    property bool hasBattery: false
    property real battery: 0
    property bool charging: false

    spacing: 10

    Label {
        anchors.verticalCenter: parent.verticalCenter
        visible: area.keyboard !== ""
        text: area.keyboard
        small: true
        font.weight: Font.Bold
    }
    Icon {
        anchors.verticalCenter: parent.verticalCenter
        color: area.muted ? Theme.muted : Theme.modules.audio
        name: area.muted ? "volume_off" : area.volume > 0.5 ? "volume_up" : area.volume > 0 ? "volume_down" : "volume_mute"
    }
    Icon {
        anchors.verticalCenter: parent.verticalCenter
        color: area.network === "offline" ? Theme.muted : Theme.modules.wifi
        name: {
            if (area.network === "wired")
                return "lan";
            if (area.network === "offline")
                return "wifi_off";
            const s = area.wifiStrength;
            return s > 0.75 ? "wifi" : s > 0.5 ? "network_wifi_3_bar" : s > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
        }
    }
    Icon {
        anchors.verticalCenter: parent.verticalCenter
        color: area.bluetoothOn ? Theme.modules.bluetooth : Theme.muted
        name: !area.bluetoothOn ? "bluetooth_disabled" : area.bluetoothConnected ? "bluetooth_connected" : "bluetooth"
    }
    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: area.hasBattery
        spacing: 2

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            color: area.battery < 0.15 && !area.charging ? Theme.red : Theme.modules.battery
            name: area.charging ? "battery_charging_full" : "battery_" + Math.min(6, Math.floor(area.battery * 7)) + "_bar"
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(area.battery * 100) + "%"
            small: true
        }
    }
}
