.pragma library

// The wallpaper list as the selector shows it: filtered by color, by the
// recent picks or by a search, and file paths turned into URLs.

// "/home/me/a #1.jpg" -> "file:///home/me/a%20%231.jpg" ("#" would end a URL).
function fileUrl(path) {
    return path ? "file://" + path.split("/").map(encodeURIComponent).join("/") : "";
}

// `images`: [{ path, name, category, theme }]; `colors`: { path: color class };
// `recent`: paths, newest first, or null; `color`, `query`: "" for none.
// The search also reads the theme a wallpaper brings: "luna" finds Luna.
function filter(images, colors, recent, color, query) {
    let list = images;
    if (recent) {
        const byPath = {};
        for (const image of images)
            byPath[image.path] = image;
        list = recent.filter(path => byPath[path]).map(path => byPath[path]);
    }
    if (color)
        list = list.filter(image => colors[image.path] === color);
    const words = (query || "").trim().toLowerCase().split(/\s+/).filter(word => word);
    if (words.length)
        list = list.filter(image => {
            const text = (image.category + " " + image.name + " " + (image.theme || "")).toLowerCase();
            return words.every(word => text.includes(word));
        });
    return list;
}

// What the toolbar label shows, e.g. "Blue · 12".
function label(count, color, recent, query) {
    const what = recent ? "Recent" : color ? color.charAt(0).toUpperCase() + color.slice(1)
        : query ? "“" + query.trim() + "”" : "All";
    return what + " · " + count;
}

function indexOf(list, path) {
    return Math.max(0, list.findIndex(image => image.path === path));
}
