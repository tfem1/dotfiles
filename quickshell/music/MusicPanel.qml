import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../overlay"
import "lyrics.js" as Lyrics

// Connects the music panel to the media players (MPRIS). The position is
// asked for only while the panel shows a playing song; lyrics are fetched
// from lrclib.net only when the lyrics view is open.
Scope {
    id: root

    property bool open: false
    property int chosen: -1                       // player picked in the panel, -1: automatic
    property var lyrics: ({ kind: "off", lines: [] })
    property string lyricsFor: ""                 // the song the lyrics belong to

    readonly property var players: Mpris.players.values
    readonly property var player: root.chosen >= 0 && root.chosen < root.players.length ? root.players[root.chosen]
        : root.players.find(p => p.isPlaying) || root.players[0] || null
    readonly property string song: player ? player.trackTitle + "\n" + player.trackArtist : ""

    function toggle() {
        open = !open;
    }

    function hideLyrics() {
        lyrics = { kind: "off", lines: [] };
        lyricsFor = "";
    }

    function fetchLyrics() {
        const p = player;
        if (!p || !p.trackTitle) {
            lyrics = { kind: "none", lines: [] };
            return;
        }
        const key = song;
        lyricsFor = key;
        lyrics = { kind: "loading", lines: [] };
        const request = new XMLHttpRequest();
        request.onreadystatechange = () => {
            if (request.readyState !== XMLHttpRequest.DONE || key !== root.lyricsFor)
                return;
            let answer = null;
            try {
                if (request.status === 200)
                    answer = JSON.parse(request.responseText);
            } catch (error) {
                console.warn("music: unreadable lyrics answer:", error);
            }
            root.lyrics = Lyrics.fromAnswer(answer);
        };
        request.open("GET", Lyrics.url(p.trackTitle, p.trackArtist, p.trackAlbum, p.length));
        request.send();
    }

    // A new song while the lyrics show: fetch its lyrics too.
    onSongChanged: if (lyrics.kind !== "off") fetchLyrics()
    onOpenChanged: if (!open) hideLyrics()

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
                lyrics: root.lyrics
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
                onLyricsToggled: show => show ? root.fetchLyrics() : root.hideLyrics()
                onClosed: root.open = false
                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}
