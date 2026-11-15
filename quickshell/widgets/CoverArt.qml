import QtQuick
import QtQuick.Effects
import "../theme"
import "../components"

// The song's cover in a soft scalloped shape, or a music note on the
// theme's surface when the player gives none.
Item {
    id: cover

    property url source
    property string kind: "cookie"

    OrganicShape {
        id: shape
        anchors.fill: parent
        kind: cover.kind
        fill: Theme.surface
        stroke: "transparent"
        layer.enabled: picture.status === Image.Ready   // the mask of the picture
    }
    Image {
        id: picture
        anchors.fill: parent
        source: cover.source
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        visible: picture.status === Image.Ready
        source: picture
        maskEnabled: true
        maskSource: shape
    }
    Icon {
        anchors.centerIn: parent
        visible: picture.status !== Image.Ready
        name: "music_note"
        color: Theme.fgBright
        size: Math.round(cover.width * 0.38)
    }
}
