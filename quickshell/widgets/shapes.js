.pragma library
// Organic outlines for the desktop widgets, as polar curves: the radius
// changes softly with the angle, so the edge has no corner anywhere.
// - "cookie": a circle with small scallops all around (9 bumps);
// - "flower": five round petals;
// - "clover": four wide lobes;
// - "circle": a plain circle.

const KINDS = {
    cookie: { lobes: 9, depth: 0.055 },
    flower: { lobes: 5, depth: 0.13 },
    clover: { lobes: 4, depth: 0.1 },
    circle: { lobes: 0, depth: 0 }
};

// Radius at `angle` (radians), as a part of the largest radius (0..1).
function radius(kind, angle) {
    const shape = KINDS[kind] || KINDS.circle;
    // Starts at the top: a lobe points up, so the shape stands upright.
    return 1 - shape.depth + shape.depth * Math.cos(shape.lobes * (angle + Math.PI / 2));
}

// The outline in a w × h box, as [x, y] points (`steps` of them), closed.
function outline(kind, w, h, steps) {
    const points = [];
    const count = steps || 180;
    for (let i = 0; i < count; i++) {
        const angle = i / count * 2 * Math.PI;
        const r = radius(kind, angle);
        points.push([w / 2 + Math.cos(angle) * r * w / 2, h / 2 + Math.sin(angle) * r * h / 2]);
    }
    return points;
}
