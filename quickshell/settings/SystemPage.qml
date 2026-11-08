pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "settings.js" as Settings

// System: sound, screen, connections, keyboard, notifications and sleep.
// These act at once (no Apply): they are switches you flip often.
// `live` holds the current values; every change goes out through `action`.
Column {
    id: page

    property var live: ({})          // gameMode, volume, muted, micMuted, brightness, wifi,
                                     // bluetooth, layout, quiet, awake, idle: { dim, lock, ... }
    signal action(string name, var value)

    readonly property var steps: [0, 1, 2, 5, 10, 15, 30, 60]

    // A switch row, for the many on/off settings.
    component Toggle: SettingRow {
        id: toggle

        property string name: ""
        property bool on: false

        objectName: name
        Switch {
            checked: toggle.on
            onToggled: checked => page.action(toggle.name, checked)
        }
    }

    spacing: 12

    Toggle {
        name: "gamemode"
        title: "Game mode"
        description: "For games: no animations, blur or shadows, and notifications wait (urgent ones still show)."
        on: !!page.live.gameMode
    }

    SettingRow {
        objectName: "sound"
        title: "Sound"
        description: page.live.muted ? "Muted" : Math.round((page.live.volume || 0) * 100) + " %"
        Row {
            spacing: 12
            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: page.live.muted ? "volume_off" : "volume_up"
                tint: page.live.muted ? Theme.subtle : Theme.accent
                onClicked: page.action("muted", !page.live.muted)
            }
            Slider {
                anchors.verticalCenter: parent.verticalCenter
                width: 240
                value: page.live.volume || 0
                dimmed: !!page.live.muted
                onMoved: value => page.action("volume", value)
            }
        }
    }
    Toggle {
        name: "microphone"
        title: "Microphone"
        description: page.live.micMuted ? "Muted: apps hear nothing" : "On"
        on: !page.live.micMuted
    }
    SettingRow {
        objectName: "brightness"
        visible: page.live.brightness >= 0
        title: "Brightness"
        description: Math.round((page.live.brightness || 0) * 100) + " %"
        Slider {
            width: 290
            value: Math.max(0, page.live.brightness || 0)
            onMoved: value => page.action("brightness", value)
        }
    }

    Repeater {
        model: [["wifi", "Wi-Fi", "Networks…"], ["bluetooth", "Bluetooth", "Devices…"]]

        SettingRow {
            id: radio
            required property var modelData
            objectName: modelData[0]
            title: modelData[1]
            description: page.live[modelData[0]] ? "On" : "Off"
            Row {
                spacing: 14
                TextButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: radio.modelData[2]
                    onClicked: page.action("open-" + radio.modelData[0], true)
                }
                Switch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: !!page.live[radio.modelData[0]]
                    onToggled: checked => page.action(radio.modelData[0], checked)
                }
            }
        }
    }

    SettingRow {
        objectName: "keyboard"
        title: "Keyboard layout"
        description: "In use: " + (page.live.layout || "unknown")
        TextButton {
            text: "Next layout"
            icon: "keyboard"
            onClicked: page.action("next-layout", true)
        }
    }
    Toggle {
        name: "quiet"
        title: "Quiet mode"
        description: "Notifications wait in the system panel (SUPER + B); urgent ones still show."
        on: !!page.live.quiet
    }
    Toggle {
        name: "awake"
        title: "Stay awake"
        description: "The screen never dims, locks or sleeps on its own."
        on: !!page.live.awake
    }

    SettingRow {
        objectName: "sleep"
        title: "Sleep"
        description: "After how long without using the computer each step happens."
        wide: true
        Column {
            width: parent.width
            spacing: 10

            Repeater {
                model: [["idle.dim", "Dim the screen"], ["idle.lock", "Lock"], ["idle.screen_off", "Turn the screen off"],
                        ["idle.suspend", "Suspend"]]

                Row {
                    id: step
                    required property var modelData
                    spacing: 12
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 170
                        text: step.modelData[1]
                    }
                    Chips {
                        id: chips
                        width: page.width - 230
                        current: (page.live.idle || {})[step.modelData[0]]
                        model: Settings.steps(page.steps, chips.current)
                            .map(count => ({ value: count, label: Settings.minutes(count) }))
                        onPicked: value => page.action(step.modelData[0], value)
                    }
                }
            }
        }
    }
}
