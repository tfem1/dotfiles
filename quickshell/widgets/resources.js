.pragma library

// Readings for the desktop widgets, from plain text: /proc/stat,
// /proc/meminfo, `df`, `nvidia-smi` and cava. Tested without Quickshell.

// /proc/stat -> { busy, total, cores } (jiffies since boot, summed over
// every core; idle counts iowait too).
function cpuSample(text) {
    const lines = (text || "").split("\n");
    const fields = (lines[0] || "").trim().split(/\s+/);
    if (fields[0] !== "cpu")
        return { busy: 0, total: 0, cores: 0 };
    const values = fields.slice(1, 9).map(Number);   // user .. steal (guest is in user)
    const total = values.reduce((sum, value) => sum + value, 0);
    const idle = (values[3] || 0) + (values[4] || 0);
    return { busy: total - idle, total: total, cores: lines.filter(line => /^cpu\d+\s/.test(line)).length };
}

// Share of time busy between two samples, 0 to 1.
function cpuUsage(before, after) {
    const total = after.total - before.total;
    return total > 0 ? Math.max(0, Math.min(1, (after.busy - before.busy) / total)) : 0;
}

// /proc/meminfo -> { used, total } in bytes (used: what apps can't get back).
function memory(text) {
    const read = name => {
        const match = new RegExp("^" + name + ":\\s+(\\d+)", "m").exec(text || "");
        return match ? Number(match[1]) * 1024 : 0;
    };
    const total = read("MemTotal");
    return { used: Math.max(0, total - read("MemAvailable")), total: total };
}

// `df -P -B1 FOLDER` -> { used, total } in bytes; total = used + available,
// as `df` counts its percentage.
function disk(text) {
    const fields = ((text || "").trim().split("\n")[1] || "").trim().split(/\s+/);
    const used = Number(fields[2]), free = Number(fields[3]);
    return isFinite(used) && isFinite(free) && fields.length >= 4
        ? { used: used, total: used + free } : { used: 0, total: 0 };
}

// `nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total
// --format=csv,noheader,nounits` -> { usage, used, total } (first GPU; MiB).
function nvidia(text) {
    const fields = ((text || "").trim().split("\n")[0] || "").split(",").map(field => Number(field.trim()));
    if (fields.length < 3 || fields.some(value => !isFinite(value)))
        return { usage: 0, used: 0, total: 0 };
    return { usage: fields[0] / 100, used: fields[1] * 1048576, total: fields[2] * 1048576 };
}

// 6.2e9 -> "6.2 GB", 8e9 -> "8 GB", 512e9 -> "512 GB", 2.1e12 -> "2.1 TB".
function size(bytes) {
    const units = ["B", "KB", "MB", "GB", "TB"];
    let value = Math.max(0, bytes || 0), unit = 0;
    while (value >= 1000 && unit < units.length - 1) {
        value /= 1000;
        unit++;
    }
    const shown = value < 10 && unit > 0 ? value.toFixed(1).replace(/\.0$/, "") : Math.round(value);
    return shown + " " + units[unit];
}

// "6.2 / 16 GB": the unit once when both share it.
function usage(used, total) {
    const a = size(used), b = size(total);
    const unitA = a.split(" ")[1], unitB = b.split(" ")[1];
    return (unitA === unitB ? a.split(" ")[0] : a) + " / " + b;
}

// A cava frame ("0;12;100;...;") -> heights 0 to 1, always `count` of them.
function spectrum(line, count) {
    const values = (line || "").split(";").filter(part => part !== "").map(part => Math.max(0, Math.min(1, Number(part) / 100)));
    const result = [];
    for (let i = 0; i < count; i++)
        result.push(isFinite(values[i]) ? values[i] : 0);
    return result;
}

// "Thu, Sep 12" and "13:22" for the clock pill.
function clockParts(date, locale) {
    return {
        date: date.toLocaleDateString(locale || Qt.locale(), "ddd, MMM d"),
        time: date.toLocaleTimeString(locale || Qt.locale(), "HH:mm")
    };
}
