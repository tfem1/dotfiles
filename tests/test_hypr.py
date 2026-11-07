"""Checks of the Hyprland config, run inside a fake `hl` API (tests/lua/check_hypr.lua)."""
import json
import shutil
import subprocess
import unittest
from collections import Counter

from helpers import REPO

LUA = shutil.which("lua5.4") or shutil.which("lua")

# Every key the roadmap promises (Serpantinum's layout plus SUPER + slash).
EXPECTED_KEYS = {
    "SUPER + RETURN", "SUPER + F", "SUPER + E", "SUPER + Q", "SUPER + ALT + F", "SUPER + SHIFT + F",
    "SUPER + Left", "SUPER + CTRL + Left", "SUPER + SHIFT + Left", "SUPER + mouse:272", "SUPER + mouse:273",
    "SUPER + 1", "SUPER + 0", "SUPER + SHIFT + 1", "SUPER + SHIFT + 0",
    "SUPER + D", "SUPER + B", "SUPER + M", "SUPER + W", "SUPER + S", "SUPER + N", "SUPER + V",
    "SUPER + C", "SUPER + H", "SUPER + slash", "SUPER + A", "SUPER + R", "SUPER + L", "XF86PowerOff",
    "SUPER + SPACE", "XF86AudioPlay", "XF86AudioNext", "XF86AudioRaiseVolume", "XF86AudioMute",
    "XF86AudioMicMute", "XF86MonBrightnessUp", "Print", "SHIFT + Print", "SUPER + Print",
    "SUPER + SHIFT + Print",
}


@unittest.skipUnless(LUA, "lua not installed")
class HyprConfigTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        done = subprocess.run(
            [LUA, str(REPO / "tests/lua/check_hypr.lua"), str(REPO / "hypr")],
            capture_output=True, text=True, check=True,
        )
        cls.calls = [json.loads(line) for line in done.stdout.splitlines()]
        cls.binds = [c["args"] for c in cls.calls if c["call"] == "bind"]

    def calls_named(self, name):
        return [c["args"] for c in self.calls if c["call"] == name]

    def test_every_expected_key_is_bound(self):
        bound = {args[0] for args in self.binds}
        self.assertEqual(sorted(EXPECTED_KEYS - bound), [])

    def test_no_key_is_bound_twice(self):
        counts = Counter(args[0] for args in self.binds)
        self.assertEqual([key for key, n in counts.items() if n > 1], [])

    def test_every_bind_has_a_description(self):
        missing = [args[0] for args in self.binds if not (len(args) > 2 and args[2].get("description"))]
        self.assertEqual(missing, [])

    def test_shell_panels_use_quickshell_ipc_with_the_shell_name(self):
        launcher = next(args for args in self.binds if args[0] == "SUPER + D")
        self.assertEqual(launcher[1]["args"], "qs ipc -c desktop call launcher toggle")

    def test_workspace_keys_use_hyprland_dispatchers(self):
        ten = next(args for args in self.binds if args[0] == "SUPER + 0")
        self.assertEqual(ten[1], {"dispatcher": "dsp.focus", "args": {"workspace": 10}})

    def test_every_screen_gets_its_highest_refresh_rate(self):
        self.assertIn({"output": "", "mode": "highrr", "position": "auto", "scale": 1},
                      [args[0] for args in self.calls_named("monitor")])

    def test_autostart_launches_clipboard_history_and_the_shell(self):
        started = [args[0] for args in self.calls_named("exec_cmd")]
        self.assertIn("wl-paste --type image --watch cliphist store", started)
        self.assertIn("qs -c desktop -n -d", started)

    def test_three_finger_swipe_changes_workspace(self):
        self.assertIn({"fingers": 3, "direction": "horizontal", "action": "workspace"},
                      [args[0] for args in self.calls_named("gesture")])

    def test_entry_point_loads_the_generated_theme_last(self):
        text = (REPO / "hypr/hyprland.lua").read_text()
        self.assertTrue(text.rstrip().endswith('require("theme")\n-- <<< generated: hyprland <<<'))


if __name__ == "__main__":
    unittest.main()
