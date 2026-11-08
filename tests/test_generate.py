"""End-to-end tests of `generate`, in an isolated HOME."""
import contextlib
import io
import json
import os
import shutil
import subprocess
import tomllib
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
        config = self.paths.config_home
        pairs = ((self.hypr_theme, "theme.lua"), (hypr / "shell.lua", "shell.lua"),
                 (self.shell_theme, "theme.json"), (hypr / "hyprlock.conf", "hyprlock.conf"),
                 (config / "kitty/theme.conf", "kitty-theme.conf"),
                 (config / "gtk-3.0/theme.css", "gtk3-theme.css"), (config / "gtk-4.0/theme.css", "gtk4-theme.css"),
                 (config / "qt6ct/colors/theme.conf", "qt-colors.conf"), (config / "qt6ct/qt6ct.conf", "qt6ct.conf"),
                 (hypr / "hypridle.conf", "hypridle.conf"))
        for produced, golden in pairs:
            with self.subTest(golden=golden):
                # The config folder of the sandbox changes each run.
                text = produced.read_text().replace(str(config), "{config}")
                if os.environ.get("UPDATE_GOLDEN"):
                    (GOLDEN / golden).write_text(text)
                self.assertEqual(text, (GOLDEN / golden).read_text())

    def test_shell_theme_is_valid_json(self):
        self.run_generate("--all")
        data = json.loads(self.shell_theme.read_text())
        self.assertEqual(data["palette"]["name"], "Twilight")
        self.assertEqual(data["modules"]["wifi"], data["colors"]["accent2"])
        self.assertEqual(data["modules"]["media"], data["colors"]["accent3"])
        self.assertEqual(data["modules"]["workspaces"], data["colors"]["accent"])

    @unittest.skipUnless(shutil.which("luac"), "luac not installed")
    def test_hyprland_theme_is_valid_lua(self):
        self.run_generate("--all")
        subprocess.run(["luac", "-p", str(self.hypr_theme)], check=True)

    def test_second_run_changes_nothing(self):
        self.paths.sddm_dir.mkdir(parents=True)  # every target, the login screen's too
        self.run_generate("--all")
        _, output = self.run_generate("--all")
        targets = tomllib.loads((REPO / "templates/targets.toml").read_text())
        self.assertEqual(output.count("unchanged"), len(targets))

    def test_absent_apps_are_skipped(self):
        code, output = self.run_generate()
        self.assertEqual(code, 0)
        self.assertIn("Hyprland not installed", output)
        self.assertFalse(self.hypr_theme.exists())

    def test_the_login_screen_waits_for_its_folder(self):
        # /var/lib/tfem/sddm is made by `tfem sddm install`, with sudo.
        code, output = self.run_generate("--all")
        self.assertEqual(code, 0)
        self.assertIn("var/lib/tfem/sddm not set up", output)
        self.assertFalse(self.paths.sddm_dir.exists())

    def test_the_login_screen_gets_the_colors_and_a_copy_of_the_wallpaper(self):
        image = self.home / "Pictures/Wallpapers/pony/luna.jpg"
        image.parent.mkdir(parents=True)
        image.write_bytes(b"jpeg")
        self.write_user_file("theme.toml", '[wallpaper]\npath = "pony/luna.jpg"\n[palette]\nsource = "pony-luna"\n')
        self.paths.sddm_dir.mkdir(parents=True)
        self.env["PATH"] = "/usr/bin:/bin"  # the copy runs `cp`
        code, output = self.run_generate("--only", "sddm")
        self.assertEqual(code, 0, output)
        text = (self.paths.sddm_dir / "theme.conf").read_text()
        self.assertIn(f"background={self.paths.sddm_dir / 'background.jpg'}\n", text)
        self.assertIn("from Luna", text)
        self.assertEqual((self.paths.sddm_dir / "background.jpg").read_bytes(), b"jpeg")

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

    def test_kitty_gets_the_theme_and_keeps_its_own_settings(self):
        config = self.paths.config_home / "kitty/kitty.conf"
        config.parent.mkdir(parents=True)
        config.write_text("font_size 12\n")
        self.run_generate("--all")
        text = config.read_text()
        self.assertTrue(text.startswith("font_size 12\n"))
        self.assertTrue(text.rstrip().endswith("include theme.conf\n# <<< generated: kitty <<<"))
        # Only option names kitty knows (kitty/options/definition.py).
        known = {"foreground", "background", "selection_foreground", "selection_background", "cursor",
                 "cursor_text_color", "url_color", "active_border_color", "inactive_border_color",
                 "bell_border_color", "active_tab_foreground", "active_tab_background", "inactive_tab_foreground",
                 "inactive_tab_background", "tab_bar_background", *(f"mark{i}_{side}" for i in (1, 2, 3)
                 for side in ("foreground", "background")), *(f"color{i}" for i in range(16))}
        theme = (self.paths.config_home / "kitty/theme.conf").read_text().splitlines()
        used = {line.split()[0] for line in theme if line and not line.startswith("#")}
        self.assertEqual(sorted(used - known), [])
        self.assertEqual(len(used), len(known))

    def test_gtk_css_gets_the_import_first_in_a_closed_comment(self):
        mine = self.paths.config_home / "gtk-4.0/gtk.css"
        mine.parent.mkdir(parents=True)
        mine.write_text("window { border-radius: 0; }\n")
        self.run_generate("--all")
        self.run_generate("--all")
        self.assertEqual(mine.read_text(), '/* >>> generated: gtk4 >>> */\n@import url("theme.css");\n'
                                           '/* <<< generated: gtk4 <<< */\n\nwindow { border-radius: 0; }\n')

    def test_qt_palette_has_every_role_for_each_state(self):
        self.run_generate("--all")
        text = (self.paths.config_home / "qt6ct/colors/theme.conf").read_text()
        rows = dict(line.split("=", 1) for line in text.splitlines() if line.endswith(tuple("0123456789abcdef")))
        self.assertEqual(sorted(rows), ["active_colors", "disabled_colors", "inactive_colors"])
        for state, colors in rows.items():
            with self.subTest(state=state):
                self.assertEqual(len(colors.split(", ")), 21)  # QPalette roles up to PlaceholderText

    def test_kitty_conf_is_created_when_missing(self):
        self.run_generate("--all")
        self.assertIn("include theme.conf", (self.paths.config_home / "kitty/kitty.conf").read_text())

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

    def test_reload_command_can_use_theme_values(self):
        marker = self.home / "variant name"
        self.use_manifest(
            f'[demo]\ntemplate = "demo.tpl"\noutput = "{{config}}/demo.txt"\n'
            f'reload = "printf %s {{{{ palette.name | quote }}}} > \'{marker}\'"\n',
            {"demo.tpl": "{{ accent }}\n"},
        )
        self.run_generate()
        self.assertEqual(marker.read_text(), "Twilight")

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
