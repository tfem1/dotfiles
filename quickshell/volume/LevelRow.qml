import QtQuick
import "../theme"
import "../components"
import "sound.js" as Sound

// One volume: a mute button with its icon (or the app's own icon), a name,
// an optional detail line, the slider and the percentage.
Item {
    id: row

    property string icon: ""        // Material icon name
    property url iconSource         // app icon file, used instead when it loads
    property string title: ""
    property string detail: ""
    property real value: 0
    property bool muted: false
    property color tint: Theme.modules.audio
    signal moved(real value)
    signal muteToggled

    implicitHeight: detail ? 66 : 56

    Rectangle {
        id: badge
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 40
        radius: 20
        color: row.muted ? Theme.surface : Qt.alpha(row.tint, 0.2)

        Image {
            id: appIcon
            anchors.centerIn: parent
            width: 26
            height: 26
            sourceSize: Qt.size(52, 52)
            source: row.iconSource
            visible: status === Image.Ready
        }
        Icon {
            anchors.centerIn: parent
            visible: !appIcon.visible
            name: row.muted ? (row.icon === "mic" ? "mic_off" : "volume_off") : row.icon
            color: row.muted ? Theme.subtle : row.tint
            size: 20
        }
        TapHandler { onTapped: row.muteToggled() }
    }

    Column {
        anchors.left: badge.right
        anchors.leftMargin: 12
        anchors.right: amount.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Label {
            width: parent.width
            text: row.title
            textFormat: Text.PlainText
            color: Theme.fg
        }
        Label {
            width: parent.width
            visible: row.detail !== ""
            text: row.detail
            textFormat: Text.PlainText
            small: true
        }
        Slider {
            width: parent.width
            value: row.value
            tint: row.tint
            dimmed: row.muted
            onMoved: value => row.moved(value)
        }
    }

    Label {
        id: amount
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        horizontalAlignment: Text.AlignRight
        text: row.muted ? "Off" : Sound.percent(row.value)
        small: true
        color: row.muted ? Theme.subtle : Theme.fg
    }
}
