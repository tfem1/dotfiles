pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "../notifications"

// The system panel (SUPER + B), on the right: quick toggles, volume and
// brightness, then the notifications received (newest first). Plain data
// in, requests out (SystemPanel.qml).
Rectangle {
    id: panel

    property var wifi: ({ on: false, name: "" })
    property var bluetooth: ({ on: false, connected: 0 })
    property bool airplane: false
    property bool doNotDisturb: false
    property bool stayAwake: false
    property var volume: ({ value: 0, muted: false })
    property real brightness: -1      // -1: no backlight to control
    property var notifications: []    // [{ appName, summary, body, iconSource, time, urgent }]
    signal wifiToggled
    signal bluetoothToggled
    signal airplaneToggled
    signal doNotDisturbToggled
    signal stayAwakeToggled
    signal volumeMoved(real value)
    signal muteToggled
    signal brightnessMoved(real value)
    signal notificationDismissed(int index)
    signal clearAll
    signal powerRequested
    signal closed

    readonly property real tileWidth: (column.width - 16) / 3

    implicitWidth: 420
    radius: Theme.radius + 8
    color: Theme.panel
    focus: true
    Keys.onEscapePressed: closed()

    // Keeps clicks inside the panel from closing it.
    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: column
        x: 16
        y: 16
        width: parent.width - 32
        spacing: 12

        Item {
            width: parent.width
            height: 34
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: "Quick settings"
                color: Theme.fgBright
                font.weight: Font.DemiBold
            }
            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon: "power_settings_new"
                tint: Theme.accent
                onClicked: panel.powerRequested()
            }
        }

        Flow {
            width: parent.width
            spacing: 8

            QuickTile {
                width: panel.tileWidth
                icon: panel.wifi.on ? "wifi" : "wifi_off"
                title: "Wi-Fi"
                subtitle: !panel.wifi.on ? "Off" : panel.wifi.name || "Not connected"
                on: panel.wifi.on
                tint: Theme.modules.wifi
                onClicked: panel.wifiToggled()
            }
            QuickTile {
                width: panel.tileWidth
                icon: panel.bluetooth.on ? "bluetooth" : "bluetooth_disabled"
                title: "Bluetooth"
                subtitle: !panel.bluetooth.on ? "Off" : panel.bluetooth.connected ? panel.bluetooth.connected + " connected" : "On"
                on: panel.bluetooth.on
                tint: Theme.modules.bluetooth
                onClicked: panel.bluetoothToggled()
            }
            QuickTile {
                width: panel.tileWidth
                icon: "airplanemode_active"
                title: "Airplane"
                subtitle: panel.airplane ? "On" : "Off"
                on: panel.airplane
                tint: Theme.accent
                onClicked: panel.airplaneToggled()
            }
            QuickTile {
                width: panel.tileWidth
                icon: panel.doNotDisturb ? "notifications_off" : "notifications"
                title: "Quiet"
                subtitle: panel.doNotDisturb ? "No popups" : "Off"
                on: panel.doNotDisturb
                tint: Theme.accent
                onClicked: panel.doNotDisturbToggled()
            }
            QuickTile {
                width: panel.tileWidth
                icon: "coffee"
                title: "Stay awake"
                subtitle: panel.stayAwake ? "No sleep" : "Off"
                on: panel.stayAwake
                tint: Theme.accent
                onClicked: panel.stayAwakeToggled()
            }
        }

        Row {
            width: parent.width
            spacing: 10
            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: panel.volume.muted ? "volume_off" : "volume_up"
                tint: panel.volume.muted ? Theme.subtle : Theme.modules.audio
                onClicked: panel.muteToggled()
            }
            Slider {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 42
                value: panel.volume.value
                dimmed: panel.volume.muted
                tint: Theme.modules.audio
                onMoved: value => panel.volumeMoved(value)
            }
        }
        Row {
            visible: panel.brightness >= 0
            width: parent.width
            spacing: 10
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                name: "brightness_6"
                color: Theme.modules.brightness
                size: 18
                fillMode: Image.Pad
            }
            Slider {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 42
                value: Math.max(0, panel.brightness)
                tint: Theme.modules.brightness
                onMoved: value => panel.brightnessMoved(value)
            }
        }

        Item {
            width: parent.width
            height: 34
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications" + (panel.notifications.length ? " · " + panel.notifications.length : "")
                color: Theme.fgBright
                font.weight: Font.DemiBold
            }
            Rectangle {
                visible: panel.notifications.length > 0
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: clearLabel.implicitWidth + 22
                height: 28
                radius: 14
                color: clearHover.hovered ? Theme.surface : Theme.bgAlt
                Label { id: clearLabel; anchors.centerIn: parent; text: "Clear all"; small: true }
                HoverHandler { id: clearHover }
                TapHandler { onTapped: panel.clearAll() }
            }
        }
    }

    Flickable {
        anchors.top: column.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: parent.width
            spacing: 8

            Repeater {
                model: panel.notifications
                NotificationCard {
                    required property var modelData
                    required property int index
                    width: list.width
                    appName: modelData.appName
                    summary: modelData.summary
                    body: modelData.body
                    iconSource: modelData.iconSource || ""
                    urgent: !!modelData.urgent
                    time: Qt.formatTime(modelData.time, "HH:mm")
                    color: Theme.bgAlt
                    onClosed: panel.notificationDismissed(index)
                }
            }
        }

        Column {
            visible: panel.notifications.length === 0
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 40
            spacing: 10
            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: panel.doNotDisturb ? "notifications_off" : "notifications"
                color: Theme.muted
                size: 36
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: panel.doNotDisturb ? "Quiet mode: popups are hidden" : "No notifications"
                small: true
            }
        }
    }
}
