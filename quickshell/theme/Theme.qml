pragma Singleton
import QtQuick

// Colors, fonts and shapes of the shell, filled from the generated theme.json
// by ThemeFile. Plain QtQuick (no Quickshell) so tools/preview can render the
// same components. Defaults are the Twilight theme.
QtObject {
    id: theme

    property string name: "Twilight"
    property string variant: "dark"

    property color bg: "#171c2b"
    property color bgAlt: "#121521"
    property color surface: "#242b42"
    property color muted: "#414d77"
    property color subtle: "#6a79ae"
    property color fg: "#e1cfe7"
    property color fgBright: "#ece0f0"
    property color accent: "#d19fe4"
    property color accent2: "#c084d6"    // the theme's two other colors
    property color accent3: "#ed438d"
    property color red: "#e694a1"
    property color orange: "#e6b694"
    property color yellow: "#e6d594"
    property color green: "#94e69a"
    property color cyan: "#94e6e6"
    property color blue: "#779bcb"
    property color purple: "#d19fe4"
    property color brown: "#ed438d"

    // One color per module, chosen in theme.toml ([modules]).
    component ModuleColors: QtObject {
        property color workspaces: "#d19fe4"
        property color clock: "#d19fe4"
        property color media: "#ed438d"
        property color resources: "#ed438d"
        property color battery: "#c084d6"
        property color wifi: "#c084d6"
        property color network: "#c084d6"
        property color bluetooth: "#c084d6"
        property color audio: "#c084d6"
        property color brightness: "#c084d6"
        property color notifications: "#d19fe4"
    }
    property ModuleColors modules: ModuleColors {}

    property string fontSans: "Inter"
    property string fontMono: "JetBrainsMono Nerd Font"
    property int fontSize: 11
    property int radius: 12
    property int border: 0
    property real opacity: 0.9
    property bool animations: true
    property bool gameMode: false      // no animations, no notification popups
    property bool powerSaver: false    // no animations, a dimmer screen
    property string wallpaper: ""
    // Desktop widgets shown (config.json widgets.*).
    property var widgets: ({ corner: "top-left", clock: true, audio: true, media: true, cpu: true, gpu: true, ram: true,
                             disk: true })

    // Derived values used everywhere.
    readonly property int duration: animations ? 180 : 0
    readonly property real fontPixels: fontSize * 4 / 3
    readonly property color panel: Qt.alpha(bg, opacity)

    // Copies the values of a parsed theme.json; unknown keys are ignored.
    function apply(data) {
        const copy = (target, values) => {
            for (const key in values || {})
                if (key in target)
                    target[key] = values[key];
        };
        copy(theme, data.colors);
        copy(theme.modules, data.modules);
        if (data.palette) {
            theme.name = data.palette.name;
            theme.variant = data.palette.variant;
        }
        if (data.font) {
            theme.fontSans = data.font.sans;
            theme.fontMono = data.font.mono;
            theme.fontSize = data.font.size;
        }
        if (data.shape) {
            theme.radius = data.shape.radius;
            theme.border = data.shape.border;
        }
        if (data.effects) {
            theme.opacity = data.effects.opacity;
            theme.animations = data.effects.animations;
            theme.gameMode = !!data.effects.gameMode;
            theme.powerSaver = !!data.effects.powerSaver;
        }
        theme.wallpaper = data.wallpaper || "";
        if (data.widgets)
            theme.widgets = data.widgets;
    }
}
