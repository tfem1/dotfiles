import QtQuick
import "../theme"
import "../components"

// The workspaces. "dots" (the default): the focused one is a lit rounded
// square, the others dots, brighter when they hold windows. "numbers":
// numbered circles, the focused one filled. In a row, or a column when
// `vertical`.
Grid {
    id: workspaces

    property var model: []          // [{ id, focused, occupied, urgent }]
    property bool vertical: false
    property string style: "dots"   // config.json bar.workspaces
    signal clicked(int id)

    columns: vertical ? 1 : -1
    rows: vertical ? -1 : 1
    spacing: style === "dots" ? 2 : 4
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter

    Repeater {
        model: workspaces.model

        Item {
            id: slot
            required property var modelData
            readonly property color tone: modelData.urgent ? Theme.red : Theme.modules.workspaces
            readonly property bool dots: workspaces.style === "dots"

            width: 24
            height: 24

            Rectangle {
                anchors.centerIn: parent
                width: slot.dots ? (slot.modelData.focused ? 18 : slot.modelData.occupied ? 7 : 6) : 24
                height: width
                radius: slot.dots && slot.modelData.focused ? 6 : width / 2
                color: slot.dots
                    ? (slot.modelData.focused ? slot.tone : slot.modelData.occupied ? Theme.fg : Theme.muted)
                    : (slot.modelData.focused ? slot.tone : slot.modelData.occupied ? Qt.alpha(slot.tone, 0.22) : "transparent")
                Behavior on width { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Theme.duration } }
            }
            Label {
                visible: !slot.dots
                anchors.centerIn: parent
                text: slot.modelData.id
                small: true
                font.weight: slot.modelData.focused ? Font.Bold : Font.Normal
                color: slot.modelData.focused ? Theme.bg : slot.modelData.occupied ? Theme.fg : Theme.muted
            }

            TapHandler { onTapped: workspaces.clicked(slot.modelData.id) }
        }
    }
}
