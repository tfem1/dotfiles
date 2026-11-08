import QtQuick
import "../theme"
import "../components"
import "settings.js" as Settings

// The bar at the bottom of the Settings window while Appearance changes
// wait: how many, then Cancel and Apply.
Rectangle {
    id: bar

    property var pending: ({})
    property bool busy: false
    signal apply
    signal cancel

    height: Object.keys(pending).length > 0 ? 68 : 0
    visible: height > 0
    color: Theme.bgAlt

    Label {
        x: 28
        anchors.verticalCenter: parent.verticalCenter
        text: bar.busy ? "Applying…" : Settings.changes(bar.pending) + ", not applied yet"
    }
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 22
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        TextButton {
            text: "Cancel"
            onClicked: bar.cancel()
        }
        TextButton {
            text: "Apply"
            icon: "check"
            strong: true
            opacity: bar.busy ? 0.6 : 1
            onClicked: if (!bar.busy) bar.apply()
        }
    }
}
