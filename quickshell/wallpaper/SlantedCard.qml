import QtQuick
import "../theme"

// One wallpaper of the carousel: a slanted card, the picture leaning with
// it. No clipping is needed, so it draws the same with or without a GPU.
Item {
    id: card

    property url source
    property bool active: false   // the wallpaper in use: outlined
    property real slant: 0.12     // horizontal shift per pixel of height
    signal clicked

    transform: Matrix4x4 {
        // x' = x - slant * (y - height / 2): the top leans right.
        matrix: Qt.matrix4x4(1, -card.slant, 0, card.slant * card.height / 2,
                             0, 1, 0, 0,
                             0, 0, 1, 0,
                             0, 0, 0, 1)
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    Image {
        anchors.fill: parent
        source: card.source
        sourceSize: Qt.size(720, 480)
        fillMode: Image.PreserveAspectCrop
        // PreserveAspectCrop draws only what fits: nothing spills out.
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: card.active ? 3 : hover.hovered ? 2 : 0
        border.color: card.active ? Theme.accent : Theme.fgBright
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: card.clicked() }
}
