"""scripts/settings.py: what the Settings window reads and how it writes."""
import contextlib
import io
import json
import sys
import tomllib

from helpers import REPO, SandboxTest

sys.path.insert(0, str(REPO / "scripts"))
from settings import main as settings_main  # noqa: E402


class SettingsCommandTest(SandboxTest):
    def run_main(self, *args):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            code = settings_main(list(args), env=self.env)
        return code, out.getvalue()

    def test_get_gives_values_fields_and_every_theme_with_its_colors(self):
        code, output = self.run_main("get")
        self.assertEqual(code, 0, output)
        data = json.loads(output)
        self.assertEqual(data["values"]["palette.source"], "forest-pine")
        self.assertEqual(data["values"]["idle.lock"], 10)
        self.assertEqual(data["fields"]["shape.radius"]["high"], 32)
        themes = {theme["id"]: theme for theme in data["themes"]}
        self.assertEqual(len(themes), len(list((REPO / "themes").glob("*.toml"))))
        self.assertEqual(themes["forest-pine"]["colors"]["accent"], "#8fd18c")
        self.assertEqual(set(themes["dracula"]["colors"]), {
            "bg", "bgAlt", "surface", "muted", "subtle", "fg", "fgBright", "accent", "accent2", "accent3",
            "red", "orange", "yellow", "green", "cyan", "blue", "purple", "brown"})
        self.assertEqual(data["folders"]["violet"], "#7749b5")
        self.assertEqual(data["themes"][0]["family"], "Cat")   # cat and forest first

    def test_set_writes_typed_values_in_the_right_file(self):
        self.write_user_file("theme.toml", "# mine\n[font]\nsize = 12\n")
        code, output = self.run_main("set", "shape.radius=8", "effects.game_mode=on", "idle.suspend=0",
                                     "palette.source=dracula", "--no-generate")
        self.assertEqual(code, 0, output)
        text = (self.paths.user_dir / "theme.toml").read_text()
        self.assertTrue(text.startswith("# mine\n"))
        theme = tomllib.loads(text)
        self.assertEqual(theme["shape"]["radius"], 8)
        self.assertIs(theme["effects"]["game_mode"], True)
        self.assertEqual(theme["palette"]["source"], "dracula")
        self.assertEqual(json.loads((self.paths.user_dir / "config.json").read_text()), {"idle": {"suspend": 0}})

    def test_a_new_corner_replaces_the_old_side_in_the_file(self):
        self.write_user_file("config.json", '{"widgets": {"side": "right", "cpu": false}}')
        code, output = self.run_main("set", "widgets.corner=bottom-right", "--no-generate")
        self.assertEqual(code, 0, output)
        self.assertEqual(json.loads((self.paths.user_dir / "config.json").read_text()),
                         {"widgets": {"corner": "bottom-right", "cpu": False}})

    def test_bad_values_change_nothing(self):
        for pair, message in (("shape.radius=99", "between 0 and 32"), ("effects.blur=maybe", "true or false"),
                              ("nope.key=1", "unknown setting"), ("palette.accent=pink", "must be one of")):
            with self.subTest(pair=pair):
                code, output = self.run_main("set", "shape.radius=4", pair, "--no-generate")
                self.assertEqual(code, 1)
                self.assertIn(message, output)
        self.assertFalse((self.paths.user_dir / "theme.toml").exists())

    def test_set_regenerates(self):
        code, output = self.run_main("set", "effects.game_mode=true")
        self.assertEqual(code, 0, output)
        self.assertIn("Theme Pine", output)
