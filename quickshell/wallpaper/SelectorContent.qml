pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "library.js" as Library

// The wallpaper selector: toolbar, then the wallpapers as a slanted
// carousel or a grid. Arrows browse, Enter applies, typing searches, Escape
// closes. `images` is [{ path, name, category }], `colors` { path: class },
// `recent` the paths picked last, newest first.
Item {
    id: selector

    property var images: []
    property var colors: ({})
    property var recent: []
    property string current: ""
    property alias grid: toolbar.grid
    property alias hue: toolbar.hue
    signal applied(string path, bool keepOpen)
    signal closed

    readonly property var shown: Library.filter(images, colors, toolbar.recent ? recent : null,
                                                toolbar.hue, toolbar.query)
    readonly property var selected: shown.length > 0 ? shown[view.currentIndex] : null

    function apply(index, keepOpen) {
        if (index >= 0 && index < shown.length)
            applied(shown[index].path, keepOpen);
    }

    function focusView() {
        view.forceActiveFocus();
    }

    // A new list starts on the wallpaper in use when it is part of it.
    onShownChanged: {
        carousel.currentIndex = Library.indexOf(shown, current);
        gridView.currentIndex = carousel.currentIndex;
    }
    Component.onCompleted: focusView()

    SelectorToolbar {
        id: toolbar
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.1)
        label: Library.label(selector.shown.length, hue, recent, query)
        onSearchDone: selector.focusView()
        // The other view takes over on the same wallpaper.
        onGridChanged: {
            selector.view.currentIndex = (toolbar.grid ? carousel : gridView).currentIndex;
            selector.focusView();
        }
        onRandomPicked: {
            const index = Math.floor(Math.random() * selector.shown.length);
            selector.view.currentIndex = index;
            selector.apply(index, true);
        }
    }

    Item {
        id: area
        anchors.top: toolbar.bottom
        anchors.topMargin: 28
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(460, parent.height * 0.45)
    }

    Carousel {
        id: carousel
        anchors.fill: area
        visible: !toolbar.grid
        model: selector.shown
        activePath: selector.current
        onPicked: index => selector.apply(index, false)
    }

    GridView {
        id: gridView
        anchors.horizontalCenter: area.horizontalCenter
        anchors.top: area.top
        width: Math.min(area.width - 80, 1290)
        height: area.height
        visible: toolbar.grid
        clip: true
        model: selector.shown
        cellWidth: width / Math.max(1, Math.floor(width / 258))
        cellHeight: cellWidth * 0.62
        highlightMoveDuration: Theme.duration

        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            width: GridView.view.cellWidth
            height: GridView.view.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 6
                radius: 0 // square like the carousel cards: images are not clipped
                color: Theme.surface
                border.width: cell.modelData.path === selector.current ? 3 : cell.GridView.isCurrentItem ? 2 : 0
                border.color: cell.modelData.path === selector.current ? Theme.accent : Theme.fgBright

                Image {
                    anchors.fill: parent
                    anchors.margins: parent.border.width
                    source: Library.fileUrl(cell.modelData.path)
                    sourceSize: Qt.size(400, 250)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                TapHandler { onTapped: selector.apply(cell.index, false) }
            }
        }
    }

    // The shown view has the keyboard: arrows move in it, the other keys
    // come up here.
    readonly property var view: toolbar.grid ? gridView : carousel

    Keys.onReturnPressed: apply(view.currentIndex, false)
    Keys.onEnterPressed: apply(view.currentIndex, false)
    Keys.onEscapePressed: closed()
    Keys.onPressed: event => {
        // Typing a letter or a digit starts a search with it.
        const c = event.text;
        const typed = c.length === 1 && (c.toLowerCase() !== c.toUpperCase() || (c >= "0" && c <= "9"));
        if (typed && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier))) {
            toolbar.focusSearch();
            toolbar.query += event.text;
            event.accepted = true;
        }
    }

    Column {
        anchors.top: area.bottom
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: selector.selected ? (selector.selected.category ? selector.selected.category + " · " : "") + selector.selected.name
                : selector.images.length ? "No wallpaper matches" : "No wallpaper yet: run tfem wallpapers fetch"
            color: Theme.fgBright
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "← → browse · Enter apply · type to search · Esc close"
            small: true
        }
    }
}
