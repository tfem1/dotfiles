import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../overlay"

// Connects the music panel to the media players (MPRIS). The position is
// asked for only while the panel shows a playing song; lyrics are fetched
// from lrclib.net only when the lyrics view is open.
Scope {
    id: root

    property bool open: false
    property int chosen: -1                       // player picked in the panel, -1: automatic
    property bool lyricsShown: false              // the lyrics view is open

    readonly property var players: Mpris.players.values
    readonly property var player: root.chosen >= 0 && root.chosen < root.players.length ? root.players[root.chosen]
        : root.players.find(p => p.isPlaying) || root.players[0] || null

    function toggle() {
        open = !open;
    }

    LyricsSource {
        id: lyricsSource
        player: root.player
        active: root.open && root.lyricsShown
    }

    onOpenChanged: if (!open) lyricsShown = false

    Timer {
        running: root.open && root.player !== null && root.player.isPlaying
        interval: 500
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    LazyLoader {
        active: root.open

        OverlayWindow {
            name: "music"
            dim: 0.2
            onDismissed: root.open = false

            MusicContent {
                readonly property var p: root.player

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 10
                width: implicitWidth
                height: implicitHeight
                track: p ? ({
                    title: p.trackTitle,
                    artist: p.trackArtist,
                    album: p.trackAlbum,
                    artUrl: p.trackArtUrl,
                    playing: p.isPlaying,
                    position: p.position,
                    length: p.length,
                    canSeek: p.canSeek && p.positionSupported,
                    canGoNext: p.canGoNext,
                    canGoPrevious: p.canGoPrevious,
                    shuffle: p.shuffleSupported ? p.shuffle : null,
                    loop: !p.loopSupported ? "" : p.loopState === MprisLoopState.Track ? "track"
                        : p.loopState === MprisLoopState.Playlist ? "playlist" : "none"
                }) : ({ title: "", artist: "", album: "", playing: false, position: 0, length: 0 })
                players: root.players.map(other => ({ name: other.identity || other.desktopEntry || "Player", current: other === p }))
                lyrics: lyricsSource.lyrics
                onTogglePlaying: { if (p && p.canTogglePlaying) p.togglePlaying(); }
                onNext: { if (p && p.canGoNext) p.next(); }
                onPrevious: { if (p && p.canGoPrevious) p.previous(); }
                onSeek: seconds => { if (p && p.canSeek) p.position = seconds; }
                onShuffleToggled: { if (p && p.shuffleSupported) p.shuffle = !p.shuffle; }
                // None -> whole playlist -> this song -> none.
                onLoopCycled: {
                    if (p && p.loopSupported)
                        p.loopState = p.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                            : p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
                }
                onPlayerChosen: index => root.chosen = index
                onLyricsToggled: show => root.lyricsShown = show
                onClosed: root.open = false
                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}
