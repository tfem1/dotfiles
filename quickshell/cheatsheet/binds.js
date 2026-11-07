.pragma library

// Turns `hyprctl binds -j` into the cheatsheet rows: readable key names,
// binds of the same action merged, numbered actions (workspaces) folded into
// one row. Only binds with a description are shown.

// Modifier bits of `modmask` (Hyprland, src/input/Keys.hpp).
const MODIFIERS = [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]];

// Key names are written in any case in the config: looked up in lower case.
const NAMES = {
    "return": "Enter", "space": "Space", "escape": "Esc", "slash": "/", "print": "Print",
    "left": "←", "right": "→", "up": "↑", "down": "↓",
    "mouse:272": "Left drag", "mouse:273": "Right drag",
    "xf86audioraisevolume": "Volume up", "xf86audiolowervolume": "Volume down",
    "xf86audiomute": "Mute", "xf86audiomicmute": "Mic mute", "xf86audioplay": "Play",
    "xf86audiopause": "Pause", "xf86audioprev": "Previous", "xf86audionext": "Next",
    "xf86monbrightnessup": "Brightness up", "xf86monbrightnessdown": "Brightness down",
    "xf86poweroff": "Power"
};

function keyName(key) {
    const known = NAMES[key.toLowerCase()];
    if (known)
        return known;
    return key.length === 1 ? key.toUpperCase() : key.charAt(0).toUpperCase() + key.slice(1);
}

function modifiers(mask) {
    return MODIFIERS.filter(entry => mask & entry[0]).map(entry => entry[1]);
}

// [{ description, keys: [["SUPER", "Enter"], ...] }], in config order.
function rows(binds) {
    const result = [];
    const byId = {};
    for (const bind of binds) {
        if (!bind.has_description || bind.submap)
            continue;
        const mods = modifiers(bind.modmask);
        const key = keyName(bind.key);
        const numbered = /^(.*\S) (\d+)$/.exec(bind.description);
        const id = numbered ? numbered[1] + "|" + mods.join("+") : bind.description;
        let row = byId[id];
        if (!row) {
            row = byId[id] = { description: bind.description, label: numbered ? numbered[1] : "", mods: mods, keys: [], from: null, to: null };
            result.push(row);
        }
        if (!numbered) {
            row.keys.push(mods.concat([key]));
            continue;
        }
        const n = Number(numbered[2]);
        if (!row.from || n < row.from.n)
            row.from = { n: n, key: key };
        if (!row.to || n > row.to.n)
            row.to = { n: n, key: key };
    }
    return result.map(row => {
        if (!row.from)
            return { description: row.description, keys: row.keys };
        if (row.from.n === row.to.n)
            return { description: row.description, keys: [row.mods.concat([row.from.key])] };
        return {
            description: row.label + " " + row.from.n + "–" + row.to.n,
            keys: [row.mods.concat([row.from.key + "…" + row.to.key])]
        };
    });
}
