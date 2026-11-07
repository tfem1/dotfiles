# Generated from theme.toml: do not edit by hand,
# change a setting and run the generator again.
# hyprlock exits without this file, so the lock key would do nothing.

general {
    hide_cursor = true
    ignore_empty_input = true
}

animations {
    enabled = {{ effects.animations }}
}

# The wallpaper, blurred; the theme background when no wallpaper is set.
background {
    monitor =
    path = {{ wallpaper.path }}
    color = {{ bg | hypr }}
    blur_passes = {{ effects.blur_passes }}
    blur_size = {{ effects.blur_size }}
}

label {
    monitor =
    text = $TIME
    color = {{ fg_bright | hypr }}
    font_size = 96
    font_family = {{ font.sans }}
    position = 0, 170
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:60000] date +"%A %-d %B"
    color = {{ fg | hypr }}
    font_size = 20
    font_family = {{ font.sans }}
    position = 0, 80
    halign = center
    valign = center
}

input-field {
    monitor =
    size = 320, 56
    outline_thickness = 2
    rounding = {{ shape.radius }}
    dots_size = 0.2
    outer_color = {{ accent | hypr }}
    inner_color = {{ bg_alt | alpha:0.85 | hypr }}
    font_color = {{ fg_bright | hypr }}
    font_family = {{ font.sans }}
    check_color = {{ yellow | hypr }}
    fail_color = {{ red | hypr }}
    capslock_color = {{ orange | hypr }}
    placeholder_text = Password
    fail_text = $FAIL ($ATTEMPTS)
    fade_on_empty = false
    position = 0, -40
    halign = center
    valign = center
}
