pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "settings.js" as Settings

// Tweaks: one tile per mode (game, coffee, night...), filled while it is on;
// a click turns it on or off. Sleep locks and suspends; Screenshot and
// Region close the window, then take one. Under them, the bar: its edge of
// the screen, and with or without its background; these act at once.
Column {
    id: page

    property var on: ({})        // { game, saver, coffee, night, quiet, presentation, focus }
    property var values: ({})    // `tfem settings get` values (bar.*)
    signal action(string name, var value)

    spacing: 12

    Grid {
        id: grid
        objectName: "modes"
        columns: page.width > 760 ? 4 : 3
        spacing: 10

        Repeater {
            model: Settings.MODES

            QuickTile {
                required property var modelData
                readonly property bool active: !!page.on[modelData.id]

                width: (page.width - grid.spacing * (grid.columns - 1)) / grid.columns
                icon: modelData.icon
                title: modelData.title
                subtitle: active ? "On" : modelData.text
                on: active
                onClicked: page.action("mode", modelData.id)
            }
        }
    }

    SettingRow {
        objectName: "bar-position"
        width: page.width
        title: "Bar position"
        description: "The edge of the screen the bar stands on. On the left or right, it is narrow and stacked."
        Chips {
            current: page.values["bar.position"] || "top"
            model: [{ label: "Top", value: "top" }, { label: "Bottom", value: "bottom" },
                    { label: "Left", value: "left" }, { label: "Right", value: "right" }]
            onPicked: value => page.action("bar.position", value)
        }
    }

    SettingRow {
        objectName: "bar-transparent"
        width: page.width
        title: "Transparent bar"
        description: "No background: only the pills (workspaces, clock, icons) show over the wallpaper."
        Switch {
            checked: !!page.values["bar.transparent"]
            onToggled: checked => page.action("bar.transparent", checked)
        }
    }

    SettingRow {
        objectName: "bar-layout"
        width: page.width
        title: "Bar layout"
        description: "Drag the modules of the bar to another place, to the start, the middle or the end, or into Hidden."
        wide: true
        BarLayoutEditor {
            width: parent.width
            layout: page.values["bar.layout"] || ""
            onChanged: text => page.action("bar.layout", text)
        }
    }

    SettingRow {
        objectName: "record-audio"
        width: page.width
        title: "Sound in screen recordings"
        description: "SUPER + ALT + R records the screen: with what the computer plays, with your microphone, or silent."
        Chips {
            current: page.values["record.audio"] || "computer"
            model: [{ label: "Computer", value: "computer" }, { label: "Microphone", value: "microphone" },
                    { label: "None", value: "none" }]
            onPicked: value => page.action("record.audio", value)
        }
    }

    Label {
        width: page.width
        text: "SUPER + SHIFT + C picks a color on the screen; SUPER + G turns game mode on or off; CTRL + SHIFT + S or SUPER + SHIFT + Escape takes a screenshot."
        small: true
        wrapMode: Text.WordWrap
    }
}
