pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "settings.js" as Settings

// Display: each screen on or off, its resolution and refresh rate, in one
// click. A change acts at once and asks to be kept: without an answer it
// goes back after 15 seconds, in case the screen shows nothing with it. The
// last screen on cannot be turned off.
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
                text: "Keep this change?"
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
            readonly property bool on: picked === "off" ? false : picked !== "auto" || modelData.on !== false
            readonly property bool last: on && Settings.screensOn(page.screens, page.chosen) <= 1
            readonly property string size: picked === "auto" || picked === "off" ? modelData.size
                : Settings.modeParts(picked).size

            objectName: index === 0 ? "screens" : ""
            title: modelData.name + (modelData.description ? "  ·  " + modelData.description : "")
            description: !on ? "Off: nothing shows on it."
                : modelData.current ? "In use: " + Settings.modeLabel(modelData.current)
                    + (picked === "auto" ? " (the highest refresh rate)" : "")
                : "On, with its highest refresh rate."
            wide: true

            Column {
                width: parent.width
                spacing: 10

                Row {
                    spacing: 12
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 130
                        text: "Screen"
                    }
                    Switch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: screen.on
                        frozen: screen.last
                        // On again: without the "off" rule; a screen turned off
                        // elsewhere gets its fastest mode, which turns it on.
                        onToggled: checked => page.pick(screen.modelData.name, !checked ? "off"
                            : screen.picked === "off" ? "auto"
                            : Settings.fastest(screen.modelData, (screen.modelData.resolutions[0] || {}).size))
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: screen.last
                        text: "The only screen on: it stays on."
                        small: true
                    }
                }
                Row {
                    visible: screen.on
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
                    visible: screen.on
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
