"""Tests of the wallpaper collection and of scripts/wallpapers.py (downloads against a local server)."""
import contextlib
import functools
import io
import json
import http.server
import os
import subprocess
import sys
import tempfile
import threading
import tomllib
import unittest
from pathlib import Path

from helpers import REPO, SandboxTest

sys.path.insert(0, str(REPO / "scripts"))
from wallpapers import load_collection, main as wallpapers_main  # noqa: E402

FIXTURE = """
[forest]
wallpapers = [ { id = "abc123", ext = "jpg", size = "1920x1080" } ]
[pony]
wallpapers = [ { id = "xyz789", ext = "png", size = "1920x1080" } ]
"""


class CollectionTest(unittest.TestCase):
    def test_at_least_fifty_wallpapers_mostly_pony(self):
        entries = load_collection(REPO / "wallpapers/collection.toml")
        categories = [category for category, _, _ in entries]
        self.assertGreaterEqual(len(entries), 50)
        self.assertGreater(categories.count("pony"), len(entries) / 2)

    def test_every_wallpaper_is_listed_once(self):
        ids = [wallpaper_id for _, wallpaper_id, _ in load_collection(REPO / "wallpapers/collection.toml")]
        self.assertEqual(len(ids), len(set(ids)))

    def test_installer_default_wallpaper_is_in_the_collection(self):
        deploy = (REPO / "install/deploy.sh").read_text()
        with (REPO / "wallpapers/collection.toml").open("rb") as handle:
            pony = {f"pony/wallhaven-{w['id']}.{w['ext']}" for w in tomllib.load(handle)["pony"]["wallpapers"]}
        self.assertTrue(any(f'DEFAULT_WALLPAPER="{name}"' in deploy for name in pony))


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


class FetchTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        root = Path(self._tmp.name)
        self.served = root / "served"
        image = self.served / "full/ab/wallhaven-abc123.jpg"
        image.parent.mkdir(parents=True)
        image.write_bytes(b"JPEG")
        self.collection = root / "collection.toml"
        self.collection.write_text(FIXTURE)
        self.dest = root / "Wallpapers"
        handler = functools.partial(QuietHandler, directory=str(self.served))
        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self._tmp.cleanup()

    def fetch(self, *args):
        env = {**os.environ, "TFEM_WALLPAPER_BASE": f"http://127.0.0.1:{self.server.server_port}",
               "NO_PROXY": "127.0.0.1", "no_proxy": "127.0.0.1"}
        command = [sys.executable, str(REPO / "scripts/wallpapers.py"), "fetch",
                   "--collection", str(self.collection), "--dest", str(self.dest), *args]
        done = subprocess.run(command, env=env, capture_output=True, text=True, timeout=60)
        return done.returncode, done.stdout + done.stderr

    def test_downloads_into_category_folders(self):
        self.fetch("--category", "forest")
        self.assertEqual((self.dest / "forest/wallhaven-abc123.jpg").read_bytes(), b"JPEG")

    def test_existing_files_are_kept(self):
        self.fetch("--category", "forest")
        code, output = self.fetch("--category", "forest")
        self.assertEqual(code, 0)
        self.assertIn("0 downloaded, 1 already there", output)

    def test_missing_image_fails_without_stopping_the_others(self):
        code, output = self.fetch()
        self.assertEqual(code, 2)
        self.assertIn("1 downloaded, 0 already there, 1 failed", output)
        self.assertFalse(list(self.dest.rglob("*.part")))

    def test_dry_run_downloads_nothing(self):
        code, output = self.fetch("--dry-run")
        self.assertEqual(code, 0)
        self.assertIn("would download", output)
        self.assertFalse(self.dest.exists())

    def test_invalid_collection_is_refused(self):
        self.collection.write_text('[forest]\nwallpapers = [ { id = "../../etc", ext = "jpg" } ]\n')
        code, output = self.fetch()
        self.assertEqual(code, 1)
        self.assertIn("invalid wallpaper", output)


class ListAndSetTest(SandboxTest):
    def setUp(self):
        super().setUp()
        self.folder = self.home / "Pictures/Wallpapers"
        for name in ("pony/b.jpg", "pony/A.png", "forest/c.webp", "loose.jpeg", "pony/notes.txt"):
            (self.folder / name).parent.mkdir(parents=True, exist_ok=True)
            (self.folder / name).write_bytes(b"not really an image")
        # A stand-in `qs`: the shell's theme.json is only written when Quickshell is there.
        bin_dir = self.home / "bin"
        bin_dir.mkdir()
        (bin_dir / "qs").write_text("#!/bin/sh\n")
        (bin_dir / "qs").chmod(0o755)
        self.env["PATH"] = str(bin_dir)

    def run_main(self, *args):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            code = wallpapers_main(list(args), env=self.env)
        return code, out.getvalue()

    def test_list_gives_every_image_by_category_then_name(self):
        code, output = self.run_main("list", "--json")
        self.assertEqual(code, 0)
        found = [(image["category"], image["name"]) for image in json.loads(output)]
        self.assertEqual(found, [("", "loose"), ("forest", "c"), ("pony", "A"), ("pony", "b")])

    def test_set_saves_a_relative_path_and_updates_the_shell(self):
        settings = self.home / ".config/tfem/theme.toml"
        settings.parent.mkdir(parents=True)
        settings.write_text('# mine\n[font]\nsize = 12\n')
        code, output = self.run_main("set", str(self.folder / "pony/b.jpg"))
        self.assertEqual(code, 0, output)
        self.assertEqual(tomllib.loads(settings.read_text()),
                         {"font": {"size": 12}, "wallpaper": {"path": "pony/b.jpg"}})
        self.assertTrue(settings.read_text().startswith("# mine\n"))
        shell = json.loads((self.home / ".config/quickshell/desktop/theme.json").read_text())
        self.assertEqual(shell["wallpaper"], str(self.folder / "pony/b.jpg"))

    def test_set_accepts_a_path_inside_the_wallpaper_folder(self):
        code, _ = self.run_main("set", "forest/c.webp")
        self.assertEqual(code, 0)
        settings = tomllib.loads((self.home / ".config/tfem/theme.toml").read_text())
        self.assertEqual(settings["wallpaper"]["path"], "forest/c.webp")

    def test_set_refuses_what_is_not_an_image(self):
        for target in ("pony/notes.txt", "pony/missing.jpg"):
            with self.subTest(target=target):
                code, output = self.run_main("set", target)
                self.assertEqual(code, 1)
                self.assertIn("not an image", output)
        self.assertFalse((self.home / ".config/tfem/theme.toml").exists())


if __name__ == "__main__":
    unittest.main()
