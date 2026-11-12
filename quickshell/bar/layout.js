.pragma library

// The bar's layout (config.json bar.layout): three zones, start | center | end
// (left, middle, right; top, middle, bottom on a vertical bar), each a list
// of modules: "logo|media,workspaces,clock|status,power". A module left out
// is hidden; unknown names are skipped, a module named twice shows once.

const MODULES = ["logo", "media", "workspaces", "clock", "status", "power"];
const ZONES = ["start", "center", "end"];
const DEFAULT = "logo|media,workspaces,clock|status,power";
const LABELS = {
    logo: "Distro logo", media: "Music", workspaces: "Workspaces", clock: "Clock",
    status: "Status icons", power: "Power button"
};

function parse(text) {
    const parts = String(text || DEFAULT).split("|");
    const seen = {};
    const result = {};
    ZONES.forEach((zone, index) => {
        result[zone] = (parts[index] || "").split(",").map(name => name.trim())
            .filter(name => MODULES.indexOf(name) >= 0 && !seen[name] && (seen[name] = true));
    });
    result.hidden = MODULES.filter(name => !seen[name]);
    return result;
}

function text(layout) {
    return ZONES.map(zone => layout[zone].join(",")).join("|");
}

// `name` taken from where it is and put in `zone` ("hidden" too) at `index`.
function move(layout, name, zone, index) {
    const result = {};
    ZONES.concat(["hidden"]).forEach(key => result[key] = layout[key].filter(other => other !== name));
    const list = result[zone];
    list.splice(Math.max(0, Math.min(index, list.length)), 0, name);
    return result;
}
