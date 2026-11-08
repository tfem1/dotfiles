"""FairyWren icons: dark or light half, folder color from the accent, the
folder link switch and the download (from a local stand-in repository)."""
import contextlib
import io
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from helpers import REPO, SandboxTest, fake_fairywren
from theming.colors import Color
from theming.context import build_context
from theming.icons import folder_color, theme_name
from theming.palette import resolve_palette
from theming.settings import load_theme

sys.path.insert(0, str(REPO / "scripts"))
from icons import main as icons_main, set_folders  # noqa: E402


class ChoiceTest(unittest.TestCase):
    def test_fairywren_follows_the_palette_other_names_stay(self):
        self.assertEqual(theme_name("FairyWren", "dark"), "FairyWren_Dark")
        self.assertEqual(theme_name("FairyWren", "light"), "FairyWren_Light")
        self.assertEqual(theme_name("Papirus-Dark", "light"), "Papirus-Dark")

    def test_folder_color_is_the_closest_to_the_accent(self):
        cases = {
            "#D19FE4": "violet",      # Twilight: lavender, not white
            "#F7438C": "pink",        # Pinkie
            "#667EE8": "indigo",      # Luna's periwinkle
            "#A3DEF8": "cyan",        # Rainbow
            "#55ACF3": "breeze",      # Trixie's sky blue
            "#8CC45A": "green",       # forest Moss
            "#76946A": "pine",        # Kanagawa's sage
            "#DB2D43": "red",
            "#E76838": "deeporange",
            "#FBF9AF": "yellow",
            "#808080": "grey",
            "#F4F4F4": "white",
        }
        for accent, expected in cases.items():
            with self.subTest(accent=accent):
                self.assertEqual(folder_color(Color.parse(accent)), expected)

    def test_every_measured_color_is_a_fairywren_one(self):
        from theming.icons import _MEASURED, FOLDER_COLORS
        self.assertLessEqual(set(_MEASURED), set(FOLDER_COLORS))


class ContextTest(SandboxTest):
    def context(self, text=""):
        if text:
            self.write_user_file("theme.toml", text)
        theme = load_theme(self.paths)
        return build_context(theme, resolve_palette(theme, self.paths), self.paths)

    def test_defaults_give_fairywren_with_the_theme_folders(self):
        context = self.context()
        self.assertEqual(context["icons.name"], "FairyWren_Dark")
        self.assertEqual(context["icons.folders"], "violet")
        self.assertEqual(context["dirs.data"], str(self.home / ".local/share"))

    def test_light_theme_and_chosen_folders(self):
        context = self.context('[palette]\nsource = "forest-fern"\n[icons]\nfolders = "pine"\n')
        self.assertEqual(context["icons.name"], "FairyWren_Light")
        self.assertEqual(context["icons.folders"], "pine")

    def test_unknown_folder_color_is_refused(self):
        with self.assertRaisesRegex(Exception, "icons.folders"):
            self.context('[icons]\nfolders = "rainbow"\n')


class FoldersTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.icons = Path(self._tmp.name)
        source = self.icons / "source"
        fake_fairywren(source)
        for theme in ("FairyWren_Dark", "FairyWren_Light"):
            os.rename(source / theme, self.icons / theme)

    def tearDown(self):
        self._tmp.cleanup()

    def folder(self, theme="FairyWren_Dark"):
        return (self.icons / theme / "places/folder.svg").read_text()

    def test_the_folder_link_moves_to_the_color(self):
        self.assertIn("blue", self.folder())
        self.assertEqual(set_folders(self.icons, "pink"), ["FairyWren_Dark", "FairyWren_Light"])
        self.assertIn("pink", self.folder())
        self.assertIn("pink", self.folder("FairyWren_Light"))
        self.assertEqual(set_folders(self.icons, "pink"), [])   # already there
        self.assertFalse((self.icons / "FairyWren_Dark/places/colours/.default.new").exists())

    def test_unknown_color_changes_nothing(self):
        for color in ("rainbow", "../etc"):
            with self.subTest(color=color), self.assertRaises(ValueError):
                set_folders(self.icons, color)
        self.assertIn("blue", self.folder())

    def test_nothing_to_do_before_the_download(self):
        with tempfile.TemporaryDirectory() as empty:
            self.assertEqual(set_folders(Path(empty), "pink"), [])


class FetchTest(SandboxTest):
    def test_fetch_replaces_an_old_copy_and_keeps_the_chosen_color(self):
        url = fake_fairywren(self.home / "FairyWren-Icons")
        icons = self.home / ".local/share/icons"
        (icons / "FairyWren_Dark").mkdir(parents=True)
        (icons / "FairyWren_Dark/stale.svg").write_text("old")
        record = self.home / ".local/share/tfem/icon-folders"
        record.parent.mkdir(parents=True)
        record.write_text("# written by tfem generate\nviolet\n")
        env = {**os.environ, **self.env, "TFEM_FAIRYWREN_URL": url}
        done = subprocess.run([sys.executable, str(REPO / "scripts/icons.py"), "fetch"], env=env,
                              capture_output=True, text=True, timeout=60)
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertIn("folders: violet", done.stdout)
        self.assertFalse((icons / "FairyWren_Dark/stale.svg").exists())
        self.assertIn("violet", (icons / "FairyWren_Light/places/folder.svg").read_text())
        self.assertEqual(sorted(p.name for p in icons.iterdir()), ["FairyWren_Dark", "FairyWren_Light"])

    def test_failed_download_says_so(self):
        env = {**os.environ, **self.env, "TFEM_FAIRYWREN_URL": (self.home / "missing").as_uri()}
        done = subprocess.run([sys.executable, str(REPO / "scripts/icons.py"), "fetch"], env=env,
                              capture_output=True, text=True, timeout=60)
        self.assertEqual(done.returncode, 2)
        self.assertIn("could not download FairyWren", done.stderr)

    def test_folders_command(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            code = icons_main(["folders", "Pink!"], env=self.env)
        self.assertEqual(code, 1)
        self.assertIn("invalid folder color", out.getvalue())


if __name__ == "__main__":
    unittest.main()
