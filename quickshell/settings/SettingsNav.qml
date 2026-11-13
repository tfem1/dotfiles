pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "settings.js" as Settings

// The left side of the Settings window: your profile card (it opens Home),
// search, then the pages under their sections (Appearance, Desktop,
// System). While something is typed, the matching settings replace the
// pages; Enter or a click goes to the first or chosen one.
Item {
    id: nav

    property string page: "appearance"
    property string user: ""          // shown on the profile card
    readonly property var results: Settings.search(search.text)
    signal pagePicked(string page)
    signal resultPicked(string page, string id)
    signal closed

    readonly property var pages: Settings.PAGES

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

    // You: initials in a circle, your name; a click opens Home.
    Rectangle {
        id: profile
        anchors.top: title.bottom
        anchors.topMargin: 16
        x: 14
        width: parent.width - 28
        height: 58
        radius: 22
        color: nav.page === "home" ? Qt.alpha(Theme.accent, 0.22) : profileHover.hovered ? Theme.surface : Qt.alpha(Theme.surface, 0.6)

        Rectangle {
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            height: 38
            radius: 19
            color: Qt.alpha(Theme.accent, 0.3)
            Label {
                anchors.centerIn: parent
                text: (nav.user || "?").slice(0, 2).toUpperCase()
                font.weight: Font.Bold
                color: Theme.fgBright
            }
        }
        Column {
            x: 60
            anchors.verticalCenter: parent.verticalCenter
            Label { text: nav.user || "You"; font.weight: Font.DemiBold; color: Theme.fgBright }
            Label { text: "Home"; small: true; color: Theme.accent }
        }
        Icon {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            name: "chevron_right"
            color: Theme.subtle
            size: 20
        }
        HoverHandler { id: profileHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: nav.pagePicked("home") }
    }

    SearchField {
        id: search
        anchors.top: profile.bottom
        anchors.topMargin: 12
        x: 14
        width: parent.width - 28
        placeholder: "Search a setting"
        onAccepted: if (nav.results.length > 0) nav.pick(nav.results[0])
        onCancelled: text ? text = "" : nav.closed()
    }

    // Same entry for a page and for a search result.
    component Entry: Rectangle {
        id: entry

        required property var modelData
        readonly property bool isPage: !search.text
        readonly property bool chosen: isPage && modelData.id === nav.page

        width: parent ? parent.width : 0
        height: isPage ? 44 : 48
        radius: height / 2
        color: chosen ? Qt.alpha(Theme.accent, 0.25) : hover.hovered ? Qt.alpha(Theme.surface, 0.55) : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.duration } }
        Icon {
            visible: entry.isPage
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            name: entry.modelData.icon || ""
            color: entry.chosen ? Theme.accent : Theme.subtle
            size: 20
        }
        Column {
            anchors.left: parent.left
            anchors.leftMargin: entry.isPage ? 50 : 16
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            Label {
                width: parent.width
                text: entry.modelData.title
                color: entry.chosen ? Theme.fgBright : Theme.fg
                font.weight: entry.chosen ? Font.DemiBold : Font.Normal
            }
            Label {   // a search result: the page it is on
                visible: !entry.isPage
                width: parent.width
                text: entry.isPage ? "" : Settings.pageOf(entry.modelData.page).title
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

    Flickable {
        anchors.top: search.bottom
        anchors.topMargin: 12
        anchors.bottom: parent.bottom
        x: 10
        width: parent.width - 20
        contentHeight: list.implicitHeight + 16
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: parent.width
            spacing: 2

            // The pages, section by section.
            Repeater {
                model: search.text ? [] : Settings.GROUPS

                Column {
                    id: section
                    required property string modelData
                    width: list.width
                    spacing: 2

                    Label {
                        leftPadding: 16
                        topPadding: 10
                        bottomPadding: 4
                        text: section.modelData
                        small: true
                        font.weight: Font.DemiBold
                        color: Theme.accent
                    }
                    Repeater {
                        model: nav.pages.filter(page => page.group === section.modelData)
                        Entry {}
                    }
                }
            }

            // What the search finds.
            Repeater {
                model: search.text ? nav.results : []
                Entry {}
            }

            Label {
                visible: search.text !== "" && nav.results.length === 0
                x: 16
                text: "Nothing found"
                small: true
            }
        }
    }
}
