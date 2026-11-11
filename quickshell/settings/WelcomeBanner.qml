pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "../theme"
import "../components"
import "settings.js" as Settings

// The top of the Home page: the wallpaper, darkened, with a greeting for the
// time of day, the date, the theme, the uptime and the system, and two
// buttons. Plain properties: shown with sample data by the preview.
Rectangle {
    id: banner

    property string wallpaper: ""    // file:// URL
    property string user: ""
    property string theme: ""
    property string uptime: ""       // "3 h 25 min"
    property string system: ""       // "Arch Linux"
    property date now: new Date()
    signal chooseWallpaper
    signal openTweaks

    implicitHeight: 240
    radius: Theme.radius + 6
    color: Theme.bgAlt

    // The wallpaper, cut to the round corners by a mask. Without a GPU
    // (software rendering, as in the preview) there are no shaders: the
    // picture shows as is, with square corners.
    readonly property bool shaders: GraphicsInfo.api !== GraphicsInfo.Software

    Image {
        id: picture
        anchors.fill: parent
        source: banner.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 1200
        visible: !banner.shaders
    }
    Item {
        id: shape
        anchors.fill: parent
        layer.enabled: true
        visible: false
        Rectangle {
            anchors.fill: parent
            radius: banner.radius
        }
    }
    MultiEffect {
        visible: banner.shaders
        anchors.fill: parent
        source: picture
        maskEnabled: true
        maskSource: shape
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
    Rectangle {
        anchors.fill: parent
        radius: banner.radius
        color: Qt.alpha(Theme.bg, 0.62)
    }

    Moon {
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        size: 110
        visible: banner.width > 640
    }

    Column {
        x: 30
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Label {
            text: "WELCOME BACK"
            color: Theme.accent
            small: true
            font.weight: Font.Bold
            font.letterSpacing: 3
        }
        Label {
            text: Settings.greeting(banner.now.getHours()) + (banner.user ? ", " + banner.user : "")
            color: Theme.fgBright
            font.pixelSize: Math.round(Theme.fontPixels * 2)
            font.weight: Font.DemiBold
        }
        Label {
            text: Qt.formatDateTime(banner.now, "dddd d MMMM  ·  HH:mm")
        }

        Row {
            topPadding: 4
            spacing: 8

            Repeater {
                model: [
                    { icon: "palette", text: banner.theme },
                    { icon: "schedule", text: banner.uptime ? "Up " + banner.uptime : "" },
                    { icon: "computer", text: banner.system }
                ].filter(chip => chip.text)

                Rectangle {
                    id: pill
                    required property var modelData
                    width: chip.implicitWidth + 24
                    height: 30
                    radius: height / 2
                    color: Qt.alpha(Theme.bg, 0.7)

                    Row {
                        id: chip
                        anchors.centerIn: parent
                        spacing: 6
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: pill.modelData.icon
                            color: Theme.accent
                            size: 16
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: pill.modelData.text
                            small: true
                        }
                    }
                }
            }
        }

        Row {
            topPadding: 6
            spacing: 10
            TextButton {
                text: "Wallpaper"
                icon: "wallpaper"
                onClicked: banner.chooseWallpaper()
            }
            TextButton {
                text: "Gaming hub"
                icon: "sports_esports"
                strong: true
                onClicked: banner.openTweaks()
            }
        }
    }
}
