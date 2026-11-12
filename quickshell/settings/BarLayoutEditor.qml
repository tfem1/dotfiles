pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "../bar/layout.js" as Layout

// The bar's modules in their three zones, and the hidden ones: drag a module
// to another place or zone, or into Hidden. `layout` is config.json
// bar.layout ("logo|media,workspaces,clock|status,power"); each drop sends
// the new text with changed().
Column {
    id: editor

    property string layout: ""
    readonly property var zones: Layout.parse(layout)
    signal changed(string layout)

    spacing: 8

    // Where a module dropped at `x` goes among the modules of a zone.
    function indexAt(flow, x) {
        let index = 0;
        for (let i = 0; i < flow.children.length; i++) {
            const slot = flow.children[i];
            if (slot.name !== undefined && slot.x + slot.width / 2 < x)
                index++;
        }
        return index;
    }

    Repeater {
        model: [{ zone: "start", label: "Start" }, { zone: "center", label: "Middle" },
                { zone: "end", label: "End" }, { zone: "hidden", label: "Hidden" }]

        Row {
            id: zoneRow
            required property var modelData
            spacing: 12

            Label {
                width: 64
                anchors.verticalCenter: parent.verticalCenter
                text: zoneRow.modelData.label
                small: true
                color: Theme.muted
            }

            Rectangle {
                width: editor.width - 76
                height: 46
                radius: 23
                color: drop.containsDrag ? Qt.alpha(Theme.accent, 0.12) : Theme.bg
                border.width: 1
                border.color: drop.containsDrag ? Theme.accent : Theme.surface

                DropArea {
                    id: drop
                    anchors.fill: parent
                    onDropped: event => {
                        const moved = Layout.move(editor.zones, event.source.name, zoneRow.modelData.zone,
                                                  editor.indexAt(flow, event.x - flow.x));
                        editor.changed(Layout.text(moved));
                    }
                }

                Flow {
                    id: flow
                    x: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 12
                    spacing: 6

                    Repeater {
                        model: editor.zones[zoneRow.modelData.zone]

                        Item {   // keeps the module's place while it is dragged away
                            id: slot
                            required property string modelData
                            readonly property string name: modelData
                            width: chip.width
                            height: chip.height

                            Rectangle {
                                id: chip
                                // Out of its zone while dragged; dropped before it goes back.
                                property bool dragging: false
                                width: label.implicitWidth + 44
                                height: 34
                                radius: 17
                                color: handler.active ? Qt.alpha(Theme.accent, 0.25) : Theme.surface
                                border.width: 1
                                border.color: Theme.accent
                                Drag.source: slot

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Icon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: "drag_indicator"
                                        color: Theme.muted
                                        size: 16
                                    }
                                    Label {
                                        id: label
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Layout.LABELS[slot.modelData]
                                        small: true
                                        color: Theme.fgBright
                                    }
                                }

                                DragHandler {
                                    id: handler
                                    cursorShape: Qt.ClosedHandCursor
                                    onActiveChanged: {
                                        if (active) {
                                            chip.dragging = true;
                                            // Dropped where the pointer is, not where the chip's middle is.
                                            chip.Drag.hotSpot = handler.centroid.pressPosition;
                                            chip.Drag.active = true;
                                        } else {
                                            chip.Drag.drop();
                                            chip.Drag.active = false;
                                            chip.dragging = false;
                                            chip.x = 0;
                                            chip.y = 0;
                                        }
                                    }
                                }
                                HoverHandler { cursorShape: Qt.OpenHandCursor }

                                // Above everything while dragged, across the zones.
                                states: State {
                                    when: chip.dragging
                                    ParentChange { target: chip; parent: editor }
                                    PropertyChanges { chip.z: 10 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
