.pragma library

// Song times and lyrics for the music panel and the media widget. Lyrics
// come from lrclib.net (free, open database). Players give messy names
// (YouTube: "Artist - Song (Official Video)" by "Artist - Topic"), so the
// names are cleaned, then several requests are tried in turn (attempts),
// the exact one first, then searches; the best record wins (best).

// Tells lrclib who asks, as its documentation requests.
var CLIENT = "tfem dotfiles (https://github.com/tfem1/dotfiles)";
// Lyrics found, by song: shared by everything that imports this file.
var cache = {};

// 185.4 -> "3:05"
function clock(seconds) {
    const total = Math.max(0, Math.floor(seconds || 0));
    const minutes = Math.floor(total / 60);
    const rest = total % 60;
    return minutes + ":" + (rest < 10 ? "0" : "") + rest;
}

const NOISE = [
    /\s*[\(\[][^\)\]]*\b(official|lyrics?|lyric video|audio|video|visuali[sz]er|hd|hq|4k|mv|m\/v|remaster(ed)?|explicit|clean)\b[^\)\]]*[\)\]]/gi,
    /\s*[\(\[](ft\.?|feat\.?|featuring|with)\s[^\)\]]*[\)\]]/gi,
    /\s+(ft\.?|feat\.?|featuring)\s.*$/i,
    /\s+-\s+(\d{4}\s+)?remaster(ed)?(\s+\d{4})?.*$/i,
    /\s*[|｜【].*$/,
];

// { title, artist } without what players and video sites add.
function clean(title, artist) {
    let name = (title || "").trim();
    let by = (artist || "").replace(/\s*-\s*topic$/i, "").replace(/vevo$/i, "").trim();
    for (const pattern of NOISE)
        name = name.replace(pattern, "");
    // "Artist - Song" in the title (videos): the artist part goes away.
    const dash = name.match(/^(.+?)\s+[-–—]\s+(.+)$/);
    if (dash && (!by || dash[1].toLowerCase().includes(by.toLowerCase()) || by.toLowerCase().includes(dash[1].toLowerCase()))) {
        by = by || dash[1].trim();
        name = dash[2].trim();
        for (const pattern of NOISE)
            name = name.replace(pattern, "");
    }
    by = by.split(/\s*(,|&| x | feat\.? | ft\.? )\s*/i)[0].trim();
    return { title: name.trim() || (title || "").trim(), artist: by };
}

function query(pairs) {
    return pairs.filter(pair => pair[1] !== "" && pair[1] !== undefined)
        .map(pair => pair[0] + "=" + encodeURIComponent(pair[1])).join("&");
}

function url(title, artist, album, length) {
    const duration = length >= 1 && length <= 3600 ? Math.round(length) : "";
    return "https://lrclib.net/api/get?" + query([["track_name", title], ["artist_name", artist],
                                                   ["album_name", album || ""], ["duration", duration]]);
}

// The requests to try, in turn: [{ url, search }] (search: the answer is a
// list to pick from). Exact first, then without the album, then searches.
function attempts(title, artist, album, length) {
    const names = clean(title, artist);
    const list = [];
    if (names.artist) {
        list.push({ url: url(names.title, names.artist, album, length), search: false });
        if (album)
            list.push({ url: url(names.title, names.artist, "", length), search: false });
        list.push({ url: "https://lrclib.net/api/search?" + query([["track_name", names.title], ["artist_name", names.artist]]),
                    search: true });
    }
    list.push({ url: "https://lrclib.net/api/search?" + query([["q", (names.artist + " " + names.title).trim()]]), search: true });
    return list;
}

// The record to keep from a search: one with lyrics, synced if possible,
// its length closest to the song's (within 15 s when the length is known);
// else the closest version, as plain lyrics.
function best(records, length) {
    const scored = (records || []).filter(record => record && (record.syncedLyrics || record.plainLyrics || record.instrumental))
        .map((record, order) => {
            const gap = length > 0 && record.duration > 0 ? Math.abs(record.duration - length) : 0;
            return { record: record, gap: gap, order: order, score: (record.syncedLyrics ? 0 : 10) + gap };
        })
    // Equal scores: lrclib's own order (its best match first).
    scored.sort((a, b) => a.score - b.score || a.order - b.order);
    const close = scored.filter(entry => entry.gap <= 15);
    if (close.length)
        return close[0].record;
    // Only other versions (a video with a long intro...): their words, but
    // not their timing, which would be off.
    const closest = scored.sort((a, b) => a.gap - b.gap)[0];
    if (!closest)
        return null;
    const words = closest.record.plainLyrics || parse(closest.record.syncedLyrics).map(line => line.text).join("\n");
    return { instrumental: !!closest.record.instrumental, plainLyrics: words, syncedLyrics: "" };
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
