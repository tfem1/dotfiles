# Roadmap

Each step is planned, approved, implemented, then reviewed before the next one.
Themes come before the shell, so the shell is built with the final palettes.

## Design rules

- **No gradients, anywhere.** Window borders, buttons, sliders, panels,
  backgrounds and login screens use solid colors only.
- Colors always come from the active palette: a hue name, never a fixed hex.
- **Lightweight:**
  - one Quickshell process hosts the whole shell; nothing else stays
    resident (no Waybar, no separate notification daemon, no applets, no
    polling scripts);
  - Python only runs while generating files, never in the background;
  - hidden parts are not loaded (`Loader` with `active: false`), no
    QtWebEngine;
  - system data comes from Quickshell's services and events, not from
    polling commands;
  - wallpaper thumbnails are cached at a small size;
  - the `minimal` install profile only installs the core.

## Next, in the order chosen on 2026-11-07

1. **Terminal and apps follow the theme:** done for kitty (open windows
   included), GTK 3, GTK 4 / libadwaita and Qt 5 / Qt 6.
2. **Done:** volume panel (`SUPER + V`) and calendar (`SUPER + S`).
3. **Done:** music panel (`SUPER + M`) with turning record and lyrics.
4. **Done:** power menu (lock, log out, suspend, reboot, shut down).
5. **Done:** notification center (history), do not disturb and stay awake,
   in the system panel (`SUPER + B`), with hypridle.
6. **Done:** wallpaper = character (pony wallpapers), forest wallpapers =
   green theme.
7. Settings window (`SUPER + H`).
8. Optional dock.
9. Fastfetch in the theme colors, matching cursor and icons. **Icons
   done:** FairyWren, dark or light, folders in the accent's color.
10. Custom lock screen and the two SDDM themes. **SDDM themes done**
    (`tfem sddm install`).

## 1. Theme pipeline — done

`theme.toml`, `config.json`, base16 theme format, template engine, Hyprland
(Lua) and Quickshell templates, safe writer, `tfem generate`, tests.

## 2. Palettes and app themes — next

- **Done: pony themes.** Ten themes in the colors of My Little Pony
  characters, mostly pink, purple and blue, built from canon colors by
  `theming.builder` (readable by construction, hue-checked). Twilight is the
  default theme and each theme brings its signature color as accent.

- Import the base16 collection of
  [tinted-theming/schemes](https://github.com/tinted-theming/schemes) (MIT,
  362 themes) with a reproducible script, one file per theme, author kept.
- **Hue check in the importer.** base16 slots are syntax-highlighting roles,
  not guaranteed hues: tinted's Tokyo Night puts a pale blue (`#C0CAF5`) in
  the "red" slot and a cyan (`#0DB9D7`) in the "yellow" slot. The importer
  measures the hue of each slot and fixes or flags such themes, so `red`
  always looks red in the UI (urgent notifications, low battery).
  - Rule, measured on the 361 schemes: each slot's hue is classified on the
    color wheel (red, orange, yellow, green, cyan, blue, purple) and must land
    on its own hue or a neighbouring one. Fixed hue ranges were too strict
    (251 failures, e.g. Gruvbox's teal-ish "blue" is a deliberate choice);
    the neighbour rule flags 98, all genuine mismatches (Tokyo Night, Rosé
    Pine, Tokyo City, Gruvbox Dark Medium Forest…).
  - Flagged themes are remapped when another slot has the right hue (19
    cases), otherwise hidden from the default list and marked with a warning.
  - *Tokyo Night* and *Rosé Pine* (one of the five palettes of the original
    plan) are rebuilt from their official palettes.
- **Featured themes**, shown first in the theme picker:
  - *Kanagawa* (and Kanagawa Dragon): dark night background, **green** accent
    and green-leaning module colors. **Done**, with Everforest Dark Hard and
    three original forest themes (Pine, Moss, Fern). Darkmoss, Gruvbox
    Forest and Everforest Dark Medium were left out: hue in the wrong slot
    or text too pale.
  - More green themes found by the hue check.
  - *Tokyo Night* (Night, Storm, Moon): **night blue** accent with some
    **purple** modules, built from the official Tokyo Night palette so its
    blue and purple are the real ones.
- Each theme can suggest an accent and module colors, applied when you pick
  it; you can still change them afterwards.
- Terminal themes (foot, kitty, alacritty, ghostty, wezterm), GTK and Qt,
  never overwriting existing configs. **Done: kitty** (`kitty/theme.conf`,
  loaded by one include line, reloaded live), **GTK 3 / GTK 4** (`theme.css`
  + `@import`, gsettings) and **Qt** (qt5ct / qt6ct palettes).
- `tfem theme <name>`.
- **Fastfetch in the theme colors**, with an original logo (no official
  artwork).
- **Matching cursor and icons** (pink or purple variants), from what each
  distro packages; checked per distro before being added to the installer.

## 3. Quickshell shell: bar, OSD, launcher, notifications

- **Done:** bar (Material style) with autohide, OSD, notifications, launcher,
  clipboard history, keybind cheatsheet, wallpaper selector, network panel
  (Wi-Fi and Bluetooth), volume panel, calendar, music panel, IPC for the
  keybinds, deployed by the installer. **Next:** the panels of `SUPER + B/H`,
  sidebars, dock, Mono style, do not disturb.

- A single `shell.qml` that only composes; every hidden part in a `Loader`.
- Colors read live from the generated `theme.json` (`FileView` + `JsonAdapter`).
- **Two visual styles, switchable in Settings** (`shell.style` in
  `config.json`), sharing the same components where possible:
  - *Material* (**default, main target**): the look of end-4's
    illogical-impulse from its AGS era (late 2023), as preserved in
    [tibssy/hyprland-dotfiles](https://github.com/tibssy/hyprland-dotfiles)
    (GPL-3.0, like this project). Details below.
  - *Mono*: top bar with grouped pills, monospace font, large pixel clock on
    the desktop, compact control panel with avatar, uptime, 2×2 tiles and wide
    sliders. Reference: [aelyx-shell](https://github.com/xZepyx/aelyx-shell).
  - Both are rebuilt in Quickshell: the reference runs on AGS v1 and ships a
    hyprlang `.conf` that Hyprland 0.57 no longer reads, so it cannot be used
    as is. No gradients, whatever the references do.
- **Material style, element by element:**
  - *Bar* (replaces Waybar, as planned): full width at the top. Center, side
    by side: now playing (cover, title, artist, progress), the workspaces
    (numbered circles, occupied ones highlighted) in a "notch" rounded at the
    bottom, then the clock with the date. Left area (**done**): the running
    apps, windows and tray icons together, click to focus, right click for
    a themed menu with the app's tray entries and Quit. Right area: keyboard
    layout, network, Bluetooth, battery, opens the right sidebar.
  - *Right sidebar*: large time and uptime, power and settings buttons, a row
    of quick toggle pills, grouped notifications with "Clear", a calendar with
    Calendar and To-do tabs.
  - *Left sidebar*: media card (cover, controls, progress), an anime image
    panel and a quote widget. The image panel is **SFW only**: NSFW sources and
    tags are never exposed.
  - *Desktop*: large clock and date in a corner, credit of the current
    wallpaper ("Illustration by …", from the wallpaper collection data),
    rounded screen corners.
  - *Overview*: open windows per workspace, with app search, calculator and
    command runner; it doubles as the launcher.
  - *Session menu* (lock, log out, suspend, reboot, shut down) and an optional
    on-screen keyboard.
  - Colors from the wallpaper by default (Material You), curated themes still
    available.
- **Optional dock**: `dock.enabled` in `config.json`, styled to match: a
  rounded dark bar of app icons (pinned and running), a small dot under each
  running app.
- **Do not disturb**: notifications are kept but not shown.
- **Hyprland base config** (done, in `hypr/`) in Lua, split into small modules (variables, env,
  monitors, autostart, settings, animations, keybinds), never overwriting an
  existing user config. Same behaviour as the user's reference config
  (Serpantinum's), written from scratch:
  - general: floating windows keep 6 px gaps, resize by dragging borders with
    a 30 px grab area; colors, gaps (4 / 6 px), no border, 12 px corners and
    blur (size 8, 2 passes, no shadow) come from `theme.toml`;
  - input: keyboard layout and layout switch (`alt + shift`) configurable,
    flat mouse acceleration, natural scrolling on the touchpad, typing does
    not disable it; 3-finger horizontal swipe to change workspace;
  - misc: no Hyprland logo or splash, apps cannot steal focus;
  - animations: one snappy curve (bezier 0.05, 0.9, 0.1, 1.05), windows pop
    in at 80 %, layers fade, workspaces slide;
  - autostart: clipboard history (text and images) and the shell;
  - monitors: one rule for every screen, see step 8 for the refresh rate.
- **Keybinds: the same layout as
  [Serpantinum](https://github.com/ilyamiro/serpantinum)** (key choices only;
  the Lua file is written from scratch), plus `SUPER + /` for the cheatsheet:

  | Keys | Action |
  |---|---|
  | `SUPER + Return` / `F` / `E` | terminal / browser / file manager |
  | `SUPER + Q` | close window |
  | `SUPER + ALT + F` / `SUPER + SHIFT + F` | maximize / float |
  | `SUPER + arrows` | move focus |
  | `SUPER + CTRL + arrows` | move window |
  | `SUPER + SHIFT + arrows` | resize window |
  | `SUPER + left / right mouse` | drag / resize window |
  | `SUPER + 1…0` / `SUPER + SHIFT + 1…0` | go to / send to workspace 1–10 |
  | `SUPER + D` | launcher (overview) |
  | `SUPER + B` | system panel (right sidebar) |
  | `SUPER + M` | music (left sidebar) |
  | `SUPER + W` | wallpaper selector |
  | `SUPER + S` | calendar |
  | `SUPER + N` | network |
  | `SUPER + V` | volume |
  | `SUPER + C` | clipboard history |
  | `SUPER + H` (and `SUPER + /`) | settings, keybind cheatsheet |
  | `SUPER + A` | bar autohide |
  | `SUPER + R` | reload the shell |
  | `SUPER + L`, power key | lock |
  | `SUPER + Space`, media keys | play / pause, previous, next |
  | volume, mute, mic, brightness keys | change the value, with OSD |
  | `Print` / `SHIFT + Print` | screenshot of a region / region then edit |
  | `SUPER + Print` / `SUPER + SHIFT + Print` | full screenshot / full then edit |

  These keys bring two more features: clipboard history and screenshots with
  an editor.

## 4. Wallpapers

Palette extracted from the wallpaper (matugen base16), animated wallpapers if
supported.

**Selector**, look of Serpantinum's selector (original code). **Done:** the
carousel, the grid, color filters, recent picks, random pick, search, the
wallpaper drawn by the shell, wallpaper = character. **Next:** favorites,
palette from the wallpaper.

- A carousel of slanted (parallelogram) cards over the current wallpaper;
  the selected card is large in the center, the others get smaller towards
  the edges. Arrow keys to browse, Enter to apply, animated transitions.
- A toolbar above it: name of the active filter, switch between carousel and
  grid, recent wallpapers, random pick, **color filters** (red, orange,
  yellow, green, blue, purple, pink, grey) and search. Favorites as planned.
- Color filters use the dominant color of each wallpaper, computed once with
  Quickshell's `ColorQuantizer` and kept in the shell's state folder.
- Applying a wallpaper also regenerates the palette.
- **Wallpaper = character (done):** each pony wallpaper of the collection
  that shows one character with a theme names it (`character = "luna"`, read
  from its wallhaven tags); picking it switches to that character's theme
  (Luna wallpaper, Luna theme). Forest wallpapers switch to
  `wallpaper.forest_theme` (Pine). Wallpapers without a character keep the
  current theme (later: colors from the image). `wallpaper.follow = false`
  turns it off.

**Collection (done: 50 forests, 19 of them green, and 51 My Little Pony): at least 50 wallpapers
from [wallhaven.cc](https://wallhaven.cc), mostly forests, plus My Little Pony.** Real images taken from the site, none
generated.

- wallhaven states that "all images remain property of their original
  owners", and My Little Pony belongs to Hasbro, so the images are **not
  committed** to this public repository. The repository holds the curated list
  (`wallpapers/collection.toml`: wallhaven id, category, resolution, page
  link) and `tfem wallpapers fetch` downloads them on your machine through the
  official API.
- SFW only (`purity=100`), at least 1920×1080, each pick reviewed by hand.
- Available on wallhaven (checked through its API): 268 forest wallpapers
  (16:9, top of the last year) and 125 My Little Pony wallpapers.
- Categories: `forest` (majority), `pony`, then the original ones (abstract,
  minimal, dark) if wanted.
- Forest wallpapers pair naturally with the green palettes (Kanagawa,
  Everforest) when the palette is extracted from the wallpaper.

## 5. Control panel and widgets

- **Done (network panel, `SUPER + N`):** custom Wi-Fi and Bluetooth tabs
  built on `Quickshell.Networking` and `Quickshell.Bluetooth` (no nmcli, no
  applets). Still to do: a pairing-code prompt (Quickshell has no BlueZ
  agent yet), renaming devices, the Audio tab.
- Custom Wi-Fi, Bluetooth, Network and Audio tabs built on
  `Quickshell.Networking` and `Quickshell.Bluetooth` (no nmcli, no applets):
  networks with signal and security, password prompt, failure reason,
  Bluetooth devices with type icon and battery, pair, connect, forget, rename.
- Each tab uses its module color from `[modules]`.
- Quick tiles:
  - **Do not disturb**;
  - **Stay awake**: blocks idle sleep (Quickshell idle inhibitor);
  - **Game mode**: turns off blur, animations and gaps in one click, then
    restores your settings (changing Hyprland options at runtime with the Lua
    config is to be verified).
- Widgets (clock, battery, now playing, CPU/RAM, calendar), each optional.
- **Music widget**, look of Serpantinum's player (original code):
  - the cover in a round "vinyl" that spins while playing, with a ring of bars
    around it that reacts to the sound;
  - title, artist, chips for the output device and the source app;
  - a wavy progress slider, previous / play-pause / next;
  - tabs: **Lyrics** (synced lyrics, current line highlighted, or a local
    `.lrc` file; online source to choose and verify) and **Equalizer**.
  - Lightweight check: Quickshell gives sound levels, which is enough for a
    ring that pulses; a real spectrum and the equalizer need extra audio
    tools, so they stay optional and are only enabled when installed.

## 6. Settings window

Tabs: **Profiles**, **Display**, **Themes**, **Wallpaper**, Bar, Dock,
Widgets (with module colors), System, Keybinds, Identity.

Look of Serpantinum's settings window (original code):

- A sidebar with an icon per section and collapsible groups (Welcome,
  General, Display ▸ Theme, Bar ▸ Launcher, Dock, On-Screen Display,
  Notifications, Idle, About, plus the tabs above), and a search across all
  settings.
- Each setting is a row: icon, title, one-line description, control on the
  right (switch, slider, folder picker, drop-down…).
- Theme page: a header showing the current wallpaper with a "Select
  wallpaper" button and its file name; rows for the wallpaper folder, the
  font (list of installed fonts) and the corner radius; then the color
  themes: a "wallpaper colors" card first, then a grid of cards, each with
  the theme name written in its own colors and a row of palette dots.

- **Look profiles**: save the whole look (theme, accent, wallpaper or
  wallpaper category, style, module colors, dock) under a name and switch in
  one click. Shipped examples: *Forest* (Kanagawa, forest wallpapers),
  *Pony* (palette from the wallpaper, pony wallpapers), *Tokyo Night*. Stored
  in `~/.config/tfem/profiles/`.
- **First-launch wizard**: displayed name, style, theme, wallpaper
  categories, dock or not. Everything stays editable afterwards.
- Themes: browse every theme by family, search, dark/light filter, accent,
  edit single colors and save the result as a personal theme in
  `~/.config/tfem/themes/`.
- Every change validated, applied live, with "reset to defaults".

## 7. Lock screen, login screens, authentication

- **Done:** `hyprlock` config generated from `theme.toml` (hyprlock does not
  lock without one). **Next:** a custom lock screen in the chosen style.
- **Built-in Polkit agent**: administrator password prompts drawn by the
  shell in the current theme (Quickshell 0.3 supports Polkit agents).
- **Done:** two SDDM themes in `extras/sddm/`, installed separately, colors from the
  palette:
  - *Stacked clock*: full wallpaper, date top-left, large stacked hours over
    minutes in the accent color, "press any key" then the login form.
    Reference: [pixie-sddm](https://github.com/xCaptaiN09/pixie-sddm) (MIT).
  - *Welcome panel*: blurred side panel over the wallpaper with a greeting,
    clock, date, user and password fields, show password, session, and round
    suspend / reboot / shutdown buttons. The image is yours to choose: no
    copyrighted artwork is bundled.

## 8. Displays and keybinds

`max-hz.sh` (best mode per monitor, hot-plug), Display tab. Runtime monitor
changes with the Lua config are to be verified. **Done:** keybind cheatsheet
(`SUPER + /`), every key checked by the tests.

Checked in the Hyprland wiki: `hl.monitor({ output = "", mode = "highrr" })`
picks the highest refresh rate on every screen, hot-plugged ones included,
but may lower the resolution to get it. Two choices for the Display tab:
`highrr` (simplest, no script) or `max-hz.sh`, which keeps the native
resolution and picks its highest refresh rate.

## 9. Installer and CI

Installer done (`install.sh`, `--sddm` for the login screen); still to do: CI.

One `install.sh` for Arch, Debian and Fedora, `--profile`, `--dry-run`,
`--uninstall`, mandatory backup, aliases `dots` and `wm`, CI with shellcheck,
tests and an Arch container dry run.

## 10. Documentation

Screenshots per theme, complete "Make it yours", credits.
