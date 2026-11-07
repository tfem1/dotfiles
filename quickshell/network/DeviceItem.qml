import QtQuick
import "../theme"
import "../components"
import "kinds.js" as Kinds

// One Bluetooth device: its type icon, name and state (battery when it
// reports one). Click to connect, disconnect or pair; a button forgets it.
// `device` is { name, kind, paired, connected, busy, battery, failed }.
Rectangle {
    id: item

    property var device: ({})
    signal activated
    signal forgetRequested

    readonly property color tint: Theme.modules.bluetooth

    height: 54
    radius: 14
    color: device.connected ? Qt.alpha(tint, 0.14) : hover.hovered ? Theme.surface : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.duration } }

    Rectangle {
        id: badge
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        height: 34
        radius: 17
        color: item.device.connected ? item.tint : Theme.surface

        Icon {
            anchors.centerIn: parent
            name: item.device.kind || "bluetooth"
            color: item.device.connected ? Theme.bg : Theme.fg
            size: 18
        }
    }
    Column {
        anchors.left: badge.right
        anchors.leftMargin: 12
        anchors.right: actions.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        Label {
            width: parent.width
            text: item.device.name
            textFormat: Text.PlainText
            color: item.device.connected ? Theme.fgBright : Theme.fg
            font.weight: item.device.connected ? Font.DemiBold : Font.Normal
        }
        Label {
            width: parent.width
            text: Kinds.deviceStatus(item.device)
            small: true
            color: item.device.failed ? Theme.red : item.device.connected ? item.tint : Theme.subtle
        }
    }
    Row {
        id: actions
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        IconButton {
            visible: !!item.device.paired && (!!item.device.connected || hover.hovered)
            icon: "delete"
            tint: Theme.subtle
            onClicked: item.forgetRequested()
        }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: item.activated() }
}
