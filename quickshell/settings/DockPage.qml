pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "../dock"

// Dock: on or off, its screen edge, how see-through, hidden until the
// pointer comes. It takes the theme's colors (it changes with the theme or
// the wallpaper). Pinned apps: a right click on an icon in the dock. Every
// setting acts at once (`tfem settings set dock.*`).
Column {
    id: page

    property var values: ({})        // `tfem settings get` values
    signal action(string name, var value)

    readonly property real opacityValue: values["dock.opacity"] !== undefined ? values["dock.opacity"] : 0.85

    spacing: 12

    // What it looks like, in the theme's colors, at this opacity.
    Rectangle {
        width: page.width
        height: 110
        radius: Theme.radius
        color: Theme.bgAlt
        clip: true

        Rectangle {   // a wallpaper-like stripe behind, so the opacity shows
            anchors.fill: parent
            color: Qt.alpha(Theme.accent, 0.35)
            radius: parent.radius
        }
        DockContent {
            anchors.centerIn: parent
            fill: page.opacityValue
            apps: [
                { id: "a", name: "Files", running: 1, focused: true },
                { id: "b", name: "Web", running: 1, focused: false },
                { id: "c", name: "Terminal", running: 0 },
                { id: "d", name: "Music", running: 0 }
            ]
        }
    }

    SettingRow {
        objectName: "dock-enabled"
        width: page.width
        title: "Dock"
        description: "Your pinned apps and the ones running, on the desktop. Right click an icon to pin or unpin it."
        Switch {
            checked: page.values["dock.enabled"] !== false
            onToggled: checked => page.action("dock.enabled", checked)
        }
    }

    SettingRow {
        objectName: "dock-opacity"
        width: page.width
        title: "Opacity"
        description: "How much of the dock's background shows: " + Math.round(page.opacityValue * 100)
            + " %. Its colors always come from the theme."
        Slider {
            width: 240
            // 20 % to 100 %, on the whole length of the slider.
            value: (page.opacityValue - 0.2) / 0.8
            onMoved: value => page.action("dock.opacity", Math.round((0.2 + value * 0.8) * 100) / 100)
        }
    }

    SettingRow {
        objectName: "dock-position"
        width: page.width
        title: "Position"
        description: "The edge of the screen it stands on."
        Chips {
            current: page.values["dock.position"] || "bottom"
            model: [{ label: "Bottom", value: "bottom" }, { label: "Left", value: "left" },
                    { label: "Right", value: "right" }]
            onPicked: value => page.action("dock.position", value)
        }
    }

    SettingRow {
        objectName: "dock-autohide"
        width: page.width
        title: "Hide automatically"
        description: "Windows get the whole screen; the dock slides in when the pointer touches its edge."
        Switch {
            checked: !!page.values["dock.autohide"]
            onToggled: checked => page.action("dock.autohide", checked)
        }
    }
}
