.pragma library

// Small helpers of the volume panel: icons and labels.

function volumeIcon(volume, muted) {
    if (muted || volume <= 0)
        return "volume_off";
    return volume > 0.5 ? "volume_up" : "volume_down";
}

// Device names come from PipeWire ("HDMI / DisplayPort", "Headphones",
// "bluez_output.…"): the icon is guessed from them.
function deviceIcon(name, input) {
    const text = (name || "").toLowerCase();
    if (input)
        return "mic";
    if (text.includes("hdmi") || text.includes("displayport"))
        return "tv";
    if (["headphone", "headset", "bluez", "bluetooth", "buds", "airpods"].some(word => text.includes(word)))
        return "headphones";
    return "speaker";
}

function percent(volume) {
    return Math.round(volume * 100) + "%";
}
