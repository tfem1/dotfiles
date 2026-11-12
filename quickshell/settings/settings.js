.pragma library

// The Settings window's logic: what search finds, the changes waiting to be
// applied, and how values are shown. Plain data: tested without Quickshell.

// Every row of the window: page, row id (its objectName), title, and the
// words that find it.
const INDEX = [
    { page: "appearance", id: "theme", title: "Theme", words: "colors palette forest cat tabby pine moss red orange yellow green blue purple pink ruby ember amber emerald ocean sapphire amethyst rose dark light catppuccin dracula nord gruvbox black white noir mono" },
    { page: "appearance", id: "accent", title: "Accent color", words: "highlight color" },
    { page: "appearance", id: "wallpaper", title: "Wallpaper", words: "background picture image pixel forest cat" },
    { page: "appearance", id: "folders", title: "Folder color", words: "icons fairywren" },
    { page: "appearance", id: "corners", title: "Rounded corners", words: "radius shape round" },
    { page: "appearance", id: "gaps", title: "Space between windows", words: "gaps margin spacing" },
    { page: "appearance", id: "opacity", title: "Transparency", words: "opacity glass see-through" },
    { page: "appearance", id: "blur", title: "Blur", words: "effects glass frosted" },
    { page: "appearance", id: "shadows", title: "Shadows", words: "effects shadow" },
    { page: "appearance", id: "animations", title: "Animations", words: "motion effects" },
    { page: "appearance", id: "textsize", title: "Text size", words: "font size bigger smaller" },
    { page: "tweaks", id: "modes", title: "Modes", words: "gaming coffee night sleep focus presentation power saver do not disturb screenshot region" },
    { page: "tweaks", id: "bar-position", title: "Bar position", words: "top bottom left right side vertical edge panel" },
    { page: "keys", id: "keybinds", title: "Keybinds", words: "shortcuts keys keyboard hotkeys bindings super change" },
    { page: "tweaks", id: "bar-layout", title: "Bar layout", words: "modules order move drag hide clock workspaces logo power status" },
    { page: "tweaks", id: "record-audio", title: "Sound in screen recordings", words: "record video audio microphone sound capture screencast" },
    { page: "tweaks", id: "bar-transparent", title: "Transparent bar", words: "see-through invisible background clear panel" },
    { page: "dock", id: "dock-enabled", title: "Dock", words: "apps pinned taskbar launcher icons" },
    { page: "dock", id: "dock-opacity", title: "Dock opacity", words: "transparent see-through dock" },
    { page: "dock", id: "dock-position", title: "Dock position", words: "bottom left right side dock" },
    { page: "dock", id: "dock-autohide", title: "Hide the dock", words: "autohide hidden dock" },
    { page: "widgets", id: "widget-move", title: "Move the widgets", words: "drag place position free desktop" },
    { page: "widgets", id: "widget-calendar", title: "Calendar widget", words: "month days date desktop" },
    { page: "fonts", id: "font-sans", title: "Interface font", words: "font typeface text family monocraft inter" },
    { page: "fonts", id: "font-mono", title: "Monospace font", words: "font terminal code mono typeface" },
    { page: "home", id: "welcome", title: "Welcome", words: "home uptime system os greeting" },
    { page: "system", id: "gamemode", title: "Game mode", words: "games play performance fps roblox" },
    { page: "system", id: "sound", title: "Sound", words: "volume audio speaker mute" },
    { page: "system", id: "microphone", title: "Microphone", words: "mic input mute" },
    { page: "system", id: "brightness", title: "Brightness", words: "screen display light" },
    { page: "system", id: "wifi", title: "Wi-Fi", words: "wifi network internet wireless" },
    { page: "system", id: "bluetooth", title: "Bluetooth", words: "devices headphones" },
    { page: "system", id: "keyboard", title: "Keyboard layout", words: "language azerty qwerty" },
    { page: "system", id: "quiet", title: "Quiet mode", words: "do not disturb notifications" },
    { page: "system", id: "awake", title: "Stay awake", words: "caffeine idle sleep" },
    { page: "system", id: "sleep", title: "Sleep", words: "idle dim lock screen off suspend energy power" },
    { page: "display", id: "screens", title: "Screens: on or off, refresh rate, resolution",
      words: "display screen monitor hz hertz fps refresh rate resolution 144 165 240 off on disable turn off" },
    { page: "widgets", id: "widget-corner", title: "Widgets corner",
      words: "desktop widgets corner position place left right top bottom" },
    { page: "widgets", id: "widget-clock", title: "Clock widget", words: "desktop time date" },
    { page: "widgets", id: "widget-audio", title: "Audio spectrum widget", words: "desktop cava visualizer music sound bars" },
    { page: "widgets", id: "widget-media", title: "Now playing widget", words: "desktop music song lyrics media player" },
    { page: "widgets", id: "widget-cpu", title: "CPU widget", words: "desktop processor usage load" },
    { page: "widgets", id: "widget-gpu", title: "GPU widget", words: "desktop graphics card usage vram nvidia amd" },
    { page: "widgets", id: "widget-ram", title: "RAM widget", words: "desktop memory usage" },
    { page: "widgets", id: "widget-disk", title: "Disk widget", words: "desktop storage space ssd usage" }
];

// The pages of the window, in the order of the menu.
const PAGES = [
    { id: "home", title: "Home", icon: "home", text: "Welcome, theme, uptime",
      note: "Your desktop at a glance." },
    { id: "appearance", title: "Appearance", icon: "wallpaper", text: "Theme, colors, wallpaper, effects",
      note: "Nothing changes until you press Apply: the preview shows it first." },
    { id: "fonts", title: "Fonts", icon: "text_fields", text: "Interface and monospace fonts, sizes",
      note: "Every font installed, drawn in its own face. These settings act at once." },
    { id: "system", title: "System", icon: "settings", text: "Sound, brightness, connections, sleep",
      note: "These settings act at once." },
    { id: "display", title: "Display", icon: "computer", text: "Screens on or off, resolution, Hz",
      note: "A change acts at once and asks to be kept: without an answer it goes back after 15 seconds." },
    { id: "widgets", title: "Widgets", icon: "grid_view", text: "Clock, music, CPU, GPU, RAM, disk",
      note: "On the desktop, under the windows, in the colors of the theme. These settings act at once." },
    { id: "dock", title: "Dock", icon: "apps", text: "Pinned apps, opacity, position",
      note: "In the theme's colors. These settings act at once." },
    { id: "tweaks", title: "Tweaks", icon: "tune", text: "Gaming, coffee, night, screenshots",
      note: "A click turns a mode on or off, at once." },
    { id: "keys", title: "Keybinds", icon: "keyboard", text: "Shortcuts of the panels and tools",
      note: "A new key acts at once, in Hyprland, Sway or Niri." }
];

// The modes of the Tweaks page; ids are those of Modes.flip.
const MODES = [
    { id: "game", icon: "sports_esports", title: "Gaming", text: "Tearing, CPU boost" },
    { id: "coffee", icon: "coffee", title: "Coffee", text: "Never sleeps" },
    { id: "night", icon: "dark_mode", title: "Night", text: "Warm, dim, quiet" },
    { id: "quiet", icon: "notifications_off", title: "Do not disturb", text: "Notifications wait" },
    { id: "saver", icon: "eco", title: "Power saver", text: "CPU saves, dim screen" },
    { id: "presentation", icon: "co_present", title: "Presentation", text: "No notifications" },
    { id: "focus", icon: "center_focus_strong", title: "Focus", text: "Quiet, no widgets" },
    { id: "sleep", icon: "mode_standby", title: "Sleep", text: "Lock and suspend" },
    { id: "shot-full", icon: "screenshot_monitor", title: "Screenshot", text: "The whole screen" },
    { id: "shot-region", icon: "screenshot_region", title: "Region", text: "Pick an area" }
];

// "Good morning" from 5 h, "Good afternoon" from 12 h, "Good evening" from
// 18 h, "Good night" from 22 h.
function greeting(hour) {
    return hour >= 5 && hour < 12 ? "Good morning" : hour >= 12 && hour < 18 ? "Good afternoon"
        : hour >= 18 && hour < 22 ? "Good evening" : "Good night";
}

// "3 h 25 min", "2 days 4 h", "12 min" from seconds.
function uptime(seconds) {
    const minutes = Math.floor((seconds || 0) / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);
    if (days > 0)
        return days + (days === 1 ? " day " : " days ") + hours % 24 + " h";
    return hours > 0 ? hours + " h " + minutes % 60 + " min" : minutes + " min";
}

function pageOf(id) {
    return PAGES.find(entry => entry.id === id) || PAGES[0];
}

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

// Changes asked for but not read back yet show at once over the saved
// values: a switch flips on the click, not when `tfem settings set` ends.
function overlay(values, asked) {
    return Object.assign({}, values, asked);
}

// The changes still waiting once the values are read again: those now
// saved leave.
function settle(values, asked) {
    const result = {};
    for (const key in asked || {})
        if ((values || {})[key] !== asked[key])
            result[key] = asked[key];
    return result;
}

// Without these keys (a write that failed: the saved value shows again).
function drop(asked, keys) {
    const result = Object.assign({}, asked);
    for (const key of keys || [])
        delete result[key];
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

// "2560x1440@165.00" -> { size: "2560x1440", rate: 165 } (rate rounded).
function modeParts(mode) {
    const match = (mode || "").match(/^(\d+x\d+)@([\d.]+)$/);
    return match ? { size: match[1], rate: Math.round(parseFloat(match[2])) } : { size: "", rate: 0 };
}

// "2560 × 1440 at 165 Hz".
function modeLabel(mode) {
    const parts = modeParts(mode);
    return parts.size ? parts.size.replace("x", " × ") + " at " + parts.rate + " Hz" : "Unknown";
}

// The refresh rate choices of a screen at one resolution: the highest one
// on its own ("auto": what Hyprland picks), then each rate.
function rateChoices(screen, size) {
    const found = ((screen || {}).resolutions || []).find(entry => entry.size === size);
    return [{ value: "auto", label: "Highest" }]
        .concat((found ? found.rates : []).map(rate => ({ value: rate.mode, label: rate.label })));
}

// The resolutions to offer: the biggest few, plus the one in use.
function sizeChoices(screen, current, count) {
    const sizes = ((screen || {}).resolutions || []).map(entry => entry.size);
    const shown = sizes.slice(0, count || 6);
    if (current && sizes.includes(current) && !shown.includes(current))
        shown.push(current);
    return shown.map(size => ({ value: size, label: size.replace("x", " × ") }));
}

// How many screens are on, counting what was picked in the window (a mode
// turns a screen on, "off" turns it off). The last one on stays on.
function screensOn(screens, chosen) {
    return (screens || []).filter(screen => {
        const picked = (chosen || {})[screen.name];
        return picked === "off" ? false : picked ? true : screen.on !== false;
    }).length;
}

// The fastest mode of a resolution (picked when the resolution changes).
function fastest(screen, size) {
    const found = ((screen || {}).resolutions || []).find(entry => entry.size === size);
    return found && found.rates.length > 0 ? found.rates[0].mode : "";
}
