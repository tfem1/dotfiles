# Roadmap

Each step is planned, approved, implemented, then reviewed before the next one.
Themes come before the shell, so the shell is built with the final palettes.

## Design rules

- **No gradients, anywhere.** Window borders, buttons, sliders, panels,
  backgrounds and login screens use solid colors only.
- Colors always come from the active palette: a hue name, never a fixed hex.

## 1. Theme pipeline — done

`theme.toml`, `config.json`, base16 theme format, template engine, Hyprland
(Lua) and Quickshell templates, safe writer, `tfem generate`, tests.

## 2. Palettes and app themes — next

- Import the base16 collection of
  [tinted-theming/schemes](https://github.com/tinted-theming/schemes) (MIT,
  362 themes) with a reproducible script, one file per theme, author kept.
- **Hue check in the importer.** base16 slots are syntax-highlighting roles,
  not guaranteed hues: tinted's Tokyo Night puts a pale blue (`#C0CAF5`) in
  the "red" slot and a cyan (`#0DB9D7`) in the "yellow" slot. The importer
  measures the hue of each slot and fixes or flags such themes, so `red`
  always looks red in the UI (urgent notifications, low battery).
- **Featured themes**, shown first in the theme picker:
  - *Kanagawa* (and Kanagawa Dragon): dark night background, **green** accent
    and green-leaning module colors.
  - Many more green themes: Everforest, Gruvbox Material, and others found by
    the hue check.
  - *Tokyo Night* (Night, Storm, Moon): **night blue** accent with some
    **purple** modules, built from the official Tokyo Night palette so its
    blue and purple are the real ones.
- Each theme can suggest an accent and module colors, applied when you pick
  it; you can still change them afterwards.
- Terminal themes (foot, kitty, alacritty, ghostty, wezterm), GTK and Qt,
  never overwriting existing configs.
- `tfem theme <name>`.

## 3. Quickshell shell: bar, OSD, launcher, notifications

- A single `shell.qml` that only composes; every hidden part in a `Loader`.
- Colors read live from the generated `theme.json` (`FileView` + `JsonAdapter`).
- **Two visual styles, switchable in Settings** (`shell.style` in
  `config.json`), sharing the same components where possible:
  - *Material*: thin vertical bar, rounded pill buttons, side panel with quick
    toggles, notifications and calendar, media card. Reference:
    [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)
    (illogical-impulse).
  - *Mono*: top bar with grouped pills, monospace font, large pixel clock on
    the desktop, compact control panel with avatar, uptime, 2×2 tiles and wide
    sliders. Reference: [aelyx-shell](https://github.com/xZepyx/aelyx-shell).
  - Both are original implementations; only the look is reproduced, without
    the gradients some references use.
- **Optional dock**: `dock.enabled` in `config.json`, styled to match.
- **Do not disturb**: notifications are kept but not shown.

## 4. Wallpapers

Selector (grid, preview, transitions, keyboard, search, favorites), palette
extracted from the wallpaper (matugen base16), animated wallpapers if
supported.

**Collection: at least 50 wallpapers from [wallhaven.cc](https://wallhaven.cc),
mostly forests, plus My Little Pony.** Real images taken from the site, none
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

## 6. Settings window

Tabs: **Profiles**, **Display**, **Themes**, **Wallpaper**, Bar, Dock,
Widgets (with module colors), System, Keybinds, Identity.

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

- `hyprlock` theme from `theme.toml`.
- **Built-in Polkit agent**: administrator password prompts drawn by the
  shell in the current theme (Quickshell 0.3 supports Polkit agents).
- Two SDDM themes in `extras/sddm/`, installed separately, colors from the
  palette:
  - *Stacked clock*: full wallpaper, date top-left, large stacked hours over
    minutes in the accent color, "press any key" then the login form.
    Reference: [pixie-sddm](https://github.com/xCaptaiN09/pixie-sddm) (MIT).
  - *Welcome panel*: blurred side panel over the wallpaper with a greeting,
    clock, date, user and password fields, show password, session, and round
    suspend / reboot / shutdown buttons. The image is yours to choose: no
    copyrighted artwork is bundled.

## 8. Displays and keybinds

`max-hz.sh` (best mode per monitor, hot-plug), Display tab, keybind
cheatsheet (`super + /`). Runtime monitor changes with the Lua config are to be
verified.

## 9. Installer and CI

One `install.sh` for Arch, Debian and Fedora, `--profile`, `--dry-run`,
`--uninstall`, mandatory backup, aliases `dots` and `wm`, CI with shellcheck,
tests and an Arch container dry run.

## 10. Documentation

Screenshots per theme, complete "Make it yours", credits.
