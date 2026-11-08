pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "settings.js" as Settings

// Display: the resolution and refresh rate of each screen, in one click.
// A new mode acts at once and asks to be kept: without an answer it goes
// back after 15 seconds, in case the screen shows nothing with it.
Column {
    id: page

    property var screens: []        // `tfem display list`: monitors
    property var chosen: ({})       // screen name -> mode picked (none: the highest rate)
    property var confirm: null      // { name, seconds } while a new mode waits to be kept
    signal action(string name, var value)

    function pick(name, mode) {
        if (mode && mode !== (page.chosen[name] || "auto"))
            page.action("display", { name: name, mode: mode });
    }

    spacing: 12

    // Keep or go back.
    Rectangle {
        visible: !!page.confirm
        width: page.width
        height: 70
        radius: Theme.radius
        color: Qt.alpha(Theme.accent, 0.14)
        border.width: 1
        border.color: Theme.accent

        Column {
            x: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Label {
                text: "Keep this display mode?"
                color: Theme.fgBright
                font.weight: Font.DemiBold
            }
            Label {
                text: "Going back in " + (page.confirm ? page.confirm.seconds : 0) + " s"
                small: true
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            TextButton {
                text: "Go back"
                onClicked: page.action("display-revert", true)
            }
            TextButton {
                text: "Keep"
                icon: "check"
                strong: true
                onClicked: page.action("display-keep", true)
            }
        }
    }

    SettingRow {
        objectName: page.screens.length === 0 ? "screens" : ""
        visible: page.screens.length === 0
        title: "No screen found"
        description: "Screens show here while Hyprland runs (`tfem display list` reads them)."
    }

    Repeater {
        model: page.screens

        SettingRow {
            id: screen

            required property var modelData
            required property int index
            readonly property string picked: page.chosen[modelData.name] || "auto"
            readonly property string size: picked === "auto" ? modelData.size : Settings.modeParts(picked).size

            objectName: index === 0 ? "screens" : ""
            title: modelData.name + (modelData.description ? "  ·  " + modelData.description : "")
            description: "In use: " + Settings.modeLabel(modelData.current)
                + (picked === "auto" ? " (the highest refresh rate)" : "")
            wide: true

            Column {
                width: parent.width
                spacing: 10

                Row {
                    spacing: 12
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 130
                        text: "Refresh rate"
                    }
                    Chips {
                        width: screen.width - 190
                        current: screen.picked
                        model: Settings.rateChoices(screen.modelData, screen.size)
                        onPicked: value => page.pick(screen.modelData.name, value)
                    }
                }
                Row {
                    spacing: 12
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 130
                        text: "Resolution"
                    }
                    Chips {
                        width: screen.width - 190
                        current: screen.size
                        model: Settings.sizeChoices(screen.modelData, screen.size, 6)
                        onPicked: value => page.pick(screen.modelData.name, Settings.fastest(screen.modelData, value))
                    }
                }
            }
        }
    }
}
