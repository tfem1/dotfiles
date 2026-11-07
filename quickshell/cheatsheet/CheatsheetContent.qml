pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "binds.js" as Binds

// Every described keybind, in three columns. `binds` is the parsed output of
// `hyprctl binds -j`. Escape closes.
Rectangle {
    id: sheet

    property var binds: []
    property int columns: 3
    signal closed

    readonly property var rows: Binds.rows(binds)
    readonly property int perColumn: Math.max(1, Math.ceil(rows.length / columns))

    implicitWidth: grid.implicitWidth + 56
    implicitHeight: title.height + grid.implicitHeight + 76
    radius: Theme.radius + 8
    color: Theme.panel
    focus: true
    Keys.onEscapePressed: closed()

    // Keeps clicks inside the sheet from reaching what is behind it.
    MouseArea {
        anchors.fill: parent
    }

    Row {
        id: title
        x: 28
        y: 24
        spacing: 10

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: "keyboard"
            color: Theme.accent
            size: 22
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: "Keybinds"
            color: Theme.fgBright
            font.pixelSize: Math.round(Theme.fontPixels * 1.35)
            font.weight: Font.DemiBold
        }
    }

    Label {
        anchors.centerIn: grid
        visible: sheet.rows.length === 0
        text: "No keybind to show"
        small: true
    }

    Row {
        id: grid
        x: 28
        anchors.top: title.bottom
        anchors.topMargin: 20
        spacing: 32

        Repeater {
            model: sheet.columns

            Column {
                id: column
                required property int index
                spacing: 4

                Repeater {
                    model: sheet.rows.slice(column.index * sheet.perColumn, (column.index + 1) * sheet.perColumn)

                    KeyRow {
                        required property var modelData
                        keys: modelData.keys
                        description: modelData.description
                    }
                }
            }
        }
    }
}
