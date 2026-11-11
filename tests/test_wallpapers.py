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
from unittest import mock
from pathlib import Path

from helpers import REPO, SandboxTest

sys.path.insert(0, str(REPO / "scripts"))
from wallpaper_collection import Wallpaper, find, theme_for  # noqa: E402
from wallpapers import followed_theme, load_collection, main as wallpapers_main  # noqa: E402

COLLECTION = REPO / "wallpapers/collection.toml"

FIXTURE = """
removed = ["old111", "old222"]
[other]
wallpapers = [ { id = "abc123", ext = "jpg", size = "1920x1080" } ]
[cats]
wallpapers = [ { id = "xyz789", ext = "png", size = "1920x1080" } ]
"""


class CollectionTest(unittest.TestCase):
    def test_pixel_forests_mostly_and_cats(self):
        entries = load_collection(COLLECTION)
        self.assertEqual({entry.category for entry in entries}, {"forest", "cats"})
        forests = [entry for entry in entries if entry.category == "forest"]
        self.assertGreater(len(forests), len(entries) / 2)
        self.assertGreaterEqual(len(entries) - len(forests), 8)

    def test_removed_wallpapers_are_listed_for_deletion(self):
        from wallpaper_collection import removed_ids
        removed = set(removed_ids(COLLECTION))
        self.assertIn("pow2wp", removed)   # a former forest
        self.assertIn("wymvyx", removed)   # a former My Little Pony wallpaper
        self.assertFalse(removed & {entry.id for entry in load_collection(COLLECTION)})

    def test_every_wallpaper_is_listed_once(self):
        ids = [entry.id for entry in load_collection(COLLECTION)]
        self.assertEqual(len(ids), len(set(ids)))

    def test_every_wallpaper_has_an_existing_theme(self):
        for entry in load_collection(COLLECTION):
            with self.subTest(wallpaper=entry.id):
                self.assertTrue((REPO / f"themes/{entry.theme}.toml").exists())

    def test_removed_wallpapers_stay_out(self):
        ids = {entry.id for entry in load_collection(COLLECTION)}
        self.assertFalse(ids & {"kxowv6", "01jxqg", "wymvyx"})


class ThemeMatchTest(unittest.TestCase):
    WALLPAPERS = [Wallpaper("cats", "abc123", "png", "cat-tabby"), Wallpaper("forest", "grp456", "jpg")]
    SETTINGS = {"wallpaper.follow": True, "palette.source": "forest-pine"}

    def test_found_by_the_wallhaven_id_of_the_file_name(self):
        self.assertEqual(find(Path("/x/cats/wallhaven-abc123.png"), self.WALLPAPERS).theme, "cat-tabby")
        self.assertIsNone(find(Path("/x/cats/abc123.png"), self.WALLPAPERS))
        self.assertIsNone(find(Path("/x/wallhaven-zzz999.png"), self.WALLPAPERS))

    def test_theme_or_nothing(self):
        cat, group = self.WALLPAPERS
        self.assertEqual(theme_for(cat), "cat-tabby")
        self.assertIsNone(theme_for(group))
        self.assertIsNone(theme_for(None))

    def test_follow_off_or_palette_from_the_wallpaper_keeps_the_theme(self):
        image = Path("cats/wallhaven-abc123.png")
        self.assertEqual(followed_theme(image, self.WALLPAPERS, self.SETTINGS), "cat-tabby")
        self.assertIsNone(followed_theme(image, self.WALLPAPERS, {**self.SETTINGS, "wallpaper.follow": False}))
        self.assertIsNone(followed_theme(image, self.WALLPAPERS, {**self.SETTINGS, "palette.source": "wallpaper"}))

    def test_invalid_theme_is_refused(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "collection.toml"
            path.write_text('[cats]\nwallpapers = [ { id = "abc123", ext = "png", theme = "../x" } ]\n')
            with self.assertRaisesRegex(ValueError, "invalid wallpaper"):
                load_collection(path)

    def test_installer_default_wallpaper_is_in_the_collection(self):
        deploy = (REPO / "install/deploy.sh").read_text()
        with (REPO / "wallpapers/collection.toml").open("rb") as handle:
            forest = {f"forest/wallhaven-{w['id']}.{w['ext']}" for w in tomllib.load(handle)["forest"]["wallpapers"]}
        self.assertTrue(any(f'DEFAULT_WALLPAPER="{name}"' in deploy for name in forest))


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
        self.fetch("--category", "other")
        self.assertEqual((self.dest / "other/wallhaven-abc123.jpg").read_bytes(), b"JPEG")

    def test_existing_files_are_kept(self):
        self.fetch("--category", "other")
        code, output = self.fetch("--category", "other")
        self.assertEqual(code, 0)
        self.assertIn("0 downloaded, 1 already there", output)

    def test_missing_image_fails_without_stopping_the_others(self):
        code, output = self.fetch()
        self.assertEqual(code, 2)
        self.assertIn("1 downloaded, 0 already there, 1 failed", output)
        self.assertFalse(list(self.dest.rglob("*.part")))

    def test_old_downloads_are_deleted_and_nothing_else(self):
        for name in ("forest/wallhaven-old111.jpg", "pony/wallhaven-old222.png", "pony/wallhaven-xyz789.png",
                     "pony/mine.png", "forest-mine/wallhaven-keep99.jpg"):
            (self.dest / name).parent.mkdir(parents=True, exist_ok=True)
            (self.dest / name).write_bytes(b"x")
        (self.dest / "empty-but-mine").mkdir()
        code, output = self.fetch("--category", "other")
        self.assertIn("2 wallpapers no longer in the collection deleted", output)
        self.assertFalse((self.dest / "forest").exists())        # emptied by the cleanup
        self.assertFalse((self.dest / "pony/wallhaven-old222.png").exists())
        for kept in ("pony/wallhaven-xyz789.png", "pony/mine.png", "forest-mine/wallhaven-keep99.jpg",
                     "empty-but-mine"):
            self.assertTrue((self.dest / kept).exists(), kept)

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

    def add(self, name):
        (self.folder / name).parent.mkdir(parents=True, exist_ok=True)
        (self.folder / name).write_bytes(b"not really an image")

    def shell_theme(self):
        return json.loads((self.home / ".config/quickshell/desktop/theme.json").read_text())

    def test_set_a_wallpaper_of_the_collection_switches_to_its_theme(self):
        self.add("cats/wallhaven-2y6zl6.png")   # a cat asleep on a car
        code, output = self.run_main("set", "cats/wallhaven-2y6zl6.png")
        self.assertEqual(code, 0, output)
        self.assertIn("theme: cat-tabby", output)
        settings = tomllib.loads((self.home / ".config/tfem/theme.toml").read_text())
        self.assertEqual(settings["palette"]["source"], "cat-tabby")
        self.assertEqual(self.shell_theme()["palette"]["name"], "Tabby")

    def test_follow_off_keeps_the_theme(self):
        self.add("cats/wallhaven-2y6zl6.png")
        settings = self.home / ".config/tfem/theme.toml"
        settings.parent.mkdir(parents=True)
        settings.write_text("[wallpaper]\nfollow = false\n")
        code, output = self.run_main("set", "cats/wallhaven-2y6zl6.png")
        self.assertEqual(code, 0, output)
        self.assertNotIn("palette", tomllib.loads(settings.read_text()))

    def test_missing_theme_keeps_the_theme_with_a_warning(self):
        self.add("cats/wallhaven-abc123.png")
        collection = self.home / "collection.toml"
        collection.write_text('[cats]\nwallpapers = [ { id = "abc123", ext = "png", theme = "cat-ghost" } ]\n')
        with mock.patch("wallpapers.COLLECTION", collection):
            code, output = self.run_main("set", "cats/wallhaven-abc123.png")
        self.assertEqual(code, 0, output)
        self.assertIn("'cat-ghost' not found", output)
        self.assertNotIn("palette", tomllib.loads((self.home / ".config/tfem/theme.toml").read_text()))

    def test_list_names_the_theme_each_wallpaper_brings(self):
        self.add("cats/wallhaven-2y6zl6.png")
        code, output = self.run_main("list", "--json")
        self.assertEqual(code, 0, output)
        themes = {image["name"]: image["theme"] for image in json.loads(output)}
        self.assertEqual(themes["wallhaven-2y6zl6"], "Tabby")
        self.assertEqual(themes["b"], "")

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
