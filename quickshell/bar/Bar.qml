import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// The bar on one screen: live data from the services into BarContent.
PanelWindow {
    required property var modelData

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: content.implicitHeight
    color: "transparent"
    WlrLayershell.namespace: "shell-bar"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    BarContent {
        id: content
        anchors.fill: parent

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

        onWorkspaceClicked: id => Desktop.focus(id)
        onMediaToggled: Player.toggle()
    }
}
