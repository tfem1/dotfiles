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
  (focused window, now playing with progress ring, workspaces in a notch,
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
- Roadmap: themes before the shell, two styles (Material and Mono), look
  profiles, first-launch wizard, optional dock, game mode, do not disturb,
  stay awake, Polkit agent, two SDDM themes, wallhaven wallpaper collection.
