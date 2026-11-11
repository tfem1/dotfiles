import QtQuick
import "../theme"
import "../components"

// A desktop widget's card: a small spaced-out title ("NOW PLAYING") and
// what it shows under it, a little see-through (the blur of Hyprland shows
// behind it), with very round corners.
Rectangle {
    id: card

    property string title: ""
    default property alias inner: body.data

    implicitHeight: body.childrenRect.height + (title ? 50 : 32)
    radius: Math.min(height / 2, Theme.radius + 20)
    color: Qt.alpha(Theme.bg, 0.62)
    border.width: 1
    border.color: Qt.alpha(Theme.accent, 0.3)

    Label {
        id: heading
        visible: card.title !== ""
        x: 22
        y: 15
        text: card.title.toUpperCase()
        small: true
        font.letterSpacing: 1.6
        font.weight: Font.DemiBold
    }

    Item {
        id: body
        x: 22
        y: card.title ? heading.y + heading.height + 9 : 16
        width: card.width - 44
        height: childrenRect.height
    }
}
