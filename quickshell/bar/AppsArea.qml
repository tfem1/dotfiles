pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// The running apps, at the left of the bar: one icon per app, a mark under
// those with a window (longer for the focused one). Click: bring the app
// forward; right click: its menu, with Quit. `apps` is
// [{ key, name, icon, windows, focused, tray }]. Never wider than
// `maxWidth`: the apps that do not fit are counted in a "+3".
Pill {
    id: area

    property var apps: []
    property real maxWidth: 400
    readonly property int fits: Math.max(1, Math.floor((maxWidth - padding * 2 - 30) / 32))
    readonly property var shown: apps.length > fits ? apps.slice(0, fits) : apps
    signal activated(var app)
    // x, y: where the menu opens, in the window's coordinates.
    signal menuRequested(var app, real x, real y)

    visible: apps.length > 0
    padding: 6
    spacing: 2
    color: Theme.bgAlt

    Repeater {
        model: area.shown

        Item {
            id: slot

            required property var modelData

            width: 30
            height: 32

            Rectangle {
                anchors.centerIn: parent
                width: 28
                height: 28
                radius: 9
                color: hover.hovered ? Theme.surface : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.duration } }
            }

            AppIcon {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                size: 18
                source: slot.modelData.icon
                name: slot.modelData.name
            }

            // An app only in the tray has no mark.
            Rectangle {
                visible: slot.modelData.windows > 0
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                width: slot.modelData.focused ? 12 : 4
                height: 3
                radius: 1.5
                color: slot.modelData.focused ? Theme.accent : Theme.subtle
                Behavior on width { NumberAnimation { duration: Theme.duration } }
            }

            HoverHandler { id: hover }
            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: area.activated(slot.modelData)
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: {
                    const corner = slot.mapToItem(null, 0, slot.height);
                    area.menuRequested(slot.modelData, corner.x, corner.y);
                }
            }
        }
    }

    Label {
        visible: area.apps.length > area.shown.length
        anchors.verticalCenter: parent.verticalCenter
        text: "+" + (area.apps.length - area.shown.length)
        small: true
    }
}
