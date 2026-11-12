// Generated from theme.toml ({{ palette.name }}): do not edit by hand,
// change a setting and run the generator again. The keys, frames and logo
// take the theme's colors. Layout from github.com/harilvfs/fastfetch
// (old-days branch), with the theme's colors instead of fixed ones.
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "type": "builtin",
        "height": 15,
        "width": 30,
        "padding": {
            "top": 5,
            "left": 3
        },
        "color": {
            "1": "{{ accent | sgr }}",
            "2": "{{ accent2 | sgr }}"
        }
    },
    "modules": [
        "break",
        {
            "type": "custom",
            "format": "\u001b[{{ subtle | sgr }}m┌──────────────────────Hardware──────────────────────┐"
        },
        {
            "type": "host",
            "key": "󰌢  PC",
            "keyColor": "{{ accent | sgr }}"
        },
        {
            "type": "cpu",
            "key": "│ ├󰻠 ",
            "keyColor": "{{ accent | sgr }}"
        },
        {
            "type": "gpu",
            "key": "│ ├󰍹 ",
            "keyColor": "{{ accent | sgr }}"
        },
        {
            "type": "memory",
            "key": "│ ├󰑭 ",
            "keyColor": "{{ accent | sgr }}"
        },
        {
            "type": "disk",
            "key": "└ └󰋊 ",
            "keyColor": "{{ accent | sgr }}"
        },
        {
            "type": "custom",
            "format": "\u001b[{{ subtle | sgr }}m└────────────────────────────────────────────────────┘"
        },
        "break",
        {
            "type": "custom",
            "format": "\u001b[{{ subtle | sgr }}m┌──────────────────────Software──────────────────────┐"
        },
        {
            "type": "os",
            "key": "  OS",
            "keyColor": "{{ accent2 | sgr }}"
        },
        {
            "type": "kernel",
            "key": "│ ├󰌽 ",
            "keyColor": "{{ accent2 | sgr }}"
        },
        {
            "type": "bios",
            "key": "│ ├󰖡 ",
            "keyColor": "{{ accent2 | sgr }}"
        },
        {
            "type": "packages",
            "key": "│ ├󰏗 ",
            "keyColor": "{{ accent2 | sgr }}"
        },
        {
            "type": "shell",
            "key": "└ └󰞷 ",
            "keyColor": "{{ accent2 | sgr }}"
        },
        "break",
        {
            "type": "de",
            "key": "󰧨  DE",
            "keyColor": "{{ accent3 | sgr }}"
        },
        {
            "type": "lm",
            "key": "│ ├󰍁 ",
            "keyColor": "{{ accent3 | sgr }}"
        },
        {
            "type": "wm",
            "key": "│ ├󱂬 ",
            "keyColor": "{{ accent3 | sgr }}"
        },
        {
            "type": "wmtheme",
            "key": "│ ├󰉦 ",
            "keyColor": "{{ accent3 | sgr }}"
        },
        {
            "type": "terminal",
            "key": "└ └󰆍 ",
            "keyColor": "{{ accent3 | sgr }}"
        },
        {
            "type": "custom",
            "format": "\u001b[{{ subtle | sgr }}m└────────────────────────────────────────────────────┘"
        },
        "break",
        {
            "type": "custom",
            "format": "\u001b[{{ subtle | sgr }}m┌────────────────────Uptime / Age / DT────────────────────┐"
        },
        {
            "type": "command",
            "key": "  ›  OS Age  ",
            "keyColor": "{{ accent | sgr }}",
            "text": "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days"
        },
        {
            "type": "uptime",
            "key": "  ›  Uptime  ",
            "keyColor": "{{ accent | sgr }}"
        },
        {
            "type": "datetime",
            "key": "  ›  DateTime  ",
            "keyColor": "{{ accent | sgr }}"
        },
        {
            "type": "custom",
            "format": "\u001b[{{ subtle | sgr }}m└─────────────────────────────────────────────────────────┘"
        },
        {
            "type": "colors",
            "paddingLeft": 2,
            "symbol": "circle"
        }
    ],
    "display": {
        "color": {
            "keys": "{{ accent | sgr }}",
            "title": "{{ accent | sgr }}",
            "output": "{{ fg | sgr }}"
        },
        "separator": " "
    }
}
