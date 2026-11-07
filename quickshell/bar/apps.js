.pragma library

// The running apps of the bar: open windows and tray icons grouped into one
// entry per app. Plain data in and out, so it is tested without Quickshell.

// "com.obsproject.Studio" -> "comobsprojectstudio", "OBS Studio" -> "obsstudio".
function norm(text) {
    return (text || "").toLowerCase().replace(/[^a-z0-9]/g, "");
}

// The shell's own windows are never listed (nor quit by mistake).
function isShell(appId) {
    return /^org\.quickshell/.test(appId || "");
}

// The names an app goes by: its id, the last part of a reverse-DNS id
// ("Studio"), the name of its desktop entry ("OBS Studio").
function aliases(appId, name) {
    const last = (appId || "").split(".").pop();
    return [norm(appId), norm(last), norm(name)].filter(alias => alias.length > 2);
}

// A tray icon belongs to an app when one of its names is one of the app's;
// `loose` also accepts the start of one ("obs" and "obsstudio").
function matches(names, appAliases, loose) {
    return names.some(name => appAliases.some(alias =>
        alias === name || loose && (alias.startsWith(name) || name.startsWith(alias))));
}

// `windows`: [{ appId, name, icon, activated }], in the order they opened.
// `trays`: [{ id, title, tooltip, icon, applet }]; an applet (network,
// volume…) is shown only when it belongs to an app with a window.
// Returns [{ key, name, icon, windows, focused, tray }]: `windows` is the
// number of open windows, `tray` the index in `trays` or -1.
function group(windows, trays) {
    const apps = [];
    const byKey = {};
    for (const window of windows) {
        if (isShell(window.appId))
            continue;
        const key = norm(window.appId);
        let app = byKey[key];
        if (!app) {
            app = byKey[key] = {
                key: key, name: window.name || window.appId || "Window", icon: window.icon || "",
                windows: 0, focused: false, tray: -1, aliases: aliases(window.appId, window.name)
            };
            apps.push(app);
        }
        app.windows += 1;
        app.focused = app.focused || !!window.activated;
    }
    for (let index = 0; index < trays.length; index++) {
        const tray = trays[index];
        const names = [norm(tray.id), norm(tray.title), norm(tray.tooltip)].filter(name => name.length > 2);
        const free = apps.filter(app => app.tray < 0 && app.windows > 0);
        const owner = free.find(app => matches(names, app.aliases, false))
            || free.find(app => matches(names, app.aliases, true));
        if (owner) {
            owner.tray = index;
            owner.icon = owner.icon || tray.icon || "";
        } else if (!tray.applet) {
            apps.push({
                key: "tray:" + (norm(tray.id) || index), name: tray.title || tray.tooltip || tray.id || "App",
                icon: tray.icon || "", windows: 0, focused: false, tray: index, aliases: []
            });
        }
    }
    return apps.map(app => ({
        key: app.key, name: app.name, icon: app.icon, windows: app.windows, focused: app.focused, tray: app.tray
    }));
}

// The entry of an app's own tray menu that quits it ("Quit Discord",
// "Exit", "Quitter"), or -1. Using it lets the app save before leaving.
function quitIndex(texts) {
    return texts.findIndex(text => /\b(quit|exit|quitter|beenden|salir|esci)\b/i.test(text || ""));
}

// "Discord", 2 -> "2 windows"; tray only -> "In the tray".
function detail(windows, hasTray) {
    if (windows === 0)
        return hasTray ? "In the tray" : "";
    return windows === 1 ? "1 window" : windows + " windows";
}

// The rows of a tray menu as the bar's menu shows them: the quit entry
// (`skip`, shown as the red Quit row instead) left out, separators only
// between entries. `entries`: [{ text, enabled, separator, submenu }];
// each row keeps the `index` of its entry.
function rows(entries, skip) {
    const result = [];
    for (let index = 0; index < entries.length; index++) {
        const entry = entries[index];
        if (index === skip || (entry.separator && (result.length === 0 || result[result.length - 1].separator)))
            continue;
        result.push({
            text: entry.text || "", enabled: entry.enabled !== false, separator: !!entry.separator,
            submenu: !!entry.submenu, index: index
        });
    }
    while (result.length > 0 && result[result.length - 1].separator)
        result.pop();
    return result;
}
