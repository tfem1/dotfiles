import QtQuick
import "../theme"

// An app's own icon, or the first letter of its name while it has none.
Item {
    id: appIcon

    property string source: ""
    property string name: ""
    property int size: 18

    implicitWidth: size
    implicitHeight: size

    Image {
        id: image
        anchors.fill: parent
        source: appIcon.source
        sourceSize: Qt.size(appIcon.size * 2, appIcon.size * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        visible: image.status !== Image.Ready
        radius: width / 3
        color: Theme.surface

        Text {
            anchors.centerIn: parent
            text: (appIcon.name || "?").charAt(0).toUpperCase()
            color: Theme.fgBright
            font.family: Theme.fontSans
            font.pixelSize: Math.round(appIcon.size * 0.55)
            font.weight: Font.DemiBold
        }
    }
}
