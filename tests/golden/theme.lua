-- Generated from theme.toml: do not edit by hand,
-- change a setting and run the generator again.

hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 6,
        border_size = 0,
        col = {
            active_border   = "rgba(d19fe4ff)",
            inactive_border = "rgba(242b42ff)",
        },
        -- Game mode: fullscreen windows may tear, for less input lag.
        allow_tearing = false,
    },

    -- Game mode: a fullscreen game goes straight to the screen (1), else 0.
    render = { direct_scanout = 0 },

    decoration = {
        rounding = 12,
        shadow   = { enabled = false },
        blur     = {
            enabled = true,
            size    = 8,
            passes  = 2,
        },
    },

    animations = { enabled = true },

    misc = { font_family = "JetBrainsMono Nerd Font" },
})

-- Fullscreen windows (games) tear when allow_tearing is on (game mode).
hl.window_rule({ match = { fullscreen = true }, immediate = true })
