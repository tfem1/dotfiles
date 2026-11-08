import QtQuick
import "../theme"
import "../components"

// A desktop widget's card: a small spaced-out title ("NOW PLAYING") and
// what it shows under it, on the panel color of the theme.
Rectangle {
    id: card

    property string title: ""
    default property alias inner: body.data

    implicitHeight: body.childrenRect.height + (title ? 46 : 28)
    radius: Theme.radius + 4
    color: Theme.panel
    border.width: 1
    border.color: Qt.alpha(Theme.surface, 0.8)

    Label {
        id: heading
        visible: card.title !== ""
        x: 16
        y: 13
        text: card.title.toUpperCase()
        small: true
        font.letterSpacing: 1.6
        font.weight: Font.DemiBold
    }

    Item {
        id: body
        x: 16
        y: card.title ? heading.y + heading.height + 9 : 14
        width: card.width - 32
        height: childrenRect.height
    }
}
