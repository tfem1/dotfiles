pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "settings.js" as Settings

// The Settings window (SUPER + H): a centered card, the pages and search on
// the left, the settings of the page on the right. Appearance changes wait
// in a bar at the bottom (Apply, Cancel); System settings act at once.
Item {
    id: window

    property var settings: ({ values: {}, themes: [], folders: {} })   // `tfem settings get`
    property var pending: ({})
    property var live: ({})          // see SystemPage
    property string wallpaper: ""    // file:// URL
    property string page: "appearance"
    property bool busy: false        // applying
    signal changed(string key, var value)
    signal apply
    signal cancel
    signal action(string name, var value)
    signal chooseWallpaper
    signal closed

    readonly property int changeCount: Object.keys(pending).length

    // Search result: its page, then the row, scrolled into view and lit up.
    function show(page, id) {
        window.page = page;
        Qt.callLater(() => scrollTo(id));
    }

    function scrollTo(id) {
        const column = page === "system" ? systemPage : appearancePage;
        for (const item of column.children) {
            if (item.objectName !== id)
                continue;
            flick.contentY = Math.max(0, Math.min(item.y - 12, flick.contentHeight - flick.height));
            if (item.flash)
                item.flash();
            return;
        }
    }

    focus: true
    Keys.onEscapePressed: closed()
    Component.onCompleted: nav.focusSearch()

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 1120)
        height: Math.min(parent.height - 80, 800)
        radius: Theme.radius + 8
        color: Theme.bg
        border.width: 1
        border.color: Theme.surface
        clip: true

        MouseArea { anchors.fill: parent }   // clicks inside never close it

        SettingsNav {
            id: nav
            width: 270
            height: parent.height
            page: window.page
            onPagePicked: page => {
                window.page = page;
                flick.contentY = 0;
            }
            onResultPicked: (page, id) => window.show(page, id)
            onClosed: window.closed()
        }
        Rectangle {
            x: nav.width
            width: 1
            height: parent.height
            color: Theme.surface
        }

        Item {
            x: nav.width + 1
            width: parent.width - x
            height: parent.height

            Item {
                id: header
                width: parent.width
                height: 86

                Column {
                    x: 28
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Label {
                        text: window.page === "system" ? "System" : "Appearance"
                        color: Theme.fgBright
                        font.pixelSize: Math.round(Theme.fontPixels * 1.3)
                        font.weight: Font.DemiBold
                    }
                    Label {
                        text: window.page === "system" ? "These settings act at once."
                            : "Nothing changes until you press Apply: the preview shows it first."
                        small: true
                    }
                }
                IconButton {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "close"
                    onClicked: window.closed()
                }
            }

            Flickable {
                id: flick
                anchors.top: header.bottom
                anchors.bottom: applyBar.top
                width: parent.width
                contentHeight: (window.page === "system" ? systemPage : appearancePage).implicitHeight + 28
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                AppearancePage {
                    id: appearancePage
                    visible: window.page === "appearance"
                    x: 28
                    width: flick.width - 56
                    values: window.settings.values
                    pending: window.pending
                    themes: window.settings.themes
                    folders: window.settings.folders
                    wallpaper: window.wallpaper
                    onChanged: (key, value) => window.changed(key, value)
                    onChooseWallpaper: window.chooseWallpaper()
                }
                SystemPage {
                    id: systemPage
                    visible: window.page === "system"
                    x: 28
                    width: flick.width - 56
                    live: window.live
                    onAction: (name, value) => window.action(name, value)
                }
            }

            // Changes waiting for Apply.
            Rectangle {
                id: applyBar
                anchors.bottom: parent.bottom
                width: parent.width
                height: window.changeCount > 0 ? 68 : 0
                visible: height > 0
                color: Theme.bgAlt

                Label {
                    x: 28
                    anchors.verticalCenter: parent.verticalCenter
                    text: window.busy ? "Applying…" : Settings.changes(window.pending) + ", not applied yet"
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    TextButton {
                        text: "Cancel"
                        onClicked: window.cancel()
                    }
                    TextButton {
                        text: "Apply"
                        icon: "check"
                        strong: true
                        opacity: window.busy ? 0.6 : 1
                        onClicked: if (!window.busy) window.apply()
                    }
                }
            }
        }
    }
}
