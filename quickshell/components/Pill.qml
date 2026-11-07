import QtQuick
import "../theme"

// Rounded container of the bar: its children are laid out in a row.
Rectangle {
    id: pill

    default property alias content: row.data
    property int padding: 12
    property alias spacing: row.spacing
    property bool hovered: hover.hovered
    signal clicked

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: 32
    radius: height / 2
    color: hovered ? Theme.surface : Theme.bgAlt
    Behavior on color { ColorAnimation { duration: Theme.duration } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: pill.clicked() }
}
