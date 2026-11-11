import QtQuick
import "../theme"

// Rounded container of the bar: its children are laid out in a row, or in a
// column when `vertical` (bar on the left or right), centered.
Rectangle {
    id: pill

    default property alias content: grid.data
    property int padding: 12
    property int spacing: 8
    property bool vertical: false
    property bool hovered: hover.hovered
    signal clicked

    implicitWidth: vertical ? 36 : grid.implicitWidth + padding * 2
    implicitHeight: vertical ? grid.implicitHeight + padding * 2 : 32
    radius: Math.min(width, height) / 2
    color: hovered ? Theme.surface : Theme.bgAlt
    Behavior on color { ColorAnimation { duration: Theme.duration } }

    Grid {
        id: grid
        anchors.centerIn: parent
        flow: pill.vertical ? Grid.TopToBottom : Grid.LeftToRight
        rows: pill.vertical ? -1 : 1
        columns: pill.vertical ? 1 : -1
        rowSpacing: pill.spacing
        columnSpacing: pill.spacing
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: pill.clicked() }
}
