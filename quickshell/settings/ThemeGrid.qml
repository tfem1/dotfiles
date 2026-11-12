pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// Every theme as a small card in its own colors: its name and the three
// colors the shell takes from it. Chips above narrow the list.
Column {
    id: grid

    property var themes: []          // [{ id, name, family, variant, colors }]
    property string current: ""
    property string filter: "all"
    signal picked(string id)

    readonly property var shown: themes.filter(entry =>
        filter === "all" || (filter === "nature" ? ["Forest", "Cat"].includes(entry.family)
            : filter === "colors" ? entry.family === "Colors"
            : filter === "mono" ? entry.family === "Mono"
            : filter === "light" ? entry.variant === "light" : !["Forest", "Cat", "Colors", "Mono"].includes(entry.family)))
    readonly property int columns: Math.max(2, Math.floor(width / 190))

    spacing: 12

    Chips {
        width: parent.width
        current: grid.filter
        model: [
            { value: "all", label: "All · " + grid.themes.length },
            { value: "nature", label: "Forest & cats" },
            { value: "colors", label: "Colors" },
            { value: "known", label: "Well known" },
            { value: "mono", label: "Black & white" },
            { value: "light", label: "Light" }
        ]
        onPicked: value => grid.filter = value
    }

    Flow {
        width: parent.width
        spacing: 10

        Repeater {
            model: grid.shown

            Rectangle {
                id: card

                required property var modelData
                readonly property bool chosen: modelData.id === grid.current

                width: (grid.width - (grid.columns - 1) * 10) / grid.columns
                height: 76
                radius: Theme.radius + 6
                color: modelData.colors.bg
                border.width: chosen ? 2 : 1
                border.color: chosen ? Theme.accent : Qt.alpha(modelData.colors.fg, hover.hovered ? 0.35 : 0.12)

                Text {
                    x: 12
                    y: 10
                    width: parent.width - 40
                    text: card.modelData.name
                    color: card.modelData.colors.fgBright
                    font.family: Theme.fontSans
                    font.pixelSize: Math.round(Theme.fontPixels * 0.95)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Row {
                    x: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    spacing: 6

                    Repeater {
                        model: ["accent", "accent2", "accent3"]

                        Rectangle {
                            required property string modelData
                            width: 16
                            height: 16
                            radius: 8
                            color: card.modelData.colors[modelData]
                        }
                    }
                }
                Icon {
                    visible: card.chosen
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 9
                    name: "check"
                    color: card.modelData.colors.accent
                    size: 18
                }

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler { onTapped: grid.picked(card.modelData.id) }
            }
        }
    }
}
