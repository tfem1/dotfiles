-- Generated from theme.toml: do not edit by hand,
-- change a setting and run the generator again.

hl.env("XCURSOR_THEME", {{ cursor.theme | json }})
hl.env("XCURSOR_SIZE", "{{ cursor.size }}")
hl.env("HYPRCURSOR_SIZE", "{{ cursor.size }}")

hl.config({
    general = {
        gaps_in     = {{ shape.gaps_in }},
        gaps_out    = {{ shape.gaps_out }},
        border_size = {{ shape.border }},
        col = {
            active_border   = "{{ accent | hypr }}",
            inactive_border = "{{ surface | hypr }}",
        },
        -- Game mode: fullscreen windows may tear, for less input lag.
        allow_tearing = {{ game.tearing }},
    },

    -- Game mode: a fullscreen game goes straight to the screen (1), else 0.
    render = { direct_scanout = {{ game.direct_scanout }} },

    decoration = {
        rounding = {{ shape.radius }},
        shadow   = { enabled = {{ effects.shadow }} },
        blur     = {
            enabled = {{ effects.blur }},
            size    = {{ effects.blur_size }},
            passes  = {{ effects.blur_passes }},
        },
    },

    animations = { enabled = {{ effects.animations }} },

    misc = { font_family = {{ font.mono | json }} },
})

-- Fullscreen windows (games) tear when allow_tearing is on (game mode).
hl.window_rule({ match = { fullscreen = true }, immediate = true })
