import QtQuick
import "../theme"
import "../components"

// One setting: its name and a short sentence saying what it does, then its
// control on the right (or under the text when `wide`). `flash` lights the
// row up for a moment, when search brings you to it.
Rectangle {
    id: row

    property string title: ""
    property string description: ""
    property bool wide: false
    default property alias content: slot.data

    function flash() {
        glow.restart();
    }

    width: parent ? parent.width : 600
    implicitHeight: texts.implicitHeight + (wide ? slot.height + 14 : 0) + 30
    height: Math.max(implicitHeight, wide ? 0 : slot.height + 24)
    radius: Theme.radius + 8
    color: Theme.bgAlt

    Rectangle {
        id: highlight
        anchors.fill: parent
        radius: parent.radius
        color: Theme.accent
        opacity: 0

        SequentialAnimation on opacity {
            id: glow
            running: false
            NumberAnimation { to: 0.18; duration: 160 }
            PauseAnimation { duration: 700 }
            NumberAnimation { to: 0; duration: 500 }
        }
    }

    Column {
        id: texts
        x: 20
        y: 15
        width: row.wide ? row.width - 40 : row.width - 60 - slot.width
        spacing: 3

        Label {
            width: parent.width
            text: row.title
            color: Theme.fgBright
            font.weight: Font.DemiBold
        }
        Label {
            width: parent.width
            visible: text !== ""
            text: row.description
            small: true
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
        }
    }

    Item {
        id: slot
        x: row.wide ? 20 : row.width - 20 - width
        y: row.wide ? texts.y + texts.implicitHeight + 14 : (row.height - height) / 2
        width: row.wide ? row.width - 40 : childrenRect.width
        height: childrenRect.height
    }
}
