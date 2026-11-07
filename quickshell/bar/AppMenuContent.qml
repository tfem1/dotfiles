pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// The menu of a running app (right click in the bar): its icon and name,
// the entries of its own tray menu when it has one, then Quit. `rows` is
// [{ text, enabled, separator, submenu, index }]. Escape closes it.
Rectangle {
    id: menu

    property string name: ""
    property string icon: ""
    property string detail: ""        // "2 windows", "In the tray"
    property var rows: []
    property bool nested: false       // inside a submenu: Back comes first
    property bool canQuit: true
    signal entryClicked(int index)
    signal back
    signal quit
    signal closed

    implicitWidth: 250
    implicitHeight: column.implicitHeight + 12
    radius: Theme.radius
    color: Theme.panel
    border.width: 1
    border.color: Theme.surface
    focus: true
    Keys.onEscapePressed: nested ? back() : closed()

    // One clickable line: icon, text, and a chevron for a submenu. Inline
    // components do not see this file's ids: the width is set where used.
    component Line: Rectangle {
        id: line

        property string icon: ""
        property string text: ""
        property color tint: Theme.fg
        property bool active: true
        property bool submenu: false
        signal clicked

        height: 34
        radius: Theme.radius - 4
        color: lineHover.hovered && active ? Qt.alpha(tint, 0.14) : "transparent"
        opacity: active ? 1 : 0.45

        Icon {
            id: lineIcon
            visible: line.icon !== ""
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            name: line.icon
            color: line.tint
            size: 16
        }
        Label {
            anchors.left: parent.left
            anchors.leftMargin: line.icon !== "" ? 36 : 12
            anchors.right: parent.right
            anchors.rightMargin: line.submenu ? 30 : 10
            anchors.verticalCenter: parent.verticalCenter
            text: line.text
            color: line.tint
        }
        Icon {
            visible: line.submenu
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            name: "chevron_right"
            color: Theme.subtle
            size: 16
        }
        HoverHandler { id: lineHover }
        TapHandler { onTapped: if (line.active) line.clicked() }
    }

    component Separator: Rectangle {
        height: 9
        color: "transparent"
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 16
            height: 1
            color: Theme.surface
        }
    }

    Column {
        id: column
        x: 6
        y: 6
        width: parent.width - 12

        Item {
            width: parent.width
            height: 48

            AppIcon {
                id: headIcon
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                size: 28
                source: menu.icon
                name: menu.name
            }
            Column {
                anchors.left: headIcon.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    width: parent.width
                    text: menu.name
                    color: Theme.fgBright
                    font.weight: Font.DemiBold
                }
                Label {
                    visible: menu.detail !== ""
                    width: parent.width
                    text: menu.detail
                    small: true
                }
            }
        }

        Separator {
            visible: menu.nested || menu.rows.length > 0 || menu.canQuit
            width: column.width
        }

        Line {
            visible: menu.nested
            width: column.width
            icon: "chevron_left"
            text: "Back"
            onClicked: menu.back()
        }

        Repeater {
            model: menu.rows

            Loader {
                id: row
                required property var modelData
                width: column.width
                sourceComponent: modelData.separator ? separatorRow : entryRow

                Component {
                    id: separatorRow
                    Separator {}
                }
                Component {
                    id: entryRow
                    Line {
                        text: row.modelData.text
                        active: row.modelData.enabled
                        submenu: row.modelData.submenu
                        onClicked: menu.entryClicked(row.modelData.index)
                    }
                }
            }
        }

        Separator {
            visible: menu.canQuit && !menu.nested && menu.rows.length > 0
            width: column.width
        }

        Line {
            visible: menu.canQuit && !menu.nested
            width: column.width
            icon: "close"
            text: "Quit " + menu.name
            tint: Theme.red
            onClicked: menu.quit()
        }
    }
}
