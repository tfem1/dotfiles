import QtQuick

// Who signs in: avatar and name, with arrows on each side when the machine
// has several users (the last one who signed in comes first).
Item {
    id: switcher

    property int avatarSize: 96
    readonly property string userName: list.currentItem ? list.currentItem.login : ""
    readonly property int count: list.count

    function step(by) {
        if (list.count > 1)
            list.currentIndex = (list.currentIndex + by + list.count) % list.count;
    }

    implicitWidth: 340
    implicitHeight: avatarSize + 48

    ListView {
        id: list
        anchors.fill: parent
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        orientation: ListView.Horizontal
        interactive: false
        clip: true
        model: userModel
        currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 220

        delegate: Item {
            required property string name
            required property string realName
            required property string icon
            readonly property string login: name

            width: list.width
            height: list.height

            Avatar {
                id: face
                anchors.horizontalCenter: parent.horizontalCenter
                size: switcher.avatarSize
                source: parent.icon
                name: parent.realName || parent.name
            }
            Text {
                anchors.top: face.bottom
                anchors.topMargin: 12
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: parent.realName || parent.name
                color: config.fgBright
                font.family: config.font
                font.pixelSize: 22
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }
    }

    Repeater {
        model: switcher.count > 1 ? [-1, 1] : []

        Icon {
            required property int modelData
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -20
            x: modelData < 0 ? 0 : switcher.width - width
            name: modelData < 0 ? "chevron_left" : "chevron_right"
            color: arrowHover.hovered ? config.accent : config.subtle
            size: 28

            HoverHandler {
                id: arrowHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler { onTapped: switcher.step(parent.modelData) }
        }
    }
}
