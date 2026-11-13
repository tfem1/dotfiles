pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// The dock: the app grid button (the launcher), one tile per app (lit in
// the accent color while it runs, a mark under it, longer for the focused
// one), then the Settings button. Its colors come from the theme; `opacity` (dock.opacity) is
// how much of the background shows. Plain properties: shown with sample data
// by the preview.
Rectangle {
    id: dock

    property var apps: []           // [{ id, name, icon (url), pinned, running, focused }]
    property string edge: "bottom"  // bottom | left | right: the screen edge it stands on
    readonly property bool vertical: edge !== "bottom"
    property real fill: 0.85        // dock.opacity
    signal activated(string id)
    signal pinToggled(string id)
    signal launcherClicked
    signal settingsClicked

    // The two buttons at the ends: an icon on the dock's own background.
    component EndButton: Rectangle {
        property string icon: ""
        signal clicked
        width: dock.size
        height: dock.size
        radius: 14
        color: endHover.hovered ? Theme.surface : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.duration } }
        Icon {
            anchors.centerIn: parent
            name: parent.icon
            color: Theme.accent
            size: 24
        }
        HoverHandler { id: endHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: parent.clicked() }
    }

    readonly property int size: 44
    implicitWidth: vertical ? size + 20 : row.implicitWidth + 20
    implicitHeight: vertical ? row.implicitHeight + 20 : size + 20
    radius: Math.min(Theme.radius + 14, Math.min(width, height) / 2)
    color: Qt.alpha(Theme.bg, fill)
    border.width: 1
    border.color: Qt.alpha(Theme.accent, 0.25)

    Grid {
        id: row
        anchors.centerIn: parent
        columns: dock.vertical ? 1 : -1
        rows: dock.vertical ? -1 : 1
        spacing: 10

        EndButton {
            icon: "apps"
            onClicked: dock.launcherClicked()
        }

        Repeater {
            model: dock.apps

            Item {
                id: app
                required property var modelData
                width: dock.size
                height: dock.size

                Rectangle {   // the tile: lit while the app runs
                    anchors.fill: parent
                    radius: 14
                    color: app.modelData.running > 0 ? Qt.alpha(Theme.accent, hover.hovered ? 0.75 : 0.6)
                         : hover.hovered ? Qt.lighter(Theme.surface, 1.25) : Theme.surface
                    Behavior on color { ColorAnimation { duration: Theme.duration } }
                }
                Image {
                    id: picture
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    sourceSize: Qt.size(64, 64)
                    source: app.modelData.icon || ""
                    visible: status === Image.Ready
                    scale: hover.hovered ? 1.12 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.duration } }
                }
                Label {   // no icon: the first letter
                    anchors.centerIn: parent
                    visible: !picture.visible
                    text: (app.modelData.name || app.modelData.id || "?").charAt(0).toUpperCase()
                    color: Theme.accent
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }
                // Running: a dot (a bar when focused), on the side of the screen edge.
                Rectangle {
                    visible: app.modelData.running > 0
                    width: dock.vertical ? 4 : (app.modelData.focused ? 16 : 6)
                    height: dock.vertical ? (app.modelData.focused ? 16 : 6) : 4
                    radius: 2
                    color: app.modelData.focused ? Theme.accent : Theme.accent2
                    x: dock.edge === "left" ? -6 : dock.edge === "right" ? parent.width + 2 : (parent.width - width) / 2
                    y: dock.vertical ? (parent.height - height) / 2 : parent.height + 2
                }

                HoverHandler { id: hover }
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: dock.activated(app.modelData.id)
                }
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: dock.pinToggled(app.modelData.id)
                }
            }
        }
        Rectangle {   // between the apps and Settings
            width: dock.vertical ? dock.size - 12 : 1
            height: dock.vertical ? 1 : dock.size - 12
            color: Qt.alpha(Theme.fg, 0.2)
        }
        EndButton {
            icon: "settings"
            onClicked: dock.settingsClicked()
        }
    }
}
