// Generated from theme.toml ({{ palette.name }}): do not edit by hand,
// change a setting and run the generator again. Included by
// ~/.config/niri/config.kdl; niri reloads it by itself.

layout {
    gaps {{ shape.gaps_out }}
    focus-ring {
        width 2
        active-color "{{ accent | hex }}"
        inactive-color "{{ surface | hex }}"
    }
    border {
        off
    }
}

// Rounded windows, with the theme's radius.
window-rule {
    geometry-corner-radius {{ shape.radius }}
    clip-to-geometry true
}

cursor {
    xcursor-theme "{{ cursor.theme }}"
    xcursor-size {{ cursor.size }}
}
