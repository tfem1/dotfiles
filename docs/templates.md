# Template format

A template is the file an app expects, with `{{ … }}` tags where values from
`theme.toml` go. Templates live in `templates/` and are listed in
`templates/targets.toml`.

## Tags

```
{{ name }}                    a value
{{ name | filter }}           a value passed through a filter
{{ name | alpha:0.8 | hypr }} filters apply from left to right
```

An unknown variable or filter is an error that names the file and line, with
a suggestion when a close name exists. A literal `{{` is not allowed; write
`{ {` if you really need two braces.

## Variables

| Group | Names | Example |
|---|---|---|
| Raw palette | `base00` … `base0F` (with overrides applied) | `#1e1e2e` |
| Roles | `bg` `bg_alt` `surface` `muted` `subtle` `fg` `fg_bright` | |
| Hues | `red` `orange` `yellow` `green` `cyan` `blue` `purple` `brown` | |
| Accent | `accent` (the hue chosen in `palette.accent`) | |
| Terminal | `ansi0` … `ansi15` | |
| Module colors | `modules.wifi`, `modules.audio`, … | |
| Palette info | `palette.name` `palette.family` `palette.variant` `palette.author` | `"dark"` |
| Settings | every key of `theme.toml` in dotted form | `shape.radius`, `font.sans` |
| Shell settings | every key of `config.json` in dotted form | `shell.name` |

`wallpaper.path` is always absolute (relative paths point into
`~/Pictures/Wallpapers`, where `tfem wallpapers fetch` downloads them).

Roles map to base16 slots: `bg`=00, `bg_alt`=01, `surface`=02, `muted`=03,
`subtle`=04, `fg`=05, `fg_bright`=06, `red`=08, `orange`=09, `yellow`=0A,
`green`=0B, `cyan`=0C, `blue`=0D, `purple`=0E, `brown`=0F. Terminal colors
follow the official tinted-theming mapping.

## Filters

| Filter | Output | Use |
|---|---|---|
| none / `hex` | `#cba6f7` (`#cba6f7cc` if transparent) | CSS, most apps |
| `strip` | `cba6f7` | foot and other ini files |
| `alpha:0.8` | the color with 80 % opacity | combine with another filter |
| `hypr` | `rgba(cba6f7ff)` | Hyprland, hyprlock |
| `argb` | `#cccba6f7` | Qt and QML (alpha comes **first**) |
| `rgb` | `203, 166, 247` | `rgba()` in CSS |
| `json` | `"Inter"`, `"#cba6f7"`, `12`, `true` | JSON files, Lua strings |

Booleans render as `true` / `false`, numbers in their shortest form.

**Trap:** QML reads `#rrggbbaa` as `#aarrggbb`. Keep colors opaque in
`theme.json` and apply opacity in QML, or use `argb`.

## Targets manifest

```toml
[kitty]
template = "terminal/kitty.conf.tpl"           # relative to templates/
output   = "{config}/kitty/palette.conf"       # {config} = $XDG_CONFIG_HOME
needs    = "kitty"                             # skipped if not installed
reload   = "pkill -USR1 -x kitty"              # run only when the file changed
include  = { into = "{config}/kitty/kitty.conf", line = "include palette.conf", create = true }
```

`include` keys: `into` and `line` (required), `comment` (marker prefix,
default `#`), `position` (`end` or `start`), `create` (default `false`: an
app config that does not exist is left alone and you are told which line to
add). The `{shell}` placeholder is the shell name from `config.json`.

## Adding an app

1. Write `templates/<group>/<file>.tpl` using the variables above.
2. Add an entry to `templates/targets.toml`.
3. Run `./tfem generate --dry-run --all --only <name>` and check the diff.
4. Add a golden file test in `tests/test_generate.py`.
