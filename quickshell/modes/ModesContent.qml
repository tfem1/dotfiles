pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// The modes menu (SUPER + K): one tile per mode, filled while it is on; a
// click (or its number) turns it on or off, Sleep locks and suspends. Plain
// properties: shown with sample data by the preview.
Rectangle {
    id: menu

    property var on: ({})        // { game, saver, coffee, night, quiet, presentation, focus }
    signal flipped(string mode)
    signal closed

    readonly property var modes: [
        { id: "game", icon: "sports_esports", title: "Gaming", text: "Tearing, CPU boost" },
        { id: "coffee", icon: "coffee", title: "Coffee", text: "Never sleeps" },
        { id: "night", icon: "dark_mode", title: "Night", text: "Warm, dim, quiet" },
        { id: "quiet", icon: "notifications_off", title: "Do not disturb", text: "Notifications wait" },
        { id: "saver", icon: "eco", title: "Power saver", text: "CPU saves, dim screen" },
        { id: "presentation", icon: "co_present", title: "Presentation", text: "No notifications" },
        { id: "focus", icon: "center_focus_strong", title: "Focus", text: "Quiet, no widgets" },
        { id: "sleep", icon: "mode_standby", title: "Sleep", text: "Lock and suspend" }
    ]

    implicitWidth: grid.width + 48
    implicitHeight: column.implicitHeight + 48
    radius: Theme.radius + 10
    color: Theme.bg
    border.width: 1
    border.color: Theme.surface
    focus: true
    Keys.onEscapePressed: closed()
    Keys.onPressed: event => {
        const index = event.key - Qt.Key_1;
        if (index >= 0 && index < modes.length) {
            flipped(modes[index].id);
            event.accepted = true;
        }
    }

    MouseArea { anchors.fill: parent }   // clicks inside never close it

    Column {
        id: column
        x: 24
        y: 24
        spacing: 16

        Column {
            spacing: 3
            Label {
                text: "Modes"
                color: Theme.fgBright
                font.pixelSize: Math.round(Theme.fontPixels * 1.3)
                font.weight: Font.DemiBold
            }
            Label {
                text: "A click turns a mode on or off; 1 to 8 work too, Escape closes."
                small: true
            }
        }

        Grid {
            id: grid
            columns: 4
            spacing: 10

            Repeater {
                model: menu.modes

                QuickTile {
                    required property var modelData
                    required property int index
                    readonly property bool active: !!menu.on[modelData.id]

                    width: 168
                    icon: modelData.icon
                    title: (index + 1) + "  " + modelData.title
                    subtitle: active ? "On" : modelData.text
                    on: active
                    onClicked: menu.flipped(modelData.id)
                }
            }
        }
    }
}
