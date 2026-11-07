# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `theme.toml`: single source of truth for the look of the desktop (palette,
  accent, fonts, shape, effects, cursor, icons, one color per shell module).
- `config.json`: shell settings, starting with the shell name.
- Catppuccin Mocha base16 palette (from tinted-theming/schemes).
- Theme generator (`tfem generate`, `scripts/generate.sh`): settings
  validation with clear messages, palette resolution with overrides, template
  engine with color filters, safe writer (atomic writes, backups, marked
  include lines, reload only when a file changed), `--dry-run`, `--only`,
  `--all`.
- Templates for Hyprland (Lua config, Hyprland 0.55+) and for the Quickshell
  shell (`theme.json`).
- Unit and end-to-end tests with golden files.
- Hyprland config in Lua (`hypr/`): modules for variables, monitors (highest
  refresh rate on every screen), settings, animations, autostart (clipboard
  history, shell) and keybinds with descriptions, using the same key layout
  as Serpantinum. Checked by tests that load it in a fake Hyprland API.
- Generated `hypr/shell.lua` (shell name from `config.json`) and Hyprland
  font from `theme.toml`.
- `tfem screenshot region|full [--edit]` (grim, slurp, satty).
- One-command installer (`install.sh`) for the Arch, Debian and Fedora
  families: package table with per-distro names and alternatives, every
  package checked before installing, backup of every replaced file, Hyprland
  version check, CLI and aliases in `~/.local/bin`, `--profile`,
  `--dry-run`, `--uninstall`, `--yes`. No third-party repository is added.
- Wallpaper collection: 50 wallhaven.cc wallpapers (31 forests, 19 My Little
  Pony), downloaded by `tfem wallpapers fetch` into `~/Pictures/Wallpapers`;
  relative wallpaper paths in `theme.toml` now point there.
- Screenshot editing falls back to a plain capture when satty is missing.
- Ten themes in the colors of My Little Pony characters (Twilight, the new
  default, Pinkie, Rarity, Cadance, Starlight, Luna, Trixie, Rainbow,
  Fluttershy and Celestia), built from canon colors by `theming.builder`,
  which keeps every color readable (WCAG) and every hue in its slot.
- Themes can carry a signature color; `palette.accent = "theme"` (the new
  default) uses it.
- Color checks (`theming.hues`): hue classes, neighbour rule, WCAG contrast.
- 34 more My Little Pony wallpapers: 84 in total, 53 of them pony.
- The Quickshell shell (`quickshell/`): bar in the illogical-impulse look
  (now playing with progress ring, workspaces in a notch,
  clock, keyboard layout, sound, network, Bluetooth, battery), volume and
  brightness OSD, notification daemon with popups, app launcher, IPC for the
  keybinds. Visual parts are plain QtQuick; Quickshell services are wrapped in
  small singletons. Colors follow theme.json live.
- Material Symbols icons drawn in any color (`tools/fetch_icons.py`).
- `tools/preview/render.py`: renders the shell's QML with sample data
  (PySide6), used for screenshots and QML tests.
- The installer deploys the shell; brightness keys show the OSD.
- Backups get unique folder names, so two runs in the same second never mix
  them (found by the uninstall test).
- Keybinds checked one by one against Hyprland's source and wiki. Tests now
  load every key in the fake Hyprland API and check that its dispatcher
  exists, that the program it runs comes from the installer, and that the
  shell handles its IPC call (the panels still to build are listed).
- Lock screen: generated `hyprlock.conf` in the theme colors (wallpaper,
  clock, date, password field). Without it hyprlock exits and `SUPER + L`
  did not lock.
- Shell: clipboard history (`SUPER + C`), keybind cheatsheet read from
  `hyprctl binds -j` (`SUPER + /`) and bar autohide (`SUPER + A`); shared
  search field and overlay window.
- Screenshot keys call `~/.local/bin/tfem`: Hyprland started from a login
  manager often has no `~/.local/bin` in its PATH.
- Wallpaper selector (`SUPER + W`): carousel of slanted cards or grid,
  color filters (main color of each image found once with Quickshell's
  ColorQuantizer, then kept), recent picks, random pick, search. Left and
  right arrows browse, also while searching and in the grid; it opens on the
  wallpaper in use. The shell now draws the wallpaper itself, with a fade.
- `tfem wallpapers list [--json]` and `tfem wallpapers set IMAGE`: the
  choice is written in your `theme.toml` (one key changed, comments kept)
  and the shell and lock screen files are regenerated.
- Launcher: every word is looked for in the name, description, keywords, id
  and command; names sort without regard to case; terminal apps open in
  `$TERMINAL`, which Hyprland now sets from `variables.lua`.
- kitty follows the theme: `tfem generate` writes `~/.config/kitty/theme.conf`
  (16 terminal colors, cursor, selection, borders, tabs, marks), adds one
  include line to `kitty.conf` (created if missing) and reloads open kitty
  windows (SIGUSR1).
- Network panel (`SUPER + N`, or a click on the bar's status icons), on
  Quickshell's Networking and Bluetooth (no applet, no nmcli): Wi-Fi,
  Bluetooth and airplane toggles; Wi-Fi tab with signal, security, saved
  networks, password typed in place with the failure reason (password
  needed, wrong password, out of range, company login), disconnect, forget,
  short rescans, cable and "no internet" lines; Bluetooth tab with device
  types, battery, connect, forget, pairing of nearby devices (then trusted
  and connected), visibility switch. Themed with the module colors.
- GTK and Qt apps follow the theme: `theme.css` for GTK 3 (adw-gtk3) and
  GTK 4 / libadwaita (named colors and, for libadwaita 1.6+, CSS variables),
  each loaded by one `@import` line at the top of `gtk.css`; qt5ct and qt6ct
  palettes (21 roles, disabled state dimmed) with their config;
  `QT_QPA_PLATFORMTHEME=qt5ct`; `gsettings` sets the GTK theme, style,
  icons and cursor. Checked on real GTK 3, GTK 4 and Qt windows.
- Targets: `reload` commands are rendered with the theme values, `quote`
  filter for shell quoting, `comment_end` for include markers in CSS.
- Installer: adw-gtk3, qt5ct, qt6ct, xdg-desktop-portal-gtk, gsettings.
- Volume panel (`SUPER + V`): output and microphone with mute and device
  choice, per-app volume with icon and media name (PipeWire nodes bound
  only while the panel is open); new Slider component.
- Calendar (`SUPER + S`, or a click on the bar's clock): locale-aware month
  grid (first day of the week, day and month names), ISO week numbers,
  today, month navigation by arrows, keys or wheel. Grid logic tested.
- Roadmap: the next ten steps, in the order chosen.
- Six green themes with a green accent: Kanagawa, Kanagawa Dragon and
  Everforest Dark Hard (official palettes from tinted-theming, unchanged),
  and the original Pine, Moss and Fern (`themes/seeds/forest.toml`). A test
  checks every theme keeps each hue in its slot.
- 21 green forest wallpapers from wallhaven.cc (moss, canopy, paths,
  streams), checked by eye: 105 wallpapers, 53 pony and 52 forest.
- Roadmap: themes before the shell, two styles (Material and Mono), look
  profiles, first-launch wizard, optional dock, game mode, do not disturb,
  stay awake, Polkit agent, two SDDM themes, wallhaven wallpaper collection.
