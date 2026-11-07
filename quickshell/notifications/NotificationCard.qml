import QtQuick
import "../theme"
import "../components"

// One notification: app icon, app name and time, summary, body.
// Urgent ones get a red edge and stay until closed.
Rectangle {
    id: card

    property string appName: ""
    property string summary: ""
    property string body: ""
    property url iconSource
    property string time: ""
    property bool urgent: false
    signal closed

    implicitWidth: 380
    implicitHeight: content.implicitHeight + 28
    radius: Theme.radius + 4
    color: Theme.panel
    border.width: urgent ? 2 : 0
    border.color: Theme.red

    Row {
        id: content
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Rectangle {
            width: 40
            height: 40
            radius: 20
            color: Theme.surface

            Image {
                id: appIcon
                anchors.centerIn: parent
                width: 24
                height: 24
                sourceSize: Qt.size(48, 48)
                source: card.iconSource
                visible: status === Image.Ready
            }
            Icon {
                anchors.centerIn: parent
                visible: !appIcon.visible
                name: card.urgent ? "error" : "notifications"
                color: card.urgent ? Theme.red : Theme.modules.notifications
                size: 20
            }
        }

        Column {
            width: parent.width - 52 - closeIcon.width - 12
            spacing: 3

            Label {
                width: parent.width
                text: card.appName + (card.time ? "  ·  " + card.time : "")
                small: true
            }
            Label {
                width: parent.width
                text: card.summary
                font.weight: Font.DemiBold
                color: Theme.fgBright
            }
            Label {
                width: parent.width
                visible: card.body !== ""
                text: card.body
                wrapMode: Text.Wrap
                maximumLineCount: 3
                textFormat: Text.PlainText
            }
        }

        Icon {
            id: closeIcon
            name: "close"
            color: Theme.subtle
            size: 16
            TapHandler { onTapped: card.closed() }
        }
    }
}
