import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import "../overlay"
import "../services"

// Connects the system panel: radios (NetworkManager, BlueZ), quiet mode and
// stay awake (Session), volume (PipeWire), brightness (brightnessctl, read
// when the panel opens) and the notifications kept by the daemon.
Scope {
    id: root

    required property var notifications   // the Notifications daemon
    required property var power           // the power menu
    required property var settings        // the Settings window
    property bool open: false
    property real brightness: -1

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool airplane: !Networking.wifiEnabled && !(root.adapter && root.adapter.enabled)
    readonly property var network: Connectivity.wifi ? Connectivity.wifi.networks.values.find(n => n.connected) : null

    function toggle() {
        open = !open;
        if (open)
            reader.running = true;
    }

    // `brightnessctl -m` prints "device,class,current,percent%,max".
    Process {
        id: reader
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                root.brightness = fields.length >= 4 ? parseInt(fields[3]) / 100 : -1;
            }
        }
    }

    LazyLoader {
        active: root.open

        OverlayWindow {
            name: "system"
            dim: 0.2
            onDismissed: root.open = false

            SystemContent {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 10
                width: implicitWidth
                wifi: ({ on: Networking.wifiEnabled, name: root.network ? root.network.name : "" })
                bluetooth: ({
                    on: root.adapter ? root.adapter.enabled : false,
                    connected: Bluetooth.devices.values.filter(device => device.connected).length
                })
                airplane: root.airplane
                doNotDisturb: Session.doNotDisturb
                stayAwake: Session.stayAwake
                volume: ({ value: Audio.volume, muted: Audio.muted })
                brightness: root.brightness
                notifications: root.notifications.history
                onWifiToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                onBluetoothToggled: { if (root.adapter) root.adapter.enabled = !root.adapter.enabled; }
                onAirplaneToggled: {
                    const on = !root.airplane;
                    Networking.wifiEnabled = !on;
                    if (root.adapter)
                        root.adapter.enabled = !on;
                }
                onDoNotDisturbToggled: Session.doNotDisturb = !Session.doNotDisturb
                onStayAwakeToggled: Session.stayAwake = !Session.stayAwake
                onVolumeMoved: value => { if (Audio.sink) Audio.sink.audio.volume = value; }
                onMuteToggled: { if (Audio.sink) Audio.sink.audio.muted = !Audio.sink.audio.muted; }
                onBrightnessMoved: value => {
                    root.brightness = Math.max(0.01, value);
                    Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(root.brightness * 100) + "%"]);
                }
                onNotificationDismissed: index => root.notifications.forget(root.notifications.history[index])
                onClearAll: root.notifications.clear()
                onPowerRequested: {
                    root.open = false;
                    root.power.toggle();
                }
                onSettingsRequested: {
                    root.open = false;
                    root.settings.toggle();
                }
                onClosed: root.open = false
                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}
