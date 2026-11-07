pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// The Bluetooth tab: your devices (paired), then the ones nearby while it
// searches, and whether this computer is visible to others. `devices`
// items: { ref, name, kind, paired, connected, busy, battery, failed }.
Item {
    id: page

    property bool available: true
    property bool active: true
    property bool discovering: false
    property bool discoverable: false
    property string name: ""           // this computer's Bluetooth name
    property var devices: []
    signal enableRequested
    signal discoverRequested
    signal discoverableRequested(bool visible)
    signal deviceActivated(var ref, bool paired, bool connected)
    signal forgetRequested(var ref)

    readonly property color tint: Theme.modules.bluetooth
    readonly property var mine: devices.filter(device => device.paired)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    readonly property var nearby: devices.filter(device => !device.paired)

    component Title: Item {
        property alias text: label.text
        width: parent.width
        height: 36
        Label { id: label; anchors.verticalCenter: parent.verticalCenter; x: 12; small: true; font.weight: Font.DemiBold }
    }

    Column {
        anchors.centerIn: parent
        visible: !page.active
        spacing: 12

        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "bluetooth_disabled"; color: Theme.subtle; size: 40 }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: page.available ? "Bluetooth is off" : "No Bluetooth adapter"
            color: Theme.fg
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: page.available
            width: 120
            height: 36
            radius: 18
            color: page.tint
            Label { anchors.centerIn: parent; text: "Turn on"; color: Theme.bg; font.weight: Font.DemiBold }
            TapHandler { onTapped: page.enableRequested() }
        }
    }

    Flickable {
        anchors.fill: parent
        visible: page.active
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: parent.width
            spacing: 4

            Title { text: "My devices"; visible: page.mine.length > 0 }
            Repeater {
                model: page.mine
                DeviceItem {
                    required property var modelData
                    width: content.width
                    device: modelData
                    onActivated: page.deviceActivated(modelData.ref, true, modelData.connected)
                    onForgetRequested: page.forgetRequested(modelData.ref)
                }
            }

            Item {
                width: parent.width
                height: 36
                Label { anchors.verticalCenter: parent.verticalCenter; x: 12; text: "Nearby"; small: true; font.weight: Font.DemiBold }
                IconButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    icon: page.discovering ? "bluetooth_searching" : "refresh"
                    tint: page.tint
                    spinning: page.discovering
                    onClicked: page.discoverRequested()
                }
            }
            Repeater {
                model: page.nearby
                DeviceItem {
                    required property var modelData
                    width: content.width
                    device: modelData
                    onActivated: page.deviceActivated(modelData.ref, false, false)
                }
            }
            Label {
                visible: page.nearby.length === 0
                width: parent.width
                leftPadding: 12
                text: page.discovering ? "Searching…" : "Press the button to search for devices"
                small: true
            }

            Item {
                width: parent.width
                height: 52
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 12
                    Label { text: "Visible to other devices"; color: Theme.fg }
                    Label { text: page.name ? "as “" + page.name + "”" : ""; small: true; textFormat: Text.PlainText }
                }
                Switch {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    checked: page.discoverable
                    tint: page.tint
                    onToggled: checked => page.discoverableRequested(checked)
                }
            }
        }
    }
}
