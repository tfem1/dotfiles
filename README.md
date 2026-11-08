# TFEM

Modular Hyprland dotfiles with a complete Quickshell desktop shell, driven by a
single settings file.

> **TFEM is the name of this repository and of its CLI, not the name of your
> desktop.** Nothing on screen carries the TFEM name: no branding in the bar,
> lock screen, launcher or notifications. See [Make it yours](#make-it-yours).

**Status:** early work. Done: theme pipeline, Hyprland config, installer,
wallpaper collection and pony themes. Next: more palettes and app themes, then the Quickshell
shell. The full plan is in [docs/roadmap.md](docs/roadmap.md).

## Install

One command, on Arch, Debian or Fedora and their derivatives:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/tfem1/dotfiles/main/install.sh)
```

It downloads the project to `~/.local/share/tfem`, installs the packages,
backs up every file it is about to replace (in
`~/.local/state/tfem/backups/`), copies the Hyprland config to
`~/.config/hypr`, puts the `tfem` command (and the `dots` and `wm` aliases) in
`~/.local/bin`, downloads the wallpapers and the FairyWren icons, and
generates the theme. It asks before changing anything.

| Option | Effect |
|---|---|
| `--profile minimal` | desktop essentials only, no apps, fonts or wallpapers |
| `--dry-run` | show every step, change nothing |
| `--uninstall` | put your previous config back and remove the links |
| `--yes` | do not ask for confirmation |
| `--no-packages`, `--no-wallpapers`, `--no-icons` | skip that step |

Run the same command again to update. Installed packages are never removed.

### What each distro provides

The Hyprland config is written in Lua, which needs **Hyprland 0.55 or
newer**. Everything not listed below is in the official repositories of all
three families. The installer checks every package first and skips the
missing ones instead of failing.

| Package | Arch | Debian / Ubuntu | Fedora |
|---|---|---|---|
| hyprland | ✅ 0.57 | ✅ Debian testing/unstable (0.57); ❌ Debian 13; ❌ Ubuntu 26.04 (0.53, too old) | ❌ COPR needed |
| hyprlock | ✅ | ✅ Debian unstable, Ubuntu 26.04 | ❌ COPR needed |
| quickshell | ✅ 0.3 | ✅ 0.3 (Debian 13 via backports) | ⚠️ 0.2 snapshot |
| satty (screenshot editor) | ✅ | ❌ (screenshots are saved unedited) | ❌ (same) |
| cliphist | ✅ | ✅ | ✅ Fedora 44 |

On Fedora, the installer does not add third-party repositories by itself:
enable a COPR you trust (for example `sudo dnf copr enable sdegler/hyprland`)
and run it again. Versions checked on Repology on 2026-11-07.

### Icons

The icon theme is [FairyWren](https://gitlab.com/FreshDoctor/FairyWren-Icons)
(GPL-3.0, Breeze parts LGPL-2.1), based on Papirus and Breeze. Like the
wallpapers it is not stored in this repository: `tfem icons fetch` downloads
only its two themes (about 160 MB) into `~/.local/share/icons`, and the
installer runs it for you. Papirus is installed too, as FairyWren falls back
on it for the icons it does not draw.

- **Dark or light** follows the palette: `FairyWren_Dark` for dark themes,
  `FairyWren_Light` for light ones (Celestia, Fluttershy, Fern).
- **Folders** take FairyWren's color that looks closest to the accent:
  violet for Twilight, pink for Pinkie, indigo for Luna, cyan for Rainbow,
  green or pine for the forests. Pick one yourself with `folders` (blue,
  cyan, green, indigo, magenta, pink, pine, red, teal, violet, yellow, ...).

```toml
[icons]
theme   = "FairyWren"   # or any installed icon theme, e.g. "Papirus-Dark"
folders = "theme"       # or "pink", "pine", ...
```

`tfem generate` applies it: GTK (gsettings), Qt (qt5ct, qt6ct) and the shell
(launcher, running apps).

### Wallpapers

`wallpapers/collection.toml` lists 101 wallpapers from
[wallhaven.cc](https://wallhaven.cc): 51 My Little Pony and 50 forests (19 of
them picked for their green: moss, canopy, paths, streams), SFW,
at most 10 MB each, picked by hand. They are downloaded to
`~/Pictures/Wallpapers/pony/` and `~/Pictures/Wallpapers/forest/` (about
290 MB) and never stored in this repository: the images remain the property
of their authors. Download or complete them at any time with
`tfem wallpapers fetch`.

Pick one with `SUPER + W` (see [Shell](#shell)) or `tfem wallpapers set
IMAGE`: the choice is saved in your `theme.toml`, and the desktop and the
lock screen follow. `tfem wallpapers list` shows what is in the folder; any
image you add there (jpg, png, webp) shows up in the selector.

**Wallpaper = character.** A pony wallpaper that shows one character with
a theme brings that theme: pick a Luna wallpaper and the whole desktop
(shell, terminal, GTK, Qt, lock screen) turns Luna. A forest wallpaper
brings the green `forest_theme` (Pine by default). Group pictures and your
own images keep the current theme. The selector shows the theme a wallpaper
brings, and searching a name ("luna") finds that character's wallpapers.

```toml
[wallpaper]
follow = true                   # false: a wallpaper never changes the theme
forest_theme = "forest-pine"    # or forest-moss, kanagawa, everforest-dark-hard…
```

## Themes

Ten themes in the colors of My Little Pony characters, mostly pink, purple
and blue. **Twilight** is the default.

| Theme | Look |
|---|---|
| `pony-twilight` | navy night, lavender text, magenta touches |
| `pony-pinkie` | dark raspberry, hot pink accent |
| `pony-rarity` | deep purple, white text |
| `pony-cadance` | plum, magenta accent, gold |
| `pony-starlight` | violet, teal touches |
| `pony-luna` | indigo night, royal blue accent |
| `pony-trixie` | midnight blue, silver text, sky blue accent |
| `pony-rainbow` | dark sky, the full rainbow |
| `pony-fluttershy` | light: cream and pink |
| `pony-celestia` | light: white and pastel pink |

Pick one in `~/.config/tfem/theme.toml`:

```toml
[palette]
source = "pony-pinkie"
```

Each theme comes with its signature color, used as the accent
(`accent = "theme"`, the default). The themes are not written by hand:
`themes/seeds/pony.toml` holds the canon colors of each character (from the
My Little Pony Friendship is Magic Wiki), and
`PYTHONPATH=scripts python3 -m theming.builder themes/seeds/pony.toml` turns
them into full base16 themes, adjusting lightness until every color is
readable (WCAG contrast 7:1 for text, 4.5:1 for colors) and checking that
each hue stays in its place. My Little Pony is a trademark of Hasbro; these
are fan color schemes, with no artwork.

**Minimal colors:** a theme shows at most three colors, all its own. The
accent (workspaces, clock), a second color of the same family (every status
icon and the panels) and a third one used sparingly (the now-playing ring):
greens only for the forest themes, the character's colors for a pony theme
(Pinkie: her pink, a softer pink, the blue of her eyes). Red is kept for
alerts only. Change it per module in `[modules]` of `theme.toml` if you want
more color (`wifi = "blue"`, for instance).

Six **green** themes, with a green accent, to go with the forest wallpapers:

| Theme | Look |
|---|---|
| `kanagawa` | ink night, autumn green (official Kanagawa palette) |
| `kanagawa-dragon` | warm black, sage green (official palette) |
| `everforest-dark-hard` | dark forest grey, soft green (official palette) |
| `forest-pine` | deep pine, young-leaf green, lichen teal |
| `forest-moss` | olive moss, fresh green, sunlight yellow |
| `forest-fern` | light: pale fern, dark pine text |

The first three come unchanged from
[tinted-theming/schemes](https://github.com/tinted-theming/schemes) (MIT);
the `forest-*` ones are original, built like the pony themes from
`themes/seeds/forest.toml`. Every theme is checked: each hue in its slot,
text readable.

## How theming works

One file, `theme.toml`, describes the look of the whole desktop: palette,
accent, fonts, corners, gaps, blur, cursor, and the color of each shell module.
`tfem generate` turns it into the configuration files each app expects, in
their usual places:

```
theme.toml ──► validate ──► palette (base16) ──► templates ──► ~/.config/hypr/theme.lua
themes/*.toml ─────────────────┘                             ~/.config/hypr/hyprlock.conf
                                                             ~/.config/quickshell/<shell>/theme.json
                                                             ~/.config/kitty/theme.conf
                                                             ~/.config/gtk-3.0/theme.css, gtk-4.0/theme.css
                                                             ~/.config/qt5ct/…, ~/.config/qt6ct/…
```

- Palettes use the [base16](https://github.com/tinted-theming/home) format, so
  curated themes and palettes extracted from a wallpaper look the same to every
  template.
- Generated files never replace your own configs. When an app needs a line to
  load the generated file (for example `require("theme")` in `hyprland.lua`),
  that single line is added between clearly marked comments. Anything that
  would be overwritten is backed up first, in `~/.local/state/tfem/backups/`.
- Invalid settings are rejected with a clear message before anything is
  written.
- The terminal follows too: change the theme and the shell, the bar and
  every open kitty window take the new colors together. kitty loads them
  with one `include theme.conf` line at the end of your `kitty.conf`; move
  that block up if you want your own colors to win.
- Apps follow as well:
  - **GTK 4 / libadwaita** (Files, GNOME apps): `~/.config/gtk-4.0/theme.css`,
    loaded by one `@import` line at the top of your `gtk.css`.
  - **GTK 3**: the same in `~/.config/gtk-3.0/`, read by the adw-gtk3 theme
    (installed on Arch and Fedora; Debian does not package it, so GTK 3 apps
    keep the default look there).
  - **Qt 5 and Qt 6** (VLC, qBittorrent, KDE apps): a palette for qt5ct and
    qt6ct (`QT_QPA_PLATFORMTHEME=qt5ct` is set by the Hyprland config).
  - `gsettings` gets the GTK theme, dark or light style, icons and cursor,
    so open GTK apps change at once; Qt apps take the colors when they start.
  - Firefox draws its own colors: to have it follow GTK, set
    `widget.gtk.libadwaita-colors.enabled` to `false` in `about:config`.

Details: [docs/architecture.md](docs/architecture.md) and the template format
in [docs/templates.md](docs/templates.md).

## Try it

Requirements for this step: `bash` and Python 3.11 or newer.

```bash
./tfem generate --dry-run --all   # show what would be written
./tfem generate                   # write files for the apps you have installed
```

Your personal settings go in `~/.config/tfem/theme.toml` and
`~/.config/tfem/config.json`. Only the keys you write there replace the
defaults, for example:

```toml
[palette]
accent = "green"

[shape]
radius = 8
```

Run the tests with:

```bash
PYTHONPATH=scripts:tests python3 -m unittest discover -s tests
```

With Quickshell (`qs`) and sway installed, `tests/test_shell_runtime.py` also
runs the real shell in a headless sway session (software rendering, no GPU):
it fails if the shell does not load or if opening any panel logs an error in
its code. Without them it is skipped. With Hyprland installed,
`tests/test_hypr_verify.py` checks the config with `Hyprland --verify-config`
(run the tests as your user: Hyprland refuses root).

Checked on 2026-11-08 with the versions Arch Linux ships: Hyprland 0.57.1
(`config ok`) and Quickshell 0.3.2 (the shell loads, every panel opens).

## Hyprland config

`hypr/` is a complete Hyprland configuration in Lua (Hyprland 0.55 or newer),
split into small modules: variables, monitors, settings, animations,
autostart and keybinds. Every shortcut has a description; the full list is in
[docs/roadmap.md](docs/roadmap.md#3-quickshell-shell-bar-osd-launcher-notifications)
and in `hypr/config/keybinds.lua`.

- Every screen runs at its highest refresh rate, including screens plugged
  in later.
- Apps, modifier key and keyboard layout are set in
  `hypr/config/variables.lua`.
- Colors, gaps, corners and blur come from `theme.toml` through the generated
  `theme.lua`.

The installer copies it to `~/.config/hypr`. `SUPER + /` shows every
shortcut on screen. The tests load the config in a fake Hyprland API and check
every key: the dispatcher exists, the program it runs is installed by the
installer, and the shell panel it opens exists. The keys of the panels still to
build (settings) does nothing yet.

- **Lock screen** (`SUPER + L`): hyprlock, with a config generated from
  `theme.toml` (`~/.config/hypr/hyprlock.conf`): hyprlock does not lock without
  one.

## Shell

`quickshell/` is the desktop shell, one Quickshell process started with
Hyprland. The installer copies it to `~/.config/quickshell/desktop/` (the
folder name is `shell.name` in your `config.json`). Its colors follow
`theme.toml` live: run `tfem generate` and the shell recolors itself.

- **Bar** (look of illogical-impulse): in the center now playing with a progress ring (click to play or pause), the
  workspaces 1 to 10 in a notch (click to switch), the clock and date; on the
  right the keyboard layout, sound, network, Bluetooth and battery, each in
  its module color.
- **Running apps** (top left of the bar): one icon per running app, the
  ones with a window (Discord, OBS, Roblox, your terminal…) and the ones
  closed to the tray. A mark under an app with a window, longer for the
  focused one. Click: bring it forward (again: its next window). Right
  click: a menu in the theme colors with the app's own tray entries (Mute,
  Deafen…) and **Quit**. Quit uses the app's own quit entry when it has
  one, else asks its process to stop (SIGTERM, the same polite request as
  its own Quit), so it can save first. The shell itself is never listed.
- **OSD** under the bar for the volume and the brightness.
- **Notifications**: the shell is the notification daemon; popups in the
  top-right corner, urgent ones stay until closed.
- **Wallpaper**: drawn by the shell itself, under the windows (no other
  program needed); a new one fades in.
- **Launcher** (`SUPER + D`): search and open apps. Every word typed is
  looked for in the name, description, keywords and command, so `nautilus`
  finds Files. Terminal apps (btop, nvim…) open in your terminal
  (`terminal` in `hypr/config/variables.lua`).
- **Network panel** (`SUPER + N`, or a click on the status icons of the
  bar): quick toggles for Wi-Fi, Bluetooth and airplane mode, then two tabs.
  *Wi-Fi*: every network with its signal, lock and "Saved" mark, connected
  one first; the password is typed right under the network, a wrong one is
  said so; disconnect, forget, rescan; cable connection and "no internet"
  warning. *Bluetooth*: your devices with their type icon and battery,
  connect or disconnect in one click, forget; devices nearby to pair (they
  are then trusted and connected); "visible to other devices". Colors are
  the Wi-Fi and Bluetooth module colors of the theme. Devices that ask for
  a pairing code are not supported yet (pair them once with `bluetoothctl`).
- **System panel** (`SUPER + B`), on the right: Wi-Fi, Bluetooth,
  airplane, **Quiet** (do not disturb: no popups except urgent ones, a bell
  shows in the bar) and **Stay awake** (no dimming, lock or sleep, a cup
  shows in the bar); volume and brightness; the last 50 notifications, to
  dismiss one by one or all at once. Quiet and stay awake survive a
  restart of the shell.
- **Idle** (hypridle, `hypr/hypridle.conf`): dim after 5 min, lock after
  10, screen off after 11, suspend after 30; locked before any suspend.
- **Power menu** (`SUPER + Escape`, or the power button at the right end
  of the bar): lock, log out, suspend (locks first), restart, shut down,
  with the time since start-up. Log out, restart and shut down ask for a
  second click; arrows and Enter or one letter (L, E, S, R, P) work too.
- **Music** (`SUPER + M`): the album sleeve with its record sliding out,
  turning while the music plays; title, artist, album; progress you can
  click to move in the song; previous, play/pause, next, shuffle, repeat;
  the choice of player when several are open (Spotify, Firefox…); and the
  lyrics on request, synced with the song (from lrclib.net, asked only when
  you open the lyrics: title, artist, album and length are sent).
- **Volume panel** (`SUPER + V`): output volume and mute, choice of output
  (speakers, headphones, HDMI), microphone and its choice, then one slider
  per app playing sound, with its icon and what it plays. Click, drag or
  scroll; click an icon to mute. On PipeWire through Quickshell.
- **Calendar** (`SUPER + S`, or a click on the clock): time and date, the
  month in your language with week numbers, today circled; arrows or the
  wheel change month, "Today" comes back.
- **Wallpaper selector** (`SUPER + W`): slanted cards in a carousel, or a
  grid; filters by color (each image's main color is found once, in the
  background, then remembered), recent picks, random pick and search. Left
  and right arrows browse (also while searching), Enter applies, typing
  searches. It never changes the wallpaper on its own.
- **Clipboard history** (`SUPER + C`): what you copied (kept by cliphist),
  searchable; Enter copies it again.
- **Keybind cheatsheet** (`SUPER + /`): read from Hyprland itself, so your own
  binds show up too.
- **Bar autohide** (`SUPER + A`): windows get the whole screen, the bar comes
  down when the pointer touches the top edge.

Still to come: the sidebars, the dock, the Mono style, the settings window and
the panels opened by the other keys.

To see it without a Wayland session (it renders the shell's own QML files with
sample data):

```bash
pip install PySide6-Essentials
```
```bash
python3 tools/preview/render.py --theme pony-pinkie --wallpaper your-image.png --out preview/
```

## Repository layout

```
theme.toml            default look of the desktop (the single source of truth)
config.json           default shell behaviour (shell name, and more later)
tfem                  CLI
hypr/                 Hyprland config in Lua (copied to ~/.config/hypr/)
quickshell/           the shell: wallpaper, bar, OSD, notifications, panels
install.sh, install/   one-command installer and its package table
wallpapers/           wallpaper collection (list only, images are downloaded)
themes/               base16 palettes, one file per theme
templates/            one template per generated file + targets.toml manifest
scripts/generate.sh   entry point of the generator
scripts/screenshot.sh screenshots (region or full screen, optional editing)
scripts/wallpapers.py wallpapers: download, list, set (with the theme they bring)
scripts/wallpaper_collection.py  the collection and the theme of each wallpaper
scripts/theming/      generator: settings, palette, template engine, safe writer
tools/                icon generator, preview renderer
tests/                unit and end-to-end tests, golden files
licenses/             licenses of bundled third-party material
docs/                 architecture, template format, roadmap
```

## Make it yours

- **Shell name:** the Quickshell config lives in
  `~/.config/quickshell/<name>/`. Set `shell.name` in your `config.json`
  (default `desktop`).
- **Colors:** pick any theme with `palette.source`, an accent with
  `palette.accent` (`theme` keeps the theme's signature color), and change
  single colors with `[palette.overrides]`.
- **Your own themes:** drop a base16 theme file in `~/.config/tfem/themes/`. It
  takes precedence over the bundled one with the same name.
- **CLI name:** prefer `dots` or `wm`? Link to the same script; its help uses
  whatever name you called it with:
  `ln -s "$PWD/tfem" ~/.local/bin/dots`

More renaming options (displayed name, avatar, hostname) arrive with the
Settings window.

## Credits and inspiration

- **[Serpantinum](https://github.com/ilyamiro/serpantinum)** (AGPL-3.0) shaped
  the architecture: a single Quickshell shell kept apart from the compositor
  config, one settings file applied live, palettes from presets or from the
  wallpaper with per-color overrides, and app theming that writes a separate
  theme file plus one marked include line instead of overwriting configs.
  Only ideas were reused: TFEM is an original implementation and contains no
  Serpantinum code.
- **[FairyWren](https://gitlab.com/FreshDoctor/FairyWren-Icons)** (Isaiah M,
  GPL-3.0 and LGPL-2.1): the icon theme, downloaded on your machine, never
  copied into this repository; the folder color is set through its own
  `places/colours/default` link, as its `colours.sh` does.
- **[Material Symbols](https://github.com/google/material-design-icons)**
  (Google, Apache-2.0, see `licenses/Apache-2.0.txt`): the shell's icons,
  extracted by `tools/fetch_icons.py`.
- **[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)**
  (illogical-impulse): the look of the bar, rebuilt with original code.
- **[tinted-theming](https://github.com/tinted-theming/schemes)** (MIT) for
  the base16 palettes and the standard terminal color mapping.
- Visual references for the upcoming shell and login screens are listed in
  [docs/roadmap.md](docs/roadmap.md).

## License

[GPL-3.0](LICENSE).
