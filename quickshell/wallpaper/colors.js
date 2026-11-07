.pragma library

// Color classes of the wallpaper selector, in toolbar order, and how an
// image gets one: the class that weighs most among its pixels. Vivid pixels
// weigh more than dull ones; grays, blacks and whites go to "gray".

// `var`: read from QML as Colors.CLASSES (a `const` would stay private).
var CLASSES = ["red", "orange", "yellow", "green", "blue", "purple", "pink", "gray"];

// Upper bound of each hue range, in degrees (cyan counts as blue).
const HUES = [[15, "red"], [45, "orange"], [70, "yellow"], [170, "green"], [255, "blue"],
              [290, "purple"], [345, "pink"], [360, "red"]];

function classOf(r, g, b) {
    const max = Math.max(r, g, b), min = Math.min(r, g, b);
    const value = max / 255, saturation = max === 0 ? 0 : (max - min) / max;
    if (saturation < 0.18 || value < 0.12)
        return { name: "gray", weight: 0.25 };
    let hue;
    if (max === r)
        hue = 60 * (((g - b) / (max - min)) % 6);
    else if (max === g)
        hue = 60 * ((b - r) / (max - min) + 2);
    else
        hue = 60 * ((r - g) / (max - min) + 4);
    hue = (hue + 360) % 360;
    return { name: HUES.find(range => hue < range[0])[1], weight: saturation * value };
}

// `data` is RGBA bytes, one pixel after the other.
function dominant(data) {
    const weights = {};
    for (let i = 0; i + 3 < data.length; i += 4) {
        if (data[i + 3] === 0)
            continue;
        const pixel = classOf(data[i], data[i + 1], data[i + 2]);
        weights[pixel.name] = (weights[pixel.name] || 0) + pixel.weight;
    }
    return CLASSES.reduce((best, name) => (weights[name] || 0) > (weights[best] || 0) ? name : best, "gray");
}

// `colors`: the QColor list of a ColorQuantizer (channels from 0 to 1),
// each one standing for an equal share of the image.
function dominantColors(colors) {
    const data = [];
    for (const color of colors)
        data.push(Math.round(color.r * 255), Math.round(color.g * 255), Math.round(color.b * 255), 255);
    return dominant(data);
}
