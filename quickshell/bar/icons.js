.pragma library
// Icon names of the bar's status icons, shared by the row (top, bottom) and
// the column (left, right). `s`: the status object of Bar.qml.

function volume(s) {
    return s.muted ? "volume_off" : s.volume > 0.5 ? "volume_up" : s.volume > 0 ? "volume_down" : "volume_mute";
}

function network(s) {
    if (s.network === "wired")
        return "lan";
    if (s.network === "offline" || !s.network)
        return "wifi_off";
    const strength = s.wifiStrength || 0;
    return strength > 0.75 ? "wifi" : strength > 0.5 ? "network_wifi_3_bar"
        : strength > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
}

function bluetooth(s) {
    return !s.bluetoothOn ? "bluetooth_disabled" : s.bluetoothConnected ? "bluetooth_connected" : "bluetooth";
}

function battery(s) {
    return s.charging ? "battery_charging_full" : "battery_" + Math.min(6, Math.floor((s.battery || 0) * 7)) + "_bar";
}

// The modes on, as icon names: game, power saver, night, presentation,
// focus, do not disturb, coffee.
function modes(s) {
    const m = s.modes || {};
    return [[s.game, "sports_esports"], [m.saver, "eco"], [m.night, "dark_mode"],
            [m.presentation, "co_present"], [m.focus, "center_focus_strong"],
            [s.quiet, "notifications_off"], [s.awake, "coffee"]]
        .filter(pair => pair[0]).map(pair => pair[1]);
}
