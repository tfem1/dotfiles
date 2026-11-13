pragma Singleton
import QtQuick

// Colors, fonts and shapes of the shell, filled from the generated theme.json
// by ThemeFile. Plain QtQuick (no Quickshell) so tools/preview can render the
// same components. Defaults are the Pine theme.
QtObject {
    id: theme

    property string name: "Pine"
    property string variant: "dark"

    property color bg: "#182a23"
    property color bgAlt: "#13201b"
    property color surface: "#264036"
    property color muted: "#447460"
    property color subtle: "#6eaa92"
    property color fg: "#d9e4d2"
    property color fgBright: "#e6eee2"
    property color accent: "#8fd18c"
    property color accent2: "#aedaac"    // the theme's two other colors
    property color accent3: "#91cc9d"
    property color red: "#e694a1"
    property color orange: "#d69a62"
    property color yellow: "#e8d27a"
    property color green: "#8fd18c"
    property color cyan: "#6cc3b0"
    property color blue: "#94b6e6"
    property color purple: "#c494e6"
    property color brown: "#e694c4"

    // One color per module, chosen in theme.toml ([modules]).
    component ModuleColors: QtObject {
        property color workspaces: "#8fd18c"
        property color clock: "#8fd18c"
        property color media: "#91cc9d"
        property color resources: "#91cc9d"
        property color battery: "#aedaac"
        property color wifi: "#aedaac"
        property color network: "#aedaac"
        property color bluetooth: "#aedaac"
        property color audio: "#aedaac"
        property color brightness: "#aedaac"
        property color notifications: "#8fd18c"
    }
    property ModuleColors modules: ModuleColors {}

    property string fontSans: "Inter"
    property string fontMono: "JetBrainsMono Nerd Font"
    property int fontSize: 11
    property int radius: 12
    property int border: 0
    property real opacity: 0.9
    property real tint: 0     // Settings → Glass: the accent color mixed into the glass
    property bool animations: true
    property bool gameMode: false      // no animations, no notification popups
    property bool powerSaver: false    // no animations, a dimmer screen
    property string wallpaper: ""
    // The bar (config.json bar.*): "top", "bottom", "left" or "right".
    property var bar: ({ position: "top", transparent: false, layout: "workspaces,media|clock|notifications,status",
                             workspaces: "dots" })
    // The dock (config.json dock.*); its colors come from the theme.
    property var dock: ({ enabled: true, position: "bottom", opacity: 0.85, autohide: false,
                          pinned: "firefox,kitty,org.gnome.Nautilus" })
    // Desktop widgets shown (config.json widgets.*).
    property var widgets: ({ corner: "top-left", clock: true, audio: true, media: true, cpu: true, gpu: true, ram: true,
                             disk: true })

    // Derived values used everywhere.
    readonly property int duration: animations ? 180 : 0
    readonly property real fontPixels: fontSize * 4 / 3
    readonly property color panel: Qt.alpha(Qt.tint(bg, Qt.alpha(accent, tint)), opacity)

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
            theme.tint = data.effects.tint || 0;
            theme.animations = data.effects.animations;
            theme.gameMode = !!data.effects.gameMode;
            theme.powerSaver = !!data.effects.powerSaver;
        }
        theme.wallpaper = data.wallpaper || "";
        if (data.widgets)
            theme.widgets = data.widgets;
        if (data.bar)
            theme.bar = data.bar;
        if (data.dock)
            theme.dock = data.dock;
    }
}
