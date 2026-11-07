pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// The power menu (SUPER + Escape, or the power button of the bar): lock,
// log out, suspend, restart, shut down. The last three ask for a second
// click (or Enter) before acting. Arrows move, letters pick, Escape closes.
Item {
    id: menu

    property string uptime: ""
    property int current: 0
    property string armed: ""          // action waiting for its confirmation
    signal chosen(string action)
    signal closed

    readonly property var actions: [
        { id: "lock", icon: "lock", title: "Lock", key: "L", confirm: false },
        { id: "logout", icon: "logout", title: "Log out", key: "E", confirm: true },
        { id: "suspend", icon: "bedtime", title: "Suspend", key: "S", confirm: false },
        { id: "reboot", icon: "restart_alt", title: "Restart", key: "R", confirm: true },
        { id: "poweroff", icon: "power_settings_new", title: "Shut down", key: "P", confirm: true }
    ]

    function pick(index) {
        const action = actions[index];
        current = index;
        if (action.confirm && armed !== action.id) {
            armed = action.id;
            disarm.restart();
            return;
        }
        chosen(action.id);
    }

    implicitWidth: row.implicitWidth + 64
    implicitHeight: column.implicitHeight + 56
    focus: true
    Keys.onEscapePressed: armed ? armed = "" : closed()
    Keys.onLeftPressed: current = (current + actions.length - 1) % actions.length
    Keys.onRightPressed: current = (current + 1) % actions.length
    Keys.onReturnPressed: pick(current)
    Keys.onEnterPressed: pick(current)
    Keys.onPressed: event => {
        const index = actions.findIndex(action => action.key === event.text.toUpperCase());
        if (index >= 0 && event.text) {
            pick(index);
            event.accepted = true;
        }
    }

    // A confirmation not given within 4 seconds is dropped.
    Timer {
        id: disarm
        interval: 4000
        onTriggered: menu.armed = ""
    }

    // The panel background keeps the labels readable over any wallpaper.
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius + 12
        color: Theme.panel
    }

    Column {
        id: column
        anchors.centerIn: parent
        spacing: 22

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: menu.uptime !== ""
            text: "Up for " + menu.uptime
            small: true
        }

        Row {
            id: row
            spacing: 18

            Repeater {
                model: menu.actions

                Column {
                    id: action
                    required property var modelData
                    required property int index
                    readonly property bool selected: menu.current === index
                    readonly property bool asking: menu.armed === modelData.id
                    spacing: 10

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 96
                        height: 96
                        radius: 48
                        color: action.asking ? Theme.red : action.selected ? Theme.accent
                            : hover.hovered ? Theme.surface : Theme.bgAlt
                        border.width: action.selected || action.asking ? 0 : 1
                        border.color: Theme.surface
                        Behavior on color { ColorAnimation { duration: Theme.duration } }

                        Icon {
                            anchors.centerIn: parent
                            name: action.modelData.icon
                            color: action.selected || action.asking ? Theme.bg : Theme.fg
                            size: 36
                        }
                        HoverHandler {
                            id: hover
                            onHoveredChanged: if (hovered) menu.current = action.index
                        }
                        TapHandler { onTapped: menu.pick(action.index) }
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: action.asking ? "Confirm?" : action.modelData.title
                        color: action.asking ? Theme.red : action.selected ? Theme.fgBright : Theme.fg
                        font.weight: action.selected ? Font.DemiBold : Font.Normal
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: action.modelData.key
                        small: true
                        mono: true
                    }
                }
            }
        }
    }
}
