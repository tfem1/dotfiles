import QtQuick
import "../theme"
import "../components"

// Numbered workspace circles: focused one filled with the module color,
// occupied ones on a surface, empty ones only show their number.
Row {
    id: workspaces

    property var model: []          // [{ id, focused, occupied, urgent }]
    signal clicked(int id)

    spacing: 4

    Repeater {
        model: workspaces.model

        Rectangle {
            required property var modelData
            readonly property color tone: modelData.urgent ? Theme.red : Theme.modules.workspaces

            width: 24
            height: 24
            radius: 12
            color: modelData.focused ? tone : modelData.occupied ? Theme.surface : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.duration } }

            Label {
                anchors.centerIn: parent
                text: modelData.id
                small: true
                font.weight: modelData.focused ? Font.Bold : Font.Normal
                color: modelData.focused ? Theme.bg : modelData.occupied ? Theme.fg : Theme.muted
            }

            TapHandler { onTapped: workspaces.clicked(modelData.id) }
        }
    }
}
