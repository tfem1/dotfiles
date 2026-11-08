pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// Widgets: which desktop widgets show, and in which corner. They act at once
// (`tfem settings set widgets.cpu=false`...): the shell reads them from its
// theme.json.
Column {
    id: page

    property var values: ({})        // `tfem settings get` values
    signal action(string name, var value)

    readonly property var rows: [
        ["clock", "Clock", "The date and the time, in a pill of the accent color."],
        ["audio", "Audio spectrum", "The sound as bars, drawn by cava, with the device it plays on. Paused in game mode."],
        ["media", "Now playing", "The song and its artist, and the line of the lyrics being sung (from lrclib.net)."],
        ["cpu", "CPU", "How busy the processor is, and its number of cores."],
        ["gpu", "GPU", "How busy the graphics card is, and its memory (AMD and NVIDIA cards)."],
        ["ram", "RAM", "Memory in use by the apps."],
        ["disk", "Disk", "Space used on the disk of your home folder."]
    ]

    spacing: 12

    SettingRow {
        id: cornerRow
        readonly property string corner: page.values["widgets.corner"] || "top-left"
        objectName: "widget-corner"
        title: "Corner"
        description: "Where the widgets stand on the screen: click a corner. In use: "
            + ({ "top-left": "top left", "top-right": "top right", "bottom-left": "bottom left",
                 "bottom-right": "bottom right" })[corner] + "."
        CornerPicker {
            current: cornerRow.corner
            onPicked: corner => page.action("widgets.corner", corner)
        }
    }

    Repeater {
        model: page.rows

        SettingRow {
            id: row
            required property var modelData
            objectName: "widget-" + modelData[0]
            title: modelData[1]
            description: modelData[2]
            Switch {
                checked: page.values["widgets." + row.modelData[0]] !== false
                onToggled: checked => page.action("widgets." + row.modelData[0], checked)
            }
        }
    }
}
