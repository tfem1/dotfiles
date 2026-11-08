import QtQuick
import "lyrics.js" as Lyrics

// The lyrics of a player's song, from lrclib.net, asked for only while
// `active`; a new song asks again. Used by the music panel and the desktop
// media widget. `lyrics`: { kind: "off" | "loading" | "synced" | "plain"
// | "instrumental" | "none", lines }.
QtObject {
    id: source

    property var player: null
    property bool active: false
    property var lyrics: ({ kind: "off", lines: [] })
    property string fetchedFor: ""     // the song the lyrics belong to
    readonly property string song: player ? player.trackTitle + "\n" + player.trackArtist : ""

    function fetch() {
        const p = player;
        if (!p || !p.trackTitle) {
            lyrics = { kind: "none", lines: [] };
            return;
        }
        const key = song;
        fetchedFor = key;
        lyrics = { kind: "loading", lines: [] };
        const request = new XMLHttpRequest();
        request.onreadystatechange = () => {
            if (request.readyState !== XMLHttpRequest.DONE || key !== source.fetchedFor)
                return;
            let answer = null;
            try {
                if (request.status === 200)
                    answer = JSON.parse(request.responseText);
            } catch (error) {
                console.warn("lyrics: unreadable answer:", error);
            }
            source.lyrics = Lyrics.fromAnswer(answer);
        };
        request.open("GET", Lyrics.url(p.trackTitle, p.trackArtist, p.trackAlbum, p.length));
        request.send();
    }

    function clear() {
        lyrics = { kind: "off", lines: [] };
        fetchedFor = "";
    }

    onSongChanged: if (active) fetch()
    onActiveChanged: active ? fetch() : clear()
}
