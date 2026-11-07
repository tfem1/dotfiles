import QtQuick
import "../theme"
import "../components"

// The app launcher: a search field and the matching apps. Arrow keys move,
// Enter launches, Escape closes. `apps` is [{ name, comment, iconSource }].
Rectangle {
    id: launcher

    property var apps: []
    property alias query: field.text
    property alias currentIndex: list.currentIndex
    signal launched(int index)
    signal closed

    function focusSearch() {
        field.forceActiveFocus();
    }

    implicitWidth: 560
    implicitHeight: 76 + Math.min(list.count, 7) * 52
    radius: Theme.radius + 8
    color: Theme.panel

    // Keeps clicks inside the box from reaching what is behind it.
    MouseArea {
        anchors.fill: parent
    }

    Rectangle {
        id: search
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        height: 48
        radius: 24
        color: Theme.surface

        Icon {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            name: "search"
            color: Theme.accent
            size: 20
        }
        TextInput {
            id: field
            anchors.left: searchIcon.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.fg
            selectionColor: Theme.accent
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontPixels * 1.15
            focus: true
            onTextChanged: list.currentIndex = 0
            Keys.onDownPressed: list.incrementCurrentIndex()
            Keys.onUpPressed: list.decrementCurrentIndex()
            Keys.onReturnPressed: if (list.count > 0) launcher.launched(list.currentIndex)
            Keys.onEscapePressed: launcher.closed()

            Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: field.text === ""
                text: "Search apps…"
                color: Theme.subtle
                font.pixelSize: field.font.pixelSize
            }
        }
    }

    ListView {
        id: list
        anchors.top: search.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        clip: true
        model: launcher.apps
        highlightMoveDuration: Theme.duration

        delegate: LauncherItem {
            required property var modelData
            required property int index
            width: ListView.view.width
            name: modelData.name
            comment: modelData.comment || ""
            iconSource: modelData.iconSource || ""
            selected: ListView.isCurrentItem
            onActivated: launcher.launched(index)
        }
    }
}
