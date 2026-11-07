.pragma library

// Ranks desktop apps for the launcher. Every word typed must appear in the
// app's name, generic name, comment, keywords, id or command, so "nautilus"
// finds Files and "web brow" finds the browser. Names that start with the
// text come first, then names that contain it, then the other matches.

function list(value) {
    return value ? Array.from(value) : [];
}

// 3: name starts with the text, 2: name contains it, 1: other fields do, 0: no match.
function score(app, text) {
    if (!text)
        return 1;
    const name = (app.name || "").toLowerCase();
    if (name.startsWith(text))
        return 3;
    if (name.includes(text))
        return 2;
    const haystack = [name, app.genericName, app.comment, app.id]
        .concat(list(app.keywords), list(app.command).slice(0, 1))
        .join(" ").toLowerCase();
    return text.split(/\s+/).every(word => haystack.includes(word)) ? 1 : 0;
}

function rank(apps, query, limit) {
    const text = (query || "").trim().toLowerCase();
    return list(apps)
        .filter(app => !app.noDisplay)
        .map(app => ({ app: app, score: score(app, text), key: (app.name || "").toLowerCase() }))
        .filter(match => match.score > 0)
        // Lower case: "btop" sorts with the B, not after every capital.
        .sort((a, b) => b.score - a.score || a.key.localeCompare(b.key))
        .slice(0, limit)
        .map(match => match.app);
}
