pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "settings.js" as Settings

// Glass: how see-through the shell is (bar, panels, notifications) and the
// frosted blur behind it and behind see-through windows. A style in one
// click, or each setting on its own. Like Appearance, nothing changes
// until Apply; the preview shows it first. The blur is Hyprland's.
Column {
    id: page

    property var values: ({})        // `tfem settings get` values
    property var pending: ({})       // changes waiting for Apply
    property var themes: []
    property string wallpaper: ""
    signal changed(string key, var value)

    function v(key) {
        return Settings.value(values, pending, key);
    }

    readonly property var theme: Settings.theme(themes, v("palette.source"))
    readonly property var colors: theme ? theme.colors : ({})
    readonly property color accent: Settings.accentColor(theme, v("palette.accent"))
    // One click: [label, opacity, blur, size, passes, vibrancy, noise]
    readonly property var styles: [
        ["Clear", 0.55, true, 10, 3, 0.35, 0.02],
        ["Frosted", 0.8, true, 8, 2, 0.17, 0.01],
        ["Solid", 1.0, false, 8, 2, 0.17, 0.01]
    ]
    readonly property string style: {
        const match = styles.find(s => Math.abs((v("effects.opacity") || 1) - s[1]) < 0.01 && !!v("effects.blur") === s[2]);
        return match ? match[0] : "";
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
    }

    SettingRow {
        objectName: "glass-style"
        title: "Style"
        description: "Clear: much of the wallpaper shows, colorful blur. Frosted: soft glass. Solid: no transparency, no blur."
        wide: true
        Chips {
            width: parent.width
            current: page.style
            model: page.styles.map(s => ({ value: s[0], label: s[0] }))
            onPicked: value => {
                const s = page.styles.find(style => style[0] === value);
                const keys = ["effects.opacity", "effects.blur", "effects.blur_size", "effects.blur_passes",
                              "effects.blur_vibrancy", "effects.blur_noise"];
                keys.forEach((key, i) => page.changed(key, s[i + 1]));
            }
        }
    }
    SettingRow {
        objectName: "opacity"
        title: "Transparency"
        description: "How solid the bar, the panels and the notifications are."
        SettingSlider { low: 0.5; step: 0.05; current: page.v("effects.opacity") || 1; unit: "%"; onPicked: value => page.changed("effects.opacity", Math.round(value * 100) / 100) }
    }
    SettingRow {
        objectName: "glass-tint"
        title: "Tint"
        description: "A touch of the accent color in the glass."
        SettingSlider { low: 0; high: 0.3; step: 0.02; current: page.v("effects.glass_tint") || 0; unit: "%"; onPicked: value => page.changed("effects.glass_tint", Math.round(value * 100) / 100) }
    }
    SettingRow {
        objectName: "blur"
        title: "Blur"
        description: "Frosted glass behind the shell and see-through windows (Hyprland)."
        Switch {
            checked: !!page.v("effects.blur")
            onToggled: checked => page.changed("effects.blur", checked)
        }
    }
    Repeater {   // the blur's own settings, while it is on
        model: [
            ["blur-size", "effects.blur_size", "Strength", "How far the blur spreads.", 1, 20, 1, ""],
            ["blur-passes", "effects.blur_passes", "Smoothness", "More passes: softer, a little more work for the GPU.", 1, 4, 1, ""],
            ["blur-vibrancy", "effects.blur_vibrancy", "Vibrancy", "How colorful what shows through is.", 0, 1, 0.05, "%"],
            ["blur-noise", "effects.blur_noise", "Grain", "A fine grain over the glass, like frosted glass.", 0, 0.2, 0.01, "%"]
        ]

        SettingRow {
            id: row
            required property var modelData
            visible: !!page.v("effects.blur")
            objectName: modelData[0]
            title: modelData[2]
            description: modelData[3]
            SettingSlider {
                low: row.modelData[4]
                high: row.modelData[5]
                step: row.modelData[6]
                unit: row.modelData[7]
                current: page.v(row.modelData[1]) || 0
                onPicked: value => page.changed(row.modelData[1], Math.round(value * 100) / 100)
            }
        }
    }
    SettingRow {
        objectName: "blur-popups"
        visible: !!page.v("effects.blur")
        title: "Blur the menus"
        description: "Right-click menus get the glass too."
        Switch {
            checked: !!page.v("effects.blur_popups")
            onToggled: checked => page.changed("effects.blur_popups", checked)
        }
    }
}
