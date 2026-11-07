pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// The clipboard history: a search field and the copied entries, newest
// first. Arrow keys move, Enter copies, Escape closes.
// `entries` is [{ text, image }].
Rectangle {
    id: box

    property var entries: []
    property alias query: search.text
    signal chosen(int index)
    signal closed

    function focusSearch() {
        search.focusInput();
    }

    implicitWidth: 560
    implicitHeight: 76 + Math.max(1, Math.min(list.count, 8)) * 44
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
        placeholder: "Search the clipboard…"
        onTextChanged: list.currentIndex = 0
        onMoveDown: list.incrementCurrentIndex()
        onMoveUp: list.decrementCurrentIndex()
        onAccepted: if (list.count > 0) box.chosen(list.currentIndex)
        onCancelled: box.closed()
    }

    Label {
        anchors.centerIn: list
        visible: list.count === 0
        text: box.query ? "No match" : "Nothing copied yet"
        small: true
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
        model: box.entries
        highlightMoveDuration: Theme.duration

        delegate: Rectangle {
            id: entry

            required property var modelData
            required property int index
            readonly property bool current: ListView.isCurrentItem

            width: ListView.view.width
            height: 44
            radius: 12
            color: current ? Qt.alpha(Theme.accent, 0.18) : hover.hovered ? Theme.surface : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.duration } }

            Icon {
                id: kind
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                name: entry.modelData.image ? "image" : "content_paste"
                color: entry.current ? Theme.accent : Theme.subtle
                size: 18
            }
            Label {
                anchors.left: kind.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: entry.modelData.text
                textFormat: Text.PlainText // copied text may look like markup
                color: entry.current ? Theme.fgBright : Theme.fg
            }

            HoverHandler { id: hover }
            TapHandler { onTapped: box.chosen(entry.index) }
        }
    }
}
