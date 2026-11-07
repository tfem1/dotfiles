.pragma library

// Small helpers of the network panel: icons for signal strength and
// Bluetooth device types, the order of the lists, and the line of text
// under each item.

function wifiIcon(strength) {
    return strength > 0.75 ? "wifi" : strength > 0.5 ? "network_wifi_3_bar"
        : strength > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
}

// BlueZ names device types with freedesktop icon names.
var DEVICE_ICONS = [["audio-headset", "headphones"], ["audio-headphones", "headphones"],
                    ["audio-card", "speaker"], ["input-mouse", "mouse"],
                    ["input-keyboard", "keyboard_alt"], ["input-gaming", "sports_esports"],
                    ["phone", "smartphone"], ["computer", "computer"]];

function deviceIcon(icon) {
    const found = DEVICE_ICONS.find(entry => (icon || "").startsWith(entry[0]));
    return found ? found[1] : "bluetooth";
}

// Connected first, then saved networks, then by signal.
function sortNetworks(networks) {
    return networks.slice().sort((a, b) => (b.connected - a.connected) || (b.known - a.known)
        || (b.strength - a.strength) || a.name.localeCompare(b.name));
}

var FAILURES = {
    password: "Password needed",
    wrong: "Wrong password?",
    lost: "Out of range",
    enterprise: "Company login: not supported here yet",
    other: "Could not connect",
    pair: "Could not pair: it may ask for a code, pair it once with bluetoothctl"
};

function networkStatus(network) {
    if (network.failed)
        return FAILURES[network.failed] || FAILURES.other;
    if (network.busy)
        return network.connected ? "Disconnecting…" : "Connecting…";
    if (network.connected)
        return network.secured ? "Connected · secured" : "Connected · open network";
    if (network.known)
        return "Saved";
    return network.secured ? "Secured" : "Open network";
}

function deviceStatus(device) {
    if (device.failed)
        return FAILURES[device.failed] || FAILURES.other;
    if (device.busy)
        return device.paired ? (device.connected ? "Disconnecting…" : "Connecting…") : "Pairing…";
    if (device.connected)
        return device.battery >= 0 ? "Connected · battery " + Math.round(device.battery * 100) + "%" : "Connected";
    return device.paired ? "Not connected" : "Click to pair";
}
