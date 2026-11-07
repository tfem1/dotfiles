pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// The app launcher: a search field and the matching apps. Arrow keys move,
// Enter launches, Escape closes. `apps` is [{ name, comment, iconSource }].
Rectangle {
    id: launcher

    property var apps: []
    property alias query: search.text
    property alias currentIndex: list.currentIndex
    signal launched(int index)
    signal closed

    function focusSearch() {
        search.focusInput();
    }

    implicitWidth: 560
    implicitHeight: 76 + Math.min(list.count, 7) * 52
    radius: Theme.radius + 8
    color: Theme.panel

    // Keeps clicks inside the box from reaching what is behind it.
    MouseArea {
        anchors.fill: parent
    }

    SearchField {
        id: search
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        placeholder: "Search apps…"
        onTextChanged: list.currentIndex = 0
        onMoveDown: list.incrementCurrentIndex()
        onMoveUp: list.decrementCurrentIndex()
        onAccepted: if (list.count > 0) launcher.launched(list.currentIndex)
        onCancelled: launcher.closed()
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
