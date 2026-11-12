"""Builds the LOGOS table of quickshell/components/logos.js from Simple Icons
(CC0-1.0): the logo of each distro, one SVG path in a 24x24 box.

Usage: npm pack simple-icons@16.37.0 && tar xzf simple-icons-16.37.0.tgz
       python3 tools/import_logos.py package/icons
Keys are the ID of /etc/os-release; several IDs can share a logo.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# os-release ID -> Simple Icons file name
LOGOS = {
    "arch": "archlinux", "artix": "artixlinux", "endeavouros": "endeavouros", "manjaro": "manjaro",
    "garuda": "garudalinux", "fedora": "fedora", "nobara": "nobaralinux", "rhel": "redhat",
    "centos": "centos", "rocky": "rockylinux", "almalinux": "almalinux", "debian": "debian",
    "ubuntu": "ubuntu", "linuxmint": "linuxmint", "pop": "popos", "elementary": "elementary",
    "zorin": "zorin", "kali": "kalilinux", "neon": "kdeneon", "mx": "mxlinux",
    "opensuse": "opensuse", "opensuse-tumbleweed": "opensuse", "opensuse-leap": "opensuse",
    "nixos": "nixos", "gentoo": "gentoo", "void": "voidlinux", "alpine": "alpinelinux",
    "slackware": "slackware", "asahi": "asahilinux", "openbsd": "openbsd", "freebsd": "freebsd",
    "cachyos": "cachyos",
    "linux": "linux",   # Tux: any other Linux
}


def main(icons: Path) -> int:
    lines = []
    for distro, name in LOGOS.items():
        svg = (icons / f"{name}.svg").read_text()
        paths = re.findall(r'<path d="([^"]+)"', svg)
        if len(paths) != 1:
            raise SystemExit(f"{name}: expected one path, found {len(paths)}")
        lines.append(f'    "{distro}": "{paths[0]}",')
    target = ROOT / "quickshell/components/logos.js"
    text = target.read_text()
    start = text.index("const LOGOS = {\n") + len("const LOGOS = {\n")
    end = text.index("\n};", start)
    target.write_text(text[:start] + "\n".join(lines) + text[end:])
    print(f"{len(lines)} logos -> {target.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1])))
