import QtQuick
import "../theme"
import "../components"
import "kinds.js" as Kinds

// One Wi-Fi network: signal, name, state; buttons to disconnect or forget.
// `expanded` opens a password field right under it.
// `network` is { name, strength, secured, known, connected, busy, failed }.
Rectangle {
    id: item

    property var network: ({})
    property bool expanded: false
    signal activated
    signal passwordEntered(string password)
    signal disconnectRequested
    signal forgetRequested

    readonly property color tint: Theme.modules.wifi

    function focusPassword() {
        field.forceActiveFocus();
    }

    height: 54 + (expanded ? 50 : 0)
    radius: 14
    color: network.connected ? Qt.alpha(tint, 0.14) : hover.hovered ? Theme.surface : "transparent"
    Behavior on height { NumberAnimation { duration: Theme.duration } }
    Behavior on color { ColorAnimation { duration: Theme.duration } }
    clip: true

    Item {
        id: line
        width: parent.width
        height: 54

        Icon {
            id: signalIcon
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            name: Kinds.wifiIcon(item.network.strength)
            color: item.network.connected ? item.tint : Theme.fg
            size: 22
        }
        Column {
            anchors.left: signalIcon.right
            anchors.leftMargin: 12
            anchors.right: actions.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            Label {
                width: parent.width
                text: item.network.name
                textFormat: Text.PlainText
                color: item.network.connected ? Theme.fgBright : Theme.fg
                font.weight: item.network.connected ? Font.DemiBold : Font.Normal
            }
            Label {
                width: parent.width
                text: Kinds.networkStatus(item.network)
                small: true
                color: item.network.failed ? Theme.red : item.network.connected ? item.tint : Theme.subtle
            }
        }
        Row {
            id: actions
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            IconButton {
                visible: !!item.network.connected
                icon: "link_off"
                onClicked: item.disconnectRequested()
            }
            IconButton {
                visible: !!item.network.known && (!!item.network.connected || hover.hovered)
                icon: "delete"
                tint: Theme.subtle
                onClicked: item.forgetRequested()
            }
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: !!item.network.secured && !item.network.connected
                name: "lock"
                color: Theme.subtle
                size: 16
            }
        }
        TapHandler { onTapped: item.activated() }
    }

    // Password, typed right under the network.
    Rectangle {
        anchors.top: line.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        anchors.topMargin: 0
        height: 38
        radius: 10
        color: Theme.bgAlt
        visible: item.expanded

        TextInput {
            id: field
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: reveal.left
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.fg
            selectionColor: item.tint
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontPixels
            echoMode: reveal.shown ? TextInput.Normal : TextInput.Password
            Keys.onReturnPressed: if (text) item.passwordEntered(text)
            Keys.onEnterPressed: if (text) item.passwordEntered(text)

            Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: field.text === ""
                text: "Password"
                small: true
            }
        }
        IconButton {
            id: reveal
            property bool shown: false
            anchors.right: go.left
            anchors.verticalCenter: parent.verticalCenter
            size: 30
            icon: shown ? "visibility_off" : "visibility"
            tint: Theme.subtle
            onClicked: shown = !shown
        }
        IconButton {
            id: go
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            size: 30
            icon: "check"
            tint: item.tint
            onClicked: if (field.text) item.passwordEntered(field.text)
        }
    }

    HoverHandler { id: hover }
}
