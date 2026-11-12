.pragma library
// The dock's list: pinned apps first (config.json dock.pinned, desktop file
// ids), then the apps that run without being pinned. A window belongs to an
// app when its Wayland app id matches the desktop id, ignoring case, a
// ".desktop" ending and a reverse-domain prefix ("org.gnome.Nautilus" and
// "nautilus" are one app).

function ids(text) {
    return (text || "").split(",").map(id => id.trim()).filter(id => id);
}

function key(id) {
    const plain = (id || "").toLowerCase().replace(/\.desktop$/, "");
    return plain.split(".").pop();
}

// `pinned`: "firefox,kitty"; `windows`: [{ appId, activated }].
// Gives [{ id, pinned, running (window count), focused }].
function items(pinned, windows) {
    const result = ids(pinned).map(id => ({ id: id, pinned: true, running: 0, focused: false }));
    for (const window of windows || []) {
        if (!window.appId)
            continue;
        let item = result.find(entry => key(entry.id) === key(window.appId));
        if (!item) {
            item = { id: window.appId, pinned: false, running: 0, focused: false };
            result.push(item);
        }
        item.running += 1;
        item.focused = item.focused || !!window.activated;
    }
    return result;
}

// `pinned` with `id` added at the end, or taken out.
function togglePin(pinned, id) {
    const list = ids(pinned);
    const found = list.findIndex(entry => key(entry) === key(id));
    if (found >= 0)
        list.splice(found, 1);
    else
        list.push(id);
    return list.join(",");
}

// Which window of an app to bring forward: the one after the focused one,
// so clicking again cycles through them.
function nextWindow(windows, id) {
    const own = (windows || []).filter(window => key(window.appId) === key(id));
    if (own.length === 0)
        return -1;
    const focused = own.findIndex(window => window.activated);
    return (windows || []).indexOf(own[(focused + 1) % own.length]);
}
