.pragma library

// The Settings window's logic: what search finds, the changes waiting to be
// applied, and how values are shown. Plain data: tested without Quickshell.

// Every row of the window: page, row id (its objectName), title, and the
// words that find it.
const INDEX = [
    { page: "appearance", id: "theme", title: "Theme", words: "colors palette pony dark light catppuccin dracula nord gruvbox" },
    { page: "appearance", id: "accent", title: "Accent color", words: "highlight color" },
    { page: "appearance", id: "wallpaper", title: "Wallpaper", words: "background picture image character" },
    { page: "appearance", id: "folders", title: "Folder color", words: "icons fairywren" },
    { page: "appearance", id: "corners", title: "Rounded corners", words: "radius shape round" },
    { page: "appearance", id: "gaps", title: "Space between windows", words: "gaps margin spacing" },
    { page: "appearance", id: "opacity", title: "Transparency", words: "opacity glass see-through" },
    { page: "appearance", id: "blur", title: "Blur", words: "effects glass frosted" },
    { page: "appearance", id: "shadows", title: "Shadows", words: "effects shadow" },
    { page: "appearance", id: "animations", title: "Animations", words: "motion effects" },
    { page: "appearance", id: "textsize", title: "Text size", words: "font size bigger smaller" },
    { page: "system", id: "gamemode", title: "Game mode", words: "games play performance fps roblox" },
    { page: "system", id: "sound", title: "Sound", words: "volume audio speaker mute" },
    { page: "system", id: "microphone", title: "Microphone", words: "mic input mute" },
    { page: "system", id: "brightness", title: "Brightness", words: "screen display light" },
    { page: "system", id: "wifi", title: "Wi-Fi", words: "wifi network internet wireless" },
    { page: "system", id: "bluetooth", title: "Bluetooth", words: "devices headphones" },
    { page: "system", id: "keyboard", title: "Keyboard layout", words: "language azerty qwerty" },
    { page: "system", id: "quiet", title: "Quiet mode", words: "do not disturb notifications" },
    { page: "system", id: "awake", title: "Stay awake", words: "caffeine idle sleep" },
    { page: "system", id: "sleep", title: "Sleep", words: "idle dim lock screen off suspend energy power" }
];

// Rows whose title or words hold every word of `query` (nothing for "").
function search(query) {
    const words = (query || "").toLowerCase().split(/\s+/).filter(word => word);
    if (words.length === 0)
        return [];
    return INDEX.filter(entry => {
        const text = (entry.title + " " + entry.words).toLowerCase();
        return words.every(word => text.includes(word));
    });
}

// A setting as it will be: the change waiting to be applied, else the saved one.
function value(values, pending, key) {
    return pending && key in pending ? pending[key] : (values || {})[key];
}

// `pending` with `key` set to `next`; a value equal to the saved one is not
// a change any more.
function change(values, pending, key, next) {
    const result = Object.assign({}, pending);
    if ((values || {})[key] === next)
        delete result[key];
    else
        result[key] = next;
    return result;
}

// "KEY=VALUE" arguments for `tfem settings set`, in a stable order.
function pairs(pending) {
    return Object.keys(pending || {}).sort().map(key => key + "=" + pending[key]);
}

// The theme with this id (or the first one while the list is loading).
function theme(themes, id) {
    return (themes || []).find(entry => entry.id === id) || (themes || [])[0] || null;
}

// The color an accent choice gives with a theme: its own, or one of its hues.
function accentColor(entry, choice) {
    if (!entry)
        return "#888888";
    return choice === "theme" || !entry.colors[choice] ? entry.colors.accent : entry.colors[choice];
}

// The usual choices, plus the value in use when it is not one of them
// (11 minutes stays visible and chosen).
function steps(usual, current) {
    if (typeof current !== "number" || usual.includes(current))
        return usual;
    return usual.concat([current]).sort((a, b) => a - b);
}

// Idle minutes as the window shows them.
function minutes(count) {
    if (!count)
        return "Never";
    return count < 60 ? count + " min" : (count / 60) + " h";
}

// "1 change", "3 changes".
function changes(pending) {
    const count = Object.keys(pending || {}).length;
    return count === 1 ? "1 change" : count + " changes";
}
