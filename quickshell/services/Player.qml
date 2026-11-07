pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The media player to show: the one playing, otherwise the first one.
Singleton {
    id: root

    readonly property var player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) || players[0] || null;
    }
    readonly property bool active: player !== null
    readonly property string title: player ? player.trackTitle : ""
    readonly property string artist: player ? player.trackArtist : ""
    readonly property bool playing: player ? player.isPlaying : false
    readonly property real progress: player && player.length > 0 ? player.position / player.length : 0

    function toggle() {
        if (player && player.canTogglePlaying)
            player.togglePlaying();
    }

    // MPRIS does not push the position: ask for it every second while playing.
    Timer {
        running: root.playing
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }
}
