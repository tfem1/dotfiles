import QtQuick
import "../theme"
import "../components"

// One app in the launcher list: icon (or its first letter), name, comment.
Rectangle {
    id: item

    property string name: ""
    property string comment: ""
    property url iconSource
    property bool selected: false
    signal activated

    height: 52
    radius: 14
    color: selected ? Qt.alpha(Theme.accent, 0.18) : hover.hovered ? Theme.surface : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.duration } }

    Rectangle {
        id: badge
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        height: 34
        radius: 10
        color: appIcon.visible ? "transparent" : Theme.surface

        Image {
            id: appIcon
            anchors.fill: parent
            sourceSize: Qt.size(64, 64)
            source: item.iconSource
            visible: status === Image.Ready
        }
        Label {
            anchors.centerIn: parent
            visible: !appIcon.visible
            text: item.name.charAt(0).toUpperCase()
            color: Theme.accent
            font.weight: Font.Bold
        }
    }

    Column {
        anchors.left: badge.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        Label {
            width: parent.width
            text: item.name
            color: item.selected ? Theme.fgBright : Theme.fg
            font.weight: item.selected ? Font.DemiBold : Font.Normal
        }
        Label {
            width: parent.width
            visible: item.comment !== ""
            text: item.comment
            small: true
        }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: item.activated() }
}
