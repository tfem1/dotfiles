# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed

- No more blurred rectangle behind the shell: Hyprland blurs the bar, the
  launcher, the panels, the notifications and the widgets only where they
  are drawn (a layer rule with `ignore_alpha`), so the blur follows their
  round corners. Right-click menus are blurred the same way.
- Resizing on a touchpad: hold `SUPER + ALT` and move the pointer
  (`SUPER + CTRL` to move the window), as the Hyprland wiki suggests.
  `SUPER` + right drag and dragging a window's edge still work.

### Added

- **fastfetch in the theme's colors**: harilvfs/fastfetch's boxed layout,
  keys in the accent colors, frames in the quiet one, logo in the accent
  (`~/.config/fastfetch/config.jsonc`, new `fastfetch` target and package;
  new template filter `sgr`). Checked with fastfetch 2.70.
- **Screen recording**: `SUPER + ALT + R` starts and stops it (Hyprland,
  Sway and Niri), `tfem record [full|region] [--audio]` from a terminal;
  wf-recorder on the screen in focus, videos in `~/Videos/Screencasts`, a
  red dot in the bar meanwhile (`qs ipc call recording`). New packages:
  `wf-recorder`, `libnotify`.
- **Sway and Niri** besides Hyprland: the install screen's first line (or
  `--wm sway|niri`) picks the window manager, installs its packages and
  writes its config (`sway/config`, `niri/config.kdl`) with the same keys
  and the same shell; `tfem generate` writes their theme file (colors,
  gaps, corners, font, cursor). The bar's workspaces work on all three
  (Sway's IPC, `niri msg`); log out, keyboard layout and screens off use the
  compositor in use; `SUPER + Tab` opens niri's own overview there. The
  Sway config is checked by `sway -C` in the tests.
- **The logo of your distro** at the top left: 31 systems (Arch, CachyOS, Fedora,
  Debian, Ubuntu, NixOS, Mint, Pop!_OS, openSUSE, EndeavourOS, Manjaro...),
  from Simple Icons, Tux for any other Linux.
- Settings → **Fonts**: interface and monospace fonts picked among the
  fonts installed (each drawn in its own face, with a search), and their
  sizes.

### Changed

- Settings are rounder: the pages are pills (the one open tinted with the
  accent), the rows and the theme cards have rounder corners.
- **Calendar widget**: the month, today in the accent color
  (`widgets.calendar`).
- **Widgets you can move**: Settings → Widgets → Move… (or
  `qs ipc call widgets edit`), drag each widget anywhere, "Back to the
  corner" to undo; places saved as `widgets.places.<name>` in
  `config.json` (`tfem settings set` now writes such keys).
- **Workspace overview** (`SUPER + Tab`): the 10 workspaces with their
  windows in place, as live pictures; click to go to a workspace or a
  window, drag a window to another workspace to move it, 1–0 and Escape.
- **Lyrics for almost every song**: cleaned names (videos, "- Topic",
  "feat.", remasters, "Artist - Song" titles), then four requests in turn
  (exact, without album, search by title and artist, free search), the
  synced record of the closest length kept, plain words when only other
  versions exist; found lyrics kept for the session; lrclib is told who asks
  (`Lrclib-Client`), as its documentation requests.
- **Dock** with its Settings page: pinned and running apps (Wayland
  windows, desktop files), click to open or cycle windows, right click to
  pin; colors from the theme, opacity from 20 to 100 %, bottom, left or
  right, hidden until the pointer comes if you want (`dock.*` in
  `config.json`).
- **Install screen**: the installer opens on a TFEM banner and the list of
  what it will install (packages, wallpapers, icons, Monocraft, the login
  screen), to change with the keyboard before anything happens. Pure bash
  (`install/tui.sh`); `--no-tui` for the plain question, skipped with
  `--yes` and `--dry-run`.
- **Themes in the colors of the wallpapers**, measured on the images:
  Moonlit (night forest, teal moon; the new default), Lagoon, Autumn,
  Sakura (light) and Velvet. The wallpapers of the collection bring them.
- **The theme has the colors of the wallpaper**: picking a wallpaper in the
  selector reads its 8 main colors, and the hue that covers the most of the
  image becomes the theme's color (a green wallpaper, a green theme; a blue
  one, a blue theme), made readable by the theme builder
  (`palette.source = "wallpaper"`). An image without color gets Noir. A
  wallpaper picked before its colors were read is applied once they are.
- **Monocraft**, a pixel font, everywhere by default: the shell, the lock
  screen, kitty (`font_family`), GTK (`font-name`, `monospace-font-name`),
  Qt (qt5ct and qt6ct `[Fonts]`), Hyprland and the login screen. The
  installer downloads it with `tfem fonts fetch` (release v4.2.1, checked
  against its SHA-256; `--no-fonts` skips it), and `tfem sddm install`
  copies it to `/usr/local/share/fonts/monocraft` for the login screen.
- **Pixel-art wallpapers** from wallhaven.cc: 15 forests (day, night, mist,
  snow) and 11 cats, picked by hand. Each one names its theme
  (`theme = "forest-moss"` in `wallpapers/collection.toml`): day forests
  bring Moss, night and mist Pine, snow Nord, cats Tabby.
- **Tabby** (`cat-tabby`), an original cat theme built from a few colors of a
  ginger tabby (`themes/seeds/cat.toml`).
- 14 themes in all: Pine (the new default, with a night forest), Moss,
  Tabby, Noir and 10 well-known ones (Catppuccin Mocha and Latte, Dracula,
  Nord, Gruvbox, Tokyo Night Moon, Everforest, Kanagawa, OneDark, Solarized
  Dark). The Settings window groups them: Forest & cats, Well known, Black
  & white, Light.
- The terminal (kitty) is slightly see-through (`effects.opacity`), so
  Hyprland's blur shows behind it.
- `SUPER + SHIFT + Escape`: screenshot of the whole screen.
- Settings opens on a **Home** page: a welcome banner on the wallpaper
  ("Good evening, alex", the date and time, theme, uptime and system, a
  moon drawn in the theme's colors), with **Wallpaper** and **Gaming hub**
  buttons, then one card per page.
- The bar goes on any edge of the screen (top, bottom, left, right) and can
  be fully transparent, from Settings → Tweaks (`bar.position`,
  `bar.transparent` in `config.json`). On the left or right it is narrow,
  everything stacked.
- Desktop widgets are a little see-through, with the blur behind them, and
  CPU, GPU, RAM and disk each stand in an organic shape: a scalloped
  cookie, a five-petal flower, a circle and a clover. The other cards get
  very round corners.
- Settings → **Tweaks**: the modes (Gaming, Coffee, Night, Do not disturb,
  Power saver, Presentation, Focus, Sleep, Screenshot, Region) as tiles.

### Changed

- The installer installs SDDM and the **stacked clock** login screen by
  default and turns SDDM on, unless another login manager is in use (left
  as is). `--sddm welcome-panel` picks the other one, `--no-sddm` skips both.
  On Debian it also installs `qml6-module-qtquick-effects`, which the theme
  needs and the `sddm` package does not pull in.
- The login screen follows the theme with no sudo: the installed theme reads
  `theme.conf.user`, a link to `/var/lib/tfem/sddm/theme.conf`, in a folder
  you own, with a copy of the wallpaper. `tfem generate` keeps it up to date
  (new `sddm` target), so the Settings window and `tfem wallpapers set`
  change the login screen too. Checked with the real SDDM greeter.
- `tfem sddm install` installs the stacked clock when no name is given;
  `--enable` turns SDDM on at the next start.

### Removed

- **My Little Pony** is gone: its 22 themes, its 51 wallpapers (their old
  downloads are deleted by `tfem wallpapers fetch`), the "My Little Pony"
  filter, the pony samples in the previews.
- Fewer themes, kept simple: Catppuccin Frappé and Macchiato, Nord Light,
  Gruvbox Light, Solarized Light, One Light, Ayu, Material Palenight, GitHub
  Dark, Everforest Light, Tomorrow Night Eighties, Kanagawa Dragon and Fern
  are out.
- `SUPER + K` and the modes menu: the modes are in Settings → Tweaks.
- The running apps at the top left of the bar (icons, right-click menu with
  Quit): not wanted after all. The distro logo takes their place.
- The 50 forest wallpapers: the collection is My Little Pony only (51).
  `wallpapers/collection.toml` lists the ids taken out (`removed`) and
  `tfem wallpapers fetch` deletes their old downloads, only those files and
  the folders this leaves empty. `wallpaper.forest_theme` is gone with them.

### Fixed

- The one-line install command did not work in fish (`<(…)` is bash only):
  the README gives the fish form (`… | psub`). Run as `curl … | bash`, the
  installer now reads its questions (and pacman's) from the terminal,
  not from the rest of the piped script.
- The Settings window kept "changes, not applied yet" after Apply: the
  shell's JavaScript has no `Object.fromEntries`, so clearing the applied
  changes failed. Found while testing the modes menu in the real Quickshell.
- The Settings window felt slow: a switch or a choice only moved once
  `tfem settings set` had regenerated every file and the settings were read
  again (up to a second or more). Now it moves on the click; the change is
  confirmed when read back, and a write that fails puts the saved value
  back. Widgets and game mode change in the shell at once too; Wi-Fi and
  Bluetooth switches show the asked state while NetworkManager or BlueZ
  answer; a Display mode shows as picked at once. Checked in the real
  Quickshell with a write slowed down to 3 seconds.
- `tfem generate` ran the reload commands with its own environment
  instead of the one it was given.
- `tfem` was "command not found" in the terminal on Arch: `~/.local/bin` is
  not on its default PATH. Hyprland now adds it (once, even on reload) for
  every program it starts. Checked with `Hyprland --verify-config` 0.57.1.
- The shell did not start at all since the system panel was added: one line
  of `shell.qml` set a property that `SystemPanel` does not have, and
  Quickshell refuses the whole config then, so there was no bar and no
  wallpaper. Found by running the real Quickshell 0.3.2.
- New test `tests/test_shell_runtime.py`: runs the real shell in a headless
  sway session, opens every panel through IPC and fails on any error from
  the shell's code. The previous QML tests only loaded the visual parts with
  plain Qt, which is why this slipped through.
- New test `tests/test_hypr_verify.py`: the Hyprland config, with the
  generated theme.lua and shell.lua, must pass `Hyprland --verify-config`
  (checked with Hyprland 0.57.1, the version of Arch Linux: config ok).

### Added

- **OpenBSD, in part**: the installer recognises OpenBSD (by `uname`, it has
  no os-release), installs what OpenBSD 7.8 packages with `doas pkg_add`
  (names checked against the 7.8 amd64 package list), and themes the apps;
  the desktop (Hyprland, Quickshell) and the login screen are left out,
  since neither exists on OpenBSD yet. The installer's backups use portable
  `cp -RPp` and no GNU-only `date +%N`.
- **Modes menu** (`SUPER + K`): Gaming, Coffee (never sleeps), Night
  (warmer screen with hyprsunset, dimmer, quiet), Do not disturb, Power
  saver (power-saver profile through powerprofilesctl, effects off, dimmer;
  never with Gaming), Presentation (no notification at all, never sleeps),
  Focus (quiet, no widgets) and Sleep (lock, then suspend). An icon in the
  bar for each mode on; the shell's modes survive a restart. New packages:
  power-profiles-daemon (tuned-ppd on recent Fedora) and hyprsunset (not
  packaged on Fedora: night mode only dims there). Checked in the real
  Quickshell with stand-in tools that log their calls, and with
  `Hyprland --verify-config` 0.57.1.
- **Game mode** does more for performance, and `SUPER + G` switches it:
  fullscreen games may tear (less input lag) and are scanned out directly
  (`allow_tearing`, an `immediate` rule for fullscreen windows,
  `render.direct_scanout`: checked with `Hyprland --verify-config`
  0.57.1); Feral GameMode is asked for its optimisations while it is on
  (`gamemoded -r`, new package `gamemode`); the desktop widgets hide and
  stop; the screen never sleeps; a gamepad shows in the bar. Checked in the
  real Quickshell.
- Screens can be turned **off** (and on again) in Settings → Display, with
  a switch per screen, and with `tfem display off NAME` / `on NAME`. The
  page lists the screens already off too (`hyprctl monitors all`); the
  last screen on stays on; a change can be kept or goes back after 15 s.
  Written as `hl.monitor({ output = ..., disabled = true })` (checked with
  `Hyprland --verify-config` 0.57.1).
- **Lock screen** of the shell, in the stacked clock style of the login
  screen: wallpaper, date, hours over minutes in the accent color, and a
  card with the password as soon as you type (a wrong password shakes it).
  Wayland session lock; the password is checked by PAM with the shell's own
  rule (`quickshell/lock/pam/password.conf`). `SUPER + L`, the power key,
  the power menu (lock, and suspend) and hypridle all use it, and fall back
  to hyprlock when the shell is not running. Checked in the real Quickshell:
  lock, a refused password, an unlock.
- **Noir**, a black and white theme for black wallpapers: pure black bar
  and panels, white text and accent, greys elsewhere (red kept for
  alerts). Listed under the new **Black & white** filter of the theme
  grid; `palette.source = "noir"`.
- Widgets in any corner of the screen: Settings → Widgets shows a small
  screen, a click on a corner moves them there (`widgets.corner`). In the
  right corners the clock and the cards hug the right edge. A
  `widgets.side` left in a config.json still works (left = top left,
  right = top right) and goes away the next time the corner is set.
- **Desktop widgets**, under the windows, in the theme's colors: a clock
  pill, CPU, GPU (AMD and NVIDIA), RAM and disk rings, an audio spectrum
  drawn by cava (new package, 24 bars, stopped in game mode) and a
  minimal now playing card (song, artist, the lyrics line being sung).
  Settings → **Widgets** turns each one on or off and picks the corner
  (`widgets.*` in `config.json`, passed to the shell through theme.json).
  Readings come from `/proc`, `df`, the amdgpu files or `nvidia-smi`, only
  while their widget shows; checked in the real Quickshell (CPU follows
  the load) and with the real cava 1.0 (the shipped config).
- The lyrics fetcher is shared by the music panel and the media widget
  (`music/LyricsSource.qml`).
- **Display** page in the Settings window: each screen's refresh rate and
  resolution in one click, applied at once (Hyprland reloads), with
  "Keep this display mode?" and a return to the previous mode after
  15 seconds without an answer. `tfem display list | set NAME MODE | auto
  NAME` does the same from a terminal. The modes live in `config.json`
  (`display.modes`, checked like the other settings) and are written to
  `~/.config/hypr/display.lua` by the new `hyprland-display` target;
  `config/monitors.lua` loads it when it exists (checked with
  `Hyprland --verify-config` 0.57.1, with and without the file).
- The distro's logo at the top left of the bar, in the accent color of the
  theme (violet with Twilight, green with Chrysalis…); a click opens the
  Settings window. Read from `/etc/os-release`: the Arch Linux logo (Simple
  Icons, CC0) shows on Arch only, as its trademark policy asks; other
  systems get the Settings gear.
- `CTRL + SHIFT + S`: screenshot of the whole screen (saved and copied,
  like `SUPER + Print`).
- Settings window (`SUPER + H`, or the gear of the system panel), in quiet
  colors, pages on the left. Appearance: theme cards in their own colors
  with filters, accent, wallpaper, folder color, corners, gaps,
  transparency, blur, shadows, animations, text size; a live preview shows
  the result before Apply (Cancel drops the changes). System, acting at
  once: game mode, sound, microphone, brightness, Wi-Fi, Bluetooth,
  keyboard layout, quiet mode, stay awake, sleep steps. Search finds a
  setting and lights it up. Tests check every search entry leads to a row.
- `tfem settings get | set KEY=VALUE...`: every setting with its bounds and
  the preview colors of every theme, as JSON; typed, checked writes to
  theme.toml or config.json (comments kept), then regeneration.
- Game mode (`effects.game_mode`): no animations, blur or shadows in
  Hyprland and the shell, notification popups held back (urgent ones
  still show).
- Sleep steps in `config.json` (`idle.dim`, `idle.lock`, `idle.screen_off`,
  `idle.suspend`, minutes, 0 = never): `hypridle.conf` is now generated
  (new `hypridle` target, restarts hypridle when it changes).
- 31 more themes, 48 in all. Twelve more My Little Pony characters, from
  their canon colors on the MLP wiki: Applejack, Sweetie Belle, Vinyl
  Scratch, Derpy, Discord, Scootaloo, Apple Bloom, Sunset Shimmer,
  Chrysalis, Spike, Octavia and Zecora; their wallpapers in the collection
  now bring their theme. Nineteen well-known palettes from tinted-theming
  (Catppuccin, Dracula, Nord, Gruvbox, Tokyo Night Moon, Solarized, One,
  Ayu, Material Palenight, GitHub Dark, Everforest Light, Tomorrow Night
  Eighties), imported by `tools/import_tinted.py` with their signature color
  (made readable when needed); the tinted-theming MIT license is now in
  `licenses/`.
- Two SDDM login screens (Qt 6), original, in the colors, font and wallpaper
  of the desktop theme: **Welcome panel** (frosted side panel: greeting,
  clock, user, password with show button and Caps Lock warning, session,
  suspend / restart / shut down) and **Stacked clock** (large stacked clock
  in the accent color, "press any key", sign-in card). `tfem sddm install
  [NAME]` builds and installs one (theme.conf from the template, wallpaper
  copy, `/etc/sddm.conf.d/zz-login-theme.conf`, warning when `/etc/sddm.conf`
  forces another theme); `tfem sddm test [NAME]` shows it in a window; the
  installer takes `--sddm [NAME]`. Checked with the real `sddm-greeter-qt6`
  in test mode; tests load both themes with stand-ins for SDDM and check the
  login call and the wrong password message.
- FairyWren icons (gitlab.com/FreshDoctor/FairyWren-Icons, GPL-3.0, not
  bundled): `tfem icons fetch` downloads only `FairyWren_Dark` and
  `FairyWren_Light`, the installer runs it (`--no-icons` to skip). The
  default icon theme is now `FairyWren`: dark or light from the palette.
  The folders take FairyWren's color that looks closest to the accent
  (OKLab distance to each folder's measured color), or the one set in
  `icons.folders`; a new `icons` target records it and points FairyWren's
  folder link at it. Papirus (FairyWren's fallback) is now a core package.
  New `{data}` placeholder for targets.

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
- System panel (`SUPER + B`): Wi-Fi, Bluetooth, airplane, quiet mode, stay
  awake, volume and brightness, and the notification history (last 50,
  dismiss one or all). The daemon keeps the history and hides popups in
  quiet mode except urgent ones; quiet and stay-awake states are saved in
  the shell's state folder and shown in the bar. Stay awake is an idle
  inhibitor on the bar's window.
- hypridle with `hypr/hypridle.conf` (from the Hyprland wiki example):
  dim, lock, screen off, suspend; started with Hyprland, installed.
- Power menu (`SUPER + Escape`, power button in the bar): lock, log out
  (Hyprland's own command), suspend after locking, restart, shut down;
  destructive actions ask for a second click within 4 seconds; keyboard
  letters; uptime from /proc/uptime. "Esc" in the cheatsheet.
- Music panel (`SUPER + M`) on MPRIS: sleeve and turning record (label in
  the theme's third color), progress with seeking, previous/play/next,
  shuffle and repeat when the player supports them, player choice, and
  synced lyrics from lrclib.net fetched only when the lyrics view is open.
  Position asked twice a second only while the panel shows a playing song.
- Running apps at the top left of the bar: open windows (Wayland
  toplevels) and tray icons (StatusNotifierItem) grouped into one icon per
  app, with a mark for the windows and the focused one. Click brings the
  app forward and cycles through its windows; right click opens a themed
  menu with the app's own tray entries (submenus in place) and Quit, which
  uses the app's quit entry or sends SIGTERM to the processes of its
  windows. Grouping, tray matching and menu rows tested; preview mode
  `apps`.
- Wallpaper = character: 24 pony wallpapers of the collection name the
  character they show (from their wallhaven tags); picking one with
  `SUPER + W` or `tfem wallpapers set` switches to that character's theme
  (Luna wallpaper, Luna theme), and a forest wallpaper to the green
  `wallpaper.forest_theme` (Pine by default). Other images keep the theme.
  Turn it off with `wallpaper.follow = false`. The selector shows the theme
  a wallpaper brings, and searching "luna" finds Luna's wallpapers.
- Minimal themes: every shell module now uses the theme's own three colors
  (`accent`, `accent2`, `accent3`) instead of eight hues. Themes may set
  `accent2` / `accent3`; otherwise they are derived from the accent (same
  hue a step lighter or deeper, and a neighbouring hue), always readable.
  Pony themes use a second canon color of the character as `accent3`
  (Pinkie's blue eyes, Twilight's magenta stripe…). Occupied workspaces are
  tinted with the accent; kitty and Qt links follow the same colors.
- Roadmap: the next ten steps, in the order chosen.
- Six green themes with a green accent: Kanagawa, Kanagawa Dragon and
  Everforest Dark Hard (official palettes from tinted-theming, unchanged),
  and the original Pine, Moss and Fern (`themes/seeds/forest.toml`). A test
  checks every theme keeps each hue in its slot.
- 21 green forest wallpapers from wallhaven.cc (moss, canopy, paths,
  streams), checked by eye: 105 wallpapers, 53 pony and 52 forest.
- Collection checked again through the wallhaven tags: a drug parody and a
  humanized pony removed (they break the collection rules), and two weak
  forest pictures, so pony stays the majority: 101 wallpapers, 51 pony and
  50 forest.
- Roadmap: themes before the shell, two styles (Material and Mono), look
  profiles, first-launch wizard, optional dock, game mode, do not disturb,
  stay awake, Polkit agent, two SDDM themes, wallhaven wallpaper collection.
