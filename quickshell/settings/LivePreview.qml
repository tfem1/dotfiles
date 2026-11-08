pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// A small desktop drawn with the settings as they will be once applied:
// the wallpaper, the bar, a window and the system panel, in the chosen
// theme, with its corners, gaps and transparency.
Rectangle {
    id: preview

    property var colors: ({})        // the chosen theme's colors (see settings get)
    property color accent: "#888888"
    property string wallpaper: ""    // file:// URL
    property int corners: 12
    property int gaps: 6
    property real glass: 0.9         // opacity of the bar and panels
    property bool gameMode: false
    property color folder: "#888888"
    readonly property real unit: width / 960

    function c(name, fallback) {
        return colors && colors[name] ? colors[name] : fallback;
    }

    implicitHeight: Math.round(width * 0.4)
    radius: Theme.radius
    color: c("bg", "#222222")
    clip: true

    Image {
        anchors.fill: parent
        source: preview.wallpaper
        sourceSize: Qt.size(640, 360)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // The bar.
    Rectangle {
        width: parent.width
        height: 26 * preview.unit
        color: Qt.alpha(preview.c("bg", "#222222"), preview.glass)

        Row {
            anchors.centerIn: parent
            spacing: 6 * preview.unit

            Repeater {
                model: 5

                Rectangle {
                    required property int index
                    anchors.verticalCenter: parent.verticalCenter
                    width: (index === 1 ? 16 : 8) * preview.unit
                    height: 8 * preview.unit
                    radius: height / 2
                    color: index === 1 ? preview.accent : preview.c("surface", "#444444")
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 10 * preview.unit
                text: "21:47"
                color: preview.accent
                font.family: Theme.fontSans
                font.pixelSize: 11 * preview.unit
                font.weight: Font.DemiBold
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 10 * preview.unit
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5 * preview.unit

            Repeater {
                model: 3
                Rectangle {
                    width: 7 * preview.unit
                    height: width
                    radius: width / 2
                    color: preview.c("accent2", preview.accent)
                }
            }
        }
    }

    // A window: a terminal, and a folder in the icons' color.
    Rectangle {
        x: preview.gaps * 2 * preview.unit
        y: (26 + preview.gaps * 2) * preview.unit
        width: parent.width * 0.6 - x
        height: parent.height - y - preview.gaps * 2 * preview.unit
        radius: preview.corners * preview.unit
        color: Qt.alpha(preview.c("bg", "#222222"), preview.glass)

        Column {
            x: 16 * preview.unit
            y: 14 * preview.unit
            spacing: 7 * preview.unit

            Repeater {
                model: [["accent", 0.30], ["fg", 0.55], ["fg", 0.42], ["accent3", 0.25], ["fg", 0.5]]

                Rectangle {
                    required property var modelData
                    width: preview.width * modelData[1] * 0.6
                    height: 6 * preview.unit
                    radius: height / 2
                    color: preview.c(modelData[0], "#aaaaaa")
                    opacity: modelData[0] === "fg" ? 0.6 : 1
                }
            }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16 * preview.unit
            width: 42 * preview.unit
            height: 32 * preview.unit
            radius: 5 * preview.unit
            color: preview.folder
        }
    }

    // The system panel.
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: preview.gaps * 2 * preview.unit
        y: (26 + preview.gaps * 2) * preview.unit
        width: parent.width * 0.34
        height: parent.height - y - preview.gaps * 2 * preview.unit
        radius: preview.corners * preview.unit
        color: Qt.alpha(preview.c("bg", "#222222"), preview.glass)

        Grid {
            x: 12 * preview.unit
            y: 12 * preview.unit
            columns: 2
            spacing: 8 * preview.unit

            Repeater {
                model: 4

                Rectangle {
                    required property int index
                    width: (preview.width * 0.34 - 32 * preview.unit) / 2
                    height: 34 * preview.unit
                    radius: Math.min(preview.corners, 14) * preview.unit
                    color: index === 0 ? preview.accent : preview.c("bgAlt", "#333333")
                }
            }
        }
        Rectangle {
            x: 12 * preview.unit
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18 * preview.unit
            width: parent.width - 24 * preview.unit
            height: 6 * preview.unit
            radius: height / 2
            color: preview.c("surface", "#444444")

            Rectangle {
                width: parent.width * 0.6
                height: parent.height
                radius: parent.radius
                color: preview.accent
            }
        }
    }

    Rectangle {
        visible: preview.gameMode
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 10
        width: badge.implicitWidth + 20
        height: 26
        radius: 13
        color: Qt.alpha(preview.c("bg", "#222222"), 0.9)

        Label {
            id: badge
            anchors.centerIn: parent
            text: "Game mode: no effects"
            small: true
        }
    }
}
