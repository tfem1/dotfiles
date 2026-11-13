pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "settings.js" as Settings

// The Settings window (SUPER + H): a centered card, the pages and search on
// the left, the settings of the page on the right. Appearance changes wait
// in a bar at the bottom (Apply, Cancel); the other pages act at once.
Item {
    id: window

    property var settings: ({ values: {}, themes: [], folders: {} })   // `tfem settings get`
    property var pending: ({})
    property var live: ({})          // see SystemPage
    property var display: ({ monitors: [], chosen: {} })   // `tfem display list`
    property var confirm: null       // see DisplayPage
    property string wallpaper: ""    // file:// URL
    property var about: ({})         // see HomePage
    property var fonts: ({ all: [], mono: [] })   // see FontsPage
    property var modes: ({})         // which modes are on, see TweaksPage
    property string page: "home"
    // Settings → Keybinds waits for a key (see Settings.qml).
    readonly property bool capturing: page === "keys" && keybindsPage.capturing
    property bool busy: false        // applying
    signal changed(string key, var value)
    signal apply
    signal cancel
    signal action(string name, var value)
    signal chooseWallpaper
    signal closed

    // Search result: its page, then the row, scrolled into view and lit up.
    function show(page, id) {
        window.page = page;
        Qt.callLater(() => scrollTo(id));
    }

    function pageItem() {
        return ({ home: homePage, system: systemPage, display: displayPage, widgets: widgetsPage,
                  dock: dockPage, tweaks: tweaksPage, fonts: fontsPage,
                  keys: keybindsPage })[page] || appearancePage;
    }

    function scrollTo(id) {
        for (const item of pageItem().children) {
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
            user: (window.about || {}).user || ""
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
                        text: Settings.pageOf(window.page).title
                        color: Theme.fgBright
                        font.pixelSize: Math.round(Theme.fontPixels * 1.3)
                        font.weight: Font.DemiBold
                    }
                    Label {
                        width: header.width - 120
                        text: Settings.pageOf(window.page).note
                        small: true
                        wrapMode: Text.WordWrap
                        elide: Text.ElideNone
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
                contentHeight: window.pageItem().implicitHeight + 28
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                HomePage {
                    id: homePage
                    visible: window.page === "home"
                    x: 28
                    width: flick.width - 56
                    wallpaper: window.wallpaper
                    about: window.about
                    onChooseWallpaper: window.chooseWallpaper()
                    onPagePicked: page => {
                        window.page = page;
                        flick.contentY = 0;
                    }
                }
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
                FontsPage {
                    id: fontsPage
                    visible: window.page === "fonts"
                    x: 28
                    width: flick.width - 56
                    values: window.settings.values
                    fonts: window.fonts
                    onAction: (name, value) => window.action(name, value)
                }
                SystemPage {
                    id: systemPage
                    visible: window.page === "system"
                    x: 28
                    width: flick.width - 56
                    live: window.live
                    onAction: (name, value) => window.action(name, value)
                }
                DisplayPage {
                    id: displayPage
                    visible: window.page === "display"
                    x: 28
                    width: flick.width - 56
                    screens: (window.display || {}).monitors || []
                    chosen: (window.display || {}).chosen || {}
                    confirm: window.confirm
                    onAction: (name, value) => window.action(name, value)
                }
                WidgetsPage {
                    id: widgetsPage
                    visible: window.page === "widgets"
                    x: 28
                    width: flick.width - 56
                    values: window.settings.values
                    onAction: (name, value) => window.action(name, value)
                }
                DockPage {
                    id: dockPage
                    visible: window.page === "dock"
                    x: 28
                    width: flick.width - 56
                    values: window.settings.values
                    onAction: (name, value) => window.action(name, value)
                }
                KeybindsPage {
                    id: keybindsPage
                    visible: window.page === "keys"
                    x: 28
                    width: flick.width - 56
                    keys: window.settings.keys || ({ actions: [], reserved: [] })
                    onAction: (name, value) => window.action(name, value)
                }
                TweaksPage {
                    id: tweaksPage
                    visible: window.page === "tweaks"
                    x: 28
                    width: flick.width - 56
                    on: window.modes
                    values: window.settings.values
                    onAction: (name, value) => window.action(name, value)
                }
            }

            // Changes waiting for Apply.
            ApplyBar {
                id: applyBar
                anchors.bottom: parent.bottom
                width: parent.width
                pending: window.pending
                busy: window.busy
                onApply: window.apply()
                onCancel: window.cancel()
            }
        }
    }
}
