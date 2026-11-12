pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "settings.js" as Settings

// Appearance: the look of the whole desktop. Changes wait for Apply; the
// preview at the top shows them first.
Column {
    id: page

    property var values: ({})
    property var pending: ({})
    property var themes: []
    property var folders: ({})       // FairyWren folder color -> its color
    property string wallpaper: ""    // file:// URL of the current wallpaper
    signal changed(string key, var value)
    signal chooseWallpaper

    function v(key) {
        return Settings.value(values, pending, key);
    }

    readonly property var theme: Settings.theme(themes, v("palette.source"))
    readonly property var colors: theme ? theme.colors : ({})
    readonly property color accent: Settings.accentColor(theme, v("palette.accent"))
    readonly property var hues: ["red", "orange", "yellow", "green", "cyan", "blue", "purple", "brown"]

    // A slider for a whole number or a step of `step`, with its value shown.
    component Setting: Row {
        id: setting

        property real low: 0
        property real high: 1
        property real step: 1
        property real current: low
        property string unit: ""
        signal picked(real value)

        spacing: 12

        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: 220
            value: (setting.current - setting.low) / (setting.high - setting.low)
            onMoved: fraction => setting.picked(Math.round((setting.low + fraction * (setting.high - setting.low))
                                                           / setting.step) * setting.step)
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: 52
            text: setting.unit === "%" ? Math.round(setting.current * 100) + " %" : setting.current + setting.unit
            horizontalAlignment: Text.AlignRight
        }
    }

    spacing: 12

    LivePreview {
        width: parent.width
        colors: page.colors
        accent: page.accent
        wallpaper: page.wallpaper
        corners: page.v("shape.radius") || 0
        gaps: page.v("shape.gaps_in") || 0
        glass: page.v("effects.opacity") || 1
        gameMode: !!page.v("effects.game_mode")
        folder: page.v("icons.folders") === "theme" ? page.accent : page.folders[page.v("icons.folders")] || page.accent
    }

    SettingRow {
        objectName: "theme"
        title: "Theme"
        description: "Colors of the bar, the panels, the terminal and your apps."
        wide: true
        ThemeGrid {
            width: parent.width
            themes: page.themes
            current: page.v("palette.source") || ""
            onPicked: id => page.changed("palette.source", id)
        }
    }
    SettingRow {
        objectName: "accent"
        title: "Accent color"
        description: "The color of the workspaces, the clock and the switches."
        wide: true
        Chips {
            width: parent.width
            current: page.v("palette.accent")
            model: [{ value: "theme", label: "Theme's own", color: page.colors.accent }].concat(
                page.hues.map(hue => ({ value: hue, label: hue.charAt(0).toUpperCase() + hue.slice(1),
                                        color: page.colors[hue] })))
            onPicked: value => page.changed("palette.accent", value)
        }
    }
    SettingRow {
        objectName: "colors"
        title: "Every color of the theme"
        description: "Off: 5 colors (background, text and the theme's 3 own). On: its red, green, blue… too, in the terminal and your apps."
        Switch {
            checked: page.v("palette.colors") === "all"
            onToggled: checked => page.changed("palette.colors", checked ? "all" : "few")
        }
    }
    SettingRow {
        objectName: "wallpaper"
        title: "Wallpaper"
        description: "Opens the wallpaper selector (SUPER + W)."
        TextButton {
            text: "Choose…"
            icon: "wallpaper"
            onClicked: page.chooseWallpaper()
        }
    }
    SettingRow {
        title: "A wallpaper brings its theme"
        description: "A wallpaper of the collection switches to its theme: a night forest to Moonlit, a cat to Tabby; any other image to a theme made from its own colors."
        Switch {
            checked: !!page.v("wallpaper.follow")
            onToggled: checked => page.changed("wallpaper.follow", checked)
        }
    }
    SettingRow {
        objectName: "folders"
        title: "Folder color"
        description: "The folders of the FairyWren icons."
        wide: true
        Chips {
            width: parent.width
            current: page.v("icons.folders")
            model: [{ value: "theme", label: "Like the accent", color: page.accent }].concat(
                ["violet", "pink", "magenta", "indigo", "blue", "cyan", "teal", "green", "pine", "yellow",
                 "orange", "red", "grey"].map(name => ({ value: name, label: name.charAt(0).toUpperCase()
                                                         + name.slice(1), color: page.folders[name] })))
            onPicked: value => page.changed("icons.folders", value)
        }
    }
    SettingRow {
        objectName: "corners"
        title: "Rounded corners"
        description: "Of the windows and of the shell."
        Setting { high: 32; current: page.v("shape.radius") || 0; unit: " px"; onPicked: value => page.changed("shape.radius", value) }
    }
    SettingRow {
        objectName: "gaps"
        title: "Space between windows"
        description: "Around them, the space is half as large again."
        Setting {
            high: 24
            current: page.v("shape.gaps_in") || 0
            unit: " px"
            onPicked: value => {
                page.changed("shape.gaps_in", value);
                page.changed("shape.gaps_out", Math.round(value * 1.5));
            }
        }
    }
    SettingRow {
        objectName: "opacity"
        title: "Transparency"
        description: "How solid the bar and the panels are."
        Setting { low: 0.5; step: 0.05; current: page.v("effects.opacity") || 1; unit: "%"; onPicked: value => page.changed("effects.opacity", Math.round(value * 100) / 100) }
    }
    Repeater {
        model: [["blur", "effects.blur", "Blur", "Frosted glass behind see-through windows."],
                ["shadows", "effects.shadow", "Shadows", "A soft shadow under the windows."],
                ["animations", "effects.animations", "Animations", "Windows and panels move smoothly."]]

        SettingRow {
            id: toggleRow
            required property var modelData
            objectName: modelData[0]
            title: modelData[2]
            description: modelData[3]
            Switch {
                checked: !!page.v(toggleRow.modelData[1])
                onToggled: checked => page.changed(toggleRow.modelData[1], checked)
            }
        }
    }
    SettingRow {
        objectName: "textsize"
        title: "Text size"
        description: "Of the bar and the panels, in points."
        Setting { low: 9; high: 16; current: page.v("font.size") || 11; unit: " pt"; onPicked: value => page.changed("font.size", value) }
    }
}
