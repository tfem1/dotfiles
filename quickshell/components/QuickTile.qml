import QtQuick
import "../theme"

// A quick toggle (network and system panels): icon, name and a short
// state line, filled with its color while on.
Rectangle {
    id: tile

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool on: false
    property color tint: Theme.accent
    signal clicked

    height: 76
    radius: 18
    color: on ? tint : hover.hovered ? Theme.surface : Theme.bgAlt
    Behavior on color { ColorAnimation { duration: Theme.duration } }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Icon {
            name: tile.icon
            color: tile.on ? Theme.bg : Theme.fg
            size: 22
        }
        Label {
            width: parent.width
            text: tile.title
            color: tile.on ? Theme.bg : Theme.fg
            font.weight: Font.DemiBold
        }
        Label {
            width: parent.width
            text: tile.subtitle
            textFormat: Text.PlainText
            small: true
            color: tile.on ? Qt.alpha(Theme.bg, 0.75) : Theme.subtle
        }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: tile.clicked() }
}
