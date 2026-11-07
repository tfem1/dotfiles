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
            active_border   = "rgba(cba6f7ff)",
            inactive_border = "rgba(313244ff)",
        },
    },

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
