pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "settings.js" as Settings

// Home: the welcome banner, then one card per page to go to it.
Column {
    id: page

    property string wallpaper: ""
    property var about: ({})         // { user, theme, uptime, system }
    signal chooseWallpaper
    signal pagePicked(string page)

    spacing: 16

    WelcomeBanner {
        objectName: "welcome"
        width: page.width
        wallpaper: page.wallpaper
        user: page.about.user || ""
        theme: page.about.theme || ""
        uptime: page.about.uptime || ""
        system: page.about.system || ""
        onChooseWallpaper: page.chooseWallpaper()
        onOpenTweaks: page.pagePicked("tweaks")
    }

    Grid {
        id: grid
        columns: page.width > 700 ? 3 : 2
        spacing: 12

        Repeater {
            model: Settings.PAGES.filter(entry => entry.id !== "home")

            Rectangle {
                id: card
                required property var modelData
                width: (page.width - grid.spacing * (grid.columns - 1)) / grid.columns
                height: 78
                radius: Theme.radius
                color: hover.hovered ? Theme.surface : Theme.bgAlt
                Behavior on color { ColorAnimation { duration: Theme.duration } }

                Row {
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: card.modelData.icon
                        color: Theme.accent
                        size: 24
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Label {
                            text: card.modelData.title
                            color: Theme.fgBright
                            font.weight: Font.DemiBold
                        }
                        Label {
                            width: card.width - 72
                            text: card.modelData.text
                            small: true
                        }
                    }
                }
                HoverHandler { id: hover }
                TapHandler { onTapped: page.pagePicked(card.modelData.id) }
            }
        }
    }
}
