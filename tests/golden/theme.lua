-- Fichier généré depuis theme.toml : ne pas le modifier à la main,
-- change plutôt un réglage puis relance la génération.

hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 12,
        border_size = 2,
        col = {
            active_border   = "rgba(cba6f7ff)",
            inactive_border = "rgba(313244ff)",
        },
    },

    decoration = {
        rounding = 12,
        shadow   = { enabled = true },
        blur     = {
            enabled = true,
            size    = 6,
            passes  = 2,
        },
    },

    animations = { enabled = true },
})
