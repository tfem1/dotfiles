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
    // On: the module color, see-through in glass (Settings → Glass).
    color: on ? (Theme.glassy ? Qt.alpha(tint, 0.38) : tint) : hover.hovered ? Theme.surface : Theme.tile
    readonly property color onText: Theme.glassy ? Theme.fgBright : Theme.bg
    Behavior on color { ColorAnimation { duration: Theme.duration } }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Icon {
            name: tile.icon
            color: tile.on ? tile.onText : Theme.fg
            size: 22
        }
        Label {
            width: parent.width
            text: tile.title
            color: tile.on ? tile.onText : Theme.fg
            font.weight: Font.DemiBold
        }
        Label {
            width: parent.width
            text: tile.subtitle
            textFormat: Text.PlainText
            small: true
            color: tile.on ? Qt.alpha(tile.onText, 0.75) : Theme.subtle
        }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: tile.clicked() }
}
