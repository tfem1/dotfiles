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
