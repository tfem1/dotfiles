import QtQuick
import Quickshell
import "../services"
import "apps.js" as Apps

// The right-click menu of a running app, just under its icon: the entries
// of the app's own tray menu (in the theme colors), submenus opened in
// place, and Quit. A click outside or Escape closes it.
PopupWindow {
    id: popup

    required property string appKey
    required property var barWindow
    property real atX: 0
    property real atY: 0
    property var path: []     // submenus opened, innermost last
    signal done

    // The app as it is now: closes by itself once the app is gone.
    readonly property var app: Running.apps.find(entry => entry.key === appKey) || null
    readonly property var tray: app ? Running.trayOf(app) : null
    readonly property var entries: opener.children ? opener.children.values : []
    readonly property int quitAt: path.length === 0
        ? Apps.quitIndex(entries.map(entry => entry.isSeparator ? "" : entry.text)) : -1
    // The app's own quit entry: the Quit row uses it (shown at the top level).
    readonly property var quitEntry: quitAt >= 0 ? entries[quitAt] : null
    onAppChanged: if (!app) done()
    onVisibleChanged: if (!visible) done()

    anchor.window: barWindow
    anchor.rect.x: atX
    anchor.rect.y: atY + 6
    grabFocus: true
    visible: true
    color: "transparent"
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    Component.onCompleted: Running.prepareQuit()

    QsMenuOpener {
        id: opener
        menu: popup.path.length > 0 ? popup.path[popup.path.length - 1]
            : popup.tray && popup.tray.hasMenu ? popup.tray.menu : null
    }

    AppMenuContent {
        id: content
        anchors.fill: parent
        name: popup.app ? popup.app.name : ""
        icon: popup.app ? popup.app.icon : ""
        detail: popup.app ? Apps.detail(popup.app.windows, popup.app.tray >= 0) : ""
        rows: Apps.rows(popup.entries.map(entry => ({
            text: entry.text,
            enabled: entry.enabled,
            separator: entry.isSeparator,
            submenu: entry.hasChildren
        })), popup.quitAt)
        nested: popup.path.length > 0
        canQuit: !!popup.app && (popup.app.windows > 0 || popup.quitEntry !== null)
        Component.onCompleted: forceActiveFocus()

        onEntryClicked: index => {
            const entry = popup.entries[index];
            if (entry.hasChildren) {
                popup.path = popup.path.concat([entry]);
            } else {
                entry.triggered();
                popup.done();
            }
        }
        onBack: popup.path = popup.path.slice(0, -1)
        onQuit: {
            Running.quit(popup.app, popup.quitEntry);
            popup.done();
        }
        onClosed: popup.done()
    }
}
