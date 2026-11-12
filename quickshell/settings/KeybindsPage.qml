pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "keys.js" as KeyNames

// Keybinds: the shortcuts of the shell panels, screenshots, recording and
// color picker (keybinds.toml). Click a key, then press the new one: it is
// saved at once (`tfem settings set keys.ID=...`) and written for Hyprland,
// Sway or Niri. While a key is awaited, the window manager's own shortcuts
// are held back (`capturing`: a ShortcutInhibitor in Settings.qml), so
// SUPER + D reaches this page instead of opening the launcher.
Column {
    id: page

    // `tfem settings get` keys: { actions: [{ id, title, key, default }], reserved: [...] }
    property var keys: ({ actions: [], reserved: [] })
    property string listening: ""    // the action waiting for its new key
    property string note: ""
    readonly property bool capturing: listening !== ""
    signal action(string name, var value)

    function choose(id, key) {
        const actions = keys.actions || [];
        const mine = actions.find(action => action.id === id);
        if ((keys.reserved || []).indexOf(key) >= 0) {
            note = KeyNames.label(key) + " is a shortcut of the window manager itself: pick another key.";
            return;
        }
        const other = KeyNames.owner(actions, key, id);
        note = other ? "“" + other.title + "” had " + KeyNames.label(key) + ": it has no key now, give it another one."
                     : mine ? mine.title + ": " + KeyNames.label(key) : "";
        listening = "";
        action("keys." + id, key);
    }

    spacing: 6

    Label {
        objectName: "keybinds"
        width: page.width
        text: "Click a shortcut, then press the new keys (Escape cancels). Windows, workspaces, lock and media keys stay as they are."
        small: true
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: page.keys.actions || []

        Rectangle {
            id: row
            required property var modelData
            readonly property bool waiting: page.listening === modelData.id

            width: page.width
            height: 48
            radius: Theme.radius
            color: waiting ? Qt.alpha(Theme.accent, 0.12) : Theme.bg

            Label {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.right: keyBox.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.title
                elide: Text.ElideRight
            }

            Row {
                id: keyBox
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                IconButton {   // back to the key it had at first
                    visible: row.modelData.key !== row.modelData.default
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "restart_alt"
                    size: 28
                    onClicked: page.choose(row.modelData.id, row.modelData.default)
                }
                Rectangle {
                    width: Math.max(130, shown.implicitWidth + 28)
                    height: 32
                    radius: 16
                    color: row.waiting ? Theme.accent : Theme.surface
                    border.width: 1
                    border.color: row.modelData.key ? Theme.accent : Theme.red

                    Label {
                        id: shown
                        anchors.centerIn: parent
                        text: row.waiting ? "Press the keys…" : KeyNames.label(row.modelData.key)
                        color: row.waiting ? Theme.bg : row.modelData.key ? Theme.fgBright : Theme.red
                        small: true
                        font.weight: Font.Bold
                    }
                    TapHandler {
                        onTapped: {
                            page.note = "";
                            page.listening = row.waiting ? "" : row.modelData.id;
                            catcher.forceActiveFocus();
                        }
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }
        }
    }

    Label {
        width: page.width
        visible: page.note !== ""
        text: page.note
        color: Theme.accent
        small: true
        wrapMode: Text.WordWrap
    }

    // Takes the keys while one is awaited.
    Item {
        id: catcher
        objectName: "catcher"
        width: 1
        height: 1
        Keys.onPressed: event => {
            if (!page.capturing)
                return;
            event.accepted = true;
            if (event.key === Qt.Key_Escape && !event.modifiers) {
                page.listening = "";
                return;
            }
            const key = KeyNames.combo(event.key, event.modifiers);
            if (key)
                page.choose(page.listening, key);
        }
    }
}
