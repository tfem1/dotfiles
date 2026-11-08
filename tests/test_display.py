"""Screens: modes from `hyprctl monitors -j`, config.json display.modes, the
generated display.lua and `tfem display` (with a fake hyprctl)."""
import contextlib
import io
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from helpers import REPO, SandboxTest
from theming.display import lua_rules, monitors
from theming.settings import SettingsError, load_config

from display import main as display_main  # noqa: E402

LUA = shutil.which("lua5.4") or shutil.which("lua")

# As Hyprland lists them: biggest resolution first, some rates twice or skewed.
HYPRCTL = [{
    "name": "DP-1", "description": "Dell Inc. DELL S2721DGF", "width": 2560, "height": 1440,
    "refreshRate": 143.97200, "availableModes": [
        "2560x1440@165.08Hz", "2560x1440@143.97Hz", "2560x1440@120.00Hz", "2560x1440@119.99Hz",
        "2560x1440@59.95Hz", "1920x1080@60.00Hz", "1920x1080@144.00Hz", "1280x720@60.00Hz", "nonsense",
    ],
}]


class ModesTest(unittest.TestCase):
    def test_modes_are_grouped_by_resolution_fastest_first(self):
        screen = monitors(HYPRCTL)[0]
        self.assertEqual((screen["name"], screen["current"], screen["size"]),
                         ("DP-1", "2560x1440@143.97", "2560x1440"))
        self.assertEqual([r["size"] for r in screen["resolutions"]], ["2560x1440", "1920x1080", "1280x720"])
        rates = screen["resolutions"][0]["rates"]
        # 120.00 and 119.99 are one choice: the higher one, exactly as listed.
        self.assertEqual([(r["label"], r["mode"]) for r in rates], [
            ("165 Hz", "2560x1440@165.08"), ("144 Hz", "2560x1440@143.97"),
            ("120 Hz", "2560x1440@120.00"), ("60 Hz", "2560x1440@59.95"),
        ])
        self.assertEqual([r["label"] for r in screen["resolutions"][1]["rates"]], ["144 Hz", "60 Hz"])

    def test_rules_name_each_screen_and_keep_the_others_automatic(self):
        self.assertIn("No mode picked", lua_rules({}))
        self.assertEqual(lua_rules({"DP-1": "2560x1440@165.08"}),
                         'hl.monitor({ output = "DP-1", mode = "2560x1440@165.08", position = "auto", scale = 1 })')


class ConfigTest(SandboxTest):
    def test_display_modes_are_checked(self):
        self.write_user_file("config.json", json.dumps({"display": {"modes": {"DP-1": "2560x1440@165.08"}}}))
        self.assertEqual(load_config(self.paths)["display.modes.DP-1"], "2560x1440@165.08")
        for modes, problem in (({"DP-1": "fast"}, "screen mode"), ({"DP 1": "1920x1080@60"}, "unknown key")):
            with self.subTest(modes=modes):
                self.write_user_file("config.json", json.dumps({"display": {"modes": modes}}))
                with self.assertRaisesRegex(SettingsError, problem):
                    load_config(self.paths)


class CommandTest(SandboxTest):
    def setUp(self):
        super().setUp()
        bin_dir = self.home / "bin"
        bin_dir.mkdir()
        for name, body in (("hyprctl", f"echo \"hyprctl $*\" >> {self.home}/calls.log\n"
                                       f"[ \"$1\" = monitors ] && cat {self.home}/monitors.json; exit 0"),
                           ("Hyprland", "exit 0")):
            (bin_dir / name).write_text(f"#!/bin/sh\n{body}\n")
            (bin_dir / name).chmod(0o755)
        (self.home / "monitors.json").write_text(json.dumps(HYPRCTL))
        self.env["PATH"] = f"{bin_dir}:/usr/bin:/bin"

    def run_display(self, *args):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            code = display_main(list(args), env=self.env)
        return code, out.getvalue()

    def test_list_shows_the_screens_and_the_picked_modes(self):
        code, output = self.run_display("list")
        self.assertEqual(code, 0, output)
        listing = json.loads(output)
        self.assertEqual(listing["monitors"][0]["name"], "DP-1")
        self.assertEqual(listing["chosen"], {})

    def test_set_writes_the_rule_and_reloads_hyprland(self):
        code, output = self.run_display("set", "DP-1", "2560x1440@165.08")
        self.assertEqual(code, 0, output)
        config = json.loads((self.paths.user_dir / "config.json").read_text())
        self.assertEqual(config["display"]["modes"], {"DP-1": "2560x1440@165.08"})
        rules = (self.paths.config_home / "hypr/display.lua").read_text()
        self.assertIn('output = "DP-1", mode = "2560x1440@165.08"', rules)
        self.assertIn("hyprctl reload", (self.home / "calls.log").read_text())
        code, _ = self.run_display("auto", "DP-1")
        self.assertEqual(code, 0)
        self.assertNotIn("DP-1", (self.paths.config_home / "hypr/display.lua").read_text())

    def test_bad_names_and_modes_are_refused(self):
        self.assertEqual(self.run_display("set", "DP-1", "fast")[0], 1)
        self.assertEqual(self.run_display("set", "../x", "1920x1080@60")[0], 1)
        self.assertEqual(self.run_display("set", "DP-1")[0], 64)
        self.assertFalse((self.paths.user_dir / "config.json").exists())


@unittest.skipUnless(LUA, "lua not installed")
class HyprlandLoadsTheRulesTest(unittest.TestCase):
    def test_monitors_lua_loads_display_lua_when_it_exists(self):
        with tempfile.TemporaryDirectory() as temp:
            hypr = Path(temp) / "hypr"
            shutil.copytree(REPO / "hypr", hypr)

            def monitor_calls():
                done = subprocess.run([LUA, str(REPO / "tests/lua/check_hypr.lua"), str(hypr)],
                                      capture_output=True, text=True, check=True)
                calls = [json.loads(line) for line in done.stdout.splitlines()]
                return [c["args"][0]["output"] for c in calls if c["call"] == "monitor"]

            self.assertEqual(monitor_calls(), [""])  # not generated yet: no error
            (hypr / "display.lua").write_text(lua_rules({"DP-1": "2560x1440@165.08"}) + "\n")
            self.assertEqual(monitor_calls(), ["", "DP-1"])


if __name__ == "__main__":
    unittest.main(argv=sys.argv)
