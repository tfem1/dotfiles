"""Tests du chargement des réglages : fusion avec les défauts et validation."""
import unittest

from helpers import SandboxTest
from theming.schema import THEME_SCHEMA
from theming.settings import SettingsError, load_config, load_theme


class DefaultsTest(SandboxTest):
    def test_repo_defaults_are_valid(self):
        load_theme(self.paths)
        load_config(self.paths)

    def test_defaults_cover_every_schema_key(self):
        self.assertEqual(set(load_theme(self.paths)), set(THEME_SCHEMA))

    def test_paths_follow_xdg(self):
        self.assertEqual(self.paths.user_dir, self.home / ".config/tfem")
        self.assertEqual(self.paths.state_dir, self.home / ".local/state/tfem")


class UserFileTest(SandboxTest):
    def test_user_values_replace_defaults_key_by_key(self):
        self.write_user_file("theme.toml", "[shape]\nradius = 4\n")
        theme = load_theme(self.paths)
        self.assertEqual(theme["shape.radius"], 4)
        self.assertEqual(theme["shape.border"], 2)

    def test_overrides_are_accepted(self):
        self.write_user_file("theme.toml", '[palette.overrides]\nbase00 = "#000000"\n')
        self.assertEqual(load_theme(self.paths)["palette.overrides.base00"], "#000000")

    def test_user_config_json_is_merged(self):
        self.write_user_file("config.json", '{"shell": {"name": "aurora"}}')
        self.assertEqual(load_config(self.paths)["shell.name"], "aurora")


class ValidationTest(SandboxTest):
    def problems_for(self, text, name="theme.toml"):
        self.write_user_file(name, text)
        loader = load_theme if name == "theme.toml" else load_config
        with self.assertRaises(SettingsError) as caught:
            loader(self.paths)
        return "\n".join(caught.exception.problems)

    def test_reports_out_of_range_with_dotted_key(self):
        self.assertIn("shape.radius: doit être entre 0 et 32", self.problems_for("[shape]\nradius = 99\n"))

    def test_reports_wrong_type(self):
        self.assertIn("effects.blur: doit valoir true ou false", self.problems_for('[effects]\nblur = "yes"\n'))

    def test_reports_all_problems_at_once(self):
        problems = self.problems_for("[shape]\nradius = -1\nborder = 50\n")
        self.assertIn("shape.radius", problems)
        self.assertIn("shape.border", problems)

    def test_unknown_key_suggests_the_right_one(self):
        self.assertIn("tu voulais dire 'shape.radius'", self.problems_for("[shape]\nradus = 3\n"))

    def test_unknown_override_slot(self):
        self.assertIn("palette.overrides.base10", self.problems_for('[palette.overrides]\nbase10 = "#000000"\n'))

    def test_invalid_override_color(self):
        self.assertIn("couleur invalide", self.problems_for('[palette.overrides]\nbase00 = "black"\n'))

    def test_module_color_must_be_a_hue(self):
        self.assertIn("modules.wifi: doit être l'une de ces valeurs", self.problems_for('[modules]\nwifi = "pink"\n'))

    def test_empty_font_is_rejected(self):
        self.assertIn("font.sans: ne doit pas être vide", self.problems_for('[font]\nsans = ""\n'))

    def test_newer_format_version_is_refused(self):
        self.assertIn("version de format 9", self.problems_for("schema = 9\n"))

    def test_broken_toml_points_to_the_file(self):
        self.assertIn("theme.toml", self.problems_for("[shape\nradius = 1\n"))

    def test_shell_name_must_be_a_safe_directory_name(self):
        self.assertIn("shell.name", self.problems_for('{"shell": {"name": "../x"}}', "config.json"))


if __name__ == "__main__":
    unittest.main()
