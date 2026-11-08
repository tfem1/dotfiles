pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// A few choices, one picked: `model` is [{ value, label, color }] (a color
// draws a dot before the label). Wraps onto more lines when narrow.
Flow {
    id: chips

    property var model: []
    property var current
    signal picked(var value)

    spacing: 8

    Repeater {
        model: chips.model

        Rectangle {
            id: chip

            required property var modelData
            readonly property bool chosen: chips.current === modelData.value

            width: row.implicitWidth + 26
            height: 34
            radius: height / 2
            color: chosen ? Qt.alpha(Theme.accent, 0.16) : hover.hovered ? Theme.surface : Theme.bg
            border.width: 1
            border.color: chosen ? Theme.accent : Theme.surface
            Behavior on color { ColorAnimation { duration: Theme.duration } }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !!chip.modelData.color
                    width: 14
                    height: 14
                    radius: 7
                    color: chip.modelData.color || "transparent"
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: chip.modelData.label
                    color: chip.chosen ? Theme.fgBright : Theme.fg
                    small: true
                }
            }

            HoverHandler {
                id: hover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler { onTapped: chips.picked(chip.modelData.value) }
        }
    }
}
