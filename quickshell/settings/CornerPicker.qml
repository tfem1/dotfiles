pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// A small screen with its four corners: a click on one picks it, the picked
// one is filled with the accent color.
Rectangle {
    id: picker

    property string current: "top-left"
    signal picked(string corner)

    implicitWidth: 168
    implicitHeight: 100
    radius: 10
    color: Theme.bg
    border.width: 1
    border.color: Theme.surface

    // The bar of the small screen, for a sense of top and bottom.
    Rectangle {
        x: 6
        y: 6
        width: parent.width - 12
        height: 6
        radius: 3
        color: Theme.surface
    }

    Repeater {
        model: ["top-left", "top-right", "bottom-left", "bottom-right"]

        Rectangle {
            id: spot

            required property string modelData
            readonly property bool chosen: picker.current === modelData

            x: modelData.endsWith("left") ? 10 : picker.width - width - 10
            y: modelData.startsWith("top") ? 18 : picker.height - height - 10
            width: 48
            height: 30
            radius: 6
            color: chosen ? Theme.accent : hover.hovered ? Theme.muted : Theme.surface
            Behavior on color { ColorAnimation { duration: Theme.duration } }

            HoverHandler {
                id: hover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler { onTapped: picker.picked(spot.modelData) }
        }
    }
}
