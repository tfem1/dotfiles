"""End-to-end tests of `generate`, in an isolated HOME."""
import contextlib
import io
import json
import os
import shutil
import subprocess
import unittest

from helpers import REPO, SandboxTest
from theming.generate import main

GOLDEN = REPO / "tests/golden"


class GenerateTest(SandboxTest):
    def setUp(self):
        super().setUp()
        empty_bin = self.home / "bin"
        empty_bin.mkdir()
        self.env["PATH"] = str(empty_bin)  # no app "installed" by default

    def run_generate(self, *args):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            code = main(["--root", str(self.paths.root), *args], env=self.env)
        return code, out.getvalue()

    @property
    def hypr_theme(self):
        return self.paths.config_home / "hypr/theme.lua"

    @property
    def shell_theme(self):
        return self.paths.config_home / "quickshell/desktop/theme.json"


class OutputTest(GenerateTest):
    def test_renders_every_target_like_the_golden_files(self):
        code, _ = self.run_generate("--all")
        self.assertEqual(code, 0)
        hypr = self.paths.config_home / "hypr"
        pairs = ((self.hypr_theme, "theme.lua"), (hypr / "shell.lua", "shell.lua"),
                 (self.shell_theme, "theme.json"), (hypr / "hyprlock.conf", "hyprlock.conf"))
        for produced, golden in pairs:
            with self.subTest(golden=golden):
                if os.environ.get("UPDATE_GOLDEN"):
                    (GOLDEN / golden).write_text(produced.read_text())
                self.assertEqual(produced.read_text(), (GOLDEN / golden).read_text())

    def test_shell_theme_is_valid_json(self):
        self.run_generate("--all")
        data = json.loads(self.shell_theme.read_text())
        self.assertEqual(data["palette"]["name"], "Twilight")
        self.assertEqual(data["modules"]["wifi"], data["colors"]["blue"])
        self.assertEqual(data["modules"]["workspaces"], data["colors"]["accent"])

    @unittest.skipUnless(shutil.which("luac"), "luac not installed")
    def test_hyprland_theme_is_valid_lua(self):
        self.run_generate("--all")
        subprocess.run(["luac", "-p", str(self.hypr_theme)], check=True)

    def test_second_run_changes_nothing(self):
        self.run_generate("--all")
        _, output = self.run_generate("--all")
        self.assertEqual(output.count("unchanged"), 4)

    def test_absent_apps_are_skipped(self):
        code, output = self.run_generate()
        self.assertEqual(code, 0)
        self.assertIn("Hyprland not installed", output)
        self.assertFalse(self.hypr_theme.exists())

    def test_only_limits_the_targets(self):
        self.run_generate("--all", "--only", "quickshell")
        self.assertTrue(self.shell_theme.exists())
        self.assertFalse(self.hypr_theme.exists())

    def test_only_rejects_unknown_targets(self):
        code, output = self.run_generate("--only", "nope")
        self.assertEqual(code, 1)
        self.assertIn("nope", output)

    def test_shell_name_comes_from_config(self):
        self.write_user_file("config.json", '{"shell": {"name": "aurora"}}')
        self.run_generate("--all")
        self.assertTrue((self.paths.config_home / "quickshell/aurora/theme.json").exists())
        shell_lua = (self.paths.config_home / "hypr/shell.lua").read_text()
        self.assertIn('shellName = "aurora"', shell_lua)

    def test_shipped_hyprland_config_already_loads_the_theme(self):
        shipped = (REPO / "hypr/hyprland.lua").read_text()
        config = self.paths.config_home / "hypr/hyprland.lua"
        config.parent.mkdir(parents=True)
        config.write_text(shipped)
        self.run_generate("--all")
        self.assertEqual(config.read_text(), shipped)


class SafetyTest(GenerateTest):
    def test_dry_run_writes_nothing_and_shows_a_diff(self):
        code, output = self.run_generate("--all", "--dry-run")
        self.assertEqual(code, 0)
        self.assertIn("+hl.config({", output)
        self.assertFalse(self.hypr_theme.exists())
        self.assertFalse(self.paths.state_dir.exists())

    def test_invalid_settings_stop_before_writing(self):
        self.write_user_file("theme.toml", "[shape]\nradius = 999\n")
        code, output = self.run_generate("--all")
        self.assertEqual(code, 1)
        self.assertIn("shape.radius", output)
        self.assertFalse(self.hypr_theme.exists())

    def test_include_is_added_once_and_original_backed_up(self):
        config = self.paths.config_home / "hypr/hyprland.lua"
        config.parent.mkdir(parents=True)
        config.write_text("-- my config\n")
        self.run_generate("--all")
        self.run_generate("--all")
        text = config.read_text()
        self.assertTrue(text.startswith("-- my config\n"))
        self.assertEqual(text.count('require("theme")'), 1)
        backups = list((self.paths.state_dir / "backups").rglob("hyprland.lua"))
        self.assertEqual([b.read_text() for b in backups], ["-- my config\n"])

    def test_missing_app_config_is_never_created(self):
        _, output = self.run_generate("--all")
        self.assertFalse((self.paths.config_home / "hypr/hyprland.lua").exists())
        self.assertIn('require("theme")', output)

    def test_foreign_output_file_is_backed_up(self):
        self.hypr_theme.parent.mkdir(parents=True)
        self.hypr_theme.write_text("-- hand written\n")
        self.run_generate("--all")
        backups = list((self.paths.state_dir / "backups").rglob("theme.lua"))
        self.assertEqual([b.read_text() for b in backups], ["-- hand written\n"])


class ManifestTest(GenerateTest):
    def use_manifest(self, text, templates=None):
        root = self.copy_repo().root
        (root / "templates/targets.toml").write_text(text)
        for name, body in (templates or {}).items():
            (root / "templates" / name).write_text(body)

    def test_reload_runs_only_when_output_changes(self):
        marker = self.home / "reloaded"
        self.use_manifest(
            f'[demo]\ntemplate = "demo.tpl"\noutput = "{{config}}/demo.txt"\nreload = "touch {marker}"\n',
            {"demo.tpl": "{{ accent }}\n"},
        )
        self.run_generate()
        self.assertTrue(marker.exists())
        marker.unlink()
        self.run_generate()
        self.assertFalse(marker.exists())

    def test_no_reload_for_an_app_that_is_not_installed(self):
        marker = self.home / "reloaded"
        self.use_manifest(
            f'[demo]\ntemplate = "demo.tpl"\noutput = "{{config}}/demo.txt"\n'
            f'needs = "absent-app"\nreload = "touch {marker}"\n',
            {"demo.tpl": "{{ accent }}\n"},
        )
        code, _ = self.run_generate("--all")
        self.assertEqual(code, 0)
        self.assertTrue((self.paths.config_home / "demo.txt").exists())
        self.assertFalse(marker.exists())

    def test_broken_template_only_fails_its_own_target(self):
        self.use_manifest(
            '[bad]\ntemplate = "bad.tpl"\noutput = "{config}/bad.txt"\n'
            '[good]\ntemplate = "good.tpl"\noutput = "{config}/good.txt"\n',
            {"bad.tpl": "{{ nope }}\n", "good.tpl": "{{ fg }}\n"},
        )
        self.write_user_file("theme.toml", '[palette]\nsource = "catppuccin-mocha"\n')
        code, output = self.run_generate()
        self.assertEqual(code, 2)
        self.assertIn("unknown variable 'nope'", output)
        self.assertEqual((self.paths.config_home / "good.txt").read_text(), "#cdd6f4\n")

    def test_manifest_typos_are_reported(self):
        self.use_manifest('[demo]\ntemplate = "x.tpl"\nouput = "{config}/x"\n')
        code, output = self.run_generate()
        self.assertEqual(code, 1)
        self.assertIn("ouput", output)


if __name__ == "__main__":
    unittest.main()
