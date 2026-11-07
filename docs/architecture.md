# Architecture

## Where things live

| Location | Content | Who writes it |
|---|---|---|
| Repository (installed in `~/.local/share/tfem`) | defaults, themes, templates, scripts | the project |
| `~/.config/tfem/` | your `theme.toml`, `config.json`, personal `themes/` | you, the Settings window |
| `~/.config/<app>/` | generated files (`hypr/theme.lua`, …) | the generator only |
| `~/.local/state/tfem/` | backups, record of generated files | the generator only |

Your files only contain the keys you changed: each one replaces the default
with the same name, so updating the project never conflicts with your
settings, and "reset to defaults" means removing a key.

## Two settings files, one rule

- `theme.toml` holds **appearance**: palette, accent, fonts, shape, effects,
  wallpaper, cursor, icons, module colors.
- `config.json` holds **everything else**: shell name, and later bar, dock,
  widgets, displays and identity. The shell reads it live.

## Generation pipeline

1. **Load** the defaults from the repository, then your file on top
   (`settings.py`).
2. **Validate** every key against `schema.py`: type, range, allowed values.
   All problems are reported at once and nothing is written if one is found.
3. **Resolve the palette** (`palette.py`): find the theme file (your
   `themes/` first), apply `[palette.overrides]`, derive the readable roles
   (`bg`, `fg`, `accent`…) and the 16 terminal colors.
4. **Build the context** (`context.py`): a flat map of every variable a
   template can use; hues such as `"blue"` become real colors.
5. **Render each target** listed in `templates/targets.toml`
   (`template.py`, `filters.py`). A broken template only fails its own target.
6. **Write safely** (`writer.py`):
   - unchanged output: nothing is touched and the app is not reloaded;
   - output not produced by the generator (or edited by hand): backed up first;
   - writes are atomic (temporary file, then rename);
   - include lines go between `>>> generated: <target> >>>` markers, are added
     once, and an app config that does not exist is never created unless the
     target allows it (an empty `hyprland.lua` would hide Hyprland's defaults).
7. **Reload** the app when its file changed and the app is installed.

## Patterns borrowed from Serpantinum

Ideas only, no code (Serpantinum is AGPL-3.0):

- a single Quickshell instance as the shell, separate from the compositor
  config, which is split into small modules;
- one settings file, watched and applied live;
- palettes from presets or from the wallpaper, with per-color overrides;
- app theming through a separate generated file and one marked include line,
  never by overwriting the user's config;
- reload an app only when its generated file changed;
- a CLI that mirrors the Settings window, so both write through the same path.

## Verified assumptions and open checks

- Hyprland 0.57 only reads `hyprland.lua` (the `.conf` format was removed), so
  the Hyprland template produces Lua. `require("theme")` loads
  `~/.config/hypr/theme.lua`.
- To confirm on a real session: that `hyprctl reload` re-runs files loaded
  with `require` (the wiki says each `require` runs in its own scope but does
  not describe caching).
