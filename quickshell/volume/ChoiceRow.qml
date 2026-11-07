import QtQuick
import "../theme"
import "../components"

// One output or input device to choose; the one in use is marked.
Rectangle {
    id: choice

    property string icon: "speaker"
    property string title: ""
    property bool current: false
    property color tint: Theme.modules.audio
    signal chosen

    height: 40
    radius: 12
    color: current ? Qt.alpha(tint, 0.14) : hover.hovered ? Theme.surface : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.duration } }

    Icon {
        id: kind
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        name: choice.icon
        color: choice.current ? choice.tint : Theme.subtle
        size: 18
    }
    Label {
        anchors.left: kind.right
        anchors.leftMargin: 12
        anchors.right: check.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: choice.title
        textFormat: Text.PlainText
        color: choice.current ? Theme.fgBright : Theme.fg
        small: !choice.current
    }
    Icon {
        id: check
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        visible: choice.current
        name: "check"
        color: choice.tint
        size: 18
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: choice.chosen() }
}
