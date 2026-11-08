pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "settings.js" as Settings

// The left side of the Settings window: search, then the pages. While
// something is typed, the matching settings replace the pages; Enter or a
// click goes to the first or chosen one.
Item {
    id: nav

    property string page: "appearance"
    readonly property var results: Settings.search(search.text)
    signal pagePicked(string page)
    signal resultPicked(string page, string id)
    signal closed

    readonly property var pages: [
        { id: "appearance", title: "Appearance", icon: "wallpaper", text: "Theme, colors, wallpaper, effects" },
        { id: "system", title: "System", icon: "settings", text: "Sound, screen, connections, sleep" }
    ]

    function focusSearch() {
        search.focusInput();
    }

    function pick(entry) {
        search.text = "";
        nav.resultPicked(entry.page, entry.id);
    }

    Label {
        id: title
        x: 20
        y: 22
        text: "Settings"
        color: Theme.fgBright
        font.pixelSize: Math.round(Theme.fontPixels * 1.45)
        font.weight: Font.DemiBold
    }

    SearchField {
        id: search
        anchors.top: title.bottom
        anchors.topMargin: 16
        x: 14
        width: parent.width - 28
        placeholder: "Search a setting"
        onAccepted: if (nav.results.length > 0) nav.pick(nav.results[0])
        onCancelled: text ? text = "" : nav.closed()
    }

    Column {
        anchors.top: search.bottom
        anchors.topMargin: 16
        x: 10
        width: parent.width - 20
        spacing: 4

        // The pages, or what the search finds.
        Repeater {
            model: search.text ? nav.results : nav.pages

            Rectangle {
                id: entry

                required property var modelData
                readonly property bool isPage: !search.text
                readonly property bool chosen: isPage && modelData.id === nav.page

                width: parent.width
                height: isPage ? 58 : 40
                radius: Theme.radius - 2
                color: chosen ? Theme.surface : hover.hovered ? Qt.alpha(Theme.surface, 0.55) : "transparent"

                Rectangle {
                    visible: entry.chosen
                    x: 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: parent.height - 20
                    radius: 1.5
                    color: Theme.accent
                }
                Icon {
                    id: pageIcon
                    visible: entry.isPage
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    name: entry.modelData.icon || ""
                    color: entry.chosen ? Theme.accent : Theme.subtle
                    size: 20
                }
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: entry.isPage ? 48 : 16
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Label {
                        width: parent.width
                        text: entry.modelData.title
                        color: entry.chosen ? Theme.fgBright : Theme.fg
                        font.weight: entry.chosen ? Font.DemiBold : Font.Normal
                    }
                    Label {
                        width: parent.width
                        text: entry.isPage ? entry.modelData.text
                            : (entry.modelData.page === "system" ? "System" : "Appearance")
                        small: true
                    }
                }

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: entry.isPage ? nav.pagePicked(entry.modelData.id) : nav.pick(entry.modelData)
                }
            }
        }

        Label {
            visible: search.text !== "" && nav.results.length === 0
            x: 16
            text: "Nothing found"
            small: true
        }
    }
}
