pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// Fonts: the interface font (bar, panels, apps) and the monospace one
// (terminal), each picked in the list of the fonts installed (fc-list),
// drawn in its own face, with its size. They act at once (`tfem settings
// set font.*`): the shell, kitty, GTK, Qt and the lock screen follow.
Column {
    id: page

    property var values: ({})        // `tfem settings get` values
    property var fonts: ({ all: [], mono: [] })   // installed families
    property string which: "sans"    // the font being picked: sans | mono
    signal action(string name, var value)

    readonly property string sans: values["font.sans"] || "Monocraft"
    readonly property string mono: values["font.mono"] || "Monocraft"
    readonly property string current: which === "mono" ? mono : sans
    readonly property var shown: (which === "mono" ? fonts.mono : fonts.all)
        .filter(name => !filter.text || name.toLowerCase().includes(filter.text.toLowerCase()))

    spacing: 12

    // What it looks like.
    Rectangle {
        width: page.width
        height: sample.implicitHeight + 36
        radius: Theme.radius + 8
        color: Theme.bgAlt

        Column {
            id: sample
            x: 22
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Text {
                text: "The quick brown fox jumps over the lazy dog"
                color: Theme.fgBright
                font.family: page.sans
                font.pixelSize: Math.round((page.values["font.size"] || 11) * 4 / 3 * 1.3)
            }
            Text {
                text: "$ tfem generate   # 0O 1lI {}[] => !="
                color: Theme.accent
                font.family: page.mono
                font.pixelSize: Math.round((page.values["font.mono_size"] || 11) * 4 / 3)
            }
        }
    }

    Repeater {
        model: [
            { key: "sans", title: "Interface text", text: "The bar, the panels, the Settings, GTK and Qt apps." },
            { key: "mono", title: "Monospace text", text: "The terminal (kitty) and code." }
        ]

        SettingRow {
            id: row
            required property var modelData
            readonly property string sizeKey: modelData.key === "mono" ? "font.mono_size" : "font.size"
            objectName: "font-" + modelData.key
            width: page.width
            title: modelData.title + "  ·  " + (modelData.key === "mono" ? page.mono : page.sans)
            description: modelData.text
            Row {
                spacing: 10
                Chips {
                    current: page.values[row.sizeKey] || 11
                    model: [9, 10, 11, 12, 13, 14].map(size => ({ label: String(size), value: size }))
                    onPicked: value => page.action("font", { key: row.sizeKey, value: value })
                }
                TextButton {
                    text: page.which === row.modelData.key ? "Picking…" : "Change"
                    strong: page.which === row.modelData.key
                    onClicked: page.which = row.modelData.key
                }
            }
        }
    }

    // The fonts installed, each in its own face.
    Rectangle {
        width: page.width
        height: 330
        radius: Theme.radius + 8
        color: Theme.bgAlt

        SearchField {
            id: filter
            x: 14
            y: 14
            width: parent.width - 28
            placeholder: page.which === "mono" ? "Search a monospace font" : "Search a font"
        }

        ListView {
            id: list
            x: 10
            y: filter.y + filter.height + 10
            width: parent.width - 20
            height: parent.height - y - 10
            clip: true
            spacing: 4
            model: page.shown
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: entry
                required property string modelData
                readonly property bool chosen: modelData === page.current
                width: list.width
                height: 40
                radius: height / 2
                color: chosen ? Qt.alpha(Theme.accent, 0.22) : hover.hovered ? Qt.alpha(Theme.surface, 0.7) : "transparent"

                Text {
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 60
                    elide: Text.ElideRight
                    text: entry.modelData
                    font.family: entry.modelData
                    font.pixelSize: Theme.fontPixels
                    color: entry.chosen ? Theme.fgBright : Theme.fg
                }
                Icon {
                    visible: entry.chosen
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    name: "check"
                    color: Theme.accent
                }
                HoverHandler { id: hover }
                TapHandler {
                    onTapped: page.action("font", { key: page.which === "mono" ? "font.mono" : "font.sans",
                                                    value: entry.modelData })
                }
            }
        }
    }
}
