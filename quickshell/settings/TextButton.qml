import QtQuick
import "../theme"
import "../components"

// A quiet button with a word on it ("Choose…"); `strong` fills it with the
// accent, for the one action that matters (Apply).
Rectangle {
    id: button

    property string text: ""
    property string icon: ""
    property bool strong: false
    signal clicked

    implicitWidth: row.implicitWidth + 28
    implicitHeight: 36
    radius: height / 2
    color: strong ? (hover.hovered ? Theme.accent2 : Theme.accent) : hover.hovered ? Theme.surface : Theme.bg
    border.width: strong ? 0 : 1
    border.color: Theme.surface
    Behavior on color { ColorAnimation { duration: Theme.duration } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: button.icon !== ""
            name: button.icon
            color: button.strong ? Theme.bg : Theme.fg
            size: 16
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: button.text
            color: button.strong ? Theme.bg : Theme.fg
            font.weight: button.strong ? Font.DemiBold : Font.Normal
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler { onTapped: button.clicked() }
}
