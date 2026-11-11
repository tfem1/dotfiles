pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "settings.js" as Settings

// Tweaks: one tile per mode (game, coffee, night...), filled while it is on;
// a click turns it on or off. Sleep locks and suspends; Screenshot and
// Region close the window, then take one.
Column {
    id: page

    property var on: ({})        // { game, saver, coffee, night, quiet, presentation, focus }
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

    Label {
        width: page.width
        text: "SUPER + G turns game mode on or off; CTRL + SHIFT + S or SUPER + SHIFT + Escape takes a screenshot."
        small: true
        wrapMode: Text.WordWrap
    }
}
