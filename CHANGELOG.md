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
- Roadmap: themes before the shell, two styles (Material and Mono), look
  profiles, first-launch wizard, optional dock, game mode, do not disturb,
  stay awake, Polkit agent, two SDDM themes, wallhaven wallpaper collection.
