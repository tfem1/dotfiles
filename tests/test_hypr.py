"""Checks of the Hyprland config, run inside a fake `hl` API (tests/lua/check_hypr.lua)."""
import json
import re
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
    "SUPER + Escape",
    "SUPER + SPACE", "XF86AudioPlay", "XF86AudioNext", "XF86AudioRaiseVolume", "XF86AudioMute",
    "XF86AudioMicMute", "XF86MonBrightnessUp", "Print", "SHIFT + Print", "SUPER + Print",
    "SUPER + SHIFT + Print",
}

# Program of every command run by Hyprland -> its key in install/packages.tsv
# (None: always there).
PROGRAMS = {
    "kitty": "kitty", "firefox": "firefox", "nautilus": "nautilus", "qs": "quickshell",
    "hyprlock": "hyprlock", "playerctl": "playerctl", "wpctl": "wireplumber",
    "brightnessctl": "brightnessctl", "wl-paste": "wl-clipboard", "cliphist": "cliphist",
    "pidof": None,  # procps, in every base system
    "~/.local/bin/tfem": None,  # linked by the installer
}

# Dispatchers used by the config, as listed on wiki.hypr.land (Dispatchers).
DISPATCHERS = {
    "dsp.exec_cmd", "dsp.focus", "dsp.window.close", "dsp.window.fullscreen", "dsp.window.float",
    "dsp.window.drag", "dsp.window.resize", "dsp.window.move",
}

# Panels whose key is bound before the panel is built: the list must shrink
# as they arrive (a test fails when one of them gets a handler).
PENDING_PANELS = {"system", "settings"}


def programs(command):
    """First word of every part of a shell command line."""
    return [part.split()[0] for part in re.split(r"&&|\|\||;|\|", command) if part.strip()]


def ipc_handlers():
    """{target: {functions}} of every IpcHandler in the shell."""
    handlers = {}
    for qml in sorted((REPO / "quickshell").rglob("*.qml")):
        text = qml.read_text()
        for match in re.finditer(r"\bIpcHandler\s*\{", text):
            depth, end = 1, match.end()
            while depth:
                depth += {"{": 1, "}": -1}.get(text[end], 0)
                end += 1
            body = text[match.end():end]
            target = re.search(r'target:\s*"([^"]+)"', body).group(1)
            handlers.setdefault(target, set()).update(re.findall(r"function\s+(\w+)\s*\(", body))
    return handlers


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

    @property
    def commands(self):
        """Every command line Hyprland runs: keybinds and autostart."""
        bound = [args[1]["args"] for args in self.binds if args[1]["dispatcher"] == "dsp.exec_cmd"]
        return bound + [args[0] for args in self.calls_named("exec_cmd")]

    @property
    def ipc_calls(self):
        return [m for command in self.commands for m in re.findall(r"qs ipc -c (\S+) call (\S+) (\w+)", command)]

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

    def test_every_dispatcher_exists_in_hyprland(self):
        used = {args[1]["dispatcher"] for args in self.binds}
        self.assertEqual(sorted(used - DISPATCHERS), [])
        directions = {args[1]["args"]["direction"] for args in self.binds
                      if isinstance(args[1].get("args"), dict) and "direction" in args[1]["args"]}
        self.assertEqual(directions, {"left", "right", "up", "down"})

    def test_every_program_run_is_installed_by_the_installer(self):
        used = {program for command in self.commands for program in programs(command)}
        self.assertEqual(sorted(used - PROGRAMS.keys()), [])
        table = (REPO / "install/packages.tsv").read_text().splitlines()
        keys = {line.split("\t")[0] for line in table if line and not line.startswith("#")}
        self.assertEqual(sorted(k for k in PROGRAMS.values() if k and k not in keys), [])

    def test_the_cli_is_called_where_the_installer_links_it(self):
        deploy = (REPO / "install/deploy.sh").read_text()
        self.assertIn('BIN_DIR="$HOME/.local/bin"', deploy)
        self.assertIn("CLI_NAMES=(tfem ", deploy)

    def test_the_lock_key_has_a_hyprlock_config(self):
        # hyprlock exits without a config: the generator writes one.
        targets = (REPO / "templates/targets.toml").read_text()
        self.assertIn('output   = "{config}/hypr/hyprlock.conf"', targets)
        lock = next(args for args in self.binds if args[0] == "SUPER + L")
        self.assertIn("hyprlock", lock[1]["args"])

    def test_every_ipc_call_reaches_a_handler_of_the_shell(self):
        handlers = ipc_handlers()
        missing = [f"{target}.{function}" for _, target, function in self.ipc_calls
                   if target not in PENDING_PANELS and function not in handlers.get(target, set())]
        self.assertEqual(missing, [])
        self.assertEqual({name for name, _, _ in self.ipc_calls}, {"desktop"})

    def test_pending_panels_are_really_missing(self):
        self.assertEqual(sorted(PENDING_PANELS & ipc_handlers().keys()), [])
        self.assertLessEqual(PENDING_PANELS, {target for _, target, _ in self.ipc_calls})

    def test_programs_started_by_hyprland_know_the_terminal(self):
        # The launcher runs terminal apps in $TERMINAL.
        self.assertIn(["TERMINAL", "kitty"], self.calls_named("env"))

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
