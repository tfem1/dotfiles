.pragma library
// The workspace overview's model, from Hyprland's state as plain objects:
// workspaces 1 to 10, each with its windows placed as on its screen, in
// parts of the screen (0 to 1), so any card size can draw them.

// `workspaces`: [{ id, monitor: { x, y, width, height, scale } }]
// `windows`: [{ address, title, appClass, workspace (id), at: [x, y], size: [w, h], floating, focused }]
// `focused`: id of the focused workspace.
function model(workspaces, windows, focused) {
    const list = [];
    for (let id = 1; id <= 10; id++) {
        const workspace = (workspaces || []).find(entry => entry.id === id);
        const screen = workspace && workspace.monitor ? workspace.monitor : null;
        const width = screen ? screen.width / (screen.scale || 1) : 1920;
        const height = screen ? screen.height / (screen.scale || 1) : 1080;
        const own = (windows || []).filter(window => window.workspace === id).map(window => ({
            address: window.address,
            title: window.title || "",
            appClass: window.appClass || "",
            focused: !!window.focused,
            floating: !!window.floating,
            x: clamp(((window.at || [0, 0])[0] - (screen ? screen.x : 0)) / width),
            y: clamp(((window.at || [0, 0])[1] - (screen ? screen.y : 0)) / height),
            w: clamp(((window.size || [0, 0])[0]) / width),
            h: clamp(((window.size || [0, 0])[1]) / height)
        }));
        // Floating windows on top, as on screen.
        own.sort((a, b) => a.floating - b.floating);
        list.push({ id: id, focused: id === focused, windows: own });
    }
    return list;
}

function clamp(value) {
    return Math.max(0, Math.min(1, value || 0));
}

// "0x55d8..." from what Hyprland gives (with or without the 0x).
function address(value) {
    const text = String(value || "");
    return text.startsWith("0x") ? text : "0x" + text;
}

// The Lua dispatch that sends a window to a workspace, staying where you are.
function moveCommand(windowAddress, workspace) {
    return `hl.dsp.window.move({ window = "address:${address(windowAddress)}", workspace = ${Math.floor(workspace)}, follow = false })`;
}

function focusCommand(windowAddress) {
    return `hl.dsp.focus({ window = "address:${address(windowAddress)}" })`;
}

// Key 1..9, 0 -> workspace 1..10; anything else -> 0.
function workspaceForKey(text) {
    if (!/^[0-9]$/.test(text || ""))
        return 0;
    return text === "0" ? 10 : Number(text);
}
