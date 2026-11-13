"""SDDM login screens: two themes (extras/sddm) in the colors of the desktop.

Usage: sddm.py install [NAME] [--enable]   install and select it (sudo)
       sddm.py doctor                       why the login screen is (not) shown
       sddm.py test [NAME]                  show it in a window, nothing installed
       sddm.py build NAME DIR               only build it into DIR
NAME: stacked-clock (default) or welcome-panel. --enable also turns SDDM on
at the next start, in place of the login manager in use if another one is
(GDM, LightDM, ly...: disabled, not removed). A theme another SDDM config
file selects after ours (/etc/sddm.conf) is commented out, the file kept as
FILE.tfem-backup.
A built theme holds its QML, a theme.conf with the colors and font of the
current theme.toml, and a copy of the wallpaper: SDDM runs as its own user
and cannot read your home. The installed theme also reads theme.conf.user,
a link to a folder you own (/var/lib/tfem/sddm): `tfem generate` keeps it
up to date, so the login screen follows the theme with no sudo.
"""
from __future__ import annotations

import argparse
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Mapping

from theming.context import build_context  # noqa: E402  (scripts/ is on sys.path)
from theming.generate import main as generate  # noqa: E402
from theming.palette import PaletteError, resolve_palette  # noqa: E402
from theming.paths import Paths  # noqa: E402
from theming.settings import SettingsError, load_config, load_theme  # noqa: E402
from theming.template import TemplateError, render  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "extras/sddm"
THEMES = ("stacked-clock", "welcome-panel")
# Where SDDM looks; tests point these elsewhere and run without sudo.
THEMES_DIR = Path(os.environ.get("TFEM_SDDM_THEMES", "/usr/share/sddm/themes"))
# Read after the other /etc/sddm.conf.d files (alphabetical order): it wins.
CONF = Path(os.environ.get("TFEM_SDDM_CONF", "/etc/sddm.conf.d/zz-login-theme.conf"))
MAIN_CONF = Path(os.environ.get("TFEM_SDDM_MAIN_CONF", "/etc/sddm.conf"))
# The packages' defaults, read first (sddm.conf(5)).
SYSTEM_CONF_DIR = Path(os.environ.get("TFEM_SDDM_SYSTEM_CONF_DIR", "/usr/lib/sddm/sddm.conf.d"))
SUDO = os.environ.get("TFEM_SUDO", "sudo")
# The login screen runs as its own user, who cannot read your fonts: Monocraft
# is copied here for it (every user may use it then).
SYSTEM_FONTS = Path(os.environ.get("TFEM_SYSTEM_FONTS", "/usr/local/share/fonts/monocraft"))
# The login manager systemd starts; another one than SDDM is never replaced.
DM_LINK = Path(os.environ.get("TFEM_DM_LINK", "/etc/systemd/system/display-manager.service"))


def build(name: str, dest: Path, paths: Paths) -> Path:
    """Copies the theme, its shared parts and the shell's icons into `dest`,
    then writes theme.conf and the wallpaper copy."""
    if name not in THEMES:
        raise ValueError(f"unknown login theme '{name}' (available: {', '.join(THEMES)})")
    dest.mkdir(parents=True, exist_ok=True)
    for item in (SOURCE / name).iterdir():
        if item.is_file():
            shutil.copy2(item, dest / item.name)
    common = dest / "common"
    shutil.copytree(SOURCE / "common", common, dirs_exist_ok=True)
    for shared in ("Icon.qml", "icons.js"):  # the shell's Material Symbols
        shutil.copy2(ROOT / "quickshell/components" / shared, common / shared)

    theme = load_theme(paths)
    context = build_context(theme, resolve_palette(theme, paths), paths, load_config(paths))
    wallpaper = Path(str(context["wallpaper.path"])) if context["wallpaper.path"] else None
    context["sddm.background"] = ""
    if wallpaper and wallpaper.is_file():
        context["sddm.background"] = "background" + wallpaper.suffix.lower()
        shutil.copy2(wallpaper, dest / str(context["sddm.background"]))
    template = ROOT / "templates/sddm/theme.conf.tpl"
    (dest / "theme.conf").write_text(render(template.read_text(), context, source=paths.pretty(template)))
    return dest


def conf_files() -> list[Path]:
    """SDDM's config files in the order it reads them: each one overrides the
    ones before (sddm.conf(5): the two folders in alphabetical order, then
    /etc/sddm.conf)."""
    files = [f for folder in (SYSTEM_CONF_DIR, CONF.parent) for f in sorted(folder.glob("*.conf"))]
    return files + [MAIN_CONF]


def theme_in(path: Path) -> str | None:
    """The [Theme] Current of one config file, if it sets one."""
    try:
        text = path.read_text()
    except OSError:
        return None
    section, found = "", None
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("["):
            section = line
        elif section == "[Theme]" and (match := re.match(r"Current\s*=\s*(\S+)", line)):
            found = match.group(1)
    return found


def overriding(name: str) -> list[tuple[Path, str]]:
    """The files read after ours that select another theme: they would win."""
    files = conf_files()
    after = files[files.index(CONF) + 1:] if CONF in files else files
    return [(f, theme) for f in after if (theme := theme_in(f)) and theme != name]


def effective() -> tuple[str | None, Path | None]:
    """The theme SDDM shows, and the file that chooses it."""
    chosen: tuple[str | None, Path | None] = (None, None)
    for f in conf_files():
        if theme := theme_in(f):
            chosen = (theme, f)
    return chosen


def other_manager() -> str | None:
    """The login manager systemd starts, when it is not SDDM."""
    if not DM_LINK.exists() and not DM_LINK.is_symlink():
        return None
    name = Path(os.readlink(DM_LINK)).name if DM_LINK.is_symlink() else DM_LINK.name
    return None if name == "sddm.service" else name.removesuffix(".service")


def install(name: str, paths: Paths, enable: bool, env: Mapping[str, str]) -> int:
    with tempfile.TemporaryDirectory() as temp:
        staged = build(name, Path(temp) / name, paths)
        target, folder = THEMES_DIR / name, paths.sddm_dir
        conf = f"# Written by `tfem sddm install`: the login screen theme.\n[Theme]\nCurrent={name}\n"
        q = lambda value: shlex.quote(str(value))  # noqa: E731
        steps = [
            f"rm -rf {q(target)}", f"mkdir -p {q(THEMES_DIR)}", f"cp -r {q(staged)} {q(target)}",
            # Colors and wallpaper from a folder you own, kept by `tfem generate`.
            f"ln -sfn {q(folder / 'theme.conf')} {q(target / 'theme.conf.user')}",
            f"chmod -R a+rX {q(target)}",
            f"mkdir -p {q(folder)}", f"chown {os.getuid()}:{os.getgid()} {q(folder)}",
            f"chmod 755 {q(folder)} {q(folder.parent)}",
            f"mkdir -p {q(CONF.parent)}", f"printf '%s' {q(conf)} > {q(CONF)}",
        ]
        font = paths.data_home / "fonts/Monocraft/Monocraft.ttc"   # `tfem fonts fetch`
        if font.is_file():
            steps += [f"mkdir -p {q(SYSTEM_FONTS)}", f"cp {q(font)} {q(SYSTEM_FONTS / font.name)}",
                      f"chmod -R a+rX {q(SYSTEM_FONTS)}", "fc-cache -f >/dev/null 2>&1 || true"]
        # A theme selected after ours would win: its line is commented out.
        for path, _ in overriding(name):
            steps.append(f"sed -i.tfem-backup '/^\\[Theme\\]/,/^\\[/ s/^[[:space:]]*Current[[:space:]]*=/#&/' {q(path)}")
        other = other_manager()
        if enable and other:   # you picked SDDM: it takes the other one's place
            steps.append(f"systemctl disable {q(other + '.service')}")
        if enable:
            steps.append("systemctl enable sddm.service")
        command = ([SUDO] if SUDO else []) + ["sh", "-c", "set -e; " + "; ".join(steps)]
        print(f"installing the '{name}' login screen in {target} (needs administrator rights)")
        if subprocess.run(command).returncode != 0:
            print("error: the login screen was not installed", file=sys.stderr)
            return 1
    print(f"login screen: {name} (selected in {CONF})")
    # The colors and the wallpaper, written as you, in the folder SDDM reads.
    generate(["--root", str(ROOT), "--only", "sddm"], env=env)
    for path, theme in overriding(name):   # left when the edit failed
        print(f"warning: {path} still selects '{theme}' and wins: remove its [Theme] Current line",
              file=sys.stderr)
    if enable and other:
        print(f"{other} was the login manager: it is turned off (not removed), SDDM takes its place. "
              f"To go back: sudo systemctl disable sddm.service && sudo systemctl enable {other}.service")
    if enable:
        print("SDDM shows at the next start of the computer")
    if not shutil.which("sddm", path=env.get("PATH")):
        print("note: SDDM is not installed; install it (e.g. sudo pacman -S sddm)", file=sys.stderr)
    return 0


def doctor() -> int:
    """Says what SDDM will show at the next start, and what stands in the way."""
    problems = 0
    if not shutil.which("sddm"):
        print("- SDDM is not installed (e.g. sudo pacman -S sddm)")
        problems += 1
    other = other_manager()
    if other:
        print(f"- {other} is the login manager, not SDDM: tfem sddm install --enable switches to SDDM")
        problems += 1
    elif not DM_LINK.exists():
        print("- no login manager is turned on: tfem sddm install --enable turns SDDM on")
        problems += 1
    theme, source = effective()
    if theme not in THEMES:
        print(f"- SDDM shows the theme '{theme or 'default'}'" + (f" (set in {source})" if source else "")
              + ": tfem sddm install selects ours")
        problems += 1
    elif not (THEMES_DIR / theme / "Main.qml").is_file():
        print(f"- '{theme}' is selected but not in {THEMES_DIR}: run tfem sddm install {theme}")
        problems += 1
    if not problems:
        print(f"SDDM is on and shows '{theme}' (set in {source}).")
    return 1 if problems else 0


def test(name: str, paths: Paths) -> int:
    greeter = shutil.which("sddm-greeter-qt6") or shutil.which("sddm-greeter")
    if not greeter:
        print("error: sddm-greeter-qt6 not found: install SDDM first", file=sys.stderr)
        return 1
    with tempfile.TemporaryDirectory() as temp:
        staged = build(name, Path(temp) / name, paths)
        print("test mode: signing in, restart and shut down do nothing; close the window to quit")
        return subprocess.run([greeter, "--test-mode", "--theme", str(staged)]).returncode


def main(argv: list[str] | None = None, env: Mapping[str, str] = os.environ) -> int:
    parser = argparse.ArgumentParser(prog="sddm", description="Login screens for SDDM.")
    commands = parser.add_subparsers(dest="command", required=True)
    for command, text in (("install", "install and select a login screen (sudo)"),
                          ("test", "show a login screen in a window")):
        sub = commands.add_parser(command, help=text)
        sub.add_argument("name", nargs="?", default=THEMES[0], choices=THEMES)
        if command == "install":
            sub.add_argument("--enable", action="store_true", help="turn SDDM on at the next start")
    commands.add_parser("doctor", help="why the login screen is (not) shown")
    build_cmd = commands.add_parser("build", help="build a login screen into a folder")
    build_cmd.add_argument("name", choices=THEMES)
    build_cmd.add_argument("dest", type=Path)
    args = parser.parse_args(argv)
    paths = Paths.from_env(ROOT, env)
    try:
        if args.command == "install":
            return install(args.name, paths, args.enable, env)
        if args.command == "test":
            return test(args.name, paths)
        if args.command == "doctor":
            return doctor()
        print(build(args.name, args.dest, paths))
        return 0
    except (OSError, ValueError, SettingsError, PaletteError, TemplateError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
