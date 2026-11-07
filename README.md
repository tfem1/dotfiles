# TFEM

Modular Hyprland dotfiles with a complete Quickshell desktop shell, driven by a
single settings file.

> **TFEM is the name of this repository and of its CLI, not the name of your
> desktop.** Nothing on screen carries the TFEM name: no branding in the bar,
> lock screen, launcher or notifications. See [Make it yours](#make-it-yours).

**Status:** early work. Step 1 of 10 is done (theme pipeline); palettes and app themes come next. The full plan,
including what is coming next, is in [docs/roadmap.md](docs/roadmap.md).

## How theming works

One file, `theme.toml`, describes the look of the whole desktop: palette,
accent, fonts, corners, gaps, blur, cursor, and the color of each shell module.
`tfem generate` turns it into the configuration files each app expects, in
their usual places:

```
theme.toml ──► validate ──► palette (base16) ──► templates ──► ~/.config/hypr/theme.lua
themes/*.toml ─────────────────┘                             ~/.config/quickshell/<shell>/theme.json
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

## Repository layout

```
theme.toml            default look of the desktop (the single source of truth)
config.json           default shell behaviour (shell name, and more later)
tfem                  CLI
themes/               base16 palettes, one file per theme
templates/            one template per generated file + targets.toml manifest
scripts/generate.sh   entry point of the generator
scripts/theming/      generator: settings, palette, template engine, safe writer
tests/                unit and end-to-end tests, golden files
docs/                 architecture, template format, roadmap
```

## Make it yours

- **Shell name:** the Quickshell config lives in
  `~/.config/quickshell/<name>/`. Set `shell.name` in your `config.json`
  (default `desktop`).
- **Colors:** pick any theme with `palette.source`, an accent with
  `palette.accent`, and change single colors with `[palette.overrides]`.
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
- **[tinted-theming](https://github.com/tinted-theming/schemes)** (MIT) for
  the base16 palettes and the standard terminal color mapping.
- Visual references for the upcoming shell and login screens are listed in
  [docs/roadmap.md](docs/roadmap.md).

## License

[GPL-3.0](LICENSE).
