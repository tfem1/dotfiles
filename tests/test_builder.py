"""Tests of the color checks (hues.py) and of the theme builder (builder.py)."""
import subprocess
import sys
import unittest

from helpers import REPO
from theming.builder import BuildError, build_theme
from theming.colors import Color
from theming.hues import contrast, hue_class, hue_problems
from theming.palette import load_palette

SEEDS = sorted((REPO / "themes/seeds").glob("*.toml"))
BUILT_THEMES = sorted([*(REPO / "themes").glob("forest-*.toml"), *(REPO / "themes").glob("cat-*.toml")])


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
        self.assertGreaterEqual(contrast(theme["accents"]["accent"], theme["colors"]["base00"]), 4.5)

    def test_second_canon_color_is_kept_readable(self):
        theme = build_theme({**self.SEED, "accent3": "#1a1a40"})
        self.assertGreaterEqual(contrast(theme["accents"]["accent3"], theme["colors"]["base00"]), 4.5)
        self.assertNotIn("accent2", theme["accents"])  # derived at generation

    def test_light_variant_has_dark_text(self):
        colors = build_theme({**self.SEED, "variant": "light"})["colors"]
        self.assertGreater(contrast(colors["base00"], Color(0, 0, 0)), contrast(colors["base05"], Color(0, 0, 0)))

    def test_seed_color_on_the_wrong_slot_is_refused(self):
        with self.assertRaises(BuildError):
            build_theme({**self.SEED, "slots": {"red": "#2C4DE0"}})   # a blue as "red"


class ForestAndCatThemesTest(unittest.TestCase):
    def test_generated_files_match_the_seeds(self):
        for seeds in SEEDS:
            done = subprocess.run([sys.executable, "-m", "theming.builder", str(seeds), "--check"],
                                  cwd=REPO, env={"PYTHONPATH": str(REPO / "scripts")}, capture_output=True, text=True)
            self.assertEqual(done.returncode, 0, done.stdout + done.stderr)

    def test_pine_moss_and_tabby_pass_every_check(self):
        self.assertEqual([path.stem for path in BUILT_THEMES], ["cat-tabby", "forest-moss", "forest-pine"])
        for path in BUILT_THEMES:
            with self.subTest(theme=path.stem):
                palette = load_palette(path)
                self.assertIn(palette.family, ("Forest", "Cat"))
                self.assertEqual(hue_problems(palette.colors), [])
                self.assertIsNotNone(palette.accent)


class NoirThemeTest(unittest.TestCase):
    """Black and white, for black wallpapers: greys only, red kept for alerts."""

    def test_noir_is_black_and_white_and_readable(self):
        from theming.hues import hls
        palette = load_palette(REPO / "themes/noir.toml")
        self.assertEqual((palette.family, palette.variant), ("Mono", "dark"))
        self.assertEqual(palette.colors["base00"].hex(), "#000000")
        self.assertEqual(hue_problems(palette.colors), [])
        greys = {slot: color for slot, color in palette.colors.items() if slot != "base08"}
        greys.update(accent=palette.accent, accent2=palette.accent2, accent3=palette.accent3)
        for slot, color in greys.items():
            with self.subTest(slot=slot):
                self.assertLess(hls(color)[2], 0.01)   # no saturation: a grey
        for color in (palette.accent, palette.accent2, palette.accent3, palette.colors["base04"]):
            self.assertGreaterEqual(contrast(color, palette.colors["base00"]), 4.5)


class KnownThemesTest(unittest.TestCase):
    """Well-known palettes imported from tinted-theming (tools/import_tinted.py)."""

    def test_every_imported_theme_is_there_credited_and_readable(self):
        sys.path.insert(0, str(REPO / "tools"))
        from import_tinted import PICKS
        self.assertEqual(len(PICKS), 7)
        for name in PICKS:
            with self.subTest(theme=name):
                path = REPO / "themes" / f"{name}.toml"
                self.assertIn("tinted-theming/schemes (MIT)", path.read_text().splitlines()[0])
                palette = load_palette(path)
                self.assertEqual(hue_problems(palette.colors), [])
                self.assertGreaterEqual(contrast(palette.accent, palette.colors["base00"]), 4.5)
        self.assertTrue((REPO / "licenses/MIT-tinted-theming.txt").is_file())


class GreenThemesTest(unittest.TestCase):
    """The green themes: two official palettes, two built from forest seeds."""
    OFFICIAL = ("kanagawa", "everforest-dark-hard")

    def test_forest_files_match_their_seeds(self):
        done = subprocess.run([sys.executable, "-m", "theming.builder", str(REPO / "themes/seeds/forest.toml"),
                               "--check"], cwd=REPO, env={"PYTHONPATH": str(REPO / "scripts")},
                              capture_output=True, text=True)
        self.assertEqual(done.returncode, 0, done.stdout + done.stderr)

    def test_every_green_theme_is_green_and_well_formed(self):
        names = [*self.OFFICIAL, *(p.stem for p in sorted((REPO / "themes").glob("forest-*.toml")))]
        self.assertEqual(len(names), 4)
        for name in names:
            with self.subTest(theme=name):
                palette = load_palette(REPO / "themes" / f"{name}.toml")
                self.assertEqual(hue_problems(palette.colors), [])
                self.assertEqual(hue_class(palette.accent), "green")
                self.assertGreaterEqual(contrast(palette.colors["base05"], palette.colors["base00"]), 7)

    def test_every_theme_keeps_each_hue_in_its_slot(self):
        for path in sorted((REPO / "themes").glob("*.toml")):
            with self.subTest(theme=path.stem):
                self.assertEqual(hue_problems(load_palette(path).colors), [])


if __name__ == "__main__":
    unittest.main()
