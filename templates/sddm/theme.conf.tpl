# Login screen colors and font, from {{ palette.name }} ({{ palette.variant }}).
# Written by `tfem sddm install` next to the theme in /usr/share/sddm/themes,
# then kept up to date by `tfem generate` in the folder of theme.conf.user.
# Wallpaper: {{ wallpaper.path }}
[General]
background={{ sddm.background }}
variant={{ palette.variant }}
bg={{ bg | hex }}
bgAlt={{ bg_alt | hex }}
surface={{ surface | hex }}
muted={{ muted | hex }}
subtle={{ subtle | hex }}
fg={{ fg | hex }}
fgBright={{ fg_bright | hex }}
accent={{ accent | hex }}
accent2={{ accent2 | hex }}
accent3={{ accent3 | hex }}
red={{ red | hex }}
font={{ font.sans }}
radius={{ shape.radius }}
