pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// The battery panel (a click on the battery in the bar): the level in a
// ring, charging or not, the time left, the battery's health, and the power
// profile (power saver, balanced, performance). Plain properties: shown with
// sample data by the preview.
Rectangle {
    id: panel

    property real level: 0              // 0 to 1
    property bool charging: false
    property real secondsLeft: 0        // to empty, or to full while charging (0: unknown)
    property real health: 0             // 0 to 100 (0: unknown)
    property string profile: "Balanced" // PowerSaver | Balanced | Performance
    property bool hasPerformance: true
    signal profilePicked(string profile)
    signal closed

    function duration(seconds) {
        const minutes = Math.round(seconds / 60);
        return minutes >= 60 ? Math.floor(minutes / 60) + " h " + (minutes % 60) + " min" : minutes + " min";
    }

    implicitWidth: 360
    implicitHeight: column.implicitHeight + 36
    radius: Theme.radius + 8
    color: Theme.panel
    border.width: 1
    border.color: Theme.edge
    focus: true
    Keys.onEscapePressed: closed()

    MouseArea { anchors.fill: parent }   // clicks inside do not close it

    Column {
        id: column
        x: 18
        y: 18
        width: parent.width - 36
        spacing: 16

        Row {
            spacing: 18
            RingProgress {
                width: 92
                height: 92
                thickness: 7
                value: panel.level
                color: panel.level < 0.15 && !panel.charging ? Theme.red : Theme.modules.battery
                track: Qt.alpha(Theme.fg, 0.15)
                Label {
                    anchors.centerIn: parent
                    text: Math.round(panel.level * 100) + " %"
                    color: Theme.fgBright
                    font.pixelSize: Math.round(Theme.fontPixels * 1.35)
                    font.weight: Font.Bold
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Row {
                    spacing: 6
                    Icon {
                        name: panel.charging ? "battery_charging_full" : "battery_full"
                        color: Theme.modules.battery
                        size: 18
                    }
                    Label {
                        text: panel.charging ? "Charging" : "On battery"
                        color: Theme.fgBright
                        font.weight: Font.DemiBold
                    }
                }
                Label {
                    visible: panel.secondsLeft > 0
                    text: panel.duration(panel.secondsLeft) + (panel.charging ? " until full" : " left")
                    small: true
                }
                Label {
                    visible: panel.health > 0
                    text: "Health " + Math.round(panel.health) + " %"
                    small: true
                }
            }
        }

        Label {
            text: "Power profile"
            small: true
            font.weight: Font.DemiBold
        }
        Row {
            width: parent.width
            spacing: 8
            Repeater {
                model: [["PowerSaver", "Saver", "eco"], ["Balanced", "Balanced", "tune"],
                        ["Performance", "Performance", "sports_esports"]].filter(p => p[0] !== "Performance" || panel.hasPerformance)
                Rectangle {
                    id: choice
                    required property var modelData
                    readonly property bool chosen: panel.profile === modelData[0]
                    width: (parent.width - 16) / 3
                    height: 64
                    radius: 18
                    color: chosen ? Qt.alpha(Theme.accent, 0.4) : hover.hovered ? Theme.surface : Qt.alpha(Theme.surface, 0.6)
                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: choice.modelData[2]
                            color: choice.chosen ? Theme.fgBright : Theme.fg
                            size: 20
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: choice.modelData[1]
                            small: true
                            color: choice.chosen ? Theme.fgBright : Theme.fg
                        }
                    }
                    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: panel.profilePicked(choice.modelData[0]) }
                }
            }
        }
    }
}
