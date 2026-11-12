pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "overview.js" as OverviewLib

// The workspace overview (SUPER + Tab): workspaces 1 to 10 in two rows,
// each a small screen with its windows where they are. A click on a
// workspace goes there, on a window brings it forward; dragging a window
// onto another workspace moves it there. 1 to 9 and 0 pick a workspace,
// Escape closes. `thumbnail`: how a window is drawn (the real shell shows a
// live picture of it; by default, its name).
Item {
    id: overview

    property var workspaces: []       // OverviewLib.model(...)
    property real ratio: 16 / 9       // the screen's width / height
    property Component thumbnail: null
    signal workspacePicked(int id)
    signal windowPicked(string address)
    signal windowMoved(string address, int workspace)
    signal closed

    readonly property real cardWidth: Math.min((width - 120) / 5, 360)
    readonly property real cardHeight: cardWidth / ratio

    focus: true
    Keys.onEscapePressed: closed()
    Keys.onPressed: event => {
        const id = OverviewLib.workspaceForKey(event.text);
        if (id > 0) {
            workspacePicked(id);
            event.accepted = true;
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 18

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: hint.implicitWidth + 32
            height: 34
            radius: 17
            color: Qt.alpha(Theme.bg, 0.85)
            Label {
                id: hint
                anchors.centerIn: parent
                text: "Click a workspace or a window · drag a window to another workspace · 1–0 · Esc"
                small: true
            }
        }

        Grid {
            columns: 5
            spacing: 18

            Repeater {
                model: overview.workspaces

                Rectangle {
                    id: card
                    required property var modelData
                    property bool dragging: false   // one of its windows is being dragged out
                    z: dragging ? 5 : 0
                    width: overview.cardWidth
                    height: overview.cardHeight
                    radius: Theme.radius
                    color: Qt.alpha(Theme.bg, 0.78)
                    border.width: modelData.focused || drop.containsDrag ? 2 : 1
                    border.color: drop.containsDrag ? Theme.accent2 : modelData.focused ? Theme.accent : Theme.surface

                    TapHandler { onTapped: overview.workspacePicked(card.modelData.id) }
                    DropArea {
                        id: drop
                        anchors.fill: parent
                        onDropped: event => overview.windowMoved(event.source.address, card.modelData.id)
                    }

                    // The number, above the windows.
                    Rectangle {
                        z: 20
                        x: 8
                        y: 8
                        width: number.implicitWidth + 16
                        height: 24
                        radius: 12
                        color: card.modelData.focused ? Theme.accent : Qt.alpha(Theme.bg, 0.9)
                        Label {
                            id: number
                            anchors.centerIn: parent
                            text: card.modelData.id
                            color: card.modelData.focused ? Theme.bg : Theme.fg
                            font.weight: Font.Bold
                            small: true
                        }
                    }

                    Repeater {
                        model: card.modelData.windows

                        Rectangle {
                            id: shot
                            required property var modelData
                            readonly property string address: modelData.address
                            property real homeX: 4 + modelData.x * (card.width - 8)
                            property real homeY: 4 + modelData.y * (card.height - 8)
                            x: homeX
                            y: homeY
                            width: Math.max(18, Math.min(modelData.w, 1 - modelData.x) * (card.width - 8))
                            height: Math.max(14, Math.min(modelData.h, 1 - modelData.y) * (card.height - 8))
                            radius: 6
                            color: Theme.bgAlt
                            border.width: modelData.focused ? 2 : 1
                            border.color: modelData.focused ? Theme.accent : Qt.alpha(Theme.accent, 0.3)
                            clip: true
                            z: dragger.active ? 10 : 1
                            Drag.active: dragger.active
                            Drag.source: shot
                            Drag.hotSpot.x: width / 2
                            Drag.hotSpot.y: height / 2

                            Loader {
                                id: picture
                                anchors.fill: parent
                                anchors.margins: 1
                                property var window: shot.modelData
                                sourceComponent: overview.thumbnail
                            }
                            Label {   // the name, when there is no picture
                                visible: !picture.item
                                anchors.centerIn: parent
                                width: parent.width - 8
                                horizontalAlignment: Text.AlignHCenter
                                text: shot.modelData.appClass || shot.modelData.title
                                small: true
                            }

                            DragHandler {
                                id: dragger
                                onActiveChanged: {
                                    card.dragging = active;
                                    if (active)
                                        return;
                                    shot.Drag.drop();
                                    shot.x = shot.homeX;
                                    shot.y = shot.homeY;
                                }
                            }
                            TapHandler { onTapped: overview.windowPicked(shot.modelData.address) }
                        }
                    }
                }
            }
        }
    }
}
