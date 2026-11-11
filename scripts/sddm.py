"""SDDM login screens: two themes (extras/sddm) in the colors of the desktop.

Usage: sddm.py install [NAME] [--enable]   install and select it (sudo)
       sddm.py test [NAME]                  show it in a window, nothing installed
       sddm.py build NAME DIR               only build it into DIR
NAME: stacked-clock (default) or welcome-panel. --enable also turns SDDM on
at the next start, when no other login manager is on.
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


def overridden(name: str) -> str | None:
    """The theme /etc/sddm.conf forces, if any (it is read last, so it wins)."""
    try:
        text = MAIN_CONF.read_text()
    except OSError:
        return None
    section = ""
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("["):
            section = line
        elif section == "[Theme]" and (match := re.match(r"Current\s*=\s*(\S+)", line)):
            return match.group(1) if match.group(1) != name else None
    return None


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
        other = other_manager()
        if enable and not other:
            steps.append("systemctl enable sddm.service")
        command = ([SUDO] if SUDO else []) + ["sh", "-c", "set -e; " + "; ".join(steps)]
        print(f"installing the '{name}' login screen in {target} (needs administrator rights)")
        if subprocess.run(command).returncode != 0:
            print("error: the login screen was not installed", file=sys.stderr)
            return 1
    print(f"login screen: {name} (selected in {CONF})")
    # The colors and the wallpaper, written as you, in the folder SDDM reads.
    generate(["--root", str(ROOT), "--only", "sddm"], env=env)
    if other_theme := overridden(name):
        print(f"warning: {MAIN_CONF} selects '{other_theme}' and is read last: "
              f"remove its [Theme] Current line to use '{name}'", file=sys.stderr)
    if enable and other:
        print(f"note: {other} is the login manager in use, left as is. To use SDDM instead:\n"
              f"  sudo systemctl disable {other}.service && sudo systemctl enable sddm.service", file=sys.stderr)
    elif enable:
        print("SDDM shows at the next start of the computer")
    if not shutil.which("sddm", path=env.get("PATH")):
        print("note: SDDM is not installed; install it (e.g. sudo pacman -S sddm)", file=sys.stderr)
    return 0


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
        print(build(args.name, args.dest, paths))
        return 0
    except (OSError, ValueError, SettingsError, PaletteError, TemplateError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
