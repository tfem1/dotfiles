"""Tests of the color checks (hues.py) and of the theme builder (builder.py)."""
import subprocess
import sys
import unittest

from helpers import REPO
from theming.builder import BuildError, build_theme
from theming.colors import Color
from theming.hues import contrast, hue_class, hue_problems
from theming.palette import load_palette

SEEDS = REPO / "themes/seeds/pony.toml"
PONY_THEMES = sorted((REPO / "themes").glob("pony-*.toml"))


class HueTest(unittest.TestCase):
    def test_colors_are_classified_on_the_wheel(self):
        self.assertEqual(hue_class(Color.parse("#f38ba8")), "red")      # pinkish red
        self.assertEqual(hue_class(Color.parse("#83a598")), "cyan")     # Gruvbox "blue"
        self.assertIsNone(hue_class(Color.parse("#808080")))            # grey: no hue

    def test_neighbouring_hue_is_accepted_far_one_is_not(self):
        colors = {"base08": Color.parse("#c0caf5")}                     # Tokyo Night "red"
        self.assertEqual(hue_problems(colors), ["base08 should be red, looks blue"])
        self.assertEqual(hue_problems({"base0D": Color.parse("#83a598")}), [])

    def test_contrast_follows_wcag(self):
        self.assertAlmostEqual(contrast(Color(0, 0, 0), Color(255, 255, 255)), 21.0)
        self.assertAlmostEqual(contrast(Color(10, 10, 10), Color(10, 10, 10)), 1.0)


class BuilderTest(unittest.TestCase):
    SEED = {"name": "Test", "variant": "dark", "tint": "#273873", "text": "#D19FE4",
            "accent": "#662D8A", "slots": {"pink": "#ED438D"}}

    def test_built_theme_is_readable(self):
        colors = build_theme(self.SEED)["colors"]
        self.assertGreaterEqual(contrast(colors["base05"], colors["base00"]), 7)
        for slot in ("base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F"):
            with self.subTest(slot=slot):
                self.assertGreaterEqual(contrast(colors[slot], colors["base00"]), 4.5)

    def test_dark_accent_is_lightened_until_readable(self):
        theme = build_theme(self.SEED)
        self.assertGreaterEqual(contrast(theme["accent"], theme["colors"]["base00"]), 4.5)

    def test_light_variant_has_dark_text(self):
        colors = build_theme({**self.SEED, "variant": "light"})["colors"]
        self.assertGreater(contrast(colors["base00"], Color(0, 0, 0)), contrast(colors["base05"], Color(0, 0, 0)))

    def test_seed_color_on_the_wrong_slot_is_refused(self):
        with self.assertRaises(BuildError):
            build_theme({**self.SEED, "slots": {"red": "#2C4DE0"}})   # a blue as "red"


class PonyThemesTest(unittest.TestCase):
    def test_generated_files_match_the_seeds(self):
        done = subprocess.run([sys.executable, "-m", "theming.builder", str(SEEDS), "--check"],
                              cwd=REPO, env={"PYTHONPATH": str(REPO / "scripts")}, capture_output=True, text=True)
        self.assertEqual(done.returncode, 0, done.stdout + done.stderr)

    def test_ten_pony_themes_pass_every_check(self):
        self.assertEqual(len(PONY_THEMES), 10)
        for path in PONY_THEMES:
            with self.subTest(theme=path.stem):
                palette = load_palette(path)
                self.assertEqual(palette.family, "Pony")
                self.assertEqual(hue_problems(palette.colors), [])
                self.assertIsNotNone(palette.accent)


if __name__ == "__main__":
    unittest.main()
