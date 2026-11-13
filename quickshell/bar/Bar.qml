import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// The bar on one screen: live data from the services into BarContent. It
// stands on the edge picked in Settings → Tweaks (config.json bar.position).
// The space it takes is kept free by a Reserve (Bars.qml); with autohide,
// windows use the whole screen and the bar slides in when
// the pointer touches that edge.
PanelWindow {
    id: window

    required property var modelData
    property bool autohide: false
    signal statusClicked
    signal clockClicked
    signal powerClicked
    signal logoClicked
    readonly property bool pointerIn: barHover.hovered || edgeHover.hovered
    readonly property bool revealed: !autohide || pointerIn || hideDelay.running
    readonly property string edge: ["top", "bottom", "left", "right"].includes(Theme.bar.position)
        ? Theme.bar.position : "top"
    readonly property bool vertical: window.edge === "left" || window.edge === "right"

    onPointerInChanged: if (!pointerIn) hideDelay.restart()

    screen: modelData
    anchors {
        top: window.edge !== "bottom"
        bottom: window.edge !== "top"
        left: window.edge !== "right"
        right: window.edge !== "left"
    }
    readonly property int thickness: vertical ? 52 : 44
    implicitHeight: vertical ? 0 : thickness
    implicitWidth: vertical ? thickness : 0
    color: "transparent"
    // Always the whole edge, whatever the dock reserves: the space for the
    // windows is kept by a Reserve (Bars.qml).
    exclusionMode: ExclusionMode.Ignore
    // Hidden, only a thin strip at the screen edge takes the pointer.
    mask: Region { item: window.revealed ? area : strip }
    WlrLayershell.namespace: "shell-bar"

    // Coffee (stay awake), game mode (a controller is not seen as activity)
    // and presentation: hypridle respects this inhibitor while the bar shows.
    IdleInhibitor {
        window: window
        enabled: Session.stayAwake || Theme.gameMode || Session.presentation
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Keeps the bar out a moment after the pointer leaves it.
    Timer {
        id: hideDelay
        interval: 400
    }

    // Input regions: they stay in place while the bar slides.
    Item {
        id: area
        anchors.fill: parent
    }

    BarContent {
        id: content
        width: parent.width
        height: parent.height
        // Hidden: slid out past the screen edge.
        readonly property real out: window.revealed ? 0 : window.edge === "top" || window.edge === "left" ? -1 : 1
        x: window.vertical ? out * width : 0
        y: window.vertical ? 0 : out * height
        Behavior on x { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }

        edge: window.edge
        transparent: !!Theme.bar.transparent
        layout: Theme.bar.layout || ""
        workspaceStyle: Theme.bar.workspaces || "dots"

        workspaces: Desktop.workspaces
        hasMedia: Player.active
        mediaTitle: Player.title
        mediaArtist: Player.artist
        mediaProgress: Player.progress
        mediaPlaying: Player.playing
        now: clock.date
        distro: Distro.id

        status: ({
            keyboard: Keyboard.short, volume: Audio.volume, muted: Audio.muted,
            network: Connectivity.state, wifiStrength: Connectivity.strength,
            bluetoothOn: Connectivity.bluetoothOn, bluetoothConnected: Connectivity.bluetoothConnected,
            hasBattery: Power.present, battery: Power.level, charging: Power.charging,
            quiet: Session.doNotDisturb, awake: Session.stayAwake, game: Theme.gameMode,
            recording: Session.recording, updates: Updates.count,
            hasMic: !!Audio.source, micMuted: Audio.micMuted,
            modes: { saver: Theme.powerSaver, night: Session.night, presentation: Session.presentation,
                     focus: Session.focus }
        })

        onWorkspaceClicked: id => Desktop.focus(id)
        onMediaToggled: Player.toggle()
        onRightClicked: window.statusClicked()
        onClockClicked: window.clockClicked()
        onPowerClicked: window.powerClicked()
        onLogoClicked: window.logoClicked()
        onUpdatesClicked: Updates.install()

        HoverHandler { id: barHover }
    }

    Item {
        id: strip
        x: window.edge === "right" ? parent.width - width : 0
        y: window.edge === "bottom" ? parent.height - height : 0
        width: window.vertical ? 2 : parent.width
        height: window.vertical ? parent.height : 2

        HoverHandler { id: edgeHover }
    }
}
