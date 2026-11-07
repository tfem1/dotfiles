.pragma library

// Song times and lyrics for the music panel. Lyrics come from lrclib.net
// (free, open database), asked only when the lyrics view is opened.

// 185.4 -> "3:05"
function clock(seconds) {
    const total = Math.max(0, Math.floor(seconds || 0));
    const minutes = Math.floor(total / 60);
    const rest = total % 60;
    return minutes + ":" + (rest < 10 ? "0" : "") + rest;
}

function url(title, artist, album, length) {
    const query = [["track_name", title], ["artist_name", artist]];
    if (album)
        query.push(["album_name", album]);
    if (length >= 1 && length <= 3600)
        query.push(["duration", Math.round(length)]);
    return "https://lrclib.net/api/get?" + query.map(pair => pair[0] + "=" + encodeURIComponent(pair[1])).join("&");
}

// "[01:23.45] text" lines (LRC) -> [{ time, text }], sorted by time.
function parse(synced) {
    const lines = [];
    for (const row of (synced || "").split("\n")) {
        const match = /^\[(\d+):(\d+(?:\.\d+)?)\]\s?(.*)$/.exec(row.trim());
        if (match)
            lines.push({ time: Number(match[1]) * 60 + Number(match[2]), text: match[3] });
    }
    return lines.sort((a, b) => a.time - b.time);
}

// From an lrclib answer: { kind: "synced" | "plain" | "instrumental" | "none", lines }.
function fromAnswer(answer) {
    if (!answer)
        return { kind: "none", lines: [] };
    if (answer.instrumental)
        return { kind: "instrumental", lines: [] };
    const synced = parse(answer.syncedLyrics);
    if (synced.length)
        return { kind: "synced", lines: synced };
    const plain = (answer.plainLyrics || "").split("\n").map(text => ({ time: -1, text: text }));
    return plain.length > 1 || plain[0].text ? { kind: "plain", lines: plain } : { kind: "none", lines: [] };
}

// Index of the line being sung at `position` (seconds), -1 before the first.
function current(lines, position) {
    let index = -1;
    for (let i = 0; i < lines.length && lines[i].time >= 0 && lines[i].time <= position; i++)
        index = i;
    return index;
}
