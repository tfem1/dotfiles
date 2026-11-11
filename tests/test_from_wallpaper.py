"""A theme made from a wallpaper's main colors (theming/from_wallpaper.py)."""
import sys
import unittest

from helpers import REPO
from theming.colors import Color
from theming.from_wallpaper import seed, theme_text
from theming.hues import contrast, hue_class, hue_problems
from theming.palette import load_palette

NOIR = (REPO / "themes/noir.toml").read_text()


def colors(*hexes):
    return [Color.parse(value) for value in hexes]


class SeedTest(unittest.TestCase):
    def test_a_green_wallpaper_gives_a_green_theme(self):
        made = seed(colors("#1d271e", "#304022", "#132111", "#244603", "#6a7f61", "#485933", "#8cb4bd", "#507d19"))
        self.assertEqual(made["variant"], "dark")
        self.assertEqual(hue_class(Color.parse(made["accent"])), "green")
        self.assertEqual(hue_class(Color.parse(made["tint"])), "green")

    def test_a_blue_wallpaper_gives_a_blue_theme(self):
        made = seed(colors("#0f283c", "#a6d6ed", "#97525d", "#090e19", "#214966", "#376d8b", "#909eb3", "#472831"))
        self.assertEqual(hue_class(Color.parse(made["accent"])), "blue")
        self.assertEqual(hue_class(Color.parse(made["tint"])), "blue")

    def test_a_light_image_gets_a_light_theme(self):
        made = seed(colors("#edbdc7", "#f3b4b8", "#e9c5d4", "#f3aca6", "#e4cbdf", "#dfd2ed", "#e2cee6", "#a34a1e"))
        self.assertEqual(made["variant"], "light")
        self.assertEqual(hue_class(Color.parse(made["accent"])), "red")    # a pink image: rose

    def test_black_background_takes_the_image_hue(self):
        made = seed(colors("#000000", "#000000", "#020007", "#0907a3", "#0907a3", "#c5965b", "#000000", "#080614"))
        self.assertEqual(hue_class(Color.parse(made["tint"])), "blue")


class ThemeTest(unittest.TestCase):
    def theme(self, *hexes, path):
        path.write_text(theme_text(colors(*hexes), "test.png", NOIR))
        return load_palette(path)

    def test_the_theme_is_readable_and_well_formed(self):
        import tempfile
        from pathlib import Path
        samples = [("#1c0e36", "#3e938a", "#3f6985", "#e9f8ec"), ("#252520", "#5f724d", "#b5964b", "#865435"),
                   ("#edbdc7", "#f3b4b8", "#e9c5d4", "#a34a1e"), ("#650e4b", "#250c30", "#da166f", "#f88465")]
        with tempfile.TemporaryDirectory() as folder:
            for sample in samples:
                with self.subTest(colors=sample):
                    palette = self.theme(*sample, path=Path(folder) / "w.toml")
                    self.assertEqual(hue_problems(palette.colors), [])
                    self.assertGreaterEqual(contrast(palette.colors["base05"], palette.colors["base00"]), 7)
                    self.assertGreaterEqual(contrast(palette.accent, palette.colors["base00"]), 4.5)

    def test_a_gray_image_gets_noir(self):
        self.assertEqual(theme_text(colors("#151515", "#171717", "#191919", "#808080"), "gray.png", NOIR), NOIR)


if __name__ == "__main__":
    unittest.main(argv=sys.argv)
