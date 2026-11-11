import QtQuick
import "../theme"
import "../components"

// Numbered workspace circles: focused one filled with the module color,
// occupied ones lightly tinted with it, empty ones only show their number.
// In a row, or a column when `vertical`.
Grid {
    id: workspaces

    property var model: []          // [{ id, focused, occupied, urgent }]
    property bool vertical: false
    signal clicked(int id)

    columns: vertical ? 1 : -1
    rows: vertical ? -1 : 1
    spacing: 4

    Repeater {
        model: workspaces.model

        Rectangle {
            required property var modelData
            readonly property color tone: modelData.urgent ? Theme.red : Theme.modules.workspaces

            width: 24
            height: 24
            radius: 12
            color: modelData.focused ? tone : modelData.occupied ? Qt.alpha(tone, 0.22) : "transparent"
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
