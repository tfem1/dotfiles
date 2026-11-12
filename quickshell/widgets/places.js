.pragma library
// Where a dragged widget stands, in parts of the free space of the screen
// (0: against the left or top edge, 1: against the right or bottom one), so
// it stays in place on any screen size. Kept to 4 decimals for config.json.

function fraction(x, y, width, height, screenWidth, screenHeight) {
    const part = (value, room) => room > 0 ? Math.round(Math.max(0, Math.min(1, value / room)) * 10000) / 10000 : 0;
    return [part(x, screenWidth - width), part(y, screenHeight - height)];
}

// "0.25,0.6" for `tfem settings set widgets.places.NAME=...`.
function text(place) {
    return place[0] + "," + place[1];
}
