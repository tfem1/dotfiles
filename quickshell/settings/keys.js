.pragma library

// Settings → Keybinds: a key pressed (Qt key code and modifiers) turned into
// the names of keybinds.toml, "SUPER + SHIFT + C". Qt's key codes are fixed
// numbers (Qt::Key); Super is Qt's Meta modifier on Linux.

const NAMED = {
    0x01000004: "RETURN", 0x01000005: "RETURN", 0x20: "SPACE", 0x01000001: "TAB", 0x01000000: "ESCAPE",
    0x01000009: "PRINT", 0x2f: "SLASH", 0x5c: "BACKSLASH", 0x2c: "COMMA", 0x2e: "PERIOD", 0x2d: "MINUS",
    0x3d: "EQUAL", 0x3b: "SEMICOLON", 0x27: "APOSTROPHE", 0x60: "GRAVE", 0x5b: "BRACKETLEFT",
    0x5d: "BRACKETRIGHT", 0x01000003: "BACKSPACE", 0x01000007: "DELETE", 0x01000006: "INSERT",
    0x01000010: "HOME", 0x01000011: "END", 0x01000016: "PAGE_UP", 0x01000017: "PAGE_DOWN",
    0x01000012: "LEFT", 0x01000013: "UP", 0x01000014: "RIGHT", 0x01000015: "DOWN"
};
// With Shift, a digit comes as its symbol (US layout): ! is 1, ) is 0.
const SHIFTED = { 0x21: "1", 0x40: "2", 0x23: "3", 0x24: "4", 0x25: "5", 0x5e: "6", 0x26: "7", 0x2a: "8",
                  0x28: "9", 0x29: "0", 0x3f: "SLASH", 0x5f: "MINUS", 0x2b: "EQUAL" };
const MODIFIERS = [[0x10000000, "SUPER"], [0x04000000, "CTRL"], [0x08000000, "ALT"], [0x02000000, "SHIFT"]];

function keyName(key) {
    if (key >= 0x41 && key <= 0x5a || key >= 0x30 && key <= 0x39)
        return String.fromCharCode(key);
    if (key >= 0x01000030 && key <= 0x0100003b)
        return "F" + (key - 0x01000030 + 1);
    return NAMED[key] || SHIFTED[key] || "";
}

// "" while only modifiers are held, or for a key that cannot be bound.
function combo(key, modifiers) {
    const name = keyName(key);
    if (!name)
        return "";
    return MODIFIERS.filter(entry => modifiers & entry[0]).map(entry => entry[1]).concat([name]).join(" + ");
}

// The action that has this key, other than `id` (or null).
function owner(actions, key, id) {
    return actions.find(action => action.key === key && action.id !== id) || null;
}

// Shown on the key: PRINT -> Print, SUPER + SLASH -> SUPER + /.
function label(key) {
    if (!key)
        return "No key";
    const shown = { SLASH: "/", BACKSLASH: "\\", COMMA: ",", PERIOD: ".", MINUS: "-", EQUAL: "=",
                    SEMICOLON: ";", APOSTROPHE: "'", GRAVE: "`", BRACKETLEFT: "[", BRACKETRIGHT: "]",
                    RETURN: "Enter", ESCAPE: "Esc", PRINT: "Print", SPACE: "Space", PAGE_UP: "Page Up",
                    PAGE_DOWN: "Page Down", LEFT: "←", RIGHT: "→", UP: "↑", DOWN: "↓" };
    return key.split(" + ").map(part => shown[part] || part).join(" + ");
}
