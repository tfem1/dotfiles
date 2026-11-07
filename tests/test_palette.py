"""Palette tests: theme lookup, overrides, roles and context."""
import unittest

from helpers import SandboxTest
from theming.colors import Color
from theming.context import build_context
from theming.palette import PaletteError, resolve_palette
from theming.settings import load_theme

MAUVE = Color.parse("#cba6f7")
CATPPUCCIN = '[palette]\nsource = "catppuccin-mocha"\n'


class ResolveTest(SandboxTest):
    def test_loads_default_theme(self):
        palette = resolve_palette(load_theme(self.paths), self.paths)
        self.assertEqual(palette.family, "Pony")

    def test_loads_catppuccin(self):
        self.write_user_file("theme.toml", CATPPUCCIN)
        palette = resolve_palette(load_theme(self.paths), self.paths)
        self.assertEqual(palette.name, "Catppuccin Mocha")
        self.assertEqual(palette.variant, "dark")
        self.assertEqual(palette.colors["base0E"], MAUVE)

    def test_user_theme_dir_wins_over_repo(self):
        self.write_user_file("themes/catppuccin-mocha.toml", self.theme_text("Mine"))
        self.write_user_file("theme.toml", CATPPUCCIN)
        self.assertEqual(resolve_palette(load_theme(self.paths), self.paths).name, "Mine")

    def test_overrides_replace_one_slot(self):
        self.write_user_file("theme.toml", CATPPUCCIN + '[palette.overrides]\nbase00 = "#000000"\n')
        palette = resolve_palette(load_theme(self.paths), self.paths)
        self.assertEqual(palette.colors["base00"], Color(0, 0, 0))
        self.assertEqual(palette.colors["base0E"], MAUVE)

    def test_unknown_theme_suggests_a_close_name(self):
        self.write_user_file("theme.toml", '[palette]\nsource = "catppuccin-moca"\n')
        with self.assertRaises(PaletteError) as caught:
            resolve_palette(load_theme(self.paths), self.paths)
        self.assertIn("catppuccin-mocha", str(caught.exception))

    def test_wallpaper_source_without_extraction_explains_why(self):
        self.write_user_file("theme.toml", '[palette]\nsource = "wallpaper"\n')
        with self.assertRaises(PaletteError) as caught:
            resolve_palette(load_theme(self.paths), self.paths)
        self.assertIn("wallpaper", str(caught.exception))

    def test_incomplete_theme_file_is_rejected(self):
        self.write_user_file("themes/broken.toml", 'name = "Broken"\nvariant = "dark"\n[colors]\nbase00 = "#000000"\n')
        self.write_user_file("theme.toml", '[palette]\nsource = "broken"\n')
        with self.assertRaises(PaletteError) as caught:
            resolve_palette(load_theme(self.paths), self.paths)
        self.assertIn("base0F", str(caught.exception))

    @staticmethod
    def theme_text(name):
        colors = "\n".join(f'base0{d} = "#111111"' for d in "0123456789ABCDEF")
        return f'name = "{name}"\nvariant = "dark"\n[colors]\n{colors}\n'


class ContextTest(SandboxTest):
    def context(self, user_toml=""):
        if user_toml:
            self.write_user_file("theme.toml", user_toml)
        theme = load_theme(self.paths)
        return build_context(theme, resolve_palette(theme, self.paths), self.paths)

    def test_roles_follow_base16(self):
        ctx = self.context()
        self.assertEqual(ctx["bg"], ctx["base00"])
        self.assertEqual(ctx["fg"], ctx["base05"])
        self.assertEqual(ctx["purple"], ctx["base0E"])

    def test_ansi_mapping_matches_tinted_shell(self):
        ctx = self.context()
        self.assertEqual(ctx["ansi1"], ctx["base08"])
        self.assertEqual(ctx["ansi8"], ctx["base03"])
        self.assertEqual(ctx["ansi15"], ctx["base07"])

    def test_accent_resolves_to_its_hue(self):
        ctx = self.context('[palette]\naccent = "blue"\n')
        self.assertEqual(ctx["accent"], ctx["blue"])
        self.assertEqual(ctx["palette.accent"], ctx["blue"])

    def test_module_colors_are_resolved(self):
        ctx = self.context('[modules]\nwifi = "red"\nclock = "accent"\n')
        self.assertEqual(ctx["modules.wifi"], ctx["red"])
        self.assertEqual(ctx["modules.clock"], ctx["accent"])

    def test_module_colors_follow_theme_changes(self):
        self.write_user_file("themes/other.toml", ResolveTest.theme_text("Other"))
        ctx = self.context('[palette]\nsource = "other"\n')
        self.assertEqual(ctx["modules.wifi"], Color(0x11, 0x11, 0x11))

    def test_relative_wallpaper_is_made_absolute(self):
        ctx = self.context('[wallpaper]\npath = "forest/lake.jpg"\n')
        self.assertEqual(ctx["wallpaper.path"], str(self.home / "Pictures/Wallpapers/forest/lake.jpg"))

    def test_tilde_wallpaper_uses_home(self):
        ctx = self.context('[wallpaper]\npath = "~/Pictures/a.png"\n')
        self.assertEqual(ctx["wallpaper.path"], str(self.home / "Pictures/a.png"))

    def test_theme_accent_is_the_signature_color(self):
        ctx = self.context('[palette]\nsource = "pony-pinkie"\n')
        signature = resolve_palette(load_theme(self.paths), self.paths).accent
        self.assertEqual(ctx["accent"], signature)
        self.assertNotEqual(ctx["accent"], ctx["purple"])  # pink, not her purple slot

    def test_theme_without_signature_uses_its_purple(self):
        ctx = self.context(CATPPUCCIN)
        self.assertEqual(ctx["accent"], MAUVE)

    def test_palette_metadata_is_exposed(self):
        ctx = self.context(CATPPUCCIN)
        self.assertEqual(ctx["palette.name"], "Catppuccin Mocha")
        self.assertEqual(ctx["palette.variant"], "dark")


if __name__ == "__main__":
    unittest.main()
