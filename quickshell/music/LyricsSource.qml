import QtQuick
import "lyrics.js" as Lyrics

// The lyrics of a player's song, from lrclib.net, asked for only while
// `active`; a new song asks again. Several requests are tried in turn
// (lyrics.js attempts: exact match, then searches) until one has lyrics;
// what is found is kept for the session (lyrics.js cache). Used by the
// music panel and the desktop media widget. `lyrics`: { kind: "off" |
// "loading" | "synced" | "plain" | "instrumental" | "none", lines }.
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
        if (key in Lyrics.cache) {
            lyrics = Lyrics.cache[key];
            return;
        }
        lyrics = { kind: "loading", lines: [] };
        tryNext(key, Lyrics.attempts(p.trackTitle, p.trackArtist, p.trackAlbum, p.length), p.length);
    }

    // One request; on nothing found, the next one; at the end, "none".
    function tryNext(key, list, length) {
        if (key !== fetchedFor)
            return;   // another song meanwhile
        if (list.length === 0) {
            lyrics = Lyrics.cache[key] = { kind: "none", lines: [] };
            return;
        }
        const attempt = list[0];
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
            const found = Lyrics.fromAnswer(attempt.search ? Lyrics.best(answer, length) : answer);
            if (found.kind === "none")
                source.tryNext(key, list.slice(1), length);
            else
                source.lyrics = Lyrics.cache[key] = found;
        };
        request.open("GET", attempt.url);
        request.setRequestHeader("Lrclib-Client", Lyrics.CLIENT);
        request.send();
    }

    function clear() {
        lyrics = { kind: "off", lines: [] };
        fetchedFor = "";
    }

    onSongChanged: if (active) fetch()
    onActiveChanged: active ? fetch() : clear()
}
