pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "../settings"
import "places.js" as Places

// The widgets on the whole desktop: those never moved stacked in their
// corner (WidgetsContent), the others where they were dropped. While
// `editing`, every widget can be dragged (moved(name, x, y), in parts of the
// screen), "Back to the corner" puts them all back (reset), Done or Escape
// ends (done).
Item {
    id: desktop

    property alias show: stack.show
    property alias now: stack.now
    property alias cpu: stack.cpu
    property alias gpu: stack.gpu
    property alias ram: stack.ram
    property alias disk: stack.disk
    property alias levels: stack.levels
    property alias device: stack.device
    property alias hasMedia: stack.hasMedia
    property alias media: stack.media
    property var places: ({})          // saved: name -> [x, y]
    property bool editing: false
    property var moving: ({})           // while editing: every widget, name -> [x, y]
    readonly property var shownPlaces: editing ? moving : places
    readonly property string corner: show.corner || "top-left"
    signal moved(string name, real x, real y)
    signal reset
    signal done

    // Editing starts with each widget where it is now.
    onEditingChanged: {
        if (!editing)
            return;
        const all = Object.assign({}, places);
        for (const block of stack.children) {
            if (!block.objectName || !block.visible)
                continue;
            const at = block.mapToItem(desktop, 0, 0);
            all[block.objectName] = Places.fraction(at.x, at.y, block.width, block.height, width, height);
        }
        moving = all;
        forceActiveFocus();
    }

    Keys.onEscapePressed: done()

    Rectangle {   // the desktop dims a little while editing
        anchors.fill: parent
        visible: desktop.editing
        color: Qt.alpha(Theme.bg, 0.3)
    }

    WidgetsContent {
        id: stack
        places: desktop.shownPlaces
        x: desktop.corner.endsWith("right") ? desktop.width - width - 24 : 24
        y: desktop.corner.startsWith("bottom") ? desktop.height - implicitHeight - 24 : 16
    }

    Repeater {
        model: Object.keys(desktop.shownPlaces)

        Item {
            id: placed
            required property string modelData
            readonly property var at: desktop.shownPlaces[modelData] || [0, 0]
            property point pull: Qt.point(0, 0)   // while dragged
            width: block.width
            height: block.height
            visible: block.shown
            x: at[0] * (desktop.width - width) + pull.x
            y: at[1] * (desktop.height - height) + pull.y

            WidgetBlock {
                id: block
                name: placed.modelData
                feed: stack.feed
                rightSide: placed.at[0] > 0.5
            }

            Rectangle {   // editing: a frame and a grip
                anchors.fill: parent
                anchors.margins: -6
                visible: desktop.editing
                radius: Theme.radius + 6
                color: dragger.active ? Qt.alpha(Theme.accent, 0.12) : "transparent"
                border.width: 2
                border.color: dragger.active ? Theme.accent : Qt.alpha(Theme.accent, 0.5)
            }

            DragHandler {
                id: dragger
                enabled: desktop.editing
                target: null
                onActiveTranslationChanged: if (active) placed.pull = activeTranslation
                onActiveChanged: {
                    if (active)
                        return;
                    const spot = Places.fraction(placed.x, placed.y, placed.width, placed.height,
                                                 desktop.width, desktop.height);
                    desktop.moving = Object.assign({}, desktop.moving, { [placed.modelData]: spot });
                    placed.pull = Qt.point(0, 0);
                    desktop.moved(placed.modelData, spot[0], spot[1]);
                }
            }
        }
    }

    // What to do while editing.
    Rectangle {
        visible: desktop.editing
        anchors.horizontalCenter: parent.horizontalCenter
        y: 70
        width: bar.implicitWidth + 32
        height: 52
        radius: 26
        color: Theme.bg
        border.width: 1
        border.color: Theme.accent

        Row {
            id: bar
            anchors.centerIn: parent
            spacing: 12
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: "Drag the widgets where you want them"
            }
            TextButton {
                text: "Back to the corner"
                onClicked: {
                    desktop.moving = {};
                    desktop.reset();
                }
            }
            TextButton {
                text: "Done"
                icon: "check"
                strong: true
                onClicked: desktop.done()
            }
        }
    }
}
