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
            active_border   = "rgba(8fd18cff)",
            inactive_border = "rgba(264036ff)",
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
            -- Right-click menus too, only where they are drawn.
            popups  = true,
            popups_ignorealpha = 0.48,
        },
    },

    animations = { enabled = true },

    misc = { font_family = "Monocraft" },
})

-- The shell's panels (bar, launcher, Wi-Fi, settings...) are blurred behind,
-- but only where they are drawn: ignore_alpha leaves out their rounded
-- corners and the light dimming around them (0.45 at most, panels are 0.5 or
-- more), so no blurred rectangle shows.
hl.layer_rule({ match = { namespace = "^shell-.*" }, blur = true, ignore_alpha = 0.48 })

-- Fullscreen windows (games) tear when allow_tearing is on (game mode).
hl.window_rule({ match = { fullscreen = true }, immediate = true })
