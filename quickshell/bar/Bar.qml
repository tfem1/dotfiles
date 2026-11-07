import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// The bar on one screen: live data from the services into BarContent.
// With autohide, windows use the whole screen and the bar slides down when
// the pointer touches the top edge.
PanelWindow {
    id: window

    required property var modelData
    property bool autohide: false
    signal statusClicked
    signal clockClicked
    signal powerClicked
    readonly property bool pointerIn: barHover.hovered || edgeHover.hovered
    readonly property bool revealed: !autohide || pointerIn || hideDelay.running || menuKey !== ""

    // The app whose menu is open ("" for none), and where it opens.
    property string menuKey: ""
    property real menuX: 0
    property real menuY: 0

    // Right click: a new menu under that icon (an open one closes first).
    function openMenu(app, x, y) {
        menuKey = "";
        menuX = x;
        menuY = y;
        Qt.callLater(() => window.menuKey = app.key);
    }

    onPointerInChanged: if (!pointerIn) hideDelay.restart()

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: content.implicitHeight
    color: "transparent"
    exclusionMode: autohide ? ExclusionMode.Ignore : ExclusionMode.Auto
    // Hidden, only a thin strip at the top edge takes the pointer.
    mask: Region { item: window.revealed ? area : edge }
    WlrLayershell.namespace: "shell-bar"

    // Stay awake: hypridle respects this inhibitor while the bar is shown.
    IdleInhibitor {
        window: window
        enabled: Session.stayAwake
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
        y: window.revealed ? 0 : -height
        Behavior on y { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }

        apps: Running.apps
        workspaces: Desktop.workspaces
        hasMedia: Player.active
        mediaTitle: Player.title
        mediaArtist: Player.artist
        mediaProgress: Player.progress
        mediaPlaying: Player.playing
        now: clock.date

        status.keyboard: Keyboard.short
        status.volume: Audio.volume
        status.muted: Audio.muted
        status.network: Connectivity.state
        status.wifiStrength: Connectivity.strength
        status.bluetoothOn: Connectivity.bluetoothOn
        status.bluetoothConnected: Connectivity.bluetoothConnected
        status.hasBattery: Power.present
        status.battery: Power.level
        status.charging: Power.charging
        status.quiet: Session.doNotDisturb
        status.awake: Session.stayAwake

        onAppActivated: app => Running.focus(app)
        onAppMenuRequested: (app, x, y) => window.openMenu(app, x, y)
        onWorkspaceClicked: id => Desktop.focus(id)
        onMediaToggled: Player.toggle()
        onRightClicked: window.statusClicked()
        onClockClicked: window.clockClicked()
        onPowerClicked: window.powerClicked()

        HoverHandler { id: barHover }
    }

    // Only exists while a menu is open.
    LazyLoader {
        active: window.menuKey !== ""

        AppMenu {
            appKey: window.menuKey
            barWindow: window
            atX: window.menuX
            atY: window.menuY
            onDone: window.menuKey = ""
        }
    }

    Item {
        id: edge
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2

        HoverHandler { id: edgeHover }
    }
}
