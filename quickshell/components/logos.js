.pragma library

// The logo of the distro the desktop runs on, drawn in one color (the theme's
// accent) at the left of the bar. Paths from Simple Icons (CC0-1.0, 24x24),
// unchanged; the marks stay their owners'. Arch Linux: shown only on Arch
// itself, monochrome and in its proportions, as its trademark policy asks
// (terms.archlinux.org/docs/trademark-policy). Other systems get the
// Settings gear, since the button opens the Settings window.

const LOGOS = {
    "arch": "M11.39.605C10.376 3.092 9.764 4.72 8.635 7.132c.693.734 1.543 1.589 2.923 2.554-1.484-.61-2.496-1.224-3.252-1.86C6.86 10.842 4.596 15.138 0 23.395c3.612-2.085 6.412-3.37 9.021-3.862a6.61 6.61 0 01-.171-1.547l.003-.115c.058-2.315 1.261-4.095 2.687-3.973 1.426.12 2.534 2.096 2.478 4.409a6.52 6.52 0 01-.146 1.243c2.58.505 5.352 1.787 8.914 3.844-.702-1.293-1.33-2.459-1.929-3.57-.943-.73-1.926-1.682-3.933-2.713 1.38.359 2.367.772 3.137 1.234-6.09-11.334-6.582-12.84-8.67-17.74zM22.898 21.36v-.623h-.234v-.084h.562v.084h-.234v.623h.331v-.707h.142l.167.5.034.107a2.26 2.26 0 01.038-.114l.17-.493H24v.707h-.091v-.593l-.206.593h-.084l-.205-.602v.602h-.091"
};

// The ID line of /etc/os-release ("arch", "fedora"...), "" when absent.
function distroId(osRelease) {
    const match = (osRelease || "").match(/^ID=["']?([^"'\n]*)["']?$/m);
    return match ? match[1].trim().toLowerCase() : "";
}

// "Arch Linux", from PRETTY_NAME (else NAME) of /etc/os-release.
function distroName(osRelease) {
    const text = osRelease || "";
    const match = text.match(/^PRETTY_NAME=["']?([^"'\n]*)["']?$/m) || text.match(/^NAME=["']?([^"'\n]*)["']?$/m);
    return match ? match[1].trim() : "";
}

// True when this system has its own logo here.
function has(id) {
    return Object.prototype.hasOwnProperty.call(LOGOS, id);
}

// An SVG image of the logo in `color`, for an Image source.
function source(id, color) {
    const svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'>"
        + "<path fill='" + color + "' d='" + LOGOS[id] + "'/></svg>";
    return "data:image/svg+xml;utf8," + encodeURIComponent(svg);
}
