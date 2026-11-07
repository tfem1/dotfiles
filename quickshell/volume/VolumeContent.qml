pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "sound.js" as Sound

// The volume panel (SUPER + V): output and microphone with their devices,
// then the volume of each app playing sound. Colors: the audio module
// color of the theme. Plain data in, requests out (VolumePanel.qml).
// output / input: { name, volume, muted, devices: [{ ref, name, current }] }
// apps: [{ ref, name, detail, iconSource, volume, muted }]
Rectangle {
    id: panel

    property var output: ({ name: "", volume: 0, muted: false, devices: [] })
    property var input: ({ name: "", volume: 0, muted: false, devices: [] })
    property var apps: []
    signal outputMoved(real volume)
    signal outputMuteToggled
    signal outputChosen(var ref)
    signal inputMoved(real volume)
    signal inputMuteToggled
    signal inputChosen(var ref)
    signal appMoved(var ref, real volume)
    signal appMuteToggled(var ref)
    signal closed

    readonly property color tint: Theme.modules.audio

    component Title: Label {
        x: 4
        topPadding: 6
        bottomPadding: 2
        small: true
        font.weight: Font.DemiBold
    }

    implicitWidth: 440
    implicitHeight: Math.min(column.implicitHeight + 32, 720)
    radius: Theme.radius + 8
    color: Theme.panel
    focus: true
    Keys.onEscapePressed: closed()

    // Keeps clicks inside the panel from closing it.
    MouseArea {
        anchors.fill: parent
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 16
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column
            width: parent.width
            spacing: 4

            Title { text: "Output" }
            LevelRow {
                width: column.width
                icon: Sound.deviceIcon(panel.output.name, false)
                title: panel.output.name || "No output"
                value: panel.output.volume
                muted: panel.output.muted
                tint: panel.tint
                onMoved: volume => panel.outputMoved(volume)
                onMuteToggled: panel.outputMuteToggled()
            }
            Repeater {
                model: panel.output.devices.length > 1 ? panel.output.devices : []
                ChoiceRow {
                    required property var modelData
                    width: column.width
                    icon: Sound.deviceIcon(modelData.name, false)
                    title: modelData.name
                    current: modelData.current
                    tint: panel.tint
                    onChosen: panel.outputChosen(modelData.ref)
                }
            }

            Title { text: "Microphone"; visible: panel.input.devices.length > 0 }
            LevelRow {
                visible: panel.input.devices.length > 0
                width: column.width
                icon: "mic"
                title: panel.input.name
                value: panel.input.volume
                muted: panel.input.muted
                tint: panel.tint
                onMoved: volume => panel.inputMoved(volume)
                onMuteToggled: panel.inputMuteToggled()
            }
            Repeater {
                model: panel.input.devices.length > 1 ? panel.input.devices : []
                ChoiceRow {
                    required property var modelData
                    width: column.width
                    icon: "mic"
                    title: modelData.name
                    current: modelData.current
                    tint: panel.tint
                    onChosen: panel.inputChosen(modelData.ref)
                }
            }

            Title { text: "Apps" }
            Repeater {
                model: panel.apps
                LevelRow {
                    required property var modelData
                    width: column.width
                    icon: "music_note"
                    iconSource: modelData.iconSource || ""
                    title: modelData.name
                    detail: modelData.detail || ""
                    value: modelData.volume
                    muted: modelData.muted
                    tint: panel.tint
                    onMoved: volume => panel.appMoved(modelData.ref, volume)
                    onMuteToggled: panel.appMuteToggled(modelData.ref)
                }
            }
            Label {
                visible: panel.apps.length === 0
                x: 4
                topPadding: 4
                text: "No app is playing sound"
                small: true
            }
        }
    }
}
